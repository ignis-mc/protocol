"""Item stack requests and responses (gophertunnel `protocol/item_stack.go`).

Go's `StackRequestAction` interface becomes `StackRequestAction`, a struct
holding a `Variant` of the concrete actions. Each concrete action carries its
type ID as `comptime ID`. `StackRequestAction.marshal` is gophertunnel's
`IO.StackRequestAction`: the variant index, the type ID and the action.
"""

from std.builtin.rebind import downcast
from std.utils import Variant

from .container import FullContainerName
from .io import (
    IO,
    MAX_SLICE_LENGTH,
    Marshaler,
    invalid_value,
    optional_string,
    slice,
    string_slice,
    unknown_enum_option,
)

# Re-exported so packet code can import the item encodings from here too.
from .item import (
    ItemInstance,
    ItemStack,
    StackRequestItem,
    item,
    item_instance,
)
from .item_descriptor import (
    ItemDescriptorCount,
    stack_request_item_descriptor_count,
)

comptime FILTER_CAUSE_SERVER_CHAT_PUBLIC: Int32 = 0
"""Text filtered because of: server chat public."""
comptime FILTER_CAUSE_SERVER_CHAT_WHISPER: Int32 = 1
"""Text filtered because of: server chat whisper."""
comptime FILTER_CAUSE_SIGN_TEXT: Int32 = 2
"""Text filtered because of: sign text."""
comptime FILTER_CAUSE_ANVIL_TEXT: Int32 = 3
"""Text filtered because of: anvil text."""
comptime FILTER_CAUSE_BOOK_AND_QUILL_TEXT: Int32 = 4
"""Text filtered because of: book and quill text."""
comptime FILTER_CAUSE_COMMAND_BLOCK_TEXT: Int32 = 5
"""Text filtered because of: command block text."""
comptime FILTER_CAUSE_BLOCK_ACTOR_DATA_TEXT: Int32 = 6
"""Text filtered because of: block actor data text."""
comptime FILTER_CAUSE_JOIN_EVENT_TEXT: Int32 = 7
"""Text filtered because of: join event text."""
comptime FILTER_CAUSE_LEAVE_EVENT_TEXT: Int32 = 8
"""Text filtered because of: leave event text."""
comptime FILTER_CAUSE_SLASH_COMMAND_CHAT: Int32 = 9
"""Text filtered because of: slash command chat."""
comptime FILTER_CAUSE_CARTOGRAPHY_TEXT: Int32 = 10
"""Text filtered because of: cartography text."""
comptime FILTER_CAUSE_KICK_COMMAND: Int32 = 11
"""Text filtered because of: kick command."""
comptime FILTER_CAUSE_TITLE_COMMAND: Int32 = 12
"""Text filtered because of: title command."""
comptime FILTER_CAUSE_SUMMON_COMMAND: Int32 = 13
"""Text filtered because of: summon command."""

