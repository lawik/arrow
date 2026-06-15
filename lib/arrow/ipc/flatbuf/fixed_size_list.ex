defmodule Arrow.Ipc.Flatbuf.FixedSizeList do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.FixedSizeList. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct listSize: 0
  @type t :: %__MODULE__{listSize: integer() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      listSize: decode_field_listSize(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :listSize, 0), 0, &Wire.push_i32/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"listSize", Map.get(value, :listSize)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      listSize: Map.get(map, "listSize")
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      :ok
    end
  end

  @doc "Read field `listSize` from a table at position `pos`. Returns the field value or its default."
  def decode_field_listSize(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end
end
