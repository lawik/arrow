defmodule Arrow.Ipc.Flatbuf.Schema do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Schema. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct endianness: :Little, fields: [], custom_metadata: [], features: []

  @type t :: %__MODULE__{
          endianness: Arrow.Ipc.Flatbuf.Endianness.t() | nil,
          fields: [Arrow.Ipc.Flatbuf.Field.t() | nil],
          custom_metadata: [Arrow.Ipc.Flatbuf.KeyValue.t() | nil],
          features: [Arrow.Ipc.Flatbuf.Feature.t() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      endianness: decode_field_endianness(buf, pos),
      fields: decode_field_fields(buf, pos),
      custom_metadata: decode_field_custom_metadata(buf, pos),
      features: decode_field_features(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_fields} =
      case Map.get(value, :fields) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          {addrs, b} =
            Enum.map_reduce(list, b, fn item, acc ->
              {acc2, a} = Arrow.Ipc.Flatbuf.Field.build(acc, item)
              {a, acc2}
            end)

          Wire.create_offset_vector(b, addrs)
      end

    {b, addr_custom_metadata} =
      case Map.get(value, :custom_metadata) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          {addrs, b} =
            Enum.map_reduce(list, b, fn item, acc ->
              {acc2, a} = Arrow.Ipc.Flatbuf.KeyValue.build(acc, item)
              {a, acc2}
            end)

          Wire.create_offset_vector(b, addrs)
      end

    {b, addr_features} =
      case Map.get(value, :features) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          ints = Enum.map(list, &Arrow.Ipc.Flatbuf.Feature.value/1)
          Wire.create_scalar_vector(b, ints, 8, 8, &Wire.push_i64/2)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 10, addr_features)
    b = Wire.add_field_offset(b, 8, addr_custom_metadata)
    b = Wire.add_field_offset(b, 6, addr_fields)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.Endianness.value(Map.get(value, :endianness, :Little)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"endianness",
       if(Map.get(value, :endianness) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Endianness.__to_json__(Map.get(value, :endianness))
       )},
      {"fields",
       Enum.map(Map.get(value, :fields) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Field.__to_json_map__(v))
       end)},
      {"custom_metadata",
       Enum.map(Map.get(value, :custom_metadata) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.KeyValue.__to_json_map__(v))
       end)},
      {"features",
       Enum.map(Map.get(value, :features) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Feature.__to_json__(v))
       end)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      endianness:
        if(Map.get(map, "endianness") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Endianness.__from_json__(Map.get(map, "endianness"))
        ),
      fields:
        Enum.map(Map.get(map, "fields") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Field.__from_json_map__(v))
        end),
      custom_metadata:
        Enum.map(Map.get(map, "custom_metadata") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.KeyValue.__from_json_map__(v))
        end),
      features:
        Enum.map(Map.get(map, "features") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Feature.__from_json__(v))
        end)
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      with :ok <-
             (case Wire.read_vtable_field(buf, pos, 6) do
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
                                      Arrow.Ipc.Flatbuf.Field.__verify_at__(buf, tp, depth - 1)

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
                                      Arrow.Ipc.Flatbuf.KeyValue.__verify_at__(buf, tp, depth - 1)

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

  @doc "Read field `endianness` from a table at position `pos`. Returns the field value or its default."
  def decode_field_endianness(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :Little
      o -> Arrow.Ipc.Flatbuf.Endianness.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `fields` from a table at position `pos`. Returns the field value or its default."
  def decode_field_fields(buf, pos) do
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
            Arrow.Ipc.Flatbuf.Field.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end

  @doc "Read field `custom_metadata` from a table at position `pos`. Returns the field value or its default."
  def decode_field_custom_metadata(buf, pos) do
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
            Arrow.Ipc.Flatbuf.KeyValue.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end

  @doc "Read field `features` from a table at position `pos`. Returns the field value or its default."
  def decode_field_features(buf, pos) do
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
            Arrow.Ipc.Flatbuf.Feature.from_value(
              Wire.read_i64(buf, Wire.vector_elem_pos(abs, i, 8))
            )
          end
        end
    end
  end
end
