defmodule Arrow.Ipc.Flatbuf.Union do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Union. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct mode: :Sparse, typeIds: []
  @type t :: %__MODULE__{mode: Arrow.Ipc.Flatbuf.UnionMode.t() | nil, typeIds: [integer() | nil]}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      mode: decode_field_mode(buf, pos),
      typeIds: decode_field_typeIds(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_typeIds} =
      case Map.get(value, :typeIds) do
        nil -> {b, nil}
        [] -> Wire.create_scalar_vector(b, [], 4, 4, &Wire.push_i32/2)
        list when is_list(list) -> Wire.create_scalar_vector(b, list, 4, 4, &Wire.push_i32/2)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 6, addr_typeIds)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.UnionMode.value(Map.get(value, :mode, :Sparse)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"mode",
       if(Map.get(value, :mode) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.UnionMode.__to_json__(Map.get(value, :mode))
       )},
      {"typeIds", Enum.map(Map.get(value, :typeIds) || [], fn v -> v end)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      mode:
        if(Map.get(map, "mode") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.UnionMode.__from_json__(Map.get(map, "mode"))
        ),
      typeIds: Enum.map(Map.get(map, "typeIds") || [], fn v -> v end)
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
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

                            case Wire.verify_bounds(buf, elem_pos, 4) do
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

  @doc "Read field `mode` from a table at position `pos`. Returns the field value or its default."
  def decode_field_mode(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :Sparse
      o -> Arrow.Ipc.Flatbuf.UnionMode.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `typeIds` from a table at position `pos`. Returns the field value or its default."
  def decode_field_typeIds(buf, pos) do
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
            Wire.read_i32(buf, Wire.vector_elem_pos(abs, i, 4))
          end
        end
    end
  end
end
