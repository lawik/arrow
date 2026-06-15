defmodule Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX do
  # Generated from FlatBuffers table Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX. Do not edit.
  @moduledoc false

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct compressedAxis: :Row,
            indptrType: nil,
            indptrBuffer: nil,
            indicesType: nil,
            indicesBuffer: nil

  @type t :: %__MODULE__{
          compressedAxis: Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.t() | nil,
          indptrType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indptrBuffer: Arrow.Ipc.Flatbuf.Buffer.t() | nil,
          indicesType: Arrow.Ipc.Flatbuf.Int.t() | nil,
          indicesBuffer: Arrow.Ipc.Flatbuf.Buffer.t() | nil
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      compressedAxis: decode_field_compressedAxis(buf, pos),
      indptrType: decode_field_indptrType(buf, pos),
      indptrBuffer: decode_field_indptrBuffer(buf, pos),
      indicesType: decode_field_indicesType(buf, pos),
      indicesBuffer: decode_field_indicesBuffer(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_indptrType} =
      case Map.get(value, :indptrType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    {b, addr_indicesType} =
      case Map.get(value, :indicesType) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Int.build(b, v)
      end

    b = Wire.start_table(b)

    b =
      case Map.get(value, :indicesBuffer) do
        nil -> b
        v -> Wire.add_field_struct(b, 12, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 10, addr_indicesType)

    b =
      case Map.get(value, :indptrBuffer) do
        nil -> b
        v -> Wire.add_field_struct(b, 8, Arrow.Ipc.Flatbuf.Buffer.encode(v), 8)
      end

    b = Wire.add_field_offset(b, 6, addr_indptrType)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.value(Map.get(value, :compressedAxis, :Row)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc false
  def __to_json_map__(value) when is_map(value) do
    Map.new([
      {"compressedAxis",
       if(Map.get(value, :compressedAxis) == nil,
         do: nil,
         else:
           Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.__to_json__(
             Map.get(value, :compressedAxis)
           )
       )},
      {"indptrType",
       if(Map.get(value, :indptrType) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Int.__to_json_map__(Map.get(value, :indptrType))
       )},
      {"indptrBuffer",
       if(Map.get(value, :indptrBuffer) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Buffer.__to_json_map__(Map.get(value, :indptrBuffer))
       )},
      {"indicesType",
       if(Map.get(value, :indicesType) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Int.__to_json_map__(Map.get(value, :indicesType))
       )},
      {"indicesBuffer",
       if(Map.get(value, :indicesBuffer) == nil,
         do: nil,
         else: Arrow.Ipc.Flatbuf.Buffer.__to_json_map__(Map.get(value, :indicesBuffer))
       )}
    ])
    |> Map.reject(fn {_k, v} -> v == nil or v == [] end)
  end

  @doc false
  def __from_json_map__(map) when is_map(map) do
    %__MODULE__{
      compressedAxis:
        if(Map.get(map, "compressedAxis") == nil,
          do: nil,
          else:
            Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.__from_json__(
              Map.get(map, "compressedAxis")
            )
        ),
      indptrType:
        if(Map.get(map, "indptrType") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Int.__from_json_map__(Map.get(map, "indptrType"))
        ),
      indptrBuffer:
        if(Map.get(map, "indptrBuffer") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(Map.get(map, "indptrBuffer"))
        ),
      indicesType:
        if(Map.get(map, "indicesType") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Int.__from_json_map__(Map.get(map, "indicesType"))
        ),
      indicesBuffer:
        if(Map.get(map, "indicesBuffer") == nil,
          do: nil,
          else: Arrow.Ipc.Flatbuf.Buffer.__from_json_map__(Map.get(map, "indicesBuffer"))
        )
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
                    {:ok, abs_pos} -> Arrow.Ipc.Flatbuf.Int.__verify_at__(buf, abs_pos, depth - 1)
                    err -> err
                  end
              end),
           :ok <-
             (case Wire.read_vtable_field(buf, pos, 10) do
                0 ->
                  :ok

                o ->
                  case Wire.verify_follow_uoffset(buf, pos + o) do
                    {:ok, abs_pos} -> Arrow.Ipc.Flatbuf.Int.__verify_at__(buf, abs_pos, depth - 1)
                    err -> err
                  end
              end) do
        :ok
      end
    end
  end

  @doc "Read field `compressedAxis` from a table at position `pos`. Returns the field value or its default."
  def decode_field_compressedAxis(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :Row
      o -> Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `indptrType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indptrBuffer` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indptrBuffer(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end

  @doc "Read field `indicesType` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesType(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Int.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `indicesBuffer` from a table at position `pos`. Returns the field value or its default."
  def decode_field_indicesBuffer(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Buffer.decode_at(buf, pos + o)
    end
  end
end
