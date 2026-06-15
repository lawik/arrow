#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Clone or update the apache/arrow-testing fixture corpus into
# priv/arrow-testing at the pinned revision, shallowly, so
# `mix test --include fixtures` runs are reproducible. Idempotent:
# a checkout already at the pin is left untouched.
#
# The CI cache key (ARROW_TESTING_REVISION in .github/workflows/ci.yml)
# must match REVISION below — bump both together.

set -euo pipefail

REPO="https://github.com/apache/arrow-testing.git"
TARGET="priv/arrow-testing"
REVISION="9cfebfef8982fb8612e0a2c59059752bd32321a3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -d "$TARGET/.git" ]; then
  if [ "$(git -C "$TARGET" rev-parse HEAD)" = "$REVISION" ]; then
    echo "Arrow testing fixtures already at $TARGET ($REVISION)"
    exit 0
  fi
  echo "Refreshing $TARGET → $REVISION"
elif [ -e "$TARGET" ]; then
  echo "error: $TARGET exists but is not a git checkout; remove it and re-run" >&2
  exit 1
else
  mkdir -p priv
  echo "Cloning $REPO → $TARGET @ $REVISION"
  git clone --no-checkout --depth 1 "$REPO" "$TARGET"
fi

git -C "$TARGET" fetch --depth 1 origin "$REVISION"
git -C "$TARGET" checkout --detach "$REVISION"
echo "Arrow testing fixtures ready at $TARGET ($REVISION)"