comptime ITEM_STACK_RESPONSE_STATUS_OK: UInt8 = 0
"""Response status: ok."""
comptime ITEM_STACK_RESPONSE_STATUS_ERROR: UInt8 = 1
"""Response status: error."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_REQUEST_ACTION_TYPE: UInt8 = 2
"""Response status: invalid request action type."""
comptime ITEM_STACK_RESPONSE_STATUS_ACTION_REQUEST_NOT_ALLOWED: UInt8 = 3
"""Response status: action request not allowed."""
comptime ITEM_STACK_RESPONSE_STATUS_SCREEN_HANDLER_END_REQUEST_FAILED: UInt8 = 4
"""Response status: screen handler end request failed."""
comptime ITEM_STACK_RESPONSE_STATUS_ITEM_REQUEST_ACTION_HANDLER_COMMIT_FAILED: UInt8 = 5
"""Response status: item request action handler commit failed."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_REQUEST_CRAFT_ACTION_TYPE: UInt8 = 6
"""Response status: invalid request craft action type."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_REQUEST: UInt8 = 7
"""Response status: invalid craft request."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_REQUEST_SCREEN: UInt8 = 8
"""Response status: invalid craft request screen."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_RESULT: UInt8 = 9
"""Response status: invalid craft result."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_RESULT_INDEX: UInt8 = 10
"""Response status: invalid craft result index."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_RESULT_ITEM: UInt8 = 11
"""Response status: invalid craft result item."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_ITEM_NET_ID: UInt8 = 12
"""Response status: invalid item net id."""
comptime ITEM_STACK_RESPONSE_STATUS_MISSING_CREATED_OUTPUT_CONTAINER: UInt8 = 13
"""Response status: missing created output container."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_SET_CREATED_ITEM_OUTPUT_SLOT: UInt8 = 14
"""Response status: failed to set created item output slot."""
comptime ITEM_STACK_RESPONSE_STATUS_REQUEST_ALREADY_IN_PROGRESS: UInt8 = 15
"""Response status: request already in progress."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_INIT_SPARSE_CONTAINER: UInt8 = 16
"""Response status: failed to init sparse container."""
comptime ITEM_STACK_RESPONSE_STATUS_RESULT_TRANSFER_FAILED: UInt8 = 17
"""Response status: result transfer failed."""
comptime ITEM_STACK_RESPONSE_STATUS_EXPECTED_ITEM_SLOT_NOT_FULLY_CONSUMED: UInt8 = 18
"""Response status: expected item slot not fully consumed."""
comptime ITEM_STACK_RESPONSE_STATUS_EXPECTED_ANYWHERE_ITEM_NOT_FULLY_CONSUMED: UInt8 = 19
"""Response status: expected anywhere item not fully consumed."""
comptime ITEM_STACK_RESPONSE_STATUS_ITEM_ALREADY_CONSUMED_FROM_SLOT: UInt8 = 20
"""Response status: item already consumed from slot."""
comptime ITEM_STACK_RESPONSE_STATUS_CONSUMED_TOO_MUCH_FROM_SLOT: UInt8 = 21
"""Response status: consumed too much from slot."""
comptime ITEM_STACK_RESPONSE_STATUS_MISMATCH_SLOT_EXPECTED_CONSUMED_ITEM: UInt8 = 22
"""Response status: mismatch slot expected consumed item."""
comptime ITEM_STACK_RESPONSE_STATUS_MISMATCH_SLOT_EXPECTED_CONSUMED_ITEM_NET_ID_VARIANT: UInt8 = 23
"""Response status: mismatch slot expected consumed item net id variant."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_MATCH_EXPECTED_SLOT_CONSUMED_ITEM: UInt8 = 24
"""Response status: failed to match expected slot consumed item."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_MATCH_EXPECTED_ALLOWED_ANYWHERE_CONSUMED_ITEM: UInt8 = 25
"""Response status: failed to match expected allowed anywhere consumed item."""
comptime ITEM_STACK_RESPONSE_STATUS_CONSUMED_ITEM_OUT_OF_ALLOWED_SLOT_RANGE: UInt8 = 26
"""Response status: consumed item out of allowed slot range."""
comptime ITEM_STACK_RESPONSE_STATUS_CONSUMED_ITEM_NOT_ALLOWED: UInt8 = 27
"""Response status: consumed item not allowed."""
comptime ITEM_STACK_RESPONSE_STATUS_PLAYER_NOT_IN_CREATIVE_MODE: UInt8 = 28
"""Response status: player not in creative mode."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_EXPERIMENTAL_RECIPE_REQUEST: UInt8 = 29
"""Response status: invalid experimental recipe request."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_CRAFT_CREATIVE: UInt8 = 30
"""Response status: failed to craft creative."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_GET_LEVEL_RECIPE: UInt8 = 31
"""Response status: failed to get level recipe."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_FIND_RECIPE_BY_NET_ID: UInt8 = 32
"""Response status: failed to find recipe by net id."""
comptime ITEM_STACK_RESPONSE_STATUS_MISMATCHED_CRAFTING_SIZE: UInt8 = 33
"""Response status: mismatched crafting size."""
comptime ITEM_STACK_RESPONSE_STATUS_MISSING_INPUT_SPARSE_CONTAINER: UInt8 = 34
"""Response status: missing input sparse container."""
comptime ITEM_STACK_RESPONSE_STATUS_MISMATCHED_RECIPE_FOR_INPUT_GRID_ITEMS: UInt8 = 35
"""Response status: mismatched recipe for input grid items."""
comptime ITEM_STACK_RESPONSE_STATUS_EMPTY_CRAFT_RESULTS: UInt8 = 36
"""Response status: empty craft results."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_ENCHANT: UInt8 = 37
"""Response status: failed to enchant."""
comptime ITEM_STACK_RESPONSE_STATUS_MISSING_INPUT_ITEM: UInt8 = 38
"""Response status: missing input item."""
comptime ITEM_STACK_RESPONSE_STATUS_INSUFFICIENT_PLAYER_LEVEL_TO_ENCHANT: UInt8 = 39
"""Response status: insufficient player level to enchant."""
comptime ITEM_STACK_RESPONSE_STATUS_MISSING_MATERIAL_ITEM: UInt8 = 40
"""Response status: missing material item."""
comptime ITEM_STACK_RESPONSE_STATUS_MISSING_ACTOR: UInt8 = 41
"""Response status: missing actor."""
comptime ITEM_STACK_RESPONSE_STATUS_UNKNOWN_PRIMARY_EFFECT: UInt8 = 42
"""Response status: unknown primary effect."""
comptime ITEM_STACK_RESPONSE_STATUS_PRIMARY_EFFECT_OUT_OF_RANGE: UInt8 = 43
"""Response status: primary effect out of range."""
comptime ITEM_STACK_RESPONSE_STATUS_PRIMARY_EFFECT_UNAVAILABLE: UInt8 = 44
"""Response status: primary effect unavailable."""
comptime ITEM_STACK_RESPONSE_STATUS_SECONDARY_EFFECT_OUT_OF_RANGE: UInt8 = 45
"""Response status: secondary effect out of range."""
comptime ITEM_STACK_RESPONSE_STATUS_SECONDARY_EFFECT_UNAVAILABLE: UInt8 = 46
"""Response status: secondary effect unavailable."""
comptime ITEM_STACK_RESPONSE_STATUS_DST_CONTAINER_EQUAL_TO_CREATED_OUTPUT_CONTAINER: UInt8 = 47
"""Response status: dst container equal to created output container."""
comptime ITEM_STACK_RESPONSE_STATUS_DST_CONTAINER_AND_SLOT_EQUAL_TO_SRC_CONTAINER_AND_SLOT: UInt8 = 48
"""Response status: dst container and slot equal to src container and slot."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_VALIDATE_SRC_SLOT: UInt8 = 49
"""Response status: failed to validate src slot."""
comptime ITEM_STACK_RESPONSE_STATUS_FAILED_TO_VALIDATE_DST_SLOT: UInt8 = 50
"""Response status: failed to validate dst slot."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_ADJUSTED_AMOUNT: UInt8 = 51
"""Response status: invalid adjusted amount."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_ITEM_SET_TYPE: UInt8 = 52
"""Response status: invalid item set type."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_TRANSFER_AMOUNT: UInt8 = 53
"""Response status: invalid transfer amount."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_SWAP_ITEM: UInt8 = 54
"""Response status: cannot swap item."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_PLACE_ITEM: UInt8 = 55
"""Response status: cannot place item."""
comptime ITEM_STACK_RESPONSE_STATUS_UNHANDLED_ITEM_SET_TYPE: UInt8 = 56
"""Response status: unhandled item set type."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_REMOVED_AMOUNT: UInt8 = 57
"""Response status: invalid removed amount."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_REGION: UInt8 = 58
"""Response status: invalid region."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_DROP_ITEM: UInt8 = 59
"""Response status: cannot drop item."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_DESTROY_ITEM: UInt8 = 60
"""Response status: cannot destroy item."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_SOURCE_CONTAINER: UInt8 = 61
"""Response status: invalid source container."""
comptime ITEM_STACK_RESPONSE_STATUS_ITEM_NOT_CONSUMED: UInt8 = 62
"""Response status: item not consumed."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_NUM_CRAFTS: UInt8 = 63
"""Response status: invalid num crafts."""
comptime ITEM_STACK_RESPONSE_STATUS_INVALID_CRAFT_RESULT_STACK_SIZE: UInt8 = 64
"""Response status: invalid craft result stack size."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_REMOVE_ITEM: UInt8 = 65
"""Response status: cannot remove item."""
comptime ITEM_STACK_RESPONSE_STATUS_CANNOT_CONSUME_ITEM: UInt8 = 66
"""Response status: cannot consume item."""
comptime ITEM_STACK_RESPONSE_STATUS_SCREEN_STACK_ERROR: UInt8 = 67
"""Response status: screen stack error."""

