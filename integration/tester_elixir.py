# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

"""archery tester for the pure-Elixir Arrow library.

Canonical copy lives in the Elixir repo at integration/tester_elixir.py;
copy it into <arrow checkout>/dev/archery/archery/integration/ and wire
it up per integration/README.md in the Elixir repo.

Requires ARROW_ELIXIR_PATH to point at the Elixir repo root. The bin/
shims there forward to `mix arrow.integration.*` tasks; run
`mix compile` once beforehand so concurrent invocations don't race to
compile.
"""

import os

from .tester import Tester
from .util import run_cmd, log

_ELIXIR_ROOT = os.environ.get("ARROW_ELIXIR_PATH")


def _exe(name):
    if not _ELIXIR_ROOT:
        raise RuntimeError(
            "Set ARROW_ELIXIR_PATH to the root of the Elixir Arrow repo")
    path = os.path.join(_ELIXIR_ROOT, "bin", name)
    if not os.path.exists(path):
        raise RuntimeError(f"Elixir integration shim not found: {path}")
    return path


class ElixirTester(Tester):
    PRODUCER = True
    CONSUMER = True
    FLIGHT_SERVER = False
    FLIGHT_CLIENT = False
    C_DATA_SCHEMA_EXPORTER = False
    C_DATA_ARRAY_EXPORTER = False
    C_DATA_SCHEMA_IMPORTER = False
    C_DATA_ARRAY_IMPORTER = False

    name = "Elixir"

    def _run(self, cmd):
        if self.debug:
            log(" ".join(cmd))
        run_cmd(cmd)

    def validate(self, json_path, arrow_path, quirks=None):
        # quirks soften value-range validation (e.g. out-of-range
        # decimals in pre-1.0 gold files); the Elixir validator compares
        # decoded values without range-checking them, so they are
        # accepted and ignored here.
        self._run([_exe("arrow-json-integration-validate"),
                   "--json", json_path, "--arrow", arrow_path])

    def json_to_file(self, json_path, arrow_path):
        self._run([_exe("arrow-json-integration-arrow"),
                   "--json", json_path, "--arrow", arrow_path])

    def stream_to_file(self, stream_path, file_path):
        self._run([_exe("arrow-stream-to-file"),
                   "--stream", stream_path, "--arrow", file_path])

    def file_to_stream(self, file_path, stream_path):
        self._run([_exe("arrow-file-to-stream"),
                   "--arrow", file_path, "--stream", stream_path])
