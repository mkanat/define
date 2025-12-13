import textwrap

import lark
import pytest
from lark.exceptions import UnexpectedCharacters, UnexpectedToken

from compiler.parser import Parser


def _strip(text: str) -> str:
    return textwrap.dedent(text).lstrip("\n")


def _get_identifiers_from_tree(tree: lark.Tree) -> list[str]:
    """Extract all IDENTIFIER token values from a tree."""
    identifiers = []
    for child in tree.children:
        if isinstance(child, lark.Tree):
            identifiers.extend(_get_identifiers_from_tree(child))
        elif child.type == "IDENTIFIER":
            identifiers.append(child.value)
    return identifiers


def _get_tokens_by_type_from_tree(tree: lark.Tree, token_type: str) -> list[lark.Token]:
    """Extract all tokens of a specific type from a tree."""
    tokens = []
    for child in tree.children:
        if isinstance(child, lark.Tree):
            tokens.extend(_get_tokens_by_type_from_tree(child, token_type))
        elif child.type == token_type:
            tokens.append(child)
    return tokens


def _parse(source: str) -> lark.Tree:
    """Parse source and verify root structure."""
    parser = Parser()
    tree = parser.parse(source)
    assert isinstance(tree, lark.Tree)
    assert tree.data == "start"
    return tree


def _get_first_universe(tree: lark.Tree, expected_name: str) -> lark.Tree:
    """Get the first universe section and verify its name."""
    universe_sections = list(tree.find_data("universe_section"))
    assert len(universe_sections) == 1
    universe = universe_sections[0]

    universe_name_tokens = _get_tokens_by_type_from_tree(
        universe, "UNIVERSE_NAME")
    assert [t.value for t in universe_name_tokens] == [expected_name]

    return universe


def test_type_declaration_with_parent():
    """Test type declaration with parent type: 'Foo is a Bar.'."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify type declaration
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


def test_type_declaration_compiler_type():
    """Test type declaration without parent: 'Foo is.'."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify type declaration
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo"]


def test_property_declaration():
    """Test property declaration: 'Foo has a Bar named baz.'."""
    source = _strip(
        """
        AbstractUniverse:
            Foo has a Bar named baz.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify property declaration
    prop_decls = list(universe.find_data("property_declaration"))
    assert len(prop_decls) == 1
    prop_decl = prop_decls[0]
    identifiers = _get_identifiers_from_tree(prop_decl)
    assert identifiers == ["Foo", "Bar", "baz"]


def test_entity_creation_with_properties():
    """Test entity creation with properties."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                prop: "value"
                count: 3
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify entity creation
    entity_creations = list(universe.find_data("entity_creation"))
    assert len(entity_creations) == 1
    entity_creation = entity_creations[0]
    identifiers = _get_identifiers_from_tree(entity_creation)
    assert identifiers == ["Creator", "Thing", "instance", "prop", "count"]

    # Verify property assignments
    property_assignments = list(
        entity_creation.find_data("property_assignment"))
    assert len(property_assignments) == 2

    # Verify property values
    string_tokens = _get_tokens_by_type_from_tree(entity_creation, "STRING")
    assert [t.value for t in string_tokens] == ['"value"']

    number_tokens = _get_tokens_by_type_from_tree(entity_creation, "NUMBER")
    assert [t.value for t in number_tokens] == ["3"]


def test_knowledge_statement():
    """Test knowledge statement: 'Foo knows Bar's baz.'."""
    source = _strip(
        """
        PhysicalUniverse:
            Foo knows Bar's baz.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "PhysicalUniverse")

    # Verify knowledge statement
    knowledge_stmts = list(universe.find_data("knowledge_statement"))
    assert len(knowledge_stmts) == 1
    knowledge_stmt = knowledge_stmts[0]
    identifiers = _get_identifiers_from_tree(knowledge_stmt)
    assert identifiers == ["Foo", "Bar", "baz"]

    # Verify property_reference exists
    property_refs = list(knowledge_stmt.find_data("property_reference"))
    assert len(property_refs) == 1


def test_action_declaration_with_parameters_and_body():
    """Test action declaration with parameters and body."""
    source = _strip(
        """
        PhysicalUniverse:
            T can Act using a Arg named first, a Arg named second:
                T makes target Do arg1, arg2.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "PhysicalUniverse")

    # Verify action declaration
    action_decls = list(universe.find_data("action_declaration"))
    assert len(action_decls) == 1
    action_decl = action_decls[0]
    identifiers = _get_identifiers_from_tree(action_decl)
    assert identifiers == [
        "T",
        "Act",
        "Arg",
        "first",
        "Arg",
        "second",
        "T",
        "target",
        "Do",
        "arg1",
        "arg2",
    ]

    # Verify parameters exist
    action_params = list(action_decl.find_data("action_parameters"))
    assert len(action_params) == 1
    param_nodes = list(action_decl.find_data("action_param"))
    assert len(param_nodes) == 2

    # Verify body exists
    action_bodies = list(action_decl.find_data("action_body"))
    assert len(action_bodies) == 1

    # Verify action execution in body
    action_execs = list(action_decl.find_data("action_execution"))
    assert len(action_execs) == 1


def test_action_execution():
    """Test action execution: 'Actor makes target Do arg1, arg2.'."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes target Do arg1,
            arg2.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "PhysicalUniverse")

    # Verify action execution
    action_execs = list(universe.find_data("action_execution"))
    assert len(action_execs) == 1
    action_exec = action_execs[0]
    identifiers = _get_identifiers_from_tree(action_exec)
    assert identifiers == ["Actor", "target", "Do", "arg1", "arg2"]

    # Verify argument_list exists
    argument_lists = list(action_exec.find_data("argument_list"))
    assert len(argument_lists) == 1


def test_comment_allowed():
    """Test that leading-space comments are allowed."""
    source = _strip(
        """
        AbstractUniverse:
            # leading-space comment is allowed
            Foo is a Bar.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify comment is present in tree
    comment_tokens = _get_tokens_by_type_from_tree(tree, "COMMENT")
    assert len(comment_tokens) >= 1

    # Verify type declaration still parses correctly
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


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
        # Action declaration without body (invalid syntax)
        (
            _strip(
                """
                PhysicalUniverse:
                    T can Act.
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
