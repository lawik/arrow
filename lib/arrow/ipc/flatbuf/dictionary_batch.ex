defmodule Arrow.Ipc.Flatbuf.DictionaryBatch do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.DictionaryBatch. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct id: 0, data: nil, isDelta: false

  @type t :: %__MODULE__{
          id: integer() | nil,
          data: Arrow.Ipc.Flatbuf.RecordBatch.t() | nil,
          isDelta: boolean()
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      id: decode_field_id(buf, pos),
      data: decode_field_data(buf, pos),
      isDelta: decode_field_isDelta(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_data} =
      case Map.get(value, :data) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.RecordBatch.build(b, v)
      end

    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        8,
        if(Map.get(value, :isDelta, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b = Wire.add_field_offset(b, 6, addr_data)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :id, 0), 0, &Wire.push_i64/2)
    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"id", Map.get(value, :id)},
      {"data",
       if(Map.get(value, :data) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.RecordBatch.__to_json_map__(Map.get(value, :data))
       )},
      {"isDelta", Map.get(value, :isDelta)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      data:
        if(Map.get(map, "data") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.RecordBatch.__from_json_map__(Map.get(map, "data"))
        ),
      isDelta: Map.get(map, "isDelta")
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
                    {:ok, abs_pos} ->
                      Arrow.Ipc.Flatbuf.RecordBatch.__verify_at__(buf, abs_pos, depth - 1)

                    err ->
                      err
                  end
              end) do
        :ok
      end
    end
  end

  @doc "Read field `id` from a table at position `pos`. Returns the field value or its default."
  def decode_field_id(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `data` from a table at position `pos`. Returns the field value or its default."
  def decode_field_data(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.RecordBatch.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `isDelta` from a table at position `pos`. Returns the field value or its default."
  def decode_field_isDelta(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end
end
