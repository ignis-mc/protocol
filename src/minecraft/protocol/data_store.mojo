"""Data store changes (gophertunnel `protocol/data_store.go`).

Go's `DataStorePropertyValue` is recursive: lists and maps hold further
values. A Mojo struct cannot contain a list of itself, so this port keeps the
values of one property in a flat list: `DataStorePropertyValue.nodes`, where
node 0 is the top-level value and lists and maps refer to their elements by
index. Nesting is limited to `MAX_DATA_STORE_DEPTH` levels so that hostile
input cannot exhaust the stack.
"""

from .io import IO, MAX_SLICE_LENGTH, Marshaler, unknown_enum_option

comptime DATA_STORE_CHANGE_TYPE_UPDATE: UInt32 = 0
"""The change entry holds an update."""
comptime DATA_STORE_CHANGE_TYPE_CHANGE: UInt32 = 1
"""The change entry holds a property change."""
comptime DATA_STORE_CHANGE_TYPE_REMOVAL: UInt32 = 2
"""The change entry holds a removal."""

comptime DATA_STORE_CONTROL_DOUBLE: UInt32 = 0
"""The update holds a `float64`."""
comptime DATA_STORE_CONTROL_BOOLEAN: UInt32 = 1
"""The update holds a boolean."""
comptime DATA_STORE_CONTROL_STRING: UInt32 = 2
"""The update holds a string."""

comptime DATA_STORE_PROPERTY_TYPE_NONE: Int32 = 0
"""The value is empty."""
comptime DATA_STORE_PROPERTY_TYPE_BOOL: Int32 = 1
"""The value is a boolean."""
comptime DATA_STORE_PROPERTY_TYPE_INT64: Int32 = 2
"""The value is an `int64`."""
comptime DATA_STORE_PROPERTY_TYPE_DOUBLE: Int32 = 3
"""The value is a `float64`."""
comptime DATA_STORE_PROPERTY_TYPE_STRING: Int32 = 4
"""The value is a string."""
comptime DATA_STORE_PROPERTY_TYPE_LIST: Int32 = 5
"""The value is a list of values."""
comptime DATA_STORE_PROPERTY_TYPE_MAP: Int32 = 6
"""The value is a map from strings to values."""

comptime MAX_DATA_STORE_DEPTH = 256
"""The deepest nesting of lists and maps accepted in a property value."""


struct DataStoreChangeEntry(Marshaler):
    """One entry of the data store changes list."""

    var change_type: UInt32
    """One of the `DATA_STORE_CHANGE_TYPE_*` constants."""
    var update: DataStoreUpdate
    """The update, for `DATA_STORE_CHANGE_TYPE_UPDATE`."""
    var change: DataStoreChange
    """The change, for `DATA_STORE_CHANGE_TYPE_CHANGE`."""
    var removal: DataStoreRemoval
    """The removal, for `DATA_STORE_CHANGE_TYPE_REMOVAL`."""

    def __init__(out self):
        """Creates an empty update entry."""
        self.change_type = DATA_STORE_CHANGE_TYPE_UPDATE
        self.update = DataStoreUpdate()
        self.change = DataStoreChange()
        self.removal = DataStoreRemoval()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the change type is unknown or the input is malformed.
        """
        io.varuint32(self.change_type)
        if self.change_type == DATA_STORE_CHANGE_TYPE_UPDATE:
            self.update.marshal(io)
        elif self.change_type == DATA_STORE_CHANGE_TYPE_CHANGE:
            io.string(self.change.data_store_name)
            io.string(self.change.property)
            io.uint32(self.change.update_count)
            marshal_data_store_property_value(io, self.change.new_value)
        elif self.change_type == DATA_STORE_CHANGE_TYPE_REMOVAL:
            io.string(self.removal.data_store_name)
        else:
            unknown_enum_option(Int(self.change_type), "data store change type")


struct DataStoreUpdate(Marshaler):
    """An update to a data store property."""

    var data_store_name: String
    """The name of the data store."""
    var property: String
    """The property updated."""
    var path: String
    """The path within the property."""
    var control_type: UInt32
    """The type of the value, one of the `DATA_STORE_CONTROL_*` constants."""
    var double_value: Float64
    """The value, for `DATA_STORE_CONTROL_DOUBLE`."""
    var bool_value: Bool
    """The value, for `DATA_STORE_CONTROL_BOOLEAN`."""
    var string_value: String
    """The value, for `DATA_STORE_CONTROL_STRING`."""
    var property_update_count: UInt32
    """The update count of the property."""
    var path_update_count: UInt32
    """The update count of the path."""

    def __init__(out self):
        """Creates an empty update of a `float64` value."""
        self.data_store_name = String()
        self.property = String()
        self.path = String()
        self.control_type = DATA_STORE_CONTROL_DOUBLE
        self.double_value = 0
        self.bool_value = False
        self.string_value = String()
        self.property_update_count = 0
        self.path_update_count = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the update.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the control type is unknown or the input is malformed.
        """
        io.string(self.data_store_name)
        io.string(self.property)
        io.string(self.path)
        io.varuint32(self.control_type)
        if self.control_type == DATA_STORE_CONTROL_DOUBLE:
            io.float64(self.double_value)
        elif self.control_type == DATA_STORE_CONTROL_BOOLEAN:
            io.bool(self.bool_value)
        elif self.control_type == DATA_STORE_CONTROL_STRING:
            io.string(self.string_value)
        else:
            unknown_enum_option(
                Int(self.control_type), "data store control type"
            )
        io.uint32(self.property_update_count)
        io.uint32(self.path_update_count)


