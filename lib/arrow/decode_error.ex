# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.DecodeError do
  @moduledoc """
  Error returned by the decoders (`Arrow.Ipc.Stream.decode/1`,
  `Arrow.Ipc.File.decode/1`, `Arrow.Json.decode/1`) and raised by their
  `decode!/1` variants.

  The `:kind` field classifies the failure:

  - `:unsupported` — the input uses an Arrow feature this library
    deliberately does not implement: Union, `BinaryView` / `Utf8View`,
    `ListView` / `LargeListView`, `RunEndEncoded`, `Float16`, IPC body
    compression, big-endian payloads, delta dictionaries, Tensor /
    SparseTensor messages.
  - `:malformed` — the input is corrupt, truncated, or internally
    inconsistent. Legacy (pre-0.15 / V4) IPC file framing also surfaces
    here, as it is indistinguishable from a corrupt Block offset.
  """

  defexception [:kind, :message]

  @type kind :: :unsupported | :malformed
  @type t :: %__MODULE__{kind: kind(), message: String.t()}
end
