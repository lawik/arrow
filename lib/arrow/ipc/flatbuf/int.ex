defmodule Arrow.Ipc.Flatbuf.Int do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Int. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct bitWidth: 0, is_signed: false
  @type t :: %__MODULE__{bitWidth: integer() | nil, is_signed: boolean()}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      bitWidth: decode_field_bitWidth(buf, pos),
      is_signed: decode_field_is_signed(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        6,
        if(Map.get(value, :is_signed, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b = Wire.add_field_scalar(b, 4, Map.get(value, :bitWidth, 0), 0, &Wire.push_i32/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"bitWidth", Map.get(value, :bitWidth)},
      {"is_signed", Map.get(value, :is_signed)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      bitWidth: Map.get(map, "bitWidth"),
      is_signed: Map.get(map, "is_signed")
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      :ok
    end
  end

  @doc "Read field `bitWidth` from a table at position `pos`. Returns the field value or its default."
  def decode_field_bitWidth(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end

  @doc "Read field `is_signed` from a table at position `pos`. Returns the field value or its default."
  def decode_field_is_signed(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end
end
