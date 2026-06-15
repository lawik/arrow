<!--
  SPDX-FileCopyrightText: None
  SPDX-License-Identifier: CC0-1.0
-->

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
- Typed decode errors: decoders return `{:error, %Arrow.DecodeError{}}`
  with kind `:unsupported` or `:malformed`, plus raising `decode!/1`
  variants.
- Null-aware logical comparator (`Arrow.Logical`).
- CLI mix tasks: `mix arrow.inspect` (schema, batch row counts, and
  dictionary summary of an IPC file or stream) and `mix arrow.convert`
  (file ↔ stream, dictionaries preserved).
- Archery integration scripts (`scripts/*.exs`) with subprocess shims
  under `bin/` — repo-only development tooling, not part of the Hex
  package.
- Conformance-tested against the apache/arrow-testing fixture corpus
  and pyarrow-produced golden files.
- FlatBuffers metadata codec generated from the vendored apache/arrow
  `.fbs` schemas; the generated code is dependency-free.
- REUSE-compliant licensing metadata: SPDX headers / `REUSE.toml`
  annotations on every file, license texts under `LICENSES/`, and a
  `NOTICE` file carrying the Apache Arrow attribution for the vendored
  `.fbs` schemas.

Limitations: little-endian only; no Union, `BinaryView` / `Utf8View`,
`ListView` / `LargeListView`, `RunEndEncoded`, or `Float16`; no IPC
body compression.
