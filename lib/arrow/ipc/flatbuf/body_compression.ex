defmodule Arrow.Ipc.Flatbuf.BodyCompression do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.BodyCompression. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct codec: :LZ4_FRAME, method: :BUFFER

  @type t :: %__MODULE__{
          codec: Arrow.Ipc.Flatbuf.CompressionType.t() | nil,
          method: Arrow.Ipc.Flatbuf.BodyCompressionMethod.t() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      codec: decode_field_codec(buf, pos),
      method: decode_field_method(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        6,
        Arrow.Ipc.Flatbuf.BodyCompressionMethod.value(Map.get(value, :method, :BUFFER)),
        0,
        &Wire.push_i8/2
      )

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.CompressionType.value(Map.get(value, :codec, :LZ4_FRAME)),
        0,
        &Wire.push_i8/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"codec",
       if(Map.get(value, :codec) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.CompressionType.__to_json__(Map.get(value, :codec))
       )},
      {"method",
       if(Map.get(value, :method) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.BodyCompressionMethod.__to_json__(Map.get(value, :method))
       )}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      codec:
        if(Map.get(map, "codec") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.CompressionType.__from_json__(Map.get(map, "codec"))
        ),
      method:
        if(Map.get(map, "method") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.BodyCompressionMethod.__from_json__(Map.get(map, "method"))
        )
    }
  end

  @doc false
  def __verify_at__(_buf, _pos, 0), do: {:error, :depth_exceeded}

  def __verify_at__(buf, pos, _depth) do
    with {:ok, _vt_pos, _vt_size, _inline_size} <- Wire.verify_table_header(buf, pos) do
      :ok
    end
  end

  @doc "Read field `codec` from a table at position `pos`. Returns the field value or its default."
  def decode_field_codec(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :LZ4_FRAME
      o -> Arrow.Ipc.Flatbuf.CompressionType.from_value(Wire.read_i8(buf, pos + o))
    end
  end

  @doc "Read field `method` from a table at position `pos`. Returns the field value or its default."
  def decode_field_method(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> :BUFFER
      o -> Arrow.Ipc.Flatbuf.BodyCompressionMethod.from_value(Wire.read_i8(buf, pos + o))
    end
  end
end
