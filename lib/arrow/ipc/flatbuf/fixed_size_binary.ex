defmodule Arrow.Ipc.Flatbuf.FixedSizeBinary do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.FixedSizeBinary. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct byteWidth: 0
  @type t :: %__MODULE__{byteWidth: integer() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      byteWidth: decode_field_byteWidth(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :byteWidth, 0), 0, &Wire.push_i32/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"byteWidth", Map.get(value, :byteWidth)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      byteWidth: Map.get(map, "byteWidth")
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      :ok
    end
  end

  @doc "Read field `byteWidth` from a table at position `pos`. Returns the field value or its default."
  def decode_field_byteWidth(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end
end
