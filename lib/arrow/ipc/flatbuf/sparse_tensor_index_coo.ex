defmodule Arrow.Ipc.Flatbuf.SparseTensorIndexCOO do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.SparseTensorIndexCOO. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct indicesType: nil, indicesStrides: [], indicesBuffer: nil, isCanonical: false

  @type t :: %__MODULE__{
          indicesType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indicesStrides: [integer() | nil],
          indicesBuffer: Arrow.Ipc.Flatbuf.Buffer.t() | nil,
          isCanonical: boolean()
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      indicesType: decode_field_indicesType(buf, pos),
      indicesStrides: decode_field_indicesStrides(buf, pos),
      indicesBuffer: decode_field_indicesBuffer(buf, pos),
      isCanonical: decode_field_isCanonical(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_indicesType} =
      case Map.get(value, :indicesType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    {b, addr_indicesStrides} =
      case Map.get(value, :indicesStrides) do
        nil -> {b, nil}
        [] -> Wire.create_scalar_vector(b, [], 8, 8, &Wire.push_i64/2)
        list when is_list(list) -> Wire.create_scalar_vector(b, list, 8, 8, &Wire.push_i64/2)
      end

    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        10,
        if(Map.get(value, :isCanonical, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b =
      case Map.get(value, :indicesBuffer) do
        nil -> b
        v -> Wire.add_field_struct(b, 8, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 6, addr_indicesStrides)
    b = Wire.add_field_offset(b, 4, addr_indicesType)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"indicesType",
       if(Map.get(value, :indicesType) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Int.__to_json_map__(Map.get(value, :indicesType))
       )},
      {"indicesStrides", Enum.map(Map.get(value, :indicesStrides) || [], fn v -> v end)},
      {"indicesBuffer",
       if(Map.get(value, :indicesBuffer) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Buffer.__to_json_map__(Map.get(value, :indicesBuffer))
       )},
      {"isCanonical", Map.get(value, :isCanonical)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      indicesType:
        if(Map.get(map, "indicesType") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Int.__from_json_map__(Map.get(map, "indicesType"))
        ),
      indicesStrides: Enum.map(Map.get(map, "indicesStrides") || [], fn v -> v end),
      indicesBuffer:
        if(Map.get(map, "indicesBuffer") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(Map.get(map, "indicesBuffer"))
        ),
      isCanonical: Map.get(map, "isCanonical")
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
                    {:ok, abs_pos} -> Arrow.Ipc.Flatbuf.Int.__verify_at__(buf, abs_pos, depth - 1)
                    err -> err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 6) do
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

  @doc "Read field `indicesType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indicesStrides` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesStrides(buf, pos) do
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
            Wire.read_i64(buf, Wire.vector_elem_pos(abs, i, 8))
          end
        end
    end
  end

  @doc "Read field `indicesBuffer` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesBuffer(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end

  @doc "Read field `isCanonical` from a table at position `pos`. Returns the field value or its default."
  def decode_field_isCanonical(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end
end
