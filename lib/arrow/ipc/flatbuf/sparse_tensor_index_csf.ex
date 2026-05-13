defmodule Arrow.Ipc.Flatbuf.SparseTensorIndexCSF do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.SparseTensorIndexCSF. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct indptrType: nil,
            indptrBuffers: [],
            indicesType: nil,
            indicesBuffers: [],
            axisOrder: []

  @type t :: %__MODULE__{
          indptrType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indptrBuffers: [Arrow.Ipc.Flatbuf.Buffer.t() | nil],
          indicesType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indicesBuffers: [Arrow.Ipc.Flatbuf.Buffer.t() | nil],
          axisOrder: [integer() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      indptrType: decode_field_indptrType(buf, pos),
      indptrBuffers: decode_field_indptrBuffers(buf, pos),
      indicesType: decode_field_indicesType(buf, pos),
      indicesBuffers: decode_field_indicesBuffers(buf, pos),
      axisOrder: decode_field_axisOrder(buf, pos)
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

    {b, addr_indptrBuffers} =
      case Map.get(value, :indptrBuffers) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          count = length(list)
          b1 = Wire.start_vector(b, count, 16, 8)

          b2 =
            list
            |> Enum.reverse()
            |> Enum.reduce(b1, fn item, acc ->
              acc = Wire.align(acc, 8)
              bin = Arrow.Ipc.Flatbuf.Buffer.encode(item)
              %{acc | bytes: [bin | acc.bytes], size: acc.size + byte_size(bin)}
            end)

          Wire.end_vector(b2, count)
      end

    {b, addr_indicesType} =
      case Map.get(value, :indicesType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    {b, addr_indicesBuffers} =
      case Map.get(value, :indicesBuffers) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          count = length(list)
          b1 = Wire.start_vector(b, count, 16, 8)

          b2 =
            list
            |> Enum.reverse()
            |> Enum.reduce(b1, fn item, acc ->
              acc = Wire.align(acc, 8)
              bin = Arrow.Ipc.Flatbuf.Buffer.encode(item)
              %{acc | bytes: [bin | acc.bytes], size: acc.size + byte_size(bin)}
            end)

          Wire.end_vector(b2, count)
      end

    {b, addr_axisOrder} =
      case Map.get(value, :axisOrder) do
        nil -> {b, nil}
        [] -> Wire.create_scalar_vector(b, [], 4, 4, &Wire.push_i32/2)
        list when is_list(list) -> Wire.create_scalar_vector(b, list, 4, 4, &Wire.push_i32/2)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 12, addr_axisOrder)
    b = Wire.add_field_offset(b, 10, addr_indicesBuffers)
    b = Wire.add_field_offset(b, 8, addr_indicesType)
    b = Wire.add_field_offset(b, 6, addr_indptrBuffers)
    b = Wire.add_field_offset(b, 4, addr_indptrType)
    Wire.end_table(b)
  end

  @doc "Read field `indptrType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indptrBuffers` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrBuffers(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, Wire.vector_elem_pos(abs, i, 16))
          end
        end
    end
  end

  @doc "Read field `indicesType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indicesBuffers` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesBuffers(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, Wire.vector_elem_pos(abs, i, 16))
          end
        end
    end
  end

  @doc "Read field `axisOrder` from a table at position `pos`. Returns the field value or its default."
  def decode_field_axisOrder(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Wire.read_i32(buf, Wire.vector_elem_pos(abs, i, 4))
          end
        end
    end
  end
end
