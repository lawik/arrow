defmodule Arrow.Ipc.Flatbuf.RecordBatch do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.RecordBatch. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct length: 0, nodes: [], buffers: [], compression: nil, variadicBufferCounts: []

  @type t :: %__MODULE__{
          length: integer() | nil,
          nodes: [Arrow.Ipc.Flatbuf.FieldNode.t() | nil],
          buffers: [Arrow.Ipc.Flatbuf.Buffer.t() | nil],
          compression: Arrow.Ipc.Flatbuf.BodyCompression.t() | nil,
          variadicBufferCounts: [integer() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      length: decode_field_length(buf, pos),
      nodes: decode_field_nodes(buf, pos),
      buffers: decode_field_buffers(buf, pos),
      compression: decode_field_compression(buf, pos),
      variadicBufferCounts: decode_field_variadicBufferCounts(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_nodes} =
      case Map.get(value, :nodes) do
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
              bin = Arrow.Ipc.Flatbuf.FieldNode.encode(item)
              %{acc | bytes: [bin | acc.bytes], size: acc.size + byte_size(bin)}
            end)

          Wire.end_vector(b2, count)
      end

    {b, addr_buffers} =
      case Map.get(value, :buffers) do
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

    {b, addr_compression} =
      case Map.get(value, :compression) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.BodyCompression.build(b, v)
      end

    {b, addr_variadicBufferCounts} =
      case Map.get(value, :variadicBufferCounts) do
        nil -> {b, nil}
        [] -> Wire.create_scalar_vector(b, [], 8, 8, &Wire.push_i64/2)
        list when is_list(list) -> Wire.create_scalar_vector(b, list, 8, 8, &Wire.push_i64/2)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 12, addr_variadicBufferCounts)
    b = Wire.add_field_offset(b, 10, addr_compression)
    b = Wire.add_field_offset(b, 8, addr_buffers)
    b = Wire.add_field_offset(b, 6, addr_nodes)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :length, 0), 0, &Wire.push_i64/2)
    Wire.end_table(b)
  end

  @doc "Read field `length` from a table at position `pos`. Returns the field value or its default."
  def decode_field_length(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `nodes` from a table at position `pos`. Returns the field value or its default."
  def decode_field_nodes(buf, pos) do
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
            Arrow.Ipc.Flatbuf.FieldNode.decode_at(buf, Wire.vector_elem_pos(abs, i, 16))
          end
        end
    end
  end

  @doc "Read field `buffers` from a table at position `pos`. Returns the field value or its default."
  def decode_field_buffers(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
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

  @doc "Read field `compression` from a table at position `pos`. Returns the field value or its default."
  def decode_field_compression(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.BodyCompression.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `variadicBufferCounts` from a table at position `pos`. Returns the field value or its default."
  def decode_field_variadicBufferCounts(buf, pos) do
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
            Wire.read_i64(buf, Wire.vector_elem_pos(abs, i, 8))
          end
        end
    end
  end
end