comptime STACK_REQUEST_ACTION_TAKE: UInt8 = 0
"""The type ID of the take stack request action."""
comptime STACK_REQUEST_ACTION_PLACE: UInt8 = 1
"""The type ID of the place stack request action."""
comptime STACK_REQUEST_ACTION_SWAP: UInt8 = 2
"""The type ID of the swap stack request action."""
comptime STACK_REQUEST_ACTION_DROP: UInt8 = 3
"""The type ID of the drop stack request action."""
comptime STACK_REQUEST_ACTION_DESTROY: UInt8 = 4
"""The type ID of the destroy stack request action."""
comptime STACK_REQUEST_ACTION_CONSUME: UInt8 = 5
"""The type ID of the consume stack request action."""
comptime STACK_REQUEST_ACTION_CREATE: UInt8 = 6
"""The type ID of the create stack request action."""
comptime STACK_REQUEST_ACTION_PLACE_IN_CONTAINER: UInt8 = 7
"""The type ID of the place in container stack request action."""
comptime STACK_REQUEST_ACTION_TAKE_OUT_CONTAINER: UInt8 = 8
"""The type ID of the take out container stack request action."""
comptime STACK_REQUEST_ACTION_LAB_TABLE_COMBINE: UInt8 = 9
"""The type ID of the lab table combine stack request action."""
comptime STACK_REQUEST_ACTION_BEACON_PAYMENT: UInt8 = 10
"""The type ID of the beacon payment stack request action."""
comptime STACK_REQUEST_ACTION_MINE_BLOCK: UInt8 = 11
"""The type ID of the mine block stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_RECIPE: UInt8 = 12
"""The type ID of the craft recipe stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_RECIPE_AUTO: UInt8 = 13
"""The type ID of the craft recipe auto stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_CREATIVE: UInt8 = 14
"""The type ID of the craft creative stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_RECIPE_OPTIONAL: UInt8 = 15
"""The type ID of the craft recipe optional stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_GRINDSTONE: UInt8 = 16
"""The type ID of the craft grindstone stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_LOOM: UInt8 = 17
"""The type ID of the craft loom stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_RESERVED: UInt8 = 18
"""The type ID of the craft reserved stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_NON_IMPLEMENTED_DEPRECATED: UInt8 = 19
"""The type ID of the craft non implemented deprecated stack request action."""
comptime STACK_REQUEST_ACTION_CRAFT_RESULTS_DEPRECATED: UInt8 = 20
"""The type ID of the craft results deprecated stack request action."""


