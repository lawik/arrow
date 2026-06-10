# Review — `arrow` (pure-Elixir Apache Arrow)

Reviewed 2026-06-10 at commit `6db7d81` (clean tree). Scope: quality,
completeness, and general sanity of the hand-written code (`lib/arrow/**`
excluding the generated `lib/arrow/ipc/flatbuf/`), the test suite, the
mix tasks/shims, and the project tooling. Method: ran the full gate
suite, then file-by-file review of all ~4,600 hand-written lines with
spot-verification against the Arrow columnar/IPC/integration-JSON specs.

## Verdict

The core library is in genuinely good shape. The spec-tricky details
all check out: LSB-first validity bitmaps (including partial final
bytes), little-endian signed/unsigned/float packing, two's-complement
Decimal 32/64/128/256, Interval `DAY_TIME`/`MONTH_DAY_NANO` layouts,
absolute (non-zero-based) offsets, struct-validity-over-children null
semantics, IPC framing (continuation + length + 8-byte padding), EOS
marker, file magic/Footer/Block layout, prefix-inclusive
`metaDataLength`, per-type buffer ordering, and the integration-JSON
conventions (64-bit ints as strings, uppercase hex, interval objects,
dictionary batch shape). Docs are unusually thorough, formatting is
clean, error style is consistent.

The problems cluster in three places: **the project's own quality gates
are red on a clean checkout**, **the archery integration path drops
dictionaries in both directions**, and **the interop boundary silently
misreads rather than rejects** (compression, big-endian, Float16).
Plus the usual pre-release loose ends (TODO link, empty changelog).

---

## 1. Broken on a clean checkout (sanity)

Every step of the `mix check` alias after `format` currently fails:

- **Dev env does not compile.** `mix.exs:84` declares
  `{:flatbuf, path: "../flatbuf-stable", only: [:dev]}` — a sibling
  directory that does not exist here. `mix compile`, `mix check`,
  `mix dialyzer`, and `mix docs` all die at dependency resolution in
  dev. Test env works only because the dep is dev-only. Anyone cloning
  the repo cannot run the documented gates. Either vendor a pinned
  flatbuf (hex or git dep), or make it `optional` with a documented
  bootstrap step.
- **`mix credo` exits 14.** 1,132 issues, *all* in the generated
  `lib/arrow/ipc/flatbuf/` codec. `.credo.exs` includes all of `lib/`
  with `strict: true` and no exclusion. The hand-written code is
  credo-clean. Add `excluded: ["lib/arrow/ipc/flatbuf/"]`.
- **`mix spellweaver.check` exits 1.** ~500 issues in 70 files, again
  dominated by generated code not in `.cspell.json` `ignorePaths`.
  README itself has four unknown words (`flatbuf`, `foobarbaz`,
  `bigendian`, `flatbuf's`). Separately: the cspell config pulls a
  dictionary from a raw GitHub URL at check time — a network dependency
  in a quality gate.
- **`mix dialyzer` exits 2.** One error in generated code
  (`lib/arrow/ipc/flatbuf/wire.ex:136`, pattern can never match);
  `.dialyzer_ignore.exs` is empty.

The `QUALITY.md` punch-list commit (`6db7d81`) treated generated-code
issues as out of scope for *fixing* — correct — but the gate configs
were never taught that, so the gates fail anyway. One config pass
(credo exclude, cspell ignorePath, one dialyzer ignore entry) plus a
resolvable flatbuf dep would turn `mix check` green.

## 2. High — archery integration tasks drop dictionaries (both directions)

This defeats the stated purpose of the integration CLI for any
dictionary fixture, and nothing flags it:

- `lib/mix/tasks/arrow.integration.json_to_arrow.ex:26-36` destructures
  only `schema`/`batches` from `Arrow.Json.decode/1` and calls
  `IpcFile.encode(schema, batches)` — the third `dictionaries` argument
  defaults to `%{}`. Output: an IPC file whose schema declares
  dictionary encoding but contains zero `DictionaryBatch` messages.
  Spec-invalid; every other implementation will reject it.
- `lib/mix/tasks/arrow.integration.arrow_to_json.ex:27-36` — same drop
  the other way. The JSON writer omits the top-level `"dictionaries"`
  key when the registry is empty, producing JSON this library's own
  reader cannot parse back.

Both are one-line fixes — `Arrow.Json.encode/3`, `Stream.encode/3`, and
`File.encode/3` all already accept the registry. A defensive raise in
the writers when the schema has dictionary fields but the registry is
empty would have caught both. The library-level dictionary path is
correct; only the task plumbing drops it — which also shows the
tasks/shims have no test coverage of their own.

## 3. High — silent misreads at the interop boundary

- **Body compression is never inspected.** The generated
  `Flatbuf.RecordBatch` decodes the `compression` field, but no
  consumer reads it (zero references outside generated code:
  `lib/arrow/ipc/stream.ex:261-282`, `lib/arrow/ipc/file.ex:188-227`,
  `lib/arrow/ipc/metadata.ex:102-113`). An LZ4/ZSTD-compressed stream
  decodes without error into garbage values — fixed-width columns read
  compressed bytes as data. A `raise` on non-nil compression turns this
  into a clean rejection. **Also absent from the README limitations
  list**, which otherwise carefully enumerates unsupported features.
