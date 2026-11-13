"""Experiment toggles (gophertunnel `protocol/experiments.go`)."""

from .io import IO, Marshaler


struct ExperimentData(Marshaler):
    """An experiment that is either enabled or disabled."""

    var name: String
    """The name of the experiment."""
    var enabled: Bool
    """Whether the experiment is enabled; vanilla always sends `True`."""

    def __init__(out self):
        """Creates a disabled experiment with no name."""
        self.name = String()
        self.enabled = False

    def __init__(out self, name: String, enabled: Bool):
        """Creates an experiment.

        Args:
            name: The name of the experiment.
            enabled: Whether it is enabled.
        """
        self.name = name
        self.enabled = enabled

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the experiment.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.bool(self.enabled)
