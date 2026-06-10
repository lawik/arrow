# arrow

Pure-Elixir [Apache Arrow](https://arrow.apache.org/). Verified
round-trip against the upstream `arrow-testing` cross-language fixture
corpus, with pyarrow-produced golden files in the default test suite.

## Install

```elixir
{:arrow, "~> 0.1.0"}
```

`:flatbuf` is a `:dev`-only dependency (tracking
[lawik/flatbuf](https://github.com/lawik/flatbuf) main) — used once to
regenerate the metadata codec from the vendored `.fbs` sources.
Generated code is dependency-free.

## Use

In-memory data model:

```elixir
schema = %Arrow.Schema{
  fields: [
    %Arrow.Field{name: "n", type: %Arrow.Type.Int{bit_width: 32, signed: true}, nullable: false},
    %Arrow.Field{name: "s", type: %Arrow.Type.Utf8{}, nullable: true}
  ]
}

batch = %Arrow.RecordBatch{
  schema: schema,
  length: 3,
  columns: [
    %Arrow.Array.Int32{length: 3, null_count: 0, values: Arrow.Buffer.pack_primitive([1, 2, 3], :int32)},
    %Arrow.Array.Utf8{length: 3, null_count: 0,
                      offsets: Arrow.Buffer.pack_int32_offsets([3, 3, 3]),
                      values: "foobarbaz"}
  ]
}
```

IPC stream + file formats:

```elixir
bin = Arrow.Ipc.Stream.encode(schema, [batch])
{:ok, %{schema: ^schema, dictionaries: %{}, batches: [_]}} = Arrow.Ipc.Stream.decode(bin)

bin = Arrow.Ipc.File.encode(schema, [batch])
{:ok, decoded} = Arrow.Ipc.File.decode(bin)
```

Arrow integration test JSON:

```elixir
{:ok, %{schema: _, dictionaries: _, batches: _}} = Arrow.Json.decode(File.read!("fixture.json"))
iodata = Arrow.Json.encode(schema, [batch])
```

Null-aware logical equality across formats and producers:

```elixir
Arrow.Logical.payloads_equivalent?(from_stream, from_json)
```

Archery integration CLI (subprocess shims under `bin/`):

```sh
mix arrow.integration.json_to_arrow --json fixture.json --arrow out.arrow
mix arrow.integration.arrow_to_json --arrow file.arrow --json out.json
mix arrow.integration.validate     --json fixture.json --arrow file.arrow
```

Run the tests:

```sh
mix test                          # always-run suite, incl. golden decode
                                  # tests against pyarrow-produced IPC
                                  # files (test/golden/)
mix arrow.testing.fixtures        # one-time: clone apache/arrow-testing
mix test --include fixtures       # cross-language conformance suite
```

## Coverage

Logical types: `Null`, `Bool`, `Int{8,16,32,64}` (signed + unsigned),
`Float{32,64}`, `Utf8`, `Binary`, `Date{32,64}`, `Timestamp` (all units
+ timezone), `Time{32,64}`, `Duration`, `FixedSizeBinary`,
`FixedSizeList`, `List`, `Struct`, `Map`, `Decimal{32,64,128,256}`,
`Dictionary` (incl. `DictionaryBatch` in IPC), `Interval`
(`YEAR_MONTH` / `DAY_TIME` / `MONTH_DAY_NANO`), `LargeUtf8`,
`LargeBinary`, `LargeList`.

IPC: stream framing, file format (magic + Footer + Block descriptors),
RecordBatch + DictionaryBatch messages, end-of-stream markers.

## Limitations

- Little-endian only. Big-endian IPC payloads are rejected on decode.
- IPC body compression (`LZ4_FRAME` / `ZSTD`) is rejected on decode.
- Union (sparse + dense), `BinaryView` / `Utf8View`,
  `ListView` / `LargeListView`, `RunEndEncoded`, and `Float16` are
  rejected on decode and absent from the data model.
- Legacy (pre-0.15 / V4, no continuation marker) IPC files are
  rejected.
- Tensor and SparseTensor messages are out of scope for the IPC reader.
- Delta `DictionaryBatch` messages are rejected.
- `force_align` and `(vector64)` follow flatbuf's coverage, not ours.
- `Float32` / `Float64` `NaN` slots break the logical comparator
  (`NaN != NaN` per IEEE-754). Float NaN-heavy data needs custom
  comparison.

## License

Apache-2.0.