- **Endianness dropped on decode.** `from_fb_schema`
  (`lib/arrow/ipc/metadata.ex:145-150`) ignores the `endianness` field,
  so big-endian payloads byte-swap silently. The README documents this,
  but decode rejecting `:Big` is one clause and converts documented
  corruption into an error.
- **Float16 is half-wired, and the README misstates it.** README says
  Float16 is "rejected on decode" — actually `metadata.ex:339` and
  `json/reader.ex:144` accept `HALF` at schema level, then body/data
  decode dies with an opaque `FunctionClauseError` from
  `Type.primitive_array_mod/1`. Worse, `Type.primitive_kind/1`
  (`lib/arrow/type.ex:322`) maps `:half` to `:float32` (4 bytes/slot
  instead of 2) — a landmine for whoever "completes" the missing
  clause. Reject `HALF` explicitly at both schema entry points and
  delete the `:float32` mapping.

## 4. Medium — correctness and robustness

- `lib/arrow/ipc/body.ex:315-319` — `push_buffer` records the declared
  `len` and advances offsets by it, but appends the *whole* binary.
  A decoded foreign buffer with padded declared length (spec-legal),
  re-encoded, desynchronizes every subsequent buffer offset: silently
  corrupt output. Assert or slice `byte_size(bin) == len`.
- `lib/arrow/ipc/body.ex:652-669` — when a validity buffer has declared
  length 0 but `null_count > 0`, the decoder synthesizes an all-ones
  bitmap via `List.duplicate(1, row_count)` where `row_count` is the
  untrusted int64 node length: a malformed message triggers multi-GB
  allocation, and the invented bitmap silently discards claimed nulls.
  Validate node length against body size; raise on the inconsistency.
- `lib/arrow/ipc/stream.ex:51-58` / `file.ex:61-107` — encode validates
  that every supplied dictionary has a referencing field but not the
  converse: a dictionary-encoded field with no entry in the registry
  encodes into spec-invalid output (indices, no DictionaryBatch), which
  this library's own decoder also accepts — round-trip masks it.
- `lib/arrow/logical.ex:177` — dictionary index resolution uses
  `Enum.at/2`: index `-1` wraps to the last dictionary entry and
  out-of-range becomes `nil` (null). A conformance comparator should
  bounds-check and raise, as it already does for missing dictionary ids.
- `lib/arrow/logical.ex:234-243` — `payloads_equivalent?/2` compares
  dictionary arrays element-wise, so identical logical data with
  permuted or superset dictionaries compares *unequal* (verified:
  `batches_equal?` says true, `payloads_equivalent?` says false). The
  official integration comparison resolves dictionaries and compares
  values only. Over-strict for its stated purpose.
- `lib/arrow/ipc/stream.ex:257-259` — a second Schema message
  mid-stream silently replaces the schema; should raise.
- `lib/arrow/ipc/file.ex:229-240` — `read_block` skips `offset + 8`
  without checking the `0xFFFFFFFF` continuation marker (and the footer
  `version` is read but unused), so legacy V4 files or corrupt Block
  offsets misparse opaquely instead of failing with a framing error.

## 5. Medium — test suite trust (FIXED 2026-06-10)

> **Status: addressed.** The always-run tier now contains external
> ground truth: `test/golden/` holds small pyarrow-produced `.stream` /
> `.arrow` files (regenerable via `test/golden/generate.py`) and
> `test/arrow/golden_test.exs` asserts schemas and per-slot logical
> values against literals from the generator — a symmetric
> encode/decode bug can no longer pass. Added
> `test/arrow/ipc/edge_case_test.exs` (zero-row batch, all-null
> columns, DictionaryBatch round-trip through stream *and* file) and
> `test/arrow/ipc/malformed_test.exs` (truncated/garbage/bad-magic
> inputs must return `{:error, _}`). The fixture harnesses now flunk
> when `--include fixtures` is given without a corpus, soft-skip only
> "unsupported"-type ArgumentErrors (anything else flunks), compare the
> dictionary registry in the JSON round-trip, and no longer emit
> compile warnings when the corpus is absent. Original findings below
> for the record.

`mix test` (94 green) is a self-consistency suite, not a conformance
suite. All real external ground truth lives in the excluded `fixtures`
tier, and that tier leaks trust in four ways:

- **Absent corpus passes green.** With no `priv/arrow-testing/`,
  `mix test --include fixtures` runs three placeholder tests and
  reports success (verified). A CI job that forgets
  `mix arrow.testing.fixtures` reports full conformance with zero
  conformance coverage. Flunk or `@tag :skip` when the corpus is
  explicitly requested but missing.
- **ArgumentError soft-skip without an allowlist**
  (`test/arrow/fixtures_test.exs:61-62`, both IPC fixture harnesses):
  any `{:error, %ArgumentError{}}` becomes a stderr note and a pass.
  A regression that makes a *supported* type raise ArgumentError
  silently downgrades a conformance failure to a warning. Maintain an
  expected-unsupported allowlist and fail on unexpected skips.
