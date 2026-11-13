"""A small JSON tree for reading test-vector files (Wycheproof) in tests.

Nodes live in flat lists and refer to their children by index, since a
struct cannot contain a list of itself. Not for production input: it trusts
the file to be well-formed JSON and only decodes the escapes the vector
files use.
"""

comptime JSON_NULL = 0
comptime JSON_BOOL = 1
comptime JSON_NUMBER = 2
comptime JSON_STRING = 3
comptime JSON_ARRAY = 4
comptime JSON_OBJECT = 5


struct JsonTree(Movable):
    """A parsed JSON document; node 0 is the root."""

    var kinds: List[Int]
    var texts: List[String]
    var children: List[List[Int]]
    var keys: List[List[String]]

    def __init__(out self, text: StringSpan) raises:
        self.kinds = List[Int]()
        self.texts = List[String]()
        self.children = List[List[Int]]()
        self.keys = List[List[String]]()
        var src = text.as_bytes()
        var pos = 0
        _ = self._value(src, pos)

    def _new(mut self, kind: Int, var text: String) -> Int:
        self.kinds.append(kind)
        self.texts.append(text^)
        self.children.append(List[Int]())
        self.keys.append(List[String]())
        return len(self.kinds) - 1

    @staticmethod
    def _skip(src: Span[UInt8, _], mut pos: Int):
        while pos < len(src) and (
            src[pos] == 0x20
            or src[pos] == 0x0A
            or src[pos] == 0x0D
            or src[pos] == 0x09
        ):
            pos += 1

    @staticmethod
    def _string(src: Span[UInt8, _], mut pos: Int) raises -> String:
        if src[pos] != UInt8(ord('"')):
            raise Error("json: expected string")
        pos += 1
        var out = List[UInt8]()
        while src[pos] != UInt8(ord('"')):
            if src[pos] == UInt8(ord("\\")):
                pos += 1
                var c = src[pos]
                if c == UInt8(ord("n")):
                    out.append(0x0A)
                elif c == UInt8(ord("t")):
                    out.append(0x09)
                elif c == UInt8(ord("u")):
                    out.append(UInt8(ord("?")))  # comments only
                    pos += 4
                else:
                    out.append(c)
            else:
                out.append(src[pos])
            pos += 1
        pos += 1
        return String(from_utf8_lossy=Span(out))

    def _value(mut self, src: Span[UInt8, _], mut pos: Int) raises -> Int:
        Self._skip(src, pos)
        var c = src[pos]
        if c == UInt8(ord("{")):
            var node = self._new(JSON_OBJECT, String())
            pos += 1
            Self._skip(src, pos)
            if src[pos] == UInt8(ord("}")):
                pos += 1
                return node
            while True:
                Self._skip(src, pos)
                var key = Self._string(src, pos)
                Self._skip(src, pos)
                pos += 1  # ':'
                var child = self._value(src, pos)
                self.keys[node].append(key^)
                self.children[node].append(child)
                Self._skip(src, pos)
                if src[pos] == UInt8(ord(",")):
                    pos += 1
                    continue
                pos += 1  # '}'
                return node
        if c == UInt8(ord("[")):
            var node = self._new(JSON_ARRAY, String())
            pos += 1
            Self._skip(src, pos)
            if src[pos] == UInt8(ord("]")):
                pos += 1
                return node
            while True:
                var child = self._value(src, pos)
                self.children[node].append(child)
                Self._skip(src, pos)
                if src[pos] == UInt8(ord(",")):
                    pos += 1
                    continue
                pos += 1  # ']'
                return node
        if c == UInt8(ord('"')):
            return self._new(JSON_STRING, Self._string(src, pos))
        var start = pos
        while pos < len(src) and not (
            src[pos] == UInt8(ord(","))
            or src[pos] == UInt8(ord("}"))
            or src[pos] == UInt8(ord("]"))
            or src[pos] <= 0x20
        ):
            pos += 1
        var word = String(from_utf8=src[start:pos])
        if word == "null":
            return self._new(JSON_NULL, word^)
        if word == "true" or word == "false":
            return self._new(JSON_BOOL, word^)
        return self._new(JSON_NUMBER, word^)

    def get(self, node: Int, key: StringSpan) raises -> Int:
        for i in range(len(self.keys[node])):
            if self.keys[node][i] == key:
                return self.children[node][i]
        raise Error(t"json: no key {key}")

    def has(self, node: Int, key: StringSpan) -> Bool:
        for k in self.keys[node]:
            if k == key:
                return True
        return False

    def count(self, node: Int) -> Int:
        return len(self.children[node])

    def at(self, node: Int, index: Int) -> Int:
        return self.children[node][index]

    def text(self, node: Int) -> String:
        return self.texts[node]

    def int(self, node: Int) raises -> Int:
        return Int(self.texts[node])
