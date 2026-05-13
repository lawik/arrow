defmodule Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct compressedAxis: :Row,
            indptrType: nil,
            indptrBuffer: nil,
            indicesType: nil,
            indicesBuffer: nil

  @type t :: %__MODULE__{
          compressedAxis: Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.t() | nil,
          indptrType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indptrBuffer: Arrow.Ipc.Flatbuf.Buffer.t() | nil,
          indicesType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indicesBuffer: Arrow.Ipc.Flatbuf.Buffer.t() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      compressedAxis: decode_field_compressedAxis(buf, pos),
      indptrType: decode_field_indptrType(buf, pos),
      indptrBuffer: decode_field_indptrBuffer(buf, pos),
      indicesType: decode_field_indicesType(buf, pos),
      indicesBuffer: decode_field_indicesBuffer(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_indptrType} =
      case Map.get(value, :indptrType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    {b, addr_indicesType} =
      case Map.get(value, :indicesType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    b = Wire.start_table(b)

    b =
      case Map.get(value, :indicesBuffer) do
        nil -> b
        v -> Wire.add_field_struct(b, 12, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 10, addr_indicesType)

    b =
      case Map.get(value, :indptrBuffer) do
        nil -> b
        v -> Wire.add_field_struct(b, 8, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 6, addr_indptrType)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.value(Map.get(value, :compressedAxis, :Row)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `compressedAxis` from a table at position `pos`. Returns the field value or its default."
  def decode_field_compressedAxis(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :Row
      o -> Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `indptrType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indptrBuffer` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrBuffer(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end

  @doc "Read field `indicesType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indicesBuffer` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesBuffer(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end
end
