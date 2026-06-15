# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Arrow.Inspect do
  @shortdoc "Print the schema and layout of an Arrow IPC file or stream"

  @moduledoc """
  Prints a summary of an Arrow IPC file or stream: format, schema
  (field names, types, nullability), per-batch row counts, and
  dictionary sizes.

      mix arrow.inspect path/to/data.arrow

  The format is auto-detected: IPC files start with the `ARROW1`
  magic, anything else is decoded as a stream. Exits non-zero with a
  readable message on malformed or unsupported input.

  Example output:

      format: file
      schema:
        d: dictionary<utf8, indices=int8, id=0> (nullable)
      batches: 1, 6 rows total
        [0] 6 rows
      dictionaries:
        [0] 3 values, referenced by "d"
  """

  use Mix.Task

  alias Arrow.Type

  @impl Mix.Task
  def run(argv) do
    {_opts, args} = OptionParser.parse!(argv, strict: [])

    path =
      case args do
        [path] -> path
        _ -> Mix.raise("usage: mix arrow.inspect <path>")
      end

    binary = File.read!(path)
    {format, payload} = decode(binary, path)

    Mix.shell().info(render(format, payload))
  end

  defp decode(<<"ARROW1", 0, 0, _::binary>> = binary, path),
    do: {:file, decode_with(&Arrow.Ipc.File.decode/1, binary, path)}

  defp decode(binary, path),
    do: {:stream, decode_with(&Arrow.Ipc.Stream.decode/1, binary, path)}

  defp decode_with(decode, binary, path) do
    case decode.(binary) do
      {:ok, payload} -> payload
      {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
    end
  end

  defp render(format, %{schema: schema, dictionaries: dicts, batches: batches}) do
    total_rows = batches |> Enum.map(& &1.length) |> Enum.sum()

    lines =
      ["format: #{format}", "schema:"] ++
        Enum.map(schema.fields, &"  #{field_line(&1)}") ++
        ["batches: #{length(batches)}, #{total_rows} rows total"] ++
        Enum.map(Enum.with_index(batches), fn {b, i} -> "  [#{i}] #{b.length} rows" end) ++
        dictionary_lines(schema, dicts)

    Enum.join(lines, "\n")
  end

  defp dictionary_lines(_schema, dicts) when map_size(dicts) == 0, do: []

  defp dictionary_lines(schema, dicts) do
    entries =
      dicts
      |> Enum.sort_by(fn {id, _} -> id end)
      |> Enum.map(fn {id, values} ->
        field = Arrow.Field.find_by_dictionary_id(schema, id)
        referenced = if field, do: ~s(, referenced by "#{field.name}"), else: ""
        "  [#{id}] #{values.length} values#{referenced}"
      end)

    ["dictionaries:" | entries]
  end

  defp field_line(%Arrow.Field{} = f) do
    "#{f.name}: #{type_string(f)}" <> if f.nullable, do: " (nullable)", else: ""
  end

  defp type_string(%Arrow.Field{dictionary: %Type.DictionaryEncoding{} = d} = f) do
    values = type_string(%{f | dictionary: nil})
    indices = type_name(d.index_type, [])
    "dictionary<#{values}, indices=#{indices}, id=#{d.id}>"
  end

  defp type_string(%Arrow.Field{type: type, children: children}),
    do: type_name(type, children)

  defp type_name(%Type.Null{}, _), do: "null"
  defp type_name(%Type.Bool{}, _), do: "bool"
  defp type_name(%Type.Int{bit_width: b, signed: true}, _), do: "int#{b}"
  defp type_name(%Type.Int{bit_width: b, signed: false}, _), do: "uint#{b}"
  defp type_name(%Type.FloatingPoint{precision: :single}, _), do: "float32"
  defp type_name(%Type.FloatingPoint{precision: :double}, _), do: "float64"
  defp type_name(%Type.Utf8{}, _), do: "utf8"
  defp type_name(%Type.LargeUtf8{}, _), do: "large_utf8"
  defp type_name(%Type.Binary{}, _), do: "binary"
  defp type_name(%Type.LargeBinary{}, _), do: "large_binary"
  defp type_name(%Type.FixedSizeBinary{byte_width: w}, _), do: "fixed_size_binary[#{w}]"
  defp type_name(%Type.Date{unit: :day}, _), do: "date32[day]"
  defp type_name(%Type.Date{unit: :millisecond}, _), do: "date64[ms]"
  defp type_name(%Type.Time{bit_width: b, unit: u}, _), do: "time#{b}[#{unit(u)}]"
  defp type_name(%Type.Timestamp{unit: u, timezone: nil}, _), do: "timestamp[#{unit(u)}]"

  defp type_name(%Type.Timestamp{unit: u, timezone: tz}, _),
    do: "timestamp[#{unit(u)}, tz=#{tz}]"

  defp type_name(%Type.Duration{unit: u}, _), do: "duration[#{unit(u)}]"
  defp type_name(%Type.Interval{unit: u}, _), do: "interval[#{u}]"

  defp type_name(%Type.Decimal{bit_width: b, precision: p, scale: s}, _),
    do: "decimal#{b}(#{p}, #{s})"

  defp type_name(%Type.List{}, [item]), do: "list<#{type_string(item)}>"
  defp type_name(%Type.LargeList{}, [item]), do: "large_list<#{type_string(item)}>"

  defp type_name(%Type.FixedSizeList{list_size: n}, [item]),
    do: "fixed_size_list<#{type_string(item)}>[#{n}]"

  defp type_name(%Type.Struct{}, children),
    do: "struct<#{Enum.map_join(children, ", ", &"#{&1.name}: #{type_string(&1)}")}>"

  defp type_name(%Type.Map{}, [%Arrow.Field{children: [key, value]}]),
    do: "map<#{type_string(key)}, #{type_string(value)}>"

  # Anything unanticipated (new types, missing children) still renders.
  defp type_name(type, _children), do: inspect(type)

  defp unit(:second), do: "s"
  defp unit(:millisecond), do: "ms"
  defp unit(:microsecond), do: "us"
  defp unit(:nanosecond), do: "ns"
end