struct ItemStackRequest(Marshaler):
    """One request of an `ItemStackRequest` packet, answered by the server."""

    var request_id: Int32
    """A unique ID the server's response refers to."""
    var actions: List[StackRequestAction]
    """The actions the client performed."""
    var filter_strings: List[String]
    """Strings involved in the request, such as an anvil item name."""
    var filter_cause: Int32
    """The cause of any filtering, one of the `FILTER_CAUSE_*` constants."""

    def __init__(out self):
        """Creates an empty request."""
        self.request_id = 0
        self.actions = List[StackRequestAction]()
        self.filter_strings = List[String]()
        self.filter_cause = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the request.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.request_id)
        slice(io, self.actions)
        string_slice(io, self.filter_strings)
        io.int32(self.filter_cause)


struct ItemStackResponse(Marshaler):
    """The server's answer to one `ItemStackRequest`."""

    var status: UInt8
    """0 on success, else one of the `ITEM_STACK_RESPONSE_STATUS_*` errors."""
    var request_id: Int32
    """The ID of the request this answers."""
    var container_info: List[StackResponseContainerInfo]
    """The containers whose contents changed; empty on failure."""

    def __init__(out self):
        """Creates an empty successful response."""
        self.status = ITEM_STACK_RESPONSE_STATUS_OK
        self.request_id = 0
        self.container_info = List[StackResponseContainerInfo]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the response.

        The container info is optional on the wire and sent only when
        non-empty.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.status)
        io.varint32(self.request_id)
        var present = len(self.container_info) != 0
        io.bool(present)
        if present:
            slice(io, self.container_info)


struct StackResponseContainerInfo(Marshaler):
    """The item stacks in the changed slots of one container."""

    var container: FullContainerName
    """The container the slots are in."""
    var slot_info: List[StackResponseSlotInfo]
    """The changed slots."""

    def __init__(out self):
        """Creates an empty container info."""
        self.container = FullContainerName()
        self.slot_info = List[StackResponseSlotInfo]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the container info.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.container.marshal(io)
        slice(io, self.slot_info)