@fieldwise_init
struct DataStoreMapEntry(Copyable, Defaultable):
    """A key and value of a map property value."""

    var key: String
    """The map key."""
    var value: Int
    """The index of the value in `DataStorePropertyValue.nodes`."""

    def __init__(out self):
        """Creates an entry with an empty key pointing at node 0."""
        self.key = String()
        self.value = 0


struct DataStorePropertyNode(Copyable, Defaultable):
    """One typed value inside a `DataStorePropertyValue`.

    This is the content of Go's `DataStorePropertyValue`, with nested values
    replaced by indices into the enclosing value's `nodes`.
    """

    var type: Int32
    """One of the `DATA_STORE_PROPERTY_TYPE_*` constants."""
    var bool_value: Bool
    """The value, for `DATA_STORE_PROPERTY_TYPE_BOOL`."""
    var int64_value: Int64
    """The value, for `DATA_STORE_PROPERTY_TYPE_INT64`."""
    var double_value: Float64
    """The value, for `DATA_STORE_PROPERTY_TYPE_DOUBLE`."""
    var string_value: String
    """The value, for `DATA_STORE_PROPERTY_TYPE_STRING`."""
    var list_value: List[Int]
    """Node indices of the elements, for `DATA_STORE_PROPERTY_TYPE_LIST`."""
    var map_value: List[DataStoreMapEntry]
    """The entries, for `DATA_STORE_PROPERTY_TYPE_MAP`."""

    def __init__(out self):
        """Creates an empty (`DATA_STORE_PROPERTY_TYPE_NONE`) value."""
        self.type = DATA_STORE_PROPERTY_TYPE_NONE
        self.bool_value = False
        self.int64_value = 0
        self.double_value = 0
        self.string_value = String()
        self.list_value = List[Int]()
        self.map_value = List[DataStoreMapEntry]()

    def __init__(out self, type: Int32):
        """Creates an empty value of a type.

        Args:
            type: One of the `DATA_STORE_PROPERTY_TYPE_*` constants.
        """
        self = Self()
        self.type = type


struct DataStorePropertyValue(Copyable, Defaultable):
    """A typed property value, with any nested values, in a flat list."""

    var nodes: List[DataStorePropertyNode]
    """Every value; `nodes[0]` is the top-level one."""

    def __init__(out self):
        """Creates an empty (`DATA_STORE_PROPERTY_TYPE_NONE`) value."""
        self.nodes = [DataStorePropertyNode()]

    def __init__(out self, var root: DataStorePropertyNode):
        """Creates a value whose top-level node is `root`.

        Args:
            root: The top-level value.
        """
        self.nodes = [root^]

    def add(mut self, var node: DataStorePropertyNode) -> Int:
        """Appends a nested value.

        Args:
            node: The value.

        Returns:
            Its index, to put in a list or map entry.
        """
        self.nodes.append(node^)
        return len(self.nodes) - 1


