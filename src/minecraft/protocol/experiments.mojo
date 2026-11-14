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
        """Creates an experiment."""
        self.name = name
        self.enabled = enabled

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the experiment."""
        io.string(self.name)
        io.bool(self.enabled)
