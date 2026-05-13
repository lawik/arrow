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

  @doc "Encode this table as a JSON string (flatc-compatible shape)."
  @spec to_json(t() | map()) :: binary()
  def to_json(value) when is_map(value) do
    value |> __to_json_map__() |> JSON.encode!() |> IO.iodata_to_binary()
  end

  @doc "Decode a JSON string into this table's struct."
  @spec from_json(binary()) :: {:ok, t()} | {:error, term()}
  def from_json(json) when is_binary(json) do
    case JSON.decode(json) do
      {:ok, map} -> {:ok, __from_json_map__(map)}
      err -> err
    end
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

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"type_type", Arrow.Ipc.Flatbuf.Type.__to_json_type__(Map.get(value, :type))},
      {"type", Arrow.Ipc.Flatbuf.Type.__to_json_value__(Map.get(value, :type))},
      {"shape",
       Enum.map(Map.get(value, :shape) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.TensorDim.__to_json_map__(v))
       end)},
      {"strides", Enum.map(Map.get(value, :strides) || [], fn v -> v end)},
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
      strides: Enum.map(Map.get(map, "strides") || [], fn v -> v end),
      data:
        if(Map.get(map, "data") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(Map.get(map, "data"))
        )
    }
  end

  @doc """
  Structurally verify a buffer claimed to be this table.

  Checks every offset is within the buffer, vtables are well-formed,
  strings have their null terminator, vectors don't claim to extend
  past the buffer, and sub-tables are recursively verified to a
  depth of 64. Returns `:ok` on success, `{:error, reason}` on the
  first problem encountered.
  """
  @spec verify(binary()) :: :ok | {:error, term()}
  def verify(buf) when is_binary(buf) do
    with :ok <- Wire.verify_size(buf, 4),
         {:ok, root_pos} <- Wire.verify_follow_uoffset(buf, 0) do
      __verify_at__(buf, root_pos, 64)
    end
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
             (case Wire.read_vtable_field(buf, pos, 10) do
                0 ->
                  :ok

                o ->
                  case Wire.verify_follow_uoffset(buf, pos + o) do
                    {:ok, vec_pos} ->
                      case Wire.verify_vector_at(buf, vec_pos, 8) do
                        {:ok, count} when count == 0 ->
                          :ok

                        {:ok, count} ->
                          Enum.reduce_while(0..(count - 1), :ok, fn i, _acc ->
                            elem_pos = Wire.vector_elem_pos(vec_pos, i, 8)

                            case Wire.verify_bounds(buf, elem_pos, 8) do
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
