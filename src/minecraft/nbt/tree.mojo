"""A tree of NBT values that can be read and built without reflection.

gophertunnel decodes NBT into `map[string]any` or tagged Go structs through
reflection. Mojo has neither, and a struct cannot contain `List[Self]`, so a
`Tree` keeps every tag of one root in an arena and hands out `Tag` handles
(indices) to them. Compounds keep their entries in order, so a decoded tree
encodes back to the same bytes.

```mojo
var t = Tree()  # root compound named ""
var root = t.root()
t.put_string(root, "name", "minecraft:stone")
var states = t.put_compound(root, "states")
t.put_int(states, "stone_type", 0)
var name = t.get_string(root, "name")
for tag in t.children(states):
    print(t.name(tag), t.type_of(tag))
```

Handles are only meaningful for the tree that returned them. Replacing or
removing an entry leaves its old storage in the arena unreferenced; it is not
encoded.
"""

from std.memory import bitcast

from .encoding import tag_name
from .nbt import (
    TAG_BYTE,
    TAG_BYTE_ARRAY,
    TAG_COMPOUND,
    TAG_DOUBLE,
    TAG_END,
    TAG_FLOAT,
    TAG_INT,
    TAG_INT_ARRAY,
    TAG_LIST,
    TAG_LONG,
    TAG_LONG_ARRAY,
    TAG_SHORT,
    TAG_STRING,
)


@fieldwise_init
struct Tag(Equatable, ImplicitlyCopyable, Writable):
    """A handle to one tag inside a `Tree`."""

    var index: Int
    """The position of the tag in the tree's arena."""

    def __eq__(self, other: Self) -> Bool:
        """Checks whether two handles name the same tag.

        Args:
            other: The other handle.

        Returns:
            `True` if both refer to the same arena slot.
        """
        return self.index == other.index

    def write_to(self, mut writer: Some[Writer]):
        """Writes `Tag(index)`.

        Args:
            writer: The destination.
        """
        writer.write("Tag(", self.index, ")")


struct _Entry(Copyable):
    var tag: UInt8
    # Element type of a list.
    var elem: UInt8
    # The name lives in `Tree._bytes[name_start : name_start + name_len]`.
    var name_start: Int
    var name_len: Int
    # Integer value, or the bits of a float or double.
    var value: Int64
    # Strings and byte arrays: offset into `_bytes`; int and long arrays:
    # offset into `_numbers`.
    var start: Int
    var length: Int
    # Arena indices of the entries of a compound or list, in order.
    var children: List[Int]

    def __init__(out self, tag: UInt8, name_start: Int, name_len: Int):
        self.tag = tag
        self.elem = TAG_END
        self.name_start = name_start
        self.name_len = name_len
        self.value = 0
        self.start = 0
        self.length = 0
        self.children = List[Int]()


def _f32_bits(x: Float32) -> Int64:
    return Int64(bitcast[DType.uint32](x))


def _f64_bits(x: Float64) -> Int64:
    return Int64(bitcast[DType.uint64](x))


