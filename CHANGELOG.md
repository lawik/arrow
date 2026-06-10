# Changelog

## v0.1.0

Initial release.

- Pure-Elixir Apache Arrow columnar data model: `Null`, `Bool`,
  `Int{8,16,32,64}` (signed + unsigned), `Float{32,64}`, `Utf8`,
  `Binary`, `Date{32,64}`, `Timestamp`, `Time{32,64}`, `Duration`,
  `FixedSizeBinary`, `FixedSizeList`, `List`, `Struct`, `Map`,
  `Decimal{32,64,128,256}`, `Dictionary`, `Interval` (`YEAR_MONTH` /
  `DAY_TIME` / `MONTH_DAY_NANO`), `LargeUtf8`, `LargeBinary`,
  `LargeList`.
- IPC stream and file formats: RecordBatch + DictionaryBatch messages,
  end-of-stream markers, file footer and Block descriptors.
- Arrow integration-test JSON reader and writer (`Arrow.Json`).
- Null-aware logical comparator (`Arrow.Logical`).
- Archery integration mix tasks (`mix arrow.integration.*`) with
  subprocess shims under `bin/`.
- Conformance-tested against the apache/arrow-testing fixture corpus
  and pyarrow-produced golden files.
- FlatBuffers metadata codec generated from the vendored apache/arrow
  `.fbs` schemas; the generated code is dependency-free.

Limitations: little-endian only; no Union, `BinaryView` / `Utf8View`,
`ListView` / `LargeListView`, `RunEndEncoded`, or `Float16`; no IPC
body compression.