@fieldwise_init
struct DataStoreChange(Copyable, Defaultable):
    """A change to a data store property value."""

    var data_store_name: String
    """The name of the data store."""
    var property: String
    """The property that changed."""
    var update_count: UInt32
    """The update count."""
    var new_value: DataStorePropertyValue
    """The new value of the property."""

    def __init__(out self):
        """Creates an empty change."""
        self.data_store_name = String()
        self.property = String()
        self.update_count = 0
        self.new_value = DataStorePropertyValue()


@fieldwise_init
struct DataStoreRemoval(Copyable, Defaultable):
    """The removal of a data store."""

    var data_store_name: String
    """The name of the data store removed."""

    def __init__(out self):
        """Creates an empty removal."""
        self.data_store_name = String()


def marshal_data_store_property_value[
    I: IO
](mut io: I, mut x: DataStorePropertyValue) raises:
    """Marshals a property value (gophertunnel `MarshalDataStorePropertyValue`).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If a type is unknown, a node index is out of range, the value is
        nested deeper than `MAX_DATA_STORE_DEPTH`, or the input is malformed.
    """
    if io.reads() or len(x.nodes) == 0:
        x.nodes = [DataStorePropertyNode()]
    _marshal_node(io, x.nodes, 0, 0)


def _marshal_node[
    I: IO
](
    mut io: I, mut nodes: List[DataStorePropertyNode], index: Int, depth: Int
) raises:
    if depth > MAX_DATA_STORE_DEPTH:
        raise Error("data store property value is nested too deeply")
    if index < 0 or index >= len(nodes):
        raise Error(t"data store property value node {index} does not exist")
    io.int32(nodes[index].type)
    var t = nodes[index].type
    if t == DATA_STORE_PROPERTY_TYPE_NONE:
        pass
    elif t == DATA_STORE_PROPERTY_TYPE_BOOL:
        io.bool(nodes[index].bool_value)
    elif t == DATA_STORE_PROPERTY_TYPE_INT64:
        io.int64(nodes[index].int64_value)
    elif t == DATA_STORE_PROPERTY_TYPE_DOUBLE:
        io.float64(nodes[index].double_value)
    elif t == DATA_STORE_PROPERTY_TYPE_STRING:
        io.string(nodes[index].string_value)
    elif t == DATA_STORE_PROPERTY_TYPE_LIST:
        var count = UInt32(len(nodes[index].list_value))
        io.varuint32(count)
        if io.reads():
            io.slice_length(count, MAX_SLICE_LENGTH)
            var children = List[Int](capacity=Int(count))
            for _ in range(Int(count)):
                nodes.append(DataStorePropertyNode())
                var child = len(nodes) - 1
                children.append(child)
                _marshal_node(io, nodes, child, depth + 1)
            nodes[index].list_value = children^
            return
        for k in range(Int(count)):
            var child = nodes[index].list_value[k]
            _marshal_node(io, nodes, child, depth + 1)
    elif t == DATA_STORE_PROPERTY_TYPE_MAP:
        var count = UInt32(len(nodes[index].map_value))
        io.varuint32(count)
        if io.reads():
            io.slice_length(count, MAX_SLICE_LENGTH)
            var entries = List[DataStoreMapEntry](capacity=Int(count))
            for _ in range(Int(count)):
                var key = String()
                io.string(key)
                nodes.append(DataStorePropertyNode())
                var child = len(nodes) - 1
                entries.append(DataStoreMapEntry(key^, child))
                _marshal_node(io, nodes, child, depth + 1)
            nodes[index].map_value = entries^
            return
        for k in range(Int(count)):
            var key = nodes[index].map_value[k].key.copy()
            io.string(key)
            var child = nodes[index].map_value[k].value
            _marshal_node(io, nodes, child, depth + 1)
    else:
        unknown_enum_option(Int(t), "data store property type")