struct StackResponseSlotInfo(Marshaler):
    """The item stack that should be in one slot."""

    var slot: UInt8
    """The slot that changed."""
    var hotbar_slot: UInt8
    """The same slot again, as far as is known."""
    var count: UInt8
    """The total count of the item stack."""
    var stack_network_id: Int32
    """The network ID of the new stack in the slot; sent only if positive."""
    var custom_name: String
    """The custom name of the item stack."""
    var filtered_custom_name: Optional[String]
    """The custom name with profanity filtered out, if any."""
    var durability_correction: Int32
    """The current durability of the stack; must fit an `int16`."""

    def __init__(out self):
        """Creates an empty slot info."""
        self.slot = 0
        self.hotbar_slot = 0
        self.count = 0
        self.stack_network_id = 0
        self.custom_name = String()
        self.filtered_custom_name = None
        self.durability_correction = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the slot info.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the durability correction does not fit an `int16`, or the
            input is malformed.
        """
        io.uint8(self.slot)
        io.uint8(self.hotbar_slot)
        io.uint8(self.count)
        var present = self.stack_network_id > 0
        io.bool(present)
        if present:
            io.varint32(self.stack_network_id)
        io.string(self.custom_name)
        optional_string(io, self.filtered_custom_name)
        io.varint32(self.durability_correction)
        if (
            self.durability_correction < -32768
            or self.durability_correction > 32767
        ):
            invalid_value(
                String(self.durability_correction),
                "durability correction",
                "must fit in an int16",
            )


@fieldwise_init
struct StackRequestSlotInfo(Copyable, Defaultable):
    """A slot as the client sees it, used by stack request actions."""

    var container: FullContainerName
    """The container the slot is in."""
    var slot: UInt8
    """The index of the slot in the container."""
    var stack_network_id: Int32
    """The stack network ID the client expects in the slot."""

    def __init__(out self):
        """Creates slot 0 of the default container."""
        self.container = FullContainerName()
        self.slot = 0
        self.stack_network_id = 0


def stack_req_slot_info[I: IO](mut io: I, mut x: StackRequestSlotInfo) raises:
    """Marshals a slot (gophertunnel `StackReqSlotInfo`).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    x.container.marshal(io)
    io.uint8(x.slot)
    io.int32(x.stack_network_id)


# ===----------------------------------------------------------------------=== #
# Stack request actions
# ===----------------------------------------------------------------------=== #


trait StackRequestActionKind(Marshaler):
    """A concrete stack request action: one implementation of Go's
    `StackRequestAction`."""

    comptime ID: UInt8
    """The action's type ID, one of the `STACK_REQUEST_ACTION_*` constants."""


def stack_request_action_variant(id: UInt8) -> UInt32:
    """Maps an action type ID to the variant index it is sent under.

    The variant list leaves out the two container actions that are never
    sent, so IDs above them are two higher than their variant.

    Args:
        id: One of the `STACK_REQUEST_ACTION_*` constants.

    Returns:
        The variant index.
    """
    if id > STACK_REQUEST_ACTION_TAKE_OUT_CONTAINER:
        return UInt32(id) - 2
    return UInt32(id)


def _transfer[
    I: IO
](
    mut io: I,
    mut count: UInt8,
    mut source: StackRequestSlotInfo,
    mut destination: StackRequestSlotInfo,
) raises:
    # gophertunnel transferStackRequestAction.Marshal.
    io.uint8(count)
    stack_req_slot_info(io, source)
    stack_req_slot_info(io, destination)


struct TakeStackRequestAction(StackRequestActionKind):
    """Takes items from a slot into the cursor."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_TAKE
    """The action's type ID."""
    var count: UInt8
    """The number of items moved."""
    var source: StackRequestSlotInfo
    """The slot the items were taken from."""
    var destination: StackRequestSlotInfo
    """The slot the items were moved to."""

    def __init__(out self):
        """Creates an empty action."""
        self.count = 0
        self.source = StackRequestSlotInfo()
        self.destination = StackRequestSlotInfo()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        _transfer(io, self.count, self.source, self.destination)


