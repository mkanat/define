import textwrap

import pytest
from lark.exceptions import UnexpectedCharacters, UnexpectedToken

from compiler.parser import Parser


def _strip(text: str) -> str:
    return textwrap.dedent(text).lstrip("\n")


@pytest.mark.parametrize(
    "source",
    [
        _strip(
            """
            AbstractUniverse:
                Foo is a Bar.
            """
        ),
        _strip(
            """
            AbstractUniverse:
                Foo is.
            """
        ),
        _strip(
            """
            AbstractUniverse:
                Foo has a Bar named baz.
            """
        ),
        _strip(
            """
            AbstractUniverse:
                Creator creates a Thing named instance:
                    prop: "value"
                    count: 3
            """
        ),
        _strip(
            """
            PhysicalUniverse:
                A knows B's c.
            """
        ),
        _strip(
            """
            PhysicalUniverse:
                T can act.
            """
        ),
        _strip(
            """
            PhysicalUniverse:
                T can act using a Arg named first, a Arg named second:
                    T makes target action arg1, arg2.
            """
        ),
        _strip(
            """
            PhysicalUniverse:
                actor makes target action arg1,
                arg2.
            """
        ),
        _strip(
            """
            AbstractUniverse:
                # leading-space comment is allowed
                Foo is a Bar.
            """
        ),
    ],
)
def test_valid_sources(source):
    parser = Parser()
    parser.parse(source)


@pytest.mark.parametrize(
    ("source", "token_type", "token_value"),
    [
        # Double space between tokens
        (
            _strip(
                """
                AbstractUniverse:
                    Foo  is a Bar.
                """
            ),
            "SPACE",
            " ",
        ),
        # Space before period in `is.` form
        (
            _strip(
                """
                AbstractUniverse:
                    Foo is .
                """
            ),
            "DOT",
            ".",
        ),
        # Missing space after colon in property assignment
        (
            _strip(
                """
                AbstractUniverse:
                    Creator creates a Thing named instance:
                        prop:"value"
                """
            ),
            "STRING",
            '"value"',
        ),
        # Space before period
        (
            _strip(
                """
                AbstractUniverse:
                    Foo is a Bar .
                """
            ),
            "SPACE",
            " ",
        ),
        # Trailing inline comment (not at line start)
        (
            _strip(
                """
                AbstractUniverse:
                    Foo is a Bar. # trailing comment
                """
            ),
            "COMMENT",
            " # trailing comment",
        ),
        # Invalid keyword variants people might type
        (
            _strip(
                """
                AbstractUniverse:
                    Foo has an Bar named baz.
                """
            ),
            "IDENTIFIER",
            "n",
        ),
        (
            _strip(
                """
                AbstractUniverse:
                    Foo creates the Bar named baz:
                        prop: "value"
                """
            ),
            "IDENTIFIER",
            "the",
        ),
        # Missing required keyword 'named'
        (
            _strip(
                """
                AbstractUniverse:
                    Foo creates a Bar baz:
                        prop: "value"
                """
            ),
            "IDENTIFIER",
            "baz",
        ),
        # Bad universe header spacing
        (
            _strip(
                """
                AbstractUniverse :
                    Foo is a Bar.
                """
            ),
            "SPACE",
            " ",
        ),
        # Missing final newline
        (
            "AbstractUniverse:\n    Foo is a Bar.",
            "DEDENT",
            "",
        ),
        # Action declaration with extra spaces
        (
            _strip(
                """
                PhysicalUniverse:
                    T  can act.
                """
            ),
            "SPACE",
            " ",
        ),
        # Action execution missing space between target and action
        (
            _strip(
                """
                PhysicalUniverse:
                    actor makes targetaction arg1.
                """
            ),
            "DOT",
            ".",
        ),
    ],
)
def test_unexpected_token(source, token_type, token_value):
    parser = Parser()
    with pytest.raises(UnexpectedToken) as exc_info:
        parser.parse(source)

    exception = exc_info.value
    assert exception.token.type == token_type
    assert exception.token.value == token_value


@pytest.mark.parametrize(
    ("source", "char"),
    [
        # Tab indentation
        (
            "AbstractUniverse:\n\tFoo is a Bar.\n",
            "\t",
        ),
        # Carriage return usage
        (
            "AbstractUniverse:\r\n    Foo is a Bar.\r\n",
            "\r",
        ),
    ],
)
def test_unexpected_characters(source, char):
    parser = Parser()
    with pytest.raises(UnexpectedCharacters) as exc_info:
        parser.parse(source)

    exception = exc_info.value
    assert exception.char == char
