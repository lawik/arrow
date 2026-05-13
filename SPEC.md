# Arrow

A pure-Elixir implementation of the [Apache Arrow](https://arrow.apache.org/) columnar
format. The goal is a library that produces and consumes data byte-compatible with
other Arrow implementations (C++, Rust, Java, Go, JS, nanoarrow), verified against
Arrow's own cross-language integration test suite.

## Principles

- **Pure Elixir.** No NIFs, no ports, no native dependencies. Binary pattern matching
  and `:binary` / `<<>>` syntax handle everything.
- **Spec compliance is the bar.** Whatever this library produces must round-trip
  through other Arrow implementations and pass Arrow's integration tests. Performance
  is secondary to correctness.
- **Library, not framework.** No GenServers, no application, no global state. Plain
  functions over plain data structures.
- **Small surface, sharp edges.** Cover the type subset that real workloads need
  first; add exotic types only when there's a consumer.

## Scope

### In scope

- The Arrow in-memory columnar layout (validity bitmaps, value buffers, offset
  buffers, nested types).
- The Arrow **IPC** format (streaming + file).
- The Arrow **JSON integration test format** (used by `archery integration` to
  validate cross-language compatibility — see *Conformance* below).
- Mix tasks that expose the integration-test CLI surface so `archery` can drive
  this library as a participating implementation.

### Out of scope (for now)

- **FlatBuffers.** The Arrow IPC metadata (`Schema`, `RecordBatch`, `Message`,
  `Footer`) is FlatBuffers-encoded. FlatBuffers itself lives in a separate
  library, `sprawl`. Until that lands we can build everything *around* the
  metadata layer — data model, buffer layouts, JSON form, validation — and
  stub the FlatBuffers codec behind a single module boundary.
- **C Data Interface.** Useful only with a NIF; this is a pure-Elixir library.
- **Arrow Flight / Flight SQL.** gRPC RPC layer, not needed for export use cases.
- **Compute kernels.** No filters, aggregations, casts. Format only — math is the
  consumer's problem.
- **Parquet.** Different format, different library.

## Type system

Arrow defines roughly 35 logical types. We tier them.

### Tier 1 — v0.1 must-have

These cover virtually every metrics / IoT / tabular workload and are required for
the simplest integration test paths.

- `Null`
- `Bool`
- `Int8`, `Int16`, `Int32`, `Int64`
- `UInt8`, `UInt16`, `UInt32`, `UInt64`
- `Float32`, `Float64`
- `Utf8`, `Binary`
- `Date32`, `Date64`
- `Timestamp` (all units, with/without timezone)
- `List<T>`
- `Struct<...>`

### Tier 2 — v0.2

- `Time32`, `Time64`
- `Duration`
- `FixedSizeBinary`, `FixedSizeList`
- `Decimal128`
- `Dictionary<index, value>` (requires `DictionaryBatch` in IPC)
- `Map` (a list of struct under the hood)

### Tier 3 — eventually

- `Interval` (Year/Month, Day/Time, Month/Day/Nano)
- `Union` (sparse + dense)
- `Decimal256`
- `Float16`
- `LargeUtf8`, `LargeBinary`, `LargeList`
- `RunEndEncoded`
- Extension types (user metadata on top of a storage type)

## Architecture

Layered, with one module per concern. The dependency arrow only points downward.

```
Arrow.Ipc.Stream / Arrow.Ipc.File       -- framing + dispatch
Arrow.Ipc.Message                       -- continuation + length + body alignment
Arrow.Ipc.Metadata                      -- *thin wrapper over sprawl/FlatBuffers*
Arrow.Buffer                            -- raw column bytes per array layout
Arrow.Array                             -- per-type array structs
Arrow.Schema / Arrow.Field / Arrow.Type -- type system
Arrow.RecordBatch                       -- collection of arrays + schema
```

Parallel branch:

```
Arrow.Json.Reader / Arrow.Json.Writer   -- Arrow integration test JSON format
```

The JSON path is independent of FlatBuffers and is what unblocks early
compatibility testing.

### Data model

Plain structs. No process state.

```elixir
%Arrow.Schema{
  fields: [%Arrow.Field{name: "ts", type: %Arrow.Type.Timestamp{unit: :microsecond,
                                                                timezone: "UTC"},
                        nullable: false, metadata: %{}}],
  metadata: %{}
}

%Arrow.Array.Int64{
  length: 3,
  null_count: 1,
  validity: <<0b101::3>>,        # 1 = valid
  values: <<1::64, 0::64, 3::64>> # little-endian
}

%Arrow.RecordBatch{
  schema: %Arrow.Schema{...},
  length: 3,
  columns: [%Arrow.Array.Int64{...}, %Arrow.Array.Utf8{...}]
}
```

Validity bitmaps and value buffers are stored as raw binaries. Pattern matching
over them stays fast and lets us hand them straight to IO without re-encoding.

### Buffer layout

The on-the-wire layout per type is fully specified by the Arrow columnar format.
`Arrow.Buffer.{encode,decode}/2` handles each type's buffer set:

- Primitive: `validity` + `values`
- Variable binary (`Utf8`, `Binary`): `validity` + `offsets` + `values`
- List: `validity` + `offsets` + child array
- Struct: `validity` + N child arrays
- Dictionary: validity + indices (primitive layout), values stored once in
  `DictionaryBatch`

Buffer alignment: 8-byte boundaries, zero-padded. This is the contract.

### IPC framing

The IPC stream format is a sequence of length-prefixed messages:

```
continuation marker (0xFFFFFFFF, 4 bytes)
metadata length     (int32, 4 bytes)
metadata flatbuffer (variable, 8-byte aligned)
body                (column buffers, 8-byte aligned)
```

`Arrow.Ipc.Stream` handles the framing. `Arrow.Ipc.Metadata` is the only module
that needs FlatBuffers — it gets a single function per message type:

```elixir
@callback encode_schema(%Arrow.Schema{}) :: binary
@callback decode_schema(binary) :: %Arrow.Schema{}
# ... RecordBatch, DictionaryBatch, Footer
```

Until `sprawl` is available, `Arrow.Ipc.Metadata` is a behaviour with a
hand-rolled stub for the *minimum* messages our test data needs (e.g., a schema
with a single Int64 column). The stub is replaced wholesale when `sprawl` lands;
nothing above this module needs to change.

The file format wraps the stream format with magic bytes and a footer:

```
"ARROW1\0\0" ++ <stream messages> ++ <footer flatbuffer> ++ footer_length(int32) ++ "ARROW1"
```

### JSON integration test format

Arrow defines a [JSON
form](https://arrow.apache.org/docs/format/Integration.html#json-test-data-format)
specifically for cross-language testing — every primitive type has an unambiguous
JSON representation, validity is encoded as `[0, 1]` arrays, offsets are explicit.

This is the *correct* starting point because:

1. It doesn't touch FlatBuffers.
2. The Arrow project ships fixture files in its
   [`arrow-testing`](https://github.com/apache/arrow-testing) repo covering
   every type, edge case, sliced arrays, etc.
3. Implementing `JSON ↔ in-memory ↔ buffer-layout` round-trip covers the
   correctness story for the data model without needing the wire format yet.

`Arrow.Json` modules implement the spec directly. `mix arrow.validate <json>`
becomes a useful tool from day one.

## Conformance: the archery integration suite

Arrow ships a Python-based cross-language test runner in
`apache/arrow:dev/archery/`. Each participating implementation provides a CLI
that supports four modes. The runner exercises every type combination, then
cross-checks producers against consumers.

### Required CLI modes

| Mode                            | Purpose                                         |
|---------------------------------|-------------------------------------------------|
| `arrow-json-integration-arrow`  | Read JSON fixture → write IPC file              |
| `arrow-json-integration-json`   | Read IPC file → write JSON fixture              |
| `arrow-json-integration-validate` | Compare IPC file against JSON fixture          |
| `arrow-flight-test-integration-server` (later) | Flight producer (optional, Tier 3) |
| `arrow-flight-test-integration-client` (later) | Flight consumer (optional, Tier 3) |

### Implementation

These are exposed as **mix tasks**, invoked by `archery` as subprocesses:

```
mix arrow.integration.json_to_arrow --json <path> --arrow <path>
mix arrow.integration.arrow_to_json --arrow <path> --json <path>
mix arrow.integration.validate     --json <path> --arrow <path>
```

A thin shim (escript or shell wrapper) provides the exact binary names archery
expects (`arrow-json-integration-arrow`, etc.) and forwards to the mix tasks.

### Local test harness

`mix arrow.testing.fixtures` clones / refreshes the `arrow-testing` repo into
`priv/arrow-testing/`. The Elixir test suite then iterates every fixture and
exercises the round-trip:

```
JSON fixture --(json reader)--> in-memory --(buffer encode)--> bytes
bytes --(buffer decode)--> in-memory --(json writer)--> JSON
diff against original fixture
```

Plus, once FlatBuffers lands:

```
JSON --(json reader)--> in-memory --(IPC writer)--> .arrow file
.arrow file --(IPC reader)--> in-memory --(json writer)--> JSON
diff against original fixture
```

ExUnit cases are generated dynamically from the fixture set, one test per
fixture, so failures point at a specific JSON file and type.

### Upstream integration

Once the round-trip passes a meaningful fraction of fixtures, propose adding
Elixir to `apache/arrow:dev/archery/archery/integration/tester_elixir.py` so
this library participates in the official cross-language matrix. That's a real
PR conversation, not a code change here — but the CLI surface above is what
makes it possible.

## Milestones

### v0.1 — JSON round-trip, Tier 1 types

- [ ] Data model: `Schema`, `Field`, `Type`, `Array.*`, `RecordBatch`
- [ ] Buffer codec: encode/decode all Tier 1 types to/from raw buffer layout
- [ ] JSON reader: parse Arrow integration JSON for all Tier 1 types
- [ ] JSON writer: emit Arrow integration JSON for all Tier 1 types
- [ ] Fixture harness: pull `arrow-testing`, run round-trip tests
- [ ] Mix tasks: `integration.validate` works end-to-end (JSON ↔ in-memory)

### v0.2 — IPC, depends on sprawl

- [ ] `Arrow.Ipc.Metadata` real implementation backed by sprawl
- [ ] IPC stream reader/writer
- [ ] IPC file reader/writer
- [ ] Mix tasks: `integration.json_to_arrow`, `integration.arrow_to_json`
- [ ] Pass `archery integration` end-to-end against the C++ reference
      implementation for Tier 1 types

### v0.3 — Tier 2 types

- [ ] Decimal128, Dictionary, FixedSize{Binary,List}, Time32/64, Duration, Map
- [ ] DictionaryBatch handling
- [ ] Upstream PR adding Elixir to the archery matrix

### Later

- Tier 3 types
- Flight (only if a consumer asks for it)

## Non-goals — explicit

- **Performance parity with arrow-rs / arrow-cpp.** We are I/O bound for export
  workloads; that's fine. If someone needs SIMD column kernels, they should
  reach for Explorer / Polars / a Rust NIF.
- **Compute.** Filtering, aggregation, sorting, casting — all out. This library
  is the format, not the engine.
- **In-place mutation.** Arrow arrays are immutable. Builders for incremental
  construction may come later but are not v0.1.
- **A query language.** No.

## Dependency contract with sprawl

`sprawl` provides a general FlatBuffers reader/writer. `Arrow.Ipc.Metadata`
needs:

- Decode bytes → struct, for the message types: `Schema`, `RecordBatch`,
  `DictionaryBatch`, `Message`, `Footer`, `Tensor`.
- Encode struct → bytes, same set.

The `.fbs` schemas live in
[`apache/arrow:format/`](https://github.com/apache/arrow/tree/main/format) —
`Schema.fbs`, `Message.fbs`, `File.fbs`, `Tensor.fbs`. These are stable across
Arrow versions (major bumps only).

Sprawl's job is to consume those `.fbs` files (or hand-rolled equivalents) and
expose typed Elixir struct ↔ binary functions. Anything beyond that is its
concern, not Arrow's.
