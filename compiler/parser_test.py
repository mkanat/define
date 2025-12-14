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

    universe_name_tokens = _get_tokens_by_type_from_tree(universe, "UNIVERSE_NAME")
    assert [t.value for t in universe_name_tokens] == [expected_name]

    return universe


def _get_universe_by_name(tree: lark.Tree, expected_name: str) -> lark.Tree:
    """Get a universe section by name."""
    universe_sections = list(tree.find_data("universe_section"))
    for universe in universe_sections:
        universe_name_tokens = _get_tokens_by_type_from_tree(universe, "UNIVERSE_NAME")
        if universe_name_tokens and universe_name_tokens[0].value == expected_name:
            return universe
    raise AssertionError(f"Universe '{expected_name}' not found in tree")


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
    """Test compiler type declaration: 'Foo is.'."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify compiler type declaration
    compiler_type_decls = list(universe.find_data("compiler_type_declaration"))
    assert len(compiler_type_decls) == 1
    compiler_type_decl = compiler_type_decls[0]
    identifiers = _get_identifiers_from_tree(compiler_type_decl)
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
    property_assignments = list(entity_creation.find_data("property_assignment"))
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

    # Verify property_or_entity_reference exists
    property_refs = list(knowledge_stmt.find_data("property_or_entity_reference"))
    assert len(property_refs) == 1


def test_action_declaration_with_parameters_and_body():
    """Test action declaration with parameters and body."""
    source = _strip(
        """
        PhysicalUniverse:
            T can Act using a Arg named first, a Arg named second:
                T makes Owner's target Do Owner's arg1, Owner's arg2.
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
        "Owner",
        "target",
        "Do",
        "Owner",
        "arg1",
        "Owner",
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
    """Test action execution: 'Actor makes Owner's target Do Owner's arg1, Owner's arg2.'."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes Owner's target Do Owner's arg1,
            Owner's arg2.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "PhysicalUniverse")

    # Verify action execution
    action_execs = list(universe.find_data("action_execution"))
    assert len(action_execs) == 1
    action_exec = action_execs[0]
    identifiers = _get_identifiers_from_tree(action_exec)
    assert identifiers == [
        "Actor",
        "Owner",
        "target",
        "Do",
        "Owner",
        "arg1",
        "Owner",
        "arg2",
    ]

    # Verify argument_list exists
    argument_lists = list(action_exec.find_data("argument_list"))
    assert len(argument_lists) == 1
    argument_list = argument_lists[0]

    # Verify arguments are parsed correctly
    # value_reference is an inline rule, so we look for property_or_entity_reference directly
    argument_nodes = list(argument_list.find_data("property_or_entity_reference"))
    assert len(argument_nodes) == 2

    # Verify argument value references
    for arg_node in argument_nodes:
        arg_idents = _get_identifiers_from_tree(arg_node)
        # Property references have 2 identifiers: owner and property/entity name
        assert len(arg_idents) == 2


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

    # Verify type declaration still parses correctly (comments are ignored)
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


def test_comment_before_first_universe():
    """Test that comments are allowed before the first universe block."""
    source = _strip(
        """
        # This is a comment before the universe block
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify type declaration still parses correctly (comments are ignored)
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