- **JSON fixture round-trip drops dictionaries**
  (`test/arrow/fixtures_test.exs:55-59`): decodes `dictionaries`, never
  re-encodes or compares them — the same blind spot as the mix tasks.
- **No external golden bytes in the always-run tier.** Every always-run
  IPC/JSON test is encode→decode through the library's own code; both
  flatbuffer directions come from the same codegen, so symmetric bugs
  pass. Even two or three small hardcoded pyarrow-produced binaries
  committed as test data would anchor the default run.

Other gaps: zero malformed-input/error-path assertions anywhere
(`assert_raise`/`{:error` absent from test/ outside the harnesses);
no zero-row batch, zero-length offsets-buffer, or all-null column tests
at IPC level; the DictionaryBatch stream/file path is covered *only* by
excluded fixtures; `mix arrow.testing.fixtures` clones the default
branch HEAD un-pinned, so conformance results drift with upstream
(still open). The compile warnings (`@upstream_divergent`,
`read_fixture/1`) were benign artifacts of the absent corpus — the
skip-lists were still wired — but indistinguishable from a real
unwiring; test generation is now guarded on a non-empty fixture list.

## 6. Release readiness

- `mix.exs:38` — package link is `https://github.com/TODO/arrow`.
- `CHANGELOG.md` — "TODO: write changelog".
- `package/0` sets no `:files`, so Hex's defaults apply: all of `priv/`
  ships. After running `mix arrow.testing.fixtures`, that means the
  multi-hundred-MB `priv/arrow-testing/` clone goes into the tarball
  (`.gitignore` does not affect `mix hex.build`). Conversely `bin/`
  (the documented archery shims) is *not* in Hex defaults and won't
  ship. Set `:files` explicitly.
- `elixir: "~> 1.19"` is a very fresh floor — fine if intentional,
  worth a conscious decision before publishing.
- Leftover scaffold comments in `deps/0` (`dep_from_hexpm`/
  `dep_from_git`).

## 7. Low / polish

- Stale moduledocs contradicting the code: `lib/arrow/ipc/file.ex:32-39`
  (claims dictionaries written empty + inline schema authoritative;
  code does neither), `lib/arrow/ipc/stream.ex:30-32` (DictionaryBatch
  "out of scope" but implemented), `lib/arrow/ipc/metadata.ex:18-24`
  ("forthcoming" function exists in the same file),
  `arrow.integration.validate` moduledoc names the wrong comparator
  function.
- `Stream.decode`/`File.decode` rescue-everything and return raw
  exception structs (`{:error, %MatchError{}}`) — unstable API surface,
  and library bugs are indistinguishable from bad input. The integration
  tasks then pattern-match `{:ok, _}` and crash with a MatchError dump
  (exit code still non-zero, so archery works, but the message is
  buried).
- `lib/arrow/buffer.ex:157` — `unpack_primitive/3` at length 0 matches
  only `<<>>`, rejecting spec-legal padded zero-length buffers.
- `lib/arrow/array.ex:388` — moduledoc example `validity: <<0b101::3>>`
  is an invalid 3-bit bitstring read MSB-first; contradicts the
  LSB-first layout documented below it. Should be `<<0b00000101>>`.
- `lib/arrow/type.ex:135-139` — Decimal typespec still
  `128 | 256` and the tier note predates Decimal32/64 support.
- Dead code: `Arrow.Type.bit_width/1` (no callers),
  `json/writer.ex:195` Null `array_count` clause (shadowed),
  `stream.ex:253-255` `dispatch_message` pass-through.
- `json/writer.ex:204-208` — Bool DATA emitted as 0/1; spec-permitted
  but every reference writer emits `true`/`false`, and strict readers
  may reject 0/1.
- `json/writer.ex:339-340` — FixedSizeBinary DATA comprehension iterates
  the whole values buffer instead of `a.length` slots; padded foreign
  buffers yield phantom slots.
- `maybe_gunzip/1` duplicated across two tasks; `arrow_to_json` is the
  one task that can't read gzipped input.
- Tasks use `OptionParser.parse/2` and discard invalid switches —
  `--josn` yields the misleading "--json is required"; `parse!/2` fixes
  it for free.
- `test/arrow_test.exs:3` — `doctest Arrow` contributes zero doctests
  (`lib/arrow.ex` has no examples).
- README limitations honestly cover NaN, views, unions, tensors — add
  compression (see §3) and correct the Float16 wording.

## Suggested order of attack

1. Fix the two dictionary drops in the integration tasks + add a task-
   level round-trip test (§2). One line each.
2. Reject compression, big-endian, and HALF at decode (§3). A few lines
   each; converts silent corruption into errors.
3. Un-redden the gates: resolvable flatbuf dep, credo/cspell excludes
   for generated code, one dialyzer ignore (§1).
4. ~~Harden the fixture harness and add external golden binaries +
   malformed-input tests~~ — done, see §5. Remaining from §5: pin
   `mix arrow.testing.fixtures` to a revision.
5. Pre-publish pass: GitHub link, changelog, `:files` in package
   (§6), then the §4/§7 punch list.
