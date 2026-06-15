defmodule Arrow.Ipc.Flatbuf.Field do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Field. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct name: nil,
            nullable: false,
            type: nil,
            dictionary: nil,
            children: [],
            custom_metadata: []

  @type t :: %__MODULE__{
          name: String.t() | nil,
          nullable: boolean(),
          type: Arrow.Ipc.Flatbuf.Type.t(),
          dictionary: Arrow.Ipc.Flatbuf.DictionaryEncoding.t() | nil,
          children: [Arrow.Ipc.Flatbuf.Field.t() | nil],
          custom_metadata: [Arrow.Ipc.Flatbuf.KeyValue.t() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      name: decode_field_name(buf, pos),
      nullable: decode_field_nullable(buf, pos),
      type: decode_field_type(buf, pos),
      dictionary: decode_field_dictionary(buf, pos),
      children: decode_field_children(buf, pos),
      custom_metadata: decode_field_custom_metadata(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_name} =
      case Map.get(value, :name) do
        nil -> {b, nil}
        "" -> Wire.create_string(b, "")
        s when is_binary(s) -> Wire.create_string(b, s)
      end

    {b, disc_type, addr_type} =
      case Map.get(value, :type) do
        nil ->
          {b, 0, nil}

        {variant_atom, variant_value} ->
          {b2, addr} = Arrow.Ipc.Flatbuf.Type.build_variant(b, variant_atom, variant_value)
          {b2, Arrow.Ipc.Flatbuf.Type.discriminator(variant_atom), addr}
      end

    {b, addr_dictionary} =
      case Map.get(value, :dictionary) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.DictionaryEncoding.build(b, v)
      end

    {b, addr_children} =
      case Map.get(value, :children) do
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

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 16, addr_custom_metadata)
    b = Wire.add_field_offset(b, 14, addr_children)
    b = Wire.add_field_offset(b, 12, addr_dictionary)
    b = Wire.add_field_offset(b, 10, addr_type)
    b = Wire.add_field_scalar(b, 8, disc_type, 0, &Wire.push_u8/2)

    b =
      Wire.add_field_scalar(
        b,
        6,
        if(Map.get(value, :nullable, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b = Wire.add_field_offset(b, 4, addr_name)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"name", Map.get(value, :name)},
      {"nullable", Map.get(value, :nullable)},
      {"type_type", Arrow.Ipc.Flatbuf.Type.__to_json_type__(Map.get(value, :type))},
      {"type", Arrow.Ipc.Flatbuf.Type.__to_json_value__(Map.get(value, :type))},
      {"dictionary",
       if(Map.get(value, :dictionary) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.DictionaryEncoding.__to_json_map__(Map.get(value, :dictionary))
       )},
      {"children",
       Enum.map(Map.get(value, :children) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Field.__to_json_map__(v))
       end)},
      {"custom_metadata",
       Enum.map(Map.get(value, :custom_metadata) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.KeyValue.__to_json_map__(v))
       end)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      name: Map.get(map, "name"),
      nullable: Map.get(map, "nullable"),
      type: Arrow.Ipc.Flatbuf.Type.__from_json__(Map.get(map, "type_type"), Map.get(map, "type")),
      dictionary:
        if(Map.get(map, "dictionary") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.DictionaryEncoding.__from_json_map__(Map.get(map, "dictionary"))
        ),
      children:
        Enum.map(Map.get(map, "children") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Field.__from_json_map__(v))
        end),
      custom_metadata:
        Enum.map(Map.get(map, "custom_metadata") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.KeyValue.__from_json_map__(v))
        end)
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

                o ->
                  case Wire.verify_follow_uoffset(buf, pos + o) do
                    {:ok, abs_pos} -> Wire.verify_string_at(buf, abs_pos)
                    err -> err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 8) do
                0 ->
                  :ok

                type_o ->
                  with :ok <- Wire.verify_bounds(buf, pos + type_o, 1) do
                    case Wire.read_vtable_field(buf, pos, 10) do
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
             (case Wire.read_vtable_field(buf, pos, 12) do
                0 ->
                  :ok

                o ->
                  case Wire.verify_follow_uoffset(buf, pos + o) do
                    {:ok, abs_pos} ->
                      Arrow.Ipc.Flatbuf.DictionaryEncoding.__verify_at__(buf, abs_pos, depth - 1)

                    err ->
                      err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 14) do
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
             (case Wire.read_vtable_field(buf, pos, 16) do
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
              end) do
        :ok
      end
    end
  end

  @doc "Read field `name` from a table at position `pos`. Returns the field value or its default."
  def decode_field_name(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> nil
      o -> Wire.read_string_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `nullable` from a table at position `pos`. Returns the field value or its default."
  def decode_field_nullable(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end

  @doc "Read field `type` from a table at position `pos`. Returns the field value or its default."
  def decode_field_type(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 ->
        nil

      type_o ->
        case Wire.read_vtable_field(buf, pos, 10) do
          0 ->
            nil

          value_o ->
            disc = Wire.read_u8(buf, pos + type_o)
            abs_pos = Wire.follow_uoffset(buf, pos + value_o)
            Arrow.Ipc.Flatbuf.Type.decode_variant(buf, disc, abs_pos)
        end
    end
  end

  @doc "Read field `dictionary` from a table at position `pos`. Returns the field value or its default."
  def decode_field_dictionary(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.DictionaryEncoding.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `children` from a table at position `pos`. Returns the field value or its default."
  def decode_field_children(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 14) do
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
    case Wire.read_vtable_field(buf, pos, 16) do
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
end