struct PlaceStackRequestAction(StackRequestActionKind):
    """Places items from one slot into another."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_PLACE
    """The action's type ID."""
    var count: UInt8
    """The number of items moved."""
    var source: StackRequestSlotInfo
    """The slot the items were taken from."""
    var destination: StackRequestSlotInfo
    """The slot the items were moved to."""

    def __init__(out self):
        """Creates an empty action."""
        self.count = 0
        self.source = StackRequestSlotInfo()
        self.destination = StackRequestSlotInfo()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        _transfer(io, self.count, self.source, self.destination)


struct SwapStackRequestAction(StackRequestActionKind):
    """Swaps the cursor item with the item in another slot."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_SWAP
    """The action's type ID."""
    var source: StackRequestSlotInfo
    """The first slot."""
    var destination: StackRequestSlotInfo
    """The second slot."""

    def __init__(out self):
        """Creates an empty action."""
        self.source = StackRequestSlotInfo()
        self.destination = StackRequestSlotInfo()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        stack_req_slot_info(io, self.source)
        stack_req_slot_info(io, self.destination)


struct DropStackRequestAction(StackRequestActionKind):
    """Drops items out of an open inventory."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_DROP
    """The action's type ID."""
    var count: UInt8
    """The number of items dropped."""
    var source: StackRequestSlotInfo
    """The slot the items were dropped from."""
    var randomly: Bool
    """Usually false; vanilla's name for the field."""

    def __init__(out self):
        """Creates an empty action."""
        self.count = 0
        self.source = StackRequestSlotInfo()
        self.randomly = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.count)
        stack_req_slot_info(io, self.source)
        io.bool(self.randomly)


struct DestroyStackRequestAction(StackRequestActionKind):
    """Destroys items by moving them into the creative inventory."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_DESTROY
    """The action's type ID."""
    var count: UInt8
    """The number of items destroyed."""
    var source: StackRequestSlotInfo
    """The slot the items came from."""

    def __init__(out self):
        """Creates an empty action."""
        self.count = 0
        self.source = StackRequestSlotInfo()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.count)
        stack_req_slot_info(io, self.source)


struct ConsumeStackRequestAction(StackRequestActionKind):
    """Consumes items used as crafting ingredients."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CONSUME
    """The action's type ID."""
    var count: UInt8
    """The number of items consumed."""
    var source: StackRequestSlotInfo
    """The slot the items came from."""

    def __init__(out self):
        """Creates an empty action."""
        self.count = 0
        self.source = StackRequestSlotInfo()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.count)
        stack_req_slot_info(io, self.source)


struct CreateStackRequestAction(StackRequestActionKind):
    """Moves an item left over from a recipe into a slot."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CREATE
    """The action's type ID."""
    var results_slot: UInt8
    """The slot the leftover item goes to."""

    def __init__(out self):
        """Creates an empty action."""
        self.results_slot = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.results_slot)


struct LabTableCombineStackRequestAction(StackRequestActionKind):
    """Combines item stacks in a lab table."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_LAB_TABLE_COMBINE
    """The action's type ID."""

    def __init__(out self):
        """Creates the action."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the action has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never; `Marshaler` requires the signature.
        """
        pass


struct BeaconPaymentStackRequestAction(StackRequestActionKind):
    """Pays a beacon to enable its effects."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_BEACON_PAYMENT
    """The action's type ID."""
    var primary_effect: Int32
    """The primary effect selected."""
    var secondary_effect: Int32
    """The secondary effect selected."""

    def __init__(out self):
        """Creates an empty action."""
        self.primary_effect = 0
        self.secondary_effect = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.primary_effect)
        io.varint32(self.secondary_effect)


struct MineBlockStackRequestAction(StackRequestActionKind):
    """Reports the held item's state after breaking a block."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_MINE_BLOCK
    """The action's type ID."""
    var hotbar_slot: Int32
    """The hotbar slot held while mining."""
    var predicted_durability: Int32
    """The durability the client expects the item to have."""
    var stack_network_id: Int32
    """The stack network ID the client expects."""

    def __init__(out self):
        """Creates an empty action."""
        self.hotbar_slot = 0
        self.predicted_durability = 0
        self.stack_network_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.hotbar_slot)
        io.varint32(self.predicted_durability)
        io.int32(self.stack_network_id)


