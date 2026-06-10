#!/usr/bin/env python3
"""Regenerates the golden IPC files in this directory with pyarrow.

The .stream / .arrow files committed here are external ground truth for
the always-run test suite (test/arrow/golden_test.exs): bytes produced
by the reference C++ implementation via pyarrow, decoded by this
library, and asserted against the literal values below.

Last generated with pyarrow 24.0.0:

    python3 -m venv /tmp/pyarrow-venv
    /tmp/pyarrow-venv/bin/pip install pyarrow
    /tmp/pyarrow-venv/bin/python test/golden/generate.py
"""

import decimal
import os

import pyarrow as pa

HERE = os.path.dirname(os.path.abspath(__file__))


def write(name, schema, batches):
    with pa.output_stream(os.path.join(HERE, name + ".stream")) as sink:
        with pa.ipc.new_stream(sink, schema) as writer:
            for batch in batches:
                writer.write_batch(batch)
    with pa.output_stream(os.path.join(HERE, name + ".arrow")) as sink:
        with pa.ipc.new_file(sink, schema) as writer:
            for batch in batches:
                writer.write_batch(batch)


def primitives():
    schema = pa.schema(
        [
            pa.field("i32", pa.int32()),
            pa.field("u8", pa.uint8()),
            pa.field("f64", pa.float64()),
            pa.field("b", pa.bool_()),
            pa.field("s", pa.utf8()),
            pa.field("bin", pa.binary()),
            pa.field("d32", pa.date32()),
            pa.field("ts_us", pa.timestamp("us", tz="UTC")),
            pa.field("dec", pa.decimal128(10, 2)),
        ]
    )
    batch = pa.record_batch(
        [
            pa.array([1, None, 3, -2147483648, 2147483647], type=pa.int32()),
            pa.array([0, 255, None, 7, 1], type=pa.uint8()),
            pa.array([1.5, None, -0.25, 1e308, 0.0], type=pa.float64()),
            pa.array([True, None, False, True, False], type=pa.bool_()),
            pa.array(["", None, "hé", "arrow", "z"], type=pa.utf8()),
            pa.array([b"\x00\x01", None, b"", b"\xff\x00", b"abc"], type=pa.binary()),
            pa.array([0, 1, None, 19000, -1], type=pa.date32()),
            pa.array(
                [0, 1700000000000000, None, -1, 86400000000],
                type=pa.timestamp("us", tz="UTC"),
            ),
            pa.array(
                [
                    decimal.Decimal("1.23"),
                    None,
                    decimal.Decimal("-99999999.99"),
                    decimal.Decimal("0.01"),
                    decimal.Decimal("0.00"),
                ],
                type=pa.decimal128(10, 2),
            ),
        ],
        schema=schema,
    )
    write("primitives", schema, [batch])


def nested():
    schema = pa.schema(
        [
            pa.field("l", pa.list_(pa.int32())),
            pa.field(
                "st",
                pa.struct([pa.field("a", pa.int32()), pa.field("b", pa.utf8())]),
            ),
            pa.field("m", pa.map_(pa.utf8(), pa.int32())),
        ]
    )
    batch = pa.record_batch(
        [
            pa.array([[1, 2, 3], [], None, [None, 5]], type=pa.list_(pa.int32())),
            pa.array(
                [{"a": 1, "b": "x"}, None, {"a": None, "b": "y"}, {"a": 4, "b": ""}],
                type=schema.field("st").type,
            ),
            pa.array(
                [[("k1", 1), ("k2", 2)], [], None, [("k3", None)]],
                type=pa.map_(pa.utf8(), pa.int32()),
            ),
        ],
        schema=schema,
    )
    write("nested", schema, [batch])


def dictionary():
    indices = pa.array([0, 1, None, 0, 2, 1], type=pa.int8())
    values = pa.array(["a", "b", "c"], type=pa.utf8())
    dict_array = pa.DictionaryArray.from_arrays(indices, values)
    schema = pa.schema([pa.field("d", dict_array.type)])
    batch = pa.record_batch([dict_array], schema=schema)
    write("dictionary", schema, [batch])


def empty():
    schema = pa.schema([pa.field("n", pa.int32()), pa.field("s", pa.utf8())])
    batch = pa.record_batch(
        [pa.array([], type=pa.int32()), pa.array([], type=pa.utf8())],
        schema=schema,
    )
    write("empty", schema, [batch])


if __name__ == "__main__":
    primitives()
    nested()
    dictionary()
    empty()
    print(f"generated with pyarrow {pa.__version__}")
