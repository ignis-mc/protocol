"""Armour trim patterns and materials (gophertunnel `protocol/trim.go`)."""

from .io import IO, Marshaler


@fieldwise_init
struct TrimPattern(Marshaler):
    """A pattern that can be applied to armour together with a material."""

    var item_name: String
    """The smithing template item that represents the pattern."""
    var pattern_id: String
    """The pattern identifier, such as `wayfinder`."""

    def __init__(out self):
        """Creates an empty pattern."""
        self.item_name = String()
        self.pattern_id = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the pattern.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.item_name)
        io.string(self.pattern_id)


@fieldwise_init
struct TrimMaterial(Marshaler):
    """A material that can be used for an armour trim."""

    var material_id: String
    """The material identifier, such as `netherite`."""
    var colour: String
    """The text formatting colour code, such as `§j`."""
    var item_name: String
    """The material item, such as `minecraft:netherite_ingot`."""

    def __init__(out self):
        """Creates an empty material."""
        self.material_id = String()
        self.colour = String()
        self.item_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the material.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.material_id)
        io.string(self.colour)
        io.string(self.item_name)
