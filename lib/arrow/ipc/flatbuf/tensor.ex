defmodule Arrow.Ipc.Flatbuf.Tensor do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Tensor. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct type: nil, shape: [], strides: [], data: nil

  @type t :: %__MODULE__{
          type: Arrow.Ipc.Flatbuf.Type.t(),
          shape: [Arrow.Ipc.Flatbuf.TensorDim.t() | nil],
          strides: [integer() | nil],
          data: Arrow.Ipc.Flatbuf.Buffer.t() | nil
        }

  @doc "Decode a buffer whose root is this table."
  @spec decode(binary()) :: {:ok, t()} | {:error, term()}
  def decode(buf) when is_binary(buf) do
    try do
      {:ok, decode_at(buf, Wire.root_table_pos(buf))}
    catch
      kind, reason -> {:error, {kind, reason}}
    end
  end

  @doc "Encode a value to a complete buffer with this table as the root."
  @spec encode(t() | map()) :: {:ok, binary()} | {:error, term()}
  def encode(value) when is_map(value) do
    builder = Wire.new_builder()
    {builder, root_addr} = build(builder, value)
    builder = Wire.finish(builder, root_addr)
    {:ok, Wire.to_binary(builder)}
  end

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      type: decode_field_type(buf, pos),
      shape: decode_field_shape(buf, pos),
      strides: decode_field_strides(buf, pos),
      data: decode_field_data(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, disc_type, addr_type} =
      case Map.get(value, :type) do
        nil ->
          {b, 0, nil}

        {variant_atom, variant_value} ->
          {b2, addr} = Arrow.Ipc.Flatbuf.Type.build_variant(b, variant_atom, variant_value)
          {b2, Arrow.Ipc.Flatbuf.Type.discriminator(variant_atom), addr}
      end

    {b, addr_shape} =
      case Map.get(value, :shape) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          {addrs, b} =
            Enum.map_reduce(list, b, fn item, acc ->
              {acc2, a} = Arrow.Ipc.Flatbuf.TensorDim.build(acc, item)
              {a, acc2}
            end)

          Wire.create_offset_vector(b, addrs)
      end

    {b, addr_strides} =
      case Map.get(value, :strides) do
        nil -> {b, nil}
        [] -> Wire.create_scalar_vector(b, [], 8, 8, &Wire.push_i64/2)
        list when is_list(list) -> Wire.create_scalar_vector(b, list, 8, 8, &Wire.push_i64/2)
      end

    b = Wire.start_table(b)

    b =
      case Map.get(value, :data) do
        nil -> b
        v -> Wire.add_field_struct(b, 12, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 10, addr_strides)
    b = Wire.add_field_offset(b, 8, addr_shape)
    b = Wire.add_field_offset(b, 6, addr_type)
    b = Wire.add_field_scalar(b, 4, disc_type, 0, &Wire.push_u8/2)
    Wire.end_table(b)
  end

  @doc "Read field `type` from a table at position `pos`. Returns the field value or its default."
  def decode_field_type(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 ->
        nil

      type_o ->
        case Wire.read_vtable_field(buf, pos, 6) do
          0 ->
            nil

          value_o ->
            disc = Wire.read_u8(buf, pos + type_o)
            abs_pos = Wire.follow_uoffset(buf, pos + value_o)
            Arrow.Ipc.Flatbuf.Type.decode_variant(buf, disc, abs_pos)
        end
    end
  end

  @doc "Read field `shape` from a table at position `pos`. Returns the field value or its default."
  def decode_field_shape(buf, pos) do
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
            Arrow.Ipc.Flatbuf.TensorDim.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end

  @doc "Read field `strides` from a table at position `pos`. Returns the field value or its default."
  def decode_field_strides(buf, pos) do
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
            Wire.read_i64(buf, Wire.vector_elem_pos(abs, i, 8))
          end
        end
    end
  end

  @doc "Read field `data` from a table at position `pos`. Returns the field value or its default."
  def decode_field_data(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end
end