struct CraftRecipeStackRequestAction(StackRequestActionKind):
    """Starts crafting (or enchanting) an item."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_RECIPE
    """The action's type ID."""
    var recipe_network_id: UInt32
    """The network ID of the recipe."""
    var number_of_crafts: UInt8
    """How many times the recipe was crafted; has no effect."""

    def __init__(out self):
        """Creates an empty action."""
        self.recipe_network_id = 0
        self.number_of_crafts = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.recipe_network_id)
        io.uint8(self.number_of_crafts)


struct AutoCraftRecipeStackRequestAction(StackRequestActionKind):
    """Crafts a recipe by shift-clicking it in the recipe book."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_RECIPE_AUTO
    """The action's type ID."""
    var recipe_network_id: UInt32
    """The network ID of the recipe."""
    var number_of_crafts: UInt8
    """How many times the recipe was crafted."""
    var ingredients: List[ItemDescriptorCount]
    """The ingredients used, in the stack request descriptor encoding."""

    def __init__(out self):
        """Creates an empty action."""
        self.recipe_network_id = 0
        self.number_of_crafts = 0
        self.ingredients = List[ItemDescriptorCount]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.recipe_network_id)
        io.uint8(self.number_of_crafts)
        # FuncIOSlice(r, &a.Ingredients, StackRequestItemDescriptorCount)
        var count = UInt32(len(self.ingredients))
        io.varuint32(count)
        if io.reads():
            io.slice_length(count, MAX_SLICE_LENGTH)
            self.ingredients = List[ItemDescriptorCount](
                length=Int(count), fill=ItemDescriptorCount()
            )
        for i in range(Int(count)):
            stack_request_item_descriptor_count(io, self.ingredients[i])


struct CraftCreativeStackRequestAction(StackRequestActionKind):
    """Takes an item out of the creative inventory."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_CREATIVE
    """The action's type ID."""
    var creative_item_network_id: UInt32
    """The network ID of the creative item."""
    var number_of_crafts: UInt8
    """How many times the item was taken; has no effect."""

    def __init__(out self):
        """Creates an empty action."""
        self.creative_item_network_id = 0
        self.number_of_crafts = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.creative_item_network_id)
        io.uint8(self.number_of_crafts)


struct CraftRecipeOptionalStackRequestAction(StackRequestActionKind):
    """Crafts with an anvil or cartography table, using a filter string."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_RECIPE_OPTIONAL
    """The action's type ID."""
    var recipe_network_id: UInt32
    """The network ID of the multi-recipe."""
    var filter_string_index: Int32
    """The index of a filter string in the enclosing request."""

    def __init__(out self):
        """Creates an empty action."""
        self.recipe_network_id = 0
        self.filter_string_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.recipe_network_id)
        io.int32(self.filter_string_index)


struct CraftGrindstoneRecipeStackRequestAction(StackRequestActionKind):
    """Crafts a grindstone recipe."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_GRINDSTONE
    """The action's type ID."""
    var recipe_network_id: UInt32
    """The network ID of the recipe (sent as an `int32`)."""
    var number_of_crafts: UInt8
    """How many times the recipe was crafted; has no effect."""
    var cost: Int32
    """The cost of the recipe."""

    def __init__(out self):
        """Creates an empty action."""
        self.recipe_network_id = 0
        self.number_of_crafts = 0
        self.cost = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var recipe_network_id = Int32(self.recipe_network_id)
        io.int32(recipe_network_id)
        self.recipe_network_id = UInt32(recipe_network_id)
        io.uint8(self.number_of_crafts)
        io.varint32(self.cost)


struct CraftLoomRecipeStackRequestAction(StackRequestActionKind):
    """Crafts a loom recipe."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_LOOM
    """The action's type ID."""
    var pattern: String
    """The identifier of the pattern applied."""
    var times_crafted: UInt8
    """How many times the recipe was crafted."""

    def __init__(out self):
        """Creates an empty action."""
        self.pattern = String()
        self.times_crafted = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.pattern)
        io.uint8(self.times_crafted)


struct CraftReservedStackRequestAction(StackRequestActionKind):
    """An action reserved for future use."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_RESERVED
    """The action's type ID."""
    var reserved_id: String
    """An identifier for the reserved action."""
    var number_of_crafts: UInt8
    """How many times the action was performed."""

    def __init__(out self):
        """Creates an empty action."""
        self.reserved_id = String()
        self.number_of_crafts = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.reserved_id)
        io.uint8(self.number_of_crafts)


