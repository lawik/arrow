defmodule Arrow.Ipc.Flatbuf.Decimal do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Decimal. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct precision: 0, scale: 0, bitWidth: 128

  @type t :: %__MODULE__{
          precision: integer() | nil,
          scale: integer() | nil,
          bitWidth: integer() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      precision: decode_field_precision(buf, pos),
      scale: decode_field_scale(buf, pos),
      bitWidth: decode_field_bitWidth(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    b = Wire.add_field_scalar(b, 8, Map.get(value, :bitWidth, 128), 128, &Wire.push_i32/2)
    b = Wire.add_field_scalar(b, 6, Map.get(value, :scale, 0), 0, &Wire.push_i32/2)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :precision, 0), 0, &Wire.push_i32/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"precision", Map.get(value, :precision)},
      {"scale", Map.get(value, :scale)},
      {"bitWidth", Map.get(value, :bitWidth)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      precision: Map.get(map, "precision"),
      scale: Map.get(map, "scale"),
      bitWidth: Map.get(map, "bitWidth")
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      :ok
    end
  end

  @doc "Read field `precision` from a table at position `pos`. Returns the field value or its default."
  def decode_field_precision(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end

  @doc "Read field `scale` from a table at position `pos`. Returns the field value or its default."
  def decode_field_scale(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end

  @doc "Read field `bitWidth` from a table at position `pos`. Returns the field value or its default."
  def decode_field_bitWidth(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> 128
      o -> Wire.read_i32(buf, pos + o)
    end
  end
end
