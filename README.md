<!--
  SPDX-FileCopyrightText: 2026 Lars Wikman
  SPDX-License-Identifier: Apache-2.0
-->

# arrow

Pure-Elixir [Apache Arrow](https://arrow.apache.org/). Verified
round-trip against the upstream `arrow-testing` cross-language fixture
corpus, with pyarrow-produced golden files in the default test suite.

## Install

```elixir
{:arrow, "~> 0.1.0"}
```

`:flatbuf` ([lawik/flatbuf](https://github.com/lawik/flatbuf)) is a
`:dev`-only dependency from Hex, used once to regenerate the metadata
codec from the vendored `.fbs` sources.
Generated code is dependency-free. After regenerating, re-apply
`@moduledoc false` to the generated modules (they are internal and kept
out of the docs):

```sh
perl -i -pe 's{^(\s*)\@moduledoc ".*"$}{$1\@moduledoc false}' lib/arrow/ipc/flatbuf/*.ex
```

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

Decoders return `{:ok, payload}` or `{:error, %Arrow.DecodeError{kind:
:unsupported | :malformed}}`; `decode!/1` variants raise instead.

Arrow integration test JSON:

```elixir
{:ok, %{schema: _, dictionaries: _, batches: _}} = Arrow.Json.decode(File.read!("fixture.json"))
iodata = Arrow.Json.encode(schema, [batch])
```

Null-aware logical equality across formats and producers:

```elixir
Arrow.Logical.payloads_equivalent?(from_stream, from_json)
```

Mix tasks for poking at IPC data from the command line:

```sh
mix arrow.inspect data.arrow             # schema, batch row counts, dictionaries
mix arrow.convert data.arrow out.stream  # file ↔ stream, input auto-detected
```

Archery integration CLI (subprocess shims under `bin/`, forwarding to
repo-only scripts under `scripts/` — not part of the Hex package):

```sh
mix run scripts/json_to_arrow.exs --json fixture.json --arrow out.arrow
mix run scripts/arrow_to_json.exs --arrow file.arrow --json out.json
mix run scripts/validate.exs --json fixture.json --arrow file.arrow
```

Run the tests:

```sh
mix test                          # always-run suite, incl. golden decode
                                  # tests against pyarrow-produced IPC
                                  # files (test/golden/)
./scripts/fetch_fixtures.sh       # one-time: clone apache/arrow-testing
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

Apache-2.0. This project is [REUSE](https://reuse.software/)-compliant:
every file carries SPDX licensing information (in-file headers or
`REUSE.toml`), license texts live in `LICENSES/`, and `NOTICE` carries
the attribution for the FlatBuffers schemas vendored from
[apache/arrow](https://github.com/apache/arrow). `reuse spdx` generates
an SPDX bill of materials. Not affiliated with the Apache Software
Foundation.