struct CraftNonImplementedStackRequestAction(StackRequestActionKind):
    """Sent for inventory actions the new system does not implement yet."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_NON_IMPLEMENTED_DEPRECATED
    """The action's type ID."""

    def __init__(out self):
        """Creates the action."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the action has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never; `Marshaler` requires the signature.
        """
        pass


struct CraftResultsDeprecatedStackRequestAction(StackRequestActionKind):
    """The deprecated crafting results sent after a craft."""

    comptime ID: UInt8 = STACK_REQUEST_ACTION_CRAFT_RESULTS_DEPRECATED
    """The action's type ID."""
    var result_items: List[StackRequestItem]
    """The resulting items."""
    var times_crafted: UInt8
    """How many times the recipe was crafted."""

    def __init__(out self):
        """Creates an empty action."""
        self.result_items = List[StackRequestItem]()
        self.times_crafted = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.result_items)
        io.uint8(self.times_crafted)


struct StackRequestAction(Marshaler):
    """One of the concrete stack request actions (Go's `StackRequestAction`).

    `marshal` is gophertunnel `IO.StackRequestAction`: the varuint32 variant
    index, the type ID as a byte, then the action's fields.
    """

    comptime Kinds = Variant[
        TakeStackRequestAction,
        PlaceStackRequestAction,
        SwapStackRequestAction,
        DropStackRequestAction,
        DestroyStackRequestAction,
        ConsumeStackRequestAction,
        CreateStackRequestAction,
        LabTableCombineStackRequestAction,
        BeaconPaymentStackRequestAction,
        MineBlockStackRequestAction,
        CraftRecipeStackRequestAction,
        AutoCraftRecipeStackRequestAction,
        CraftCreativeStackRequestAction,
        CraftRecipeOptionalStackRequestAction,
        CraftGrindstoneRecipeStackRequestAction,
        CraftLoomRecipeStackRequestAction,
        CraftReservedStackRequestAction,
        CraftNonImplementedStackRequestAction,
        CraftResultsDeprecatedStackRequestAction,
    ]
    """The concrete action types."""
    var value: Self.Kinds
    """The held action."""

    def __init__(out self):
        """Creates an empty take action."""
        self.value = TakeStackRequestAction()

    @implicit
    def __init__[T: StackRequestActionKind](out self, var value: T):
        """Wraps a concrete action.

        Parameters:
            T: The action type.

        Args:
            value: The action.
        """
        self.value = Self.Kinds(value^)

    def type_id(self) -> UInt8:
        """Gets the type ID of the held action.

        Returns:
            One of the `STACK_REQUEST_ACTION_*` constants.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], StackRequestActionKind]
            if self.value.isa[T]():
                return T.ID
        return STACK_REQUEST_ACTION_TAKE

    @staticmethod
    def from_type(id: UInt8) -> Optional[StackRequestAction]:
        """Creates an empty action of a type (Go `lookupStackRequestAction`).

        Args:
            id: One of the `STACK_REQUEST_ACTION_*` constants.

        Returns:
            The action, or `None` for an unknown type ID.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], StackRequestActionKind]
            if id == T.ID:
                return StackRequestAction(T())
        return None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action with its type.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the action type is unknown or the input is malformed.
        """
        stack_request_action(io, self)


def stack_request_action[I: IO](mut io: I, mut x: StackRequestAction) raises:
    """Marshals an action with its type (gophertunnel `IO.StackRequestAction`).

    The type ID byte that follows the variant is ignored when reading.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the variant is unknown or the input is malformed.
    """
    var id = x.type_id()
    var variant = stack_request_action_variant(id)
    io.varuint32(variant)
    var legacy_id = id
    io.uint8(legacy_id)
    if io.reads():
        if variant > stack_request_action_variant(
            STACK_REQUEST_ACTION_CRAFT_RESULTS_DEPRECATED
        ):
            unknown_enum_option(Int(variant), "stack request action variant")
        id = UInt8(variant)
        if variant >= UInt32(STACK_REQUEST_ACTION_PLACE_IN_CONTAINER):
            id += 2
        var action = StackRequestAction.from_type(id)
        if not action:
            unknown_enum_option(Int(id), "stack request action type")
        x = action.value().copy()
    comptime for i in range(len(StackRequestAction.Kinds.Ts)):
        comptime T = downcast[
            StackRequestAction.Kinds.Ts[i], StackRequestActionKind
        ]
        if x.value.isa[T]():
            x.value[T].marshal(io)
            return
