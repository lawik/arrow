defmodule Arrow.Ipc.Flatbuf.Time do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Time. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct unit: :MILLISECOND, bitWidth: 32
  @type t :: %__MODULE__{unit: Arrow.Ipc.Flatbuf.TimeUnit.t() | nil, bitWidth: integer() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      unit: decode_field_unit(buf, pos),
      bitWidth: decode_field_bitWidth(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    b = Wire.add_field_scalar(b, 6, Map.get(value, :bitWidth, 32), 32, &Wire.push_i32/2)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.TimeUnit.value(Map.get(value, :unit, :MILLISECOND)),
        1,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"unit",
       if(Map.get(value, :unit) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.TimeUnit.__to_json__(Map.get(value, :unit))
       )},
      {"bitWidth", Map.get(value, :bitWidth)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      unit:
        if(Map.get(map, "unit") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.TimeUnit.__from_json__(Map.get(map, "unit"))
        ),
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

  @doc "Read field `unit` from a table at position `pos`. Returns the field value or its default."
  def decode_field_unit(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :MILLISECOND
      o -> Arrow.Ipc.Flatbuf.TimeUnit.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `bitWidth` from a table at position `pos`. Returns the field value or its default."
  def decode_field_bitWidth(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> 32
      o -> Wire.read_i32(buf, pos + o)
    end
  end
end
