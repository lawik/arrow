<!--
  SPDX-FileCopyrightText: 2026 Lars Wikman
  SPDX-License-Identifier: Apache-2.0
-->

# archery integration

Runbook for running Apache Arrow's `archery integration`
cross-language test runner against this library, as both producer and
consumer.

## How it plugs in

archery subprocesses the shims in `bin/`, which forward to the
scripts under `scripts/` via `mix run`:

| shim | script |
|---|---|
| `bin/arrow-json-integration-arrow` | `scripts/json_to_arrow.exs` |
| `bin/arrow-json-integration-json` | `scripts/arrow_to_json.exs` |
| `bin/arrow-json-integration-validate` | `scripts/validate.exs` |
| `bin/arrow-file-to-stream` | `scripts/file_to_stream.exs` |
| `bin/arrow-stream-to-file` | `scripts/stream_to_file.exs` |

`integration/tester_elixir.py` is the archery tester class (canonical
copy; it gets copied into the archery checkout).
`integration/archery-elixir.patch` wires it into archery's CLI/runner
and marks the per-case skips (`.skip_tester('Elixir')`).

## Setup

```sh
# 1. Shallow-clone upstream Arrow (for dev/archery); any recent main works.
#    Patch verified against ca47cd10b651a8ff5fe44fbb23f7e01dc982a57d.
git clone --depth 1 --filter=blob:none https://github.com/apache/arrow.git /tmp/arrow-upstream

# 2. Install archery into a Python venv (needs pyarrow's deps for datagen).
python3 -m venv /tmp/pyarrow-venv
/tmp/pyarrow-venv/bin/pip install -e '/tmp/arrow-upstream/dev/archery[integration]'

# 3. Wire in the Elixir tester.
cp integration/tester_elixir.py /tmp/arrow-upstream/dev/archery/archery/integration/
git -C /tmp/arrow-upstream apply "$PWD/integration/archery-elixir.patch"

# 4. Compile once so parallel archery invocations don't race to compile.
mix compile
```

## Run

```sh
GOLD=$PWD/priv/arrow-testing/data/arrow-ipc-stream/integration
ARROW_ELIXIR_PATH=$PWD /tmp/pyarrow-venv/bin/archery integration --run-ipc --with-elixir=1 \
  --gold-dirs=$GOLD/0.17.1 \
  --gold-dirs=$GOLD/1.0.0-littleendian \
  --gold-dirs=$GOLD/4.0.0-shareddict \
  --gold-dirs=$GOLD/cpp-21.0.0
```

`ARROW_ELIXIR_PATH` must point at this repo's root. Expect
`0 failures, 10 skips` over 88 cases.

## What is skipped, and why

Per-case skips (marked in `datagen.py` by the patch, inherited by the
same-named gold cases):

- `union` — Union types unsupported
- `run_end_encoded` — run-end encoding unsupported
- `binary_view`, `list_view` — view types unsupported

Gold directories not passed at all:

- `0.14.1` — legacy pre-0.15 framing (no continuation marker;
  rejected on decode)
- `1.0.0-bigendian` — big-endian buffers unsupported
- `2.0.0-compression` — LZ4/ZSTD body compression unsupported
