defmodule Arrow.Ipc.Flatbuf.Timestamp do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Timestamp. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct unit: :SECOND, timezone: nil
  @type t :: %__MODULE__{unit: Arrow.Ipc.Flatbuf.TimeUnit.t() | nil, timezone: String.t() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      unit: decode_field_unit(buf, pos),
      timezone: decode_field_timezone(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_timezone} =
      case Map.get(value, :timezone) do
        nil -> {b, nil}
        "" -> Wire.create_string(b, "")
        s when is_binary(s) -> Wire.create_string(b, s)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 6, addr_timezone)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.TimeUnit.value(Map.get(value, :unit, :SECOND)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"unit",
       if(Map.get(value, :unit) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.TimeUnit.__to_json__(Map.get(value, :unit))
       )},
      {"timezone", Map.get(value, :timezone)}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      unit:
        if(Map.get(map, "unit") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.TimeUnit.__from_json__(Map.get(map, "unit"))
        ),
      timezone: Map.get(map, "timezone")
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
                    {:ok, abs_pos} -> Wire.verify_string_at(buf, abs_pos)
                    err -> err
                  end
              end) do
        :ok
      end
    end
  end

  @doc "Read field `unit` from a table at position `pos`. Returns the field value or its default."
  def decode_field_unit(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :SECOND
      o -> Arrow.Ipc.Flatbuf.TimeUnit.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `timezone` from a table at position `pos`. Returns the field value or its default."
  def decode_field_timezone(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Wire.read_string_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end
end
