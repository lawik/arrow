defmodule Arrow.Ipc.Flatbuf.RecordBatch do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.RecordBatch. Do not edit.
  @moduledoc false

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

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"length", Map.get(value, :length)},
      {"nodes",
       Enum.map(Map.get(value, :nodes) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.FieldNode.__to_json_map__(v))
       end)},
      {"buffers",
       Enum.map(Map.get(value, :buffers) || [], fn v ->
         if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Buffer.__to_json_map__(v))
       end)},
      {"compression",
       if(Map.get(value, :compression) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.BodyCompression.__to_json_map__(Map.get(value, :compression))
       )},
      {"variadicBufferCounts",
       Enum.map(Map.get(value, :variadicBufferCounts) || [], fn v -> v end)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      length: Map.get(map, "length"),
      nodes:
        Enum.map(Map.get(map, "nodes") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.FieldNode.__from_json_map__(v))
        end),
      buffers:
        Enum.map(Map.get(map, "buffers") || [], fn v ->
          if(v == nil, do: nil, else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(v))
        end),
      compression:
        if(Map.get(map, "compression") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.BodyCompression.__from_json_map__(Map.get(map, "compression"))
        ),
      variadicBufferCounts: Enum.map(Map.get(map, "variadicBufferCounts") || [], fn v -> v end)
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
                      case Wire.verify_vector_at(buf, vec_pos, 16) do
                        {:ok, count} when count == 0 ->
                          :ok

                        {:ok, count} ->
                          Enum.reduce_while(0..(count - 1), :ok, fn i, _acc ->
                            elem_pos = Wire.vector_elem_pos(vec_pos, i, 16)

                            case Wire.verify_bounds(buf, elem_pos, 16) do
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
                      case Wire.verify_vector_at(buf, vec_pos, 16) do
                        {:ok, count} when count == 0 ->
                          :ok

                        {:ok, count} ->
                          Enum.reduce_while(0..(count - 1), :ok, fn i, _acc ->
                            elem_pos = Wire.vector_elem_pos(vec_pos, i, 16)

                            case Wire.verify_bounds(buf, elem_pos, 16) do
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
                    {:ok, abs_pos} ->
                      Arrow.Ipc.Flatbuf.BodyCompression.__verify_at__(buf, abs_pos, depth - 1)

                    err ->
                      err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 12) do
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
