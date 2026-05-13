defmodule Arrow.Ipc.Flatbuf.DictionaryEncoding do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.DictionaryEncoding. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct id: 0, indexType: nil, isOrdered: false, dictionaryKind: :DenseArray

  @type t :: %__MODULE__{
          id: integer() | nil,
          indexType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          isOrdered: boolean(),
          dictionaryKind: Arrow.Ipc.Flatbuf.DictionaryKind.t() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      id: decode_field_id(buf, pos),
      indexType: decode_field_indexType(buf, pos),
      isOrdered: decode_field_isOrdered(buf, pos),
      dictionaryKind: decode_field_dictionaryKind(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_indexType} =
      case Map.get(value, :indexType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        10,
        Arrow.Ipc.Flatbuf.DictionaryKind.value(Map.get(value, :dictionaryKind, :DenseArray)),
        0,
        &Wire.push_i16/2
      )

    b =
      Wire.add_field_scalar(
        b,
        8,
        if(Map.get(value, :isOrdered, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b = Wire.add_field_offset(b, 6, addr_indexType)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :id, 0), 0, &Wire.push_i64/2)
    Wire.end_table(b)
  end

  @doc "Read field `id` from a table at position `pos`. Returns the field value or its default."
  def decode_field_id(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `indexType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indexType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `isOrdered` from a table at position `pos`. Returns the field value or its default."
  def decode_field_isOrdered(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end

  @doc "Read field `dictionaryKind` from a table at position `pos`. Returns the field value or its default."
  def decode_field_dictionaryKind(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> :DenseArray
      o -> Arrow.Ipc.Flatbuf.DictionaryKind.from_value(Wire.read_i16(buf, pos + o))
    end
  end
end
