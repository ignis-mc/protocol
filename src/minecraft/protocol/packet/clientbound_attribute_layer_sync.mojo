"""The `ClientBoundAttributeLayerSync` packet (gophertunnel `packet/clientbound_attribute_layer_sync.go`)."""

from ..attribute_layer import (
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_REMOVE_ENVIRONMENT,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_ENVIRONMENT,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_LAYERS,
    ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_SETTINGS,
    AttributeLayerData,
    AttributeLayerSettings,
    EnvironmentAttributeData,
)
from ..io import IO, slice, string_slice, unknown_enum_option
from .id import ID_CLIENT_BOUND_ATTRIBUTE_LAYER_SYNC
from .packet import Packet


struct ClientBoundAttributeLayerSync(Packet):
    """Sent by the server to synchronise attribute layers with the client."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_ATTRIBUTE_LAYER_SYNC
    """The packet ID."""
    var payload_type: UInt32
    """One of the `ATTRIBUTE_LAYER_PAYLOAD_TYPE_*` values."""
    var layers: List[AttributeLayerData]
    """The layers, for update layers."""
    var layer_name: String
    """The layer name, for every type but update layers."""
    var dimension_id: Int32
    """The dimension, for every type but update layers."""
    var settings: AttributeLayerSettings
    """The settings, for update settings."""
    var environment_attributes: List[EnvironmentAttributeData]
    """The attributes, for update environment."""
    var remove_attribute_names: List[String]
    """The attribute names, for remove environment."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.payload_type = 0
        self.layers = List[AttributeLayerData]()
        self.layer_name = String()
        self.dimension_id = 0
        self.settings = AttributeLayerSettings()
        self.environment_attributes = List[EnvironmentAttributeData]()
        self.remove_attribute_names = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.payload_type)
        if self.payload_type == ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_LAYERS:
            slice(io, self.layers)
        elif self.payload_type == ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_SETTINGS:
            io.string(self.layer_name)
            io.varint32(self.dimension_id)
            self.settings.marshal(io)
        elif (
            self.payload_type == ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_ENVIRONMENT
        ):
            io.string(self.layer_name)
            io.varint32(self.dimension_id)
            slice(io, self.environment_attributes)
        elif (
            self.payload_type == ATTRIBUTE_LAYER_PAYLOAD_TYPE_REMOVE_ENVIRONMENT
        ):
            io.string(self.layer_name)
            io.varint32(self.dimension_id)
            string_slice(io, self.remove_attribute_names)
        else:
            unknown_enum_option(
                Int(self.payload_type), "attribute layer payload type"
            )