struct Tree(Copyable, Defaultable, Writable):
    """One NBT root tag and everything below it.

    `write_to` prints SNBT (`{name: "a", n: 3, l: [1b, 2b]}`) for debugging.
    """

    var _entries: List[_Entry]
    var _bytes: List[UInt8]
    var _numbers: List[Int64]

    def __init__(out self):
        """Creates a tree whose root is an empty compound named `""`."""
        self._entries = List[_Entry]()
        self._bytes = List[UInt8]()
        self._numbers = List[Int64]()
        self._entries.append(_Entry(TAG_COMPOUND, 0, 0))

    def __init__(out self, root_type: UInt8, name: StringSpan = "") raises:
        """Creates a tree with a zero-valued root of any type.

        Args:
            root_type: The root tag type. `TAG_END` makes an empty tree that
                encodes as a single `TAG_End` byte; a `TAG_LIST` root takes
                its element type from the first appended value.
            name: The root tag's name.

        Raises:
            If `root_type` is not a known tag type.
        """
        if root_type > TAG_LONG_ARRAY:
            raise Error(t"nbt: unknown tag type {root_type}")
        self = Tree._bare()
        _ = self._push(root_type, name.as_bytes())

    @staticmethod
    def _bare() -> Tree:
        var t = Tree()
        t._entries.clear()
        return t^

    # ===------------------------------------------------------------------=== #
    # Arena primitives (also used by decode.mojo)
    # ===------------------------------------------------------------------=== #

    def _push_bytes(mut self, b: Span[UInt8, _]) -> Int:
        var start = len(self._bytes)
        self._bytes.extend(b)
        return start

    def _push(mut self, tag: UInt8, name: Span[UInt8, _]) -> Int:
        var start = self._push_bytes(name)
        self._entries.append(_Entry(tag, start, len(name)))
        return len(self._entries) - 1

    def _link(mut self, parent: Int, child: Int):
        self._entries[parent].children.append(child)

    def _name_span(self, i: Int) -> Span[UInt8, origin_of(self._bytes)]:
        ref e = self._entries[i]
        return Span(self._bytes)[e.name_start : e.name_start + e.name_len]

    def _name_is(self, i: Int, key: Span[UInt8, _]) -> Bool:
        ref e = self._entries[i]
        if e.name_len != len(key):
            return False
        for j in range(len(key)):
            if self._bytes[e.name_start + j] != key[j]:
                return False
        return True

    def _check(self, t: Tag) raises -> Int:
        if t.index < 0 or t.index >= len(self._entries):
            raise Error(t"nbt: tag handle {t.index} is not in this tree")
        return t.index

    def _find_pos(self, parent: Int, key: Span[UInt8, _]) -> Int:
        """Returns the position of the last entry named `key`, or -1.

        Go decodes compounds into maps, where a repeated name keeps the last
        value.
        """
        ref children = self._entries[parent].children
        var i = len(children) - 1
        while i >= 0:
            if self._name_is(children[i], key):
                return i
            i -= 1
        return -1

    def _attach(mut self, parent: Tag, child: Int) raises:
        """Adds `child` to a compound (replacing a same-named entry) or list."""
        var p = self._check(parent)
        var ptag = self._entries[p].tag
        var ctag = self._entries[child].tag
        if ctag == TAG_END:
            raise Error("nbt: TAG_End cannot be an entry")
        if ptag == TAG_COMPOUND:
            var pos = self._find_pos(p, self._name_span(child))
            if pos >= 0:
                self._entries[p].children[pos] = child
            else:
                self._link(p, child)
        elif ptag == TAG_LIST:
            var elem = self._entries[p].elem
            if elem == TAG_END and len(self._entries[p].children) == 0:
                self._entries[p].elem = ctag
            elif elem != ctag:
                raise Error(
                    t"nbt: cannot add {tag_name(ctag)} to a list of"
                    t" {tag_name(elem)}"
                )
            self._link(p, child)
        else:
            raise Error(
                t"nbt: cannot add an entry to a {tag_name(ptag)}; it is not"
                t" a compound or list"
            )

    def _add(
        mut self, parent: Tag, key: StringSpan, tag: UInt8, value: Int64
    ) raises -> Tag:
        var child = self._push(tag, key.as_bytes())
        self._entries[child].value = value
        self._attach(parent, child)
        return Tag(child)

    def _add_bytes(
        mut self, parent: Tag, key: StringSpan, tag: UInt8, b: Span[UInt8, _]
    ) raises -> Tag:
        var child = self._push(tag, key.as_bytes())
        self._entries[child].start = self._push_bytes(b)
        self._entries[child].length = len(b)
        self._attach(parent, child)
        return Tag(child)

    def _add_numbers(
        mut self, parent: Tag, key: StringSpan, tag: UInt8, var n: List[Int64]
    ) raises -> Tag:
        var child = self._push(tag, key.as_bytes())
        self._entries[child].start = len(self._numbers)
        self._entries[child].length = len(n)
        self._numbers.extend(n^)
        self._attach(parent, child)
        return Tag(child)

    def _copy_entry(mut self, src: Tree, i: Int, name: Span[UInt8, _]) -> Int:
        ref e = src._entries[i]
        var dst = self._push(e.tag, name)
        self._entries[dst].elem = e.elem
        self._entries[dst].value = e.value
        self._entries[dst].length = e.length
        if e.tag == TAG_STRING or e.tag == TAG_BYTE_ARRAY:
            self._entries[dst].start = self._push_bytes(
                Span(src._bytes)[e.start : e.start + e.length]
            )
        elif e.tag == TAG_INT_ARRAY or e.tag == TAG_LONG_ARRAY:
            self._entries[dst].start = len(self._numbers)
            for j in range(e.length):
                self._numbers.append(src._numbers[e.start + j])
        elif e.tag == TAG_COMPOUND or e.tag == TAG_LIST:
            for c in e.children:
                var copied = self._copy_entry(src, c, src._name_span(c))
                self._link(dst, copied)
        return dst

    def _expect(self, t: Tag, tag: UInt8) raises -> Int:
        var i = self._check(t)
        var got = self._entries[i].tag
        if got != tag:
            raise Error(
                t"nbt: tag '{self.name(t)}' is a {tag_name(got)}, not a"
                t" {tag_name(tag)}"
            )
        return i

    # ===------------------------------------------------------------------=== #
    # Inspection
    # ===------------------------------------------------------------------=== #

    def root(self) -> Tag:
        """Gets the root tag.

        Returns:
            A handle to the root.
        """
        return Tag(0)

    def is_empty(self) -> Bool:
        """Checks whether the tree has no value (a root `TAG_End`).

        Returns:
            `True` for an empty tree.
        """
        return len(self._entries) == 0 or self._entries[0].tag == TAG_END

    def type_of(self, t: Tag) raises -> UInt8:
        """Gets the type of a tag.

        Args:
            t: The tag.

        Returns:
            One of the `TAG_*` constants.

        Raises:
            If `t` is not a handle into this tree.
        """
        return self._entries[self._check(t)].tag

    def name(self, t: Tag) -> String:
        """Gets the name of a tag; list elements and the default root have
        an empty name.

        Invalid UTF-8 is replaced with U+FFFD.

        Args:
            t: The tag.

        Returns:
            The name, or an empty string for an invalid handle.
        """
        if t.index < 0 or t.index >= len(self._entries):
            return String()
        return String(from_utf8_lossy=self._name_span(t.index))

    def elem_type(self, t: Tag) raises -> UInt8:
        """Gets the element type of a list.

        Args:
            t: A list tag.

        Returns:
            The element type; `TAG_END` for an untyped empty list.

        Raises:
            If `t` is not a list.
        """
        return self._entries[self._expect(t, TAG_LIST)].elem

    def length(self, t: Tag) raises -> Int:
        """Gets the size of a tag.

        Args:
            t: The tag.

        Returns:
            The entry count of a compound or list, the element count of an
            array, the byte length of a string, and 0 for numbers.

        Raises:
            If `t` is not a handle into this tree.
        """
        ref e = self._entries[self._check(t)]
        if e.tag == TAG_COMPOUND or e.tag == TAG_LIST:
            return len(e.children)
        return e.length

    def children(self, t: Tag) raises -> List[Tag]:
        """Lists the entries of a compound or list in order.

        Args:
            t: A compound or list tag.

        Returns:
            Handles to the entries.

        Raises:
            If `t` is not a compound or list.
        """
        ref e = self._entries[self._check(t)]
        if e.tag != TAG_COMPOUND and e.tag != TAG_LIST:
            raise Error(t"nbt: a {tag_name(e.tag)} has no entries")
        var out = List[Tag](capacity=len(e.children))
        for c in e.children:
            out.append(Tag(c))
        return out^

    def at(self, t: Tag, i: Int) raises -> Tag:
        """Gets the `i`-th entry of a compound or list.

        Args:
            t: A compound or list tag.
            i: The index.

        Returns:
            A handle to the entry.

        Raises:
            If `t` is not a compound or list or `i` is out of range.
        """
        ref e = self._entries[self._check(t)]
        if e.tag != TAG_COMPOUND and e.tag != TAG_LIST:
            raise Error(t"nbt: a {tag_name(e.tag)} has no entries")
        if i < 0 or i >= len(e.children):
            raise Error(t"nbt: index {i} out of range ({len(e.children)})")
        return Tag(e.children[i])

    def get(self, t: Tag, key: StringSpan) -> Optional[Tag]:
        """Looks up an entry of a compound by name.

        If the name repeats (only possible in decoded input), the last entry
        wins, as in gophertunnel's map decoding.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The entry, or `None` if it is missing or `t` is not a compound.
        """
        if t.index < 0 or t.index >= len(self._entries):
            return None
        if self._entries[t.index].tag != TAG_COMPOUND:
            return None
        var pos = self._find_pos(t.index, key.as_bytes())
        if pos < 0:
            return None
        return Tag(self._entries[t.index].children[pos])

    def has(self, t: Tag, key: StringSpan) -> Bool:
        """Checks whether a compound has an entry.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            `True` if the entry exists.
        """
        return Bool(self.get(t, key))

    def require(self, t: Tag, key: StringSpan) raises -> Tag:
        """Looks up an entry of a compound that must exist.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The entry.

        Raises:
            If `t` is not a compound or has no such entry.
        """
        _ = self._expect(t, TAG_COMPOUND)
        if case .Some(found) = self.get(t, key):
            return found
        raise Error(t"nbt: compound '{self.name(t)}' has no entry '{key}'")

    # ===------------------------------------------------------------------=== #
    # Typed values
    # ===------------------------------------------------------------------=== #

    def as_byte(self, t: Tag) raises -> UInt8:
        """Gets the value of a `TAG_Byte`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        return UInt8(self._entries[self._expect(t, TAG_BYTE)].value)

    def as_bool(self, t: Tag) raises -> Bool:
        """Gets a `TAG_Byte` as a bool (`1` is true, as in gophertunnel).

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        return self.as_byte(t) == 1

    def as_short(self, t: Tag) raises -> Int16:
        """Gets the value of a `TAG_Short`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        return Int16(self._entries[self._expect(t, TAG_SHORT)].value)

    def as_int(self, t: Tag) raises -> Int32:
        """Gets the value of a `TAG_Int`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        return Int32(self._entries[self._expect(t, TAG_INT)].value)

    def as_long(self, t: Tag) raises -> Int64:
        """Gets the value of a `TAG_Long`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        return self._entries[self._expect(t, TAG_LONG)].value

    def as_float(self, t: Tag) raises -> Float32:
        """Gets the value of a `TAG_Float`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        var bits = self._entries[self._expect(t, TAG_FLOAT)].value
        return bitcast[DType.float32](UInt32(bits))

    def as_double(self, t: Tag) raises -> Float64:
        """Gets the value of a `TAG_Double`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type.
        """
        var bits = self._entries[self._expect(t, TAG_DOUBLE)].value
        return bitcast[DType.float64](UInt64(bits))

    def as_string(self, t: Tag) raises -> String:
        """Gets the value of a `TAG_String`.

        Args:
            t: The tag.

        Returns:
            The value.

        Raises:
            If the tag has another type or is not valid UTF-8 (use
            `as_string_bytes` for the raw bytes).
        """
        ref e = self._entries[self._expect(t, TAG_STRING)]
        return String(from_utf8=Span(self._bytes)[e.start : e.start + e.length])

    def as_string_bytes(self, t: Tag) raises -> List[UInt8]:
        """Gets the raw bytes of a `TAG_String`.

        Args:
            t: The tag.

        Returns:
            The bytes as they were decoded or set.

        Raises:
            If the tag has another type.
        """
        ref e = self._entries[self._expect(t, TAG_STRING)]
        return List[UInt8](Span(self._bytes)[e.start : e.start + e.length])

    def as_byte_array(self, t: Tag) raises -> List[UInt8]:
        """Gets the value of a `TAG_ByteArray`.

        Args:
            t: The tag.

        Returns:
            A copy of the bytes.

        Raises:
            If the tag has another type.
        """
        ref e = self._entries[self._expect(t, TAG_BYTE_ARRAY)]
        return List[UInt8](Span(self._bytes)[e.start : e.start + e.length])

    def as_int_array(self, t: Tag) raises -> List[Int32]:
        """Gets the value of a `TAG_IntArray`.

        Args:
            t: The tag.

        Returns:
            A copy of the values.

        Raises:
            If the tag has another type.
        """
        ref e = self._entries[self._expect(t, TAG_INT_ARRAY)]
        var out = List[Int32](capacity=e.length)
        for j in range(e.length):
            out.append(Int32(self._numbers[e.start + j]))
        return out^

    def as_long_array(self, t: Tag) raises -> List[Int64]:
        """Gets the value of a `TAG_LongArray`.

        Args:
            t: The tag.

        Returns:
            A copy of the values.

        Raises:
            If the tag has another type.
        """
        ref e = self._entries[self._expect(t, TAG_LONG_ARRAY)]
        return List[Int64](Span(self._numbers)[e.start : e.start + e.length])

    def get_byte(self, t: Tag, key: StringSpan) raises -> UInt8:
        """Gets a `TAG_Byte` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_byte(self.require(t, key))

    def get_bool(self, t: Tag, key: StringSpan) raises -> Bool:
        """Gets a `TAG_Byte` entry of a compound as a bool.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_bool(self.require(t, key))

    def get_short(self, t: Tag, key: StringSpan) raises -> Int16:
        """Gets a `TAG_Short` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_short(self.require(t, key))

    def get_int(self, t: Tag, key: StringSpan) raises -> Int32:
        """Gets a `TAG_Int` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_int(self.require(t, key))

    def get_long(self, t: Tag, key: StringSpan) raises -> Int64:
        """Gets a `TAG_Long` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_long(self.require(t, key))

    def get_float(self, t: Tag, key: StringSpan) raises -> Float32:
        """Gets a `TAG_Float` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_float(self.require(t, key))

    def get_double(self, t: Tag, key: StringSpan) raises -> Float64:
        """Gets a `TAG_Double` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_double(self.require(t, key))

    def get_string(self, t: Tag, key: StringSpan) raises -> String:
        """Gets a `TAG_String` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The value.

        Raises:
            If the entry is missing, has another type or is not UTF-8.
        """
        return self.as_string(self.require(t, key))

    def get_byte_array(self, t: Tag, key: StringSpan) raises -> List[UInt8]:
        """Gets a `TAG_ByteArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            A copy of the bytes.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_byte_array(self.require(t, key))

    def get_int_array(self, t: Tag, key: StringSpan) raises -> List[Int32]:
        """Gets a `TAG_IntArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            A copy of the values.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_int_array(self.require(t, key))

    def get_long_array(self, t: Tag, key: StringSpan) raises -> List[Int64]:
        """Gets a `TAG_LongArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            A copy of the values.

        Raises:
            If the entry is missing or has another type.
        """
        return self.as_long_array(self.require(t, key))

    def get_compound(self, t: Tag, key: StringSpan) raises -> Tag:
        """Gets a `TAG_Compound` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            A handle to the nested compound.

        Raises:
            If the entry is missing or has another type.
        """
        var found = self.require(t, key)
        _ = self._expect(found, TAG_COMPOUND)
        return found

    def get_list(self, t: Tag, key: StringSpan) raises -> Tag:
        """Gets a `TAG_List` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            A handle to the list.

        Raises:
            If the entry is missing or has another type.
        """
        var found = self.require(t, key)
        _ = self._expect(found, TAG_LIST)
        return found

    # ===------------------------------------------------------------------=== #
    # Building compounds. `put_*` replaces an existing entry of the same name
    # in place (map semantics) and returns a handle to the new entry.
    # ===------------------------------------------------------------------=== #

    def put_byte(mut self, t: Tag, key: StringSpan, v: UInt8) raises -> Tag:
        """Sets a `TAG_Byte` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_BYTE, Int64(v))

    def put_bool(mut self, t: Tag, key: StringSpan, v: Bool) raises -> Tag:
        """Sets a `TAG_Byte` entry of a compound to 1 or 0.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_BYTE, Int64(1) if v else Int64(0))

    def put_short(mut self, t: Tag, key: StringSpan, v: Int16) raises -> Tag:
        """Sets a `TAG_Short` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_SHORT, Int64(v))

    def put_int(mut self, t: Tag, key: StringSpan, v: Int32) raises -> Tag:
        """Sets a `TAG_Int` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_INT, Int64(v))

    def put_long(mut self, t: Tag, key: StringSpan, v: Int64) raises -> Tag:
        """Sets a `TAG_Long` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_LONG, v)

    def put_float(mut self, t: Tag, key: StringSpan, v: Float32) raises -> Tag:
        """Sets a `TAG_Float` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_FLOAT, _f32_bits(v))

    def put_double(mut self, t: Tag, key: StringSpan, v: Float64) raises -> Tag:
        """Sets a `TAG_Double` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_DOUBLE, _f64_bits(v))

    def put_string(
        mut self, t: Tag, key: StringSpan, v: StringSpan
    ) raises -> Tag:
        """Sets a `TAG_String` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The value.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        self._need_compound(t)
        return self._add_bytes(t, key, TAG_STRING, v.as_bytes())

    def put_byte_array(
        mut self, t: Tag, key: StringSpan, v: Span[UInt8, _]
    ) raises -> Tag:
        """Sets a `TAG_ByteArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The bytes.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        self._need_compound(t)
        return self._add_bytes(t, key, TAG_BYTE_ARRAY, v)

    def put_int_array(
        mut self, t: Tag, key: StringSpan, v: Span[Int32, _]
    ) raises -> Tag:
        """Sets a `TAG_IntArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The values.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        self._need_compound(t)
        var n = List[Int64](capacity=len(v))
        for x in v:
            n.append(Int64(x))
        return self._add_numbers(t, key, TAG_INT_ARRAY, n^)

    def put_long_array(
        mut self, t: Tag, key: StringSpan, v: Span[Int64, _]
    ) raises -> Tag:
        """Sets a `TAG_LongArray` entry of a compound.

        Args:
            t: A compound tag.
            key: The entry name.
            v: The values.

        Returns:
            The new entry.

        Raises:
            If `t` is not a compound.
        """
        self._need_compound(t)
        return self._add_numbers(t, key, TAG_LONG_ARRAY, List[Int64](v))

    def put_compound(mut self, t: Tag, key: StringSpan) raises -> Tag:
        """Sets an entry of a compound to a new empty compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            The new compound, to fill in.

        Raises:
            If `t` is not a compound.
        """
        return self._add_named(t, key, TAG_COMPOUND, 0)

    def put_list(
        mut self, t: Tag, key: StringSpan, elem: UInt8 = TAG_END
    ) raises -> Tag:
        """Sets an entry of a compound to a new empty list.

        Args:
            t: A compound tag.
            key: The entry name.
            elem: The element type. With `TAG_END` the first appended value
                sets it; a list left empty is then written as a list of
                `TAG_End`, like gophertunnel's `[]any{}`.

        Returns:
            The new list, to fill in.

        Raises:
            If `t` is not a compound or `elem` is unknown.
        """
        if elem > TAG_LONG_ARRAY:
            raise Error(t"nbt: unknown tag type {elem}")
        var l = self._add_named(t, key, TAG_LIST, 0)
        self._entries[l.index].elem = elem
        return l

    def put_tree(
        mut self, t: Tag, key: StringSpan, src: Tree, src_tag: Tag
    ) raises -> Tag:
        """Sets an entry of a compound to a copy of a tag from another tree.

        Args:
            t: A compound tag.
            key: The entry name; the copied tag's own name is dropped.
            src: The tree to copy from.
            src_tag: The tag in `src` to copy, with everything below it.

        Returns:
            The copy.

        Raises:
            If `t` is not a compound or `src_tag` is not in `src`.
        """
        self._need_compound(t)
        var child = self._copy_entry(src, src._check(src_tag), key.as_bytes())
        self._attach(t, child)
        return Tag(child)

    def remove(mut self, t: Tag, key: StringSpan) raises -> Bool:
        """Removes every entry named `key` from a compound.

        Args:
            t: A compound tag.
            key: The entry name.

        Returns:
            `True` if an entry was removed.

        Raises:
            If `t` is not a compound.
        """
        var p = self._expect(t, TAG_COMPOUND)
        var kept = List[Int]()
        var removed = False
        for c in self._entries[p].children:
            if self._name_is(c, key.as_bytes()):
                removed = True
            else:
                kept.append(c)
        self._entries[p].children = kept^
        return removed

    def _need_compound(self, t: Tag) raises:
        _ = self._expect(t, TAG_COMPOUND)

    def _add_named(
        mut self, t: Tag, key: StringSpan, tag: UInt8, value: Int64
    ) raises -> Tag:
        self._need_compound(t)
        return self._add(t, key, tag, value)

    # ===------------------------------------------------------------------=== #
    # Building lists. A list holds one element type; appending another type
    # raises.
    # ===------------------------------------------------------------------=== #

    def _need_list(self, t: Tag) raises:
        _ = self._expect(t, TAG_LIST)

    def append_byte(mut self, t: Tag, v: UInt8) raises -> Tag:
        """Appends a `TAG_Byte` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_BYTE, Int64(v))

    def append_short(mut self, t: Tag, v: Int16) raises -> Tag:
        """Appends a `TAG_Short` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_SHORT, Int64(v))

    def append_int(mut self, t: Tag, v: Int32) raises -> Tag:
        """Appends a `TAG_Int` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_INT, Int64(v))

    def append_long(mut self, t: Tag, v: Int64) raises -> Tag:
        """Appends a `TAG_Long` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_LONG, v)

    def append_float(mut self, t: Tag, v: Float32) raises -> Tag:
        """Appends a `TAG_Float` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_FLOAT, _f32_bits(v))

    def append_double(mut self, t: Tag, v: Float64) raises -> Tag:
        """Appends a `TAG_Double` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_DOUBLE, _f64_bits(v))

    def append_string(mut self, t: Tag, v: StringSpan) raises -> Tag:
        """Appends a `TAG_String` to a list.

        Args:
            t: A list tag.
            v: The value.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add_bytes(t, "", TAG_STRING, v.as_bytes())

    def append_byte_array(mut self, t: Tag, v: Span[UInt8, _]) raises -> Tag:
        """Appends a `TAG_ByteArray` to a list.

        Args:
            t: A list tag.
            v: The bytes.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add_bytes(t, "", TAG_BYTE_ARRAY, v)

    def append_int_array(mut self, t: Tag, v: Span[Int32, _]) raises -> Tag:
        """Appends a `TAG_IntArray` to a list.

        Args:
            t: A list tag.
            v: The values.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        var n = List[Int64](capacity=len(v))
        for x in v:
            n.append(Int64(x))
        return self._add_numbers(t, "", TAG_INT_ARRAY, n^)

    def append_long_array(mut self, t: Tag, v: Span[Int64, _]) raises -> Tag:
        """Appends a `TAG_LongArray` to a list.

        Args:
            t: A list tag.
            v: The values.

        Returns:
            The new element.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add_numbers(t, "", TAG_LONG_ARRAY, List[Int64](v))

    def append_compound(mut self, t: Tag) raises -> Tag:
        """Appends a new empty compound to a list.

        Args:
            t: A list tag.

        Returns:
            The new compound, to fill in.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        return self._add(t, "", TAG_COMPOUND, 0)

    def append_list(mut self, t: Tag, elem: UInt8 = TAG_END) raises -> Tag:
        """Appends a new empty list to a list.

        Args:
            t: A list tag.
            elem: The nested list's element type (see `put_list`).

        Returns:
            The new list, to fill in.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        if elem > TAG_LONG_ARRAY:
            raise Error(t"nbt: unknown tag type {elem}")
        var l = self._add(t, "", TAG_LIST, 0)
        self._entries[l.index].elem = elem
        return l

    def append_tree(mut self, t: Tag, src: Tree, src_tag: Tag) raises -> Tag:
        """Appends a copy of a tag from another tree to a list.

        Args:
            t: A list tag.
            src: The tree to copy from.
            src_tag: The tag in `src` to copy, with everything below it.

        Returns:
            The copy.

        Raises:
            If `t` is not a list or holds another type.
        """
        self._need_list(t)
        var empty = List[UInt8]()
        var child = self._copy_entry(src, src._check(src_tag), Span(empty))
        self._attach(t, child)
        return Tag(child)

    # ===------------------------------------------------------------------=== #
    # SNBT
    # ===------------------------------------------------------------------=== #

    def write_to(self, mut writer: Some[Writer]):
        """Writes the root value as SNBT, for debugging.

        Numbers carry SNBT suffixes (`1b`, `2s`, `3`, `4L`, `5.5f`, `6.5d`),
        arrays are `[B; ...]`, `[I; ...]`, `[L; ...]`. The root's name is
        not written; an empty tree writes nothing.

        Args:
            writer: The destination.
        """
        if self.is_empty():
            return
        self._write_snbt(writer, 0)

    def _write_snbt[W: Writer](self, mut writer: W, i: Int):
        ref e = self._entries[i]
        var tag = e.tag
        if tag == TAG_BYTE:
            writer.write(Int8(UInt8(e.value)), "b")
        elif tag == TAG_SHORT:
            writer.write(Int16(e.value), "s")
        elif tag == TAG_INT:
            writer.write(Int32(e.value))
        elif tag == TAG_LONG:
            writer.write(e.value, "L")
        elif tag == TAG_FLOAT:
            writer.write(bitcast[DType.float32](UInt32(e.value)), "f")
        elif tag == TAG_DOUBLE:
            writer.write(bitcast[DType.float64](UInt64(e.value)), "d")
        elif tag == TAG_STRING:
            _write_quoted(
                writer, Span(self._bytes)[e.start : e.start + e.length]
            )
        elif tag == TAG_BYTE_ARRAY:
            writer.write("[B;")
            for j in range(e.length):
                writer.write(
                    "," if j > 0 else "",
                    " ",
                    Int8(self._bytes[e.start + j]),
                    "b",
                )
            writer.write("]")
        elif tag == TAG_INT_ARRAY or tag == TAG_LONG_ARRAY:
            writer.write("[I;" if tag == TAG_INT_ARRAY else "[L;")
            for j in range(e.length):
                writer.write(
                    "," if j > 0 else "", " ", self._numbers[e.start + j]
                )
                if tag == TAG_LONG_ARRAY:
                    writer.write("L")
            writer.write("]")
        elif tag == TAG_LIST:
            writer.write("[")
            for j in range(len(e.children)):
                if j > 0:
                    writer.write(", ")
                self._write_snbt(writer, e.children[j])
            writer.write("]")
        elif tag == TAG_COMPOUND:
            writer.write("{")
            for j in range(len(e.children)):
                if j > 0:
                    writer.write(", ")
                var c = e.children[j]
                var name = self._name_span(c)
                if _is_bare_key(name):
                    writer.write(StringSpan(unsafe_from_utf8=name))
                else:
                    _write_quoted(writer, name)
                writer.write(": ")
                self._write_snbt(writer, c)
            writer.write("}")


def _is_bare_key(b: Span[UInt8, _]) -> Bool:
    if len(b) == 0:
        return False
    for b8 in b:
        var c = Int(b8)
        var ok = (
            (c >= ord("a") and c <= ord("z"))
            or (c >= ord("A") and c <= ord("Z"))
            or (c >= ord("0") and c <= ord("9"))
            or c == ord("_")
            or c == ord("-")
            or c == ord(".")
            or c == ord("+")
        )
        if not ok:
            return False
    return True


def _write_quoted[W: Writer](mut writer: W, b: Span[UInt8, _]):
    var s = String(from_utf8_lossy=b)
    writer.write('"')
    for cp in s.codepoint_slices():
        if cp == '"':
            writer.write('\\"')
        elif cp == "\\":
            writer.write("\\\\")
        else:
            writer.write(cp)
    writer.write('"')
