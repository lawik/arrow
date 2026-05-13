defmodule Arrow.Ipc.Flatbuf.SparseTensor do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.SparseTensor. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct type: nil, shape: [], non_zero_length: 0, sparseIndex: nil, data: nil

  @type t :: %__MODULE__{
          type: Arrow.Ipc.Flatbuf.Type.t(),
          shape: [Arrow.Ipc.Flatbuf.TensorDim.t() | nil],
          non_zero_length: integer() | nil,
          sparseIndex: Arrow.Ipc.Flatbuf.SparseTensorIndex.t(),
          data: Arrow.Ipc.Flatbuf.Buffer.t() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      type: decode_field_type(buf, pos),
      shape: decode_field_shape(buf, pos),
      non_zero_length: decode_field_non_zero_length(buf, pos),
      sparseIndex: decode_field_sparseIndex(buf, pos),
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

    {b, disc_sparseIndex, addr_sparseIndex} =
      case Map.get(value, :sparseIndex) do
        nil ->
          {b, 0, nil}

        {variant_atom, variant_value} ->
          {b2, addr} =
            Arrow.Ipc.Flatbuf.SparseTensorIndex.build_variant(b, variant_atom, variant_value)

          {b2, Arrow.Ipc.Flatbuf.SparseTensorIndex.discriminator(variant_atom), addr}
      end

    b = Wire.start_table(b)

    b =
      case Map.get(value, :data) do
        nil -> b
        v -> Wire.add_field_struct(b, 16, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 14, addr_sparseIndex)
    b = Wire.add_field_scalar(b, 12, disc_sparseIndex, 0, &Wire.push_u8/2)
    b = Wire.add_field_scalar(b, 10, Map.get(value, :non_zero_length, 0), 0, &Wire.push_i64/2)
    b = Wire.add_field_offset(b, 8, addr_shape)
    b = Wire.add_field_offset(b, 6, addr_type)
    b = Wire.add_field_scalar(b, 4, disc_type, 0, &Wire.push_u8/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"type_type", Arrow.Ipc.Flatbuf.Type.__to_json_type__(Map.get(value, :type))},
      {"type", Arrow.Ipc.Flatbuf.Type.__to_json_value__(Map.get(value, :type))},
      {"shape",
       Enum.map(Map.get(value, :shape) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.TensorDim.__to_json_map__(v))
       end)},
      {"non_zero_length", Map.get(value, :non_zero_length)},
      {"sparseIndex_type",
       Arrow.Ipc.Flatbuf.SparseTensorIndex.__to_json_type__(Map.get(value, :sparseIndex))},
      {"sparseIndex",
       Arrow.Ipc.Flatbuf.SparseTensorIndex.__to_json_value__(Map.get(value, :sparseIndex))},
      {"data",
       if(Map.get(value, :data) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Buffer.__to_json_map__(Map.get(value, :data))
       )}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      type: Arrow.Ipc.Flatbuf.Type.__from_json__(Map.get(map, "type_type"), Map.get(map, "type")),
      shape:
        Enum.map(Map.get(map, "shape") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.TensorDim.__from_json_map__(v))
        end),
      non_zero_length: Map.get(map, "non_zero_length"),
      sparseIndex:
        Arrow.Ipc.Flatbuf.SparseTensorIndex.__from_json__(
          Map.get(map, "sparseIndex_type"),
          Map.get(map, "sparseIndex")
        ),
      data:
        if(Map.get(map, "data") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(Map.get(map, "data"))
        )
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      with :ok <-
             (case Wire.read_vtable_field(buf, pos, 4) do
                0 ->
                  :ok

                type_o ->
                  with :ok <- Wire.verify_bounds(buf, pos + type_o, 1) do
                    case Wire.read_vtable_field(buf, pos, 6) do
                      0 ->
                        :ok

                      value_o ->
                        case Wire.verify_follow_uoffset(buf, pos + value_o) do
                          {:ok, abs_pos} ->
                            disc = Wire.read_u8(buf, pos + type_o)

                            Arrow.Ipc.Flatbuf.Type.__verify_variant__(
                              buf,
                              disc,
                              abs_pos,
                              depth - 1
                            )

                          err ->
                            err
                        end
                    end
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 8) do
                0 ->
                  :ok

                o ->
                  case Wire.verify_follow_uoffset(buf, pos + o) do
                    {:ok, vec_pos} ->
                      case Wire.verify_vector_at(buf, vec_pos, 4) do
                        {:ok, count} when count == 0 ->
                          :ok

                        {:ok, count} ->
                          Enum.reduce_while(0..(count - 1), :ok, fn i, _acc ->
                            elem_pos = Wire.vector_elem_pos(vec_pos, i, 4)

                            case (case Wire.verify_follow_uoffset(buf, elem_pos) do
                                    {:ok, tp} ->
                                      Arrow.Ipc.Flatbuf.TensorDim.__verify_at__(
                                        buf,
                                        tp,
                                        depth - 1
                                      )

                                    e ->
                                      e
                                  end) do
                              :ok -> {:cont, :ok}
                              err -> {:halt, err}
                            end
                          end)

                        err ->
                          err
                      end

                    err ->
                      err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 12) do
                0 ->
                  :ok

                type_o ->
                  with :ok <- Wire.verify_bounds(buf, pos + type_o, 1) do
                    case Wire.read_vtable_field(buf, pos, 14) do
                      0 ->
                        :ok

                      value_o ->
                        case Wire.verify_follow_uoffset(buf, pos + value_o) do
                          {:ok, abs_pos} ->
                            disc = Wire.read_u8(buf, pos + type_o)

                            Arrow.Ipc.Flatbuf.SparseTensorIndex.__verify_variant__(
                              buf,
                              disc,
                              abs_pos,
                              depth - 1
                            )

                          err ->
                            err
                        end
                    end
                  end
              end) do
        :ok
      end
    end
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

  @doc "Read field `non_zero_length` from a table at position `pos`. Returns the field value or its default."
  def decode_field_non_zero_length(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `sparseIndex` from a table at position `pos`. Returns the field value or its default."
  def decode_field_sparseIndex(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 ->
        nil

      type_o ->
        case Wire.read_vtable_field(buf, pos, 14) do
          0 ->
            nil

          value_o ->
            disc = Wire.read_u8(buf, pos + type_o)
            abs_pos = Wire.follow_uoffset(buf, pos + value_o)
            Arrow.Ipc.Flatbuf.SparseTensorIndex.decode_variant(buf, disc, abs_pos)
        end
    end
  end

  @doc "Read field `data` from a table at position `pos`. Returns the field value or its default."
  def decode_field_data(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 16) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end
end