def test_universe_in_comment():
    """Test that AbstractUniverse in a comment is treated as a comment, not parsed as code."""
    source = _strip(
        """
        AbstractUniverse:
            # This is a comment with AbstractUniverse in it
            Foo is a Bar.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify no UNIVERSE_NAME tokens appear from comments (only in the actual universe name)
    # With %ignore COMMENT, comments are filtered out before parsing
    universe_name_tokens = _get_tokens_by_type_from_tree(tree, "UNIVERSE_NAME")
    assert len(universe_name_tokens) == 1
    assert universe_name_tokens[0].value == "AbstractUniverse"

    # Verify type declaration still parses correctly
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


def test_universe_in_string_literal():
    """Test that AbstractUniverse in a string literal is treated as a string, not parsed as code."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                description: "This is a string with AbstractUniverse in it"
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify string is present in tree
    string_tokens = _get_tokens_by_type_from_tree(tree, "STRING")
    assert len(string_tokens) == 1
    # Verify the string contains "AbstractUniverse"
    assert "AbstractUniverse" in string_tokens[0].value

    # Verify no UNIVERSE_NAME tokens appear in strings (only in the actual universe name)
    universe_name_tokens = _get_tokens_by_type_from_tree(tree, "UNIVERSE_NAME")
    assert len(universe_name_tokens) == 1
    assert universe_name_tokens[0].value == "AbstractUniverse"

    # Verify entity creation still parses correctly
    entity_creations = list(universe.find_data("entity_creation"))
    assert len(entity_creations) == 1
    entity_creation = entity_creations[0]
    identifiers = _get_identifiers_from_tree(entity_creation)
    assert identifiers == ["Creator", "Thing", "instance", "description"]


def test_blank_line_between_statements():
    """Test that blank lines are allowed between statements within a universe."""
    # This test verifies that statements can be separated by blank lines
    # Blank lines should be filtered out by the lexer, so this should work
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.

            Baz is a Qux.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify both type declarations are present
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 2
    first_decl = type_decls[0]
    second_decl = type_decls[1]
    assert _get_identifiers_from_tree(first_decl) == ["Foo", "Bar"]
    assert _get_identifiers_from_tree(second_decl) == ["Baz", "Qux"]


def test_multiple_blank_lines():
    """Test that multiple consecutive blank lines are allowed."""
    # Multiple blank lines should all be filtered out
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.

            Baz is a Qux.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify both type declarations are present (blank lines are ignored)
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 2
    first_decl = type_decls[0]
    second_decl = type_decls[1]
    assert _get_identifiers_from_tree(first_decl) == ["Foo", "Bar"]
    assert _get_identifiers_from_tree(second_decl) == ["Baz", "Qux"]


def test_blank_line_before_first_universe():
    """Test that blank lines are allowed before the first universe block."""
    source = _strip(
        """

        AbstractUniverse:
            Foo is a Bar.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "AbstractUniverse")

    # Verify type declaration still parses correctly
    type_decls = list(universe.find_data("type_declaration"))
    assert len(type_decls) == 1
    type_decl = type_decls[0]
    identifiers = _get_identifiers_from_tree(type_decl)
    assert identifiers == ["Foo", "Bar"]


def test_blank_line_between_universes():
    """Test that blank lines are allowed between universe sections."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.

        PhysicalUniverse:
            Baz is a Qux.
        """
    )
    tree = _parse(source)
    abstract_universe = _get_universe_by_name(tree, "AbstractUniverse")
    physical_universe = _get_universe_by_name(tree, "PhysicalUniverse")

    # Verify both universes parse correctly
    abstract_decls = list(abstract_universe.find_data("type_declaration"))
    physical_decls = list(physical_universe.find_data("type_declaration"))
    assert len(abstract_decls) == 1
    assert len(physical_decls) == 1
    assert _get_identifiers_from_tree(abstract_decls[0]) == ["Foo", "Bar"]
    assert _get_identifiers_from_tree(physical_decls[0]) == ["Baz", "Qux"]


def test_blank_lines_in_action_body():
    """Test that blank lines are allowed in action bodies."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor can Act:
                Actor makes Owner's target Do Owner's arg1.

                Actor makes Owner's target Do Owner's arg2.
        """
    )
    tree = _parse(source)
    universe = _get_first_universe(tree, "PhysicalUniverse")

    # Verify action declaration is present
    action_decls = list(universe.find_data("action_declaration"))
    assert len(action_decls) == 1

    # Verify both action executions are present
    action_executions = list(action_decls[0].find_data("action_execution"))
    assert len(action_executions) == 2


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
            "IDENTIFIER",
            "is",
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
            "creates",
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
                        actor makes target'saction arg1.
                    """
            ),
            "IDENTIFIER",
            "action",
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
        # Action declaration with colon but no body
        (
            _strip(
                """
                PhysicalUniverse:
                    TypeName can ActionName:
                """
            ),
            "DEDENT",
            "",
        ),
        # Nested universe block (forbidden)
        (
            _strip(
                """
                AbstractUniverse:
                    PhysicalUniverse:
                        Foo is a Bar.
                """
            ),
            "COLON",
            ":",
        ),
    ],
)
def test_unexpected_token(source, token_type, token_value):
    parser = Parser()
    with pytest.raises(UnexpectedToken) as exc_info:
        parser.parse(source)

    exception = exc_info.value
    assert exception.token.type == token_type, str(exception)
    assert exception.token.value == token_value, str(exception)


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
    assert exception.char == char, str(exception)
