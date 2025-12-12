from pathlib import Path
from textwrap import dedent

import pytest
from lark import Lark
from lark.exceptions import LarkError

from compiler.indenter import DefineIndenter


def build_parser():
    grammar_path = Path(__file__).with_name("grammar.lark")
    return Lark.open(
        str(grammar_path),
        parser="lalr",
        postlex=DefineIndenter(),
        start="start",
    )


def parse_ok(text: str):
    parser = build_parser()
    return parser.parse(text)


def parse_fail(text: str):
    parser = build_parser()
    with pytest.raises(LarkError):
        parser.parse(text)


def _strip(text: str) -> str:
    return dedent(text).lstrip("\n")


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
    parse_ok(source)


@pytest.mark.parametrize(
    "source",
    [
        # Double space between tokens
        _strip(
            """
            AbstractUniverse:
                Foo  is a Bar.
            """
        ),
        # Space before period in `is.` form
        _strip(
            """
            AbstractUniverse:
                Foo is .
            """
        ),
        # Missing space after colon in property assignment
        _strip(
            """
            AbstractUniverse:
                Creator creates a Thing named instance:
                    prop:"value"
            """
        ),
        # Space before period
        _strip(
            """
            AbstractUniverse:
                Foo is a Bar .
            """
        ),
        # Tab indentation
        "AbstractUniverse:\n\tFoo is a Bar.\n",
        # Carriage return usage
        "AbstractUniverse:\r\n    Foo is a Bar.\r\n",
        # Trailing inline comment (not at line start)
        _strip(
            """
            AbstractUniverse:
                Foo is a Bar. # trailing comment
            """
        ),
        # Invalid keyword variants people might type
        _strip(
            """
            AbstractUniverse:
                Foo has an Bar named baz.
            """
        ),
        _strip(
            """
            AbstractUniverse:
                Foo creates the Bar named baz:
                    prop: "value"
            """
        ),
        # Missing required keyword 'named'
        _strip(
            """
            AbstractUniverse:
                Foo creates a Bar baz:
                    prop: "value"
            """
        ),
        # Bad universe header spacing
        _strip(
            """
            AbstractUniverse :
                Foo is a Bar.
            """
        ),
        # Missing final newline
        "AbstractUniverse:\n    Foo is a Bar.",
        # Action declaration with extra spaces
        _strip(
            """
            PhysicalUniverse:
                T  can act.
            """
        ),
        # Action execution missing space between target and action
        _strip(
            """
            PhysicalUniverse:
                actor makes targetaction arg1.
            """
        ),
    ],
)
def test_invalid_sources(source):
    parse_fail(source)
