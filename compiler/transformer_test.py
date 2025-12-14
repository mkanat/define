import textwrap

import pytest

from compiler import ast
from compiler.parser import Parser
from compiler.transformer import DefineTransformer


def _strip(text: str) -> str:
    return textwrap.dedent(text).lstrip("\n")


def _parse_and_transform(source: str) -> ast.Program:
    """Parse source and transform to AST."""
    parser = Parser()
    tree = parser.parse(source)
    transformer = DefineTransformer()
    return transformer.transform(tree)


# Basic Transformations


def test_start_transforms_to_program():
    """Test that start rule transforms to Program."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    assert isinstance(program, ast.Program)
    assert len(program.universes) == 1


def test_universe_section_transforms_to_universe_block():
    """Test that universe sections transform to UniverseBlock."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    assert len(program.universes) == 1
    universe = program.universes[0]
    assert universe.name == "AbstractUniverse"
    assert len(universe.statements) == 1


def test_compiler_type_declaration():
    """Test compiler type declaration transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Number is.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    assert len(universe.statements) == 1
    decl = universe.statements[0]
    assert isinstance(decl, ast.CompilerTypeDeclaration)
    assert decl.type_name == "Number"


def test_type_declaration():
    """Test type declaration with parent type transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.TypeDeclaration)
    assert len(statements) == 1
    decl = statements[0]
    assert decl.type_name == "Foo"
    assert decl.parent_type == "Bar"


def test_property_declaration():
    """Test property declaration transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Foo has a Bar named baz.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.PropertyDeclaration)
    assert len(statements) == 1
    decl = statements[0]
    assert decl.type_name == "Foo"
    assert decl.property_type == "Bar"
    assert decl.property_name == "baz"


# Entity Creation


def test_entity_creation_with_properties():
    """Test entity creation with multiple property assignments of different value types."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                string_prop: "Hello, world!"
                number_prop: 42
                reference_prop: Owner's property
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    assert len(statements) == 1
    entity = statements[0]
    assert entity.creator == "Creator"
    assert entity.type_name == "Thing"
    assert entity.entity_name == "instance"
    assert len(entity.properties) == 3

    # Verify string literal property
    string_prop = entity.properties[0]
    assert string_prop.name == "string_prop"
    assert isinstance(string_prop.value, ast.StringLiteral)
    assert string_prop.value.raw_value == '"Hello, world!"'

    # Verify number literal property
    number_prop = entity.properties[1]
    assert number_prop.name == "number_prop"
    assert isinstance(number_prop.value, ast.NumberLiteral)
    assert number_prop.value.raw_value == "42"

    # Verify property/entity reference property
    reference_prop = entity.properties[2]
    assert reference_prop.name == "reference_prop"
    assert isinstance(reference_prop.value, ast.PropertyOrEntityReference)
    assert reference_prop.value.owner == "Owner"
    assert reference_prop.value.property_name == "property"


def test_entity_creation_without_properties():
    """Test entity creation without any property assignments."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    assert len(statements) == 1
    entity = statements[0]
    assert entity.creator == "Creator"
    assert entity.type_name == "Thing"
    assert entity.entity_name == "instance"
    assert len(entity.properties) == 0


# Value References


def test_property_or_entity_reference():
    """Test property/entity reference transformation."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor knows Owner's property.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.KnowledgeStatement)
    assert len(statements) == 1
    stmt = statements[0]
    assert isinstance(stmt, ast.KnowledgeStatement)
    assert stmt.owner == "Owner"
    assert stmt.entity_name == "property"


def test_string_literal_token():
    """Test STRING token transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                value: "test string"
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    entity = statements[0]
    assert isinstance(entity, ast.EntityCreation)
    prop = entity.properties[0]
    assert isinstance(prop.value, ast.StringLiteral)
    assert prop.value.raw_value == '"test string"'


def test_number_literal_token():
    """Test NUMBER token transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                value: 123
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    entity = statements[0]
    assert isinstance(entity, ast.EntityCreation)
    prop = entity.properties[0]
    assert isinstance(prop.value, ast.NumberLiteral)
    assert prop.value.raw_value == "123"


def test_identifier_token():
    """Test IDENTIFIER token transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.TypeDeclaration)
    decl = statements[0]
    assert isinstance(decl, ast.TypeDeclaration)
    assert isinstance(decl.type_name, str)
    assert decl.type_name == "Foo"
    assert isinstance(decl.parent_type, str)
    assert decl.parent_type == "Bar"


# Knowledge Statements


def test_knowledge_statement():
    """Test knowledge statement transformation."""
    source = _strip(
        """
        PhysicalUniverse:
            Foo knows Bar's baz.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.KnowledgeStatement)
    assert len(statements) == 1
    stmt = statements[0]
    assert isinstance(stmt, ast.KnowledgeStatement)
    assert isinstance(stmt, ast.KnowledgeStatement)
    assert stmt.knower == "Foo"
    assert stmt.owner == "Bar"
    assert stmt.entity_name == "baz"


# Action Declarations


def test_action_declaration_without_parameters():
    """Test action declaration without parameters."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor can Act:
                Actor makes Owner's target Do Owner's arg.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionDeclaration)
    assert len(statements) == 1
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert isinstance(action, ast.ActionDeclaration)
    assert action.type_name == "Actor"
    assert action.action_name == "Act"
    assert len(action.parameters) == 0
    assert len(action.body) == 1


def test_action_declaration_with_parameters():
    """Test action declaration with multiple parameters."""
    source = _strip(
        """
        PhysicalUniverse:
            T can Act using a Arg named first, a Arg named second:
                T makes Owner's target Do Owner's arg1, Owner's arg2.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionDeclaration)
    assert len(statements) == 1
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert isinstance(action, ast.ActionDeclaration)
    assert action.type_name == "T"
    assert action.action_name == "Act"
    assert len(action.parameters) == 2
    assert action.parameters[0].param_type == "Arg"
    assert action.parameters[0].param_name == "first"
    assert action.parameters[1].param_type == "Arg"
    assert action.parameters[1].param_name == "second"
    assert len(action.body) == 1


def test_action_parameters():
    """Test action parameters transformation."""
    source = _strip(
        """
        PhysicalUniverse:
            T can Act using a Arg named first, a Arg named second:
                T makes Owner's target Do Owner's arg.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionDeclaration)
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert len(action.parameters) == 2
    assert all(isinstance(p, ast.ActionParameter) for p in action.parameters)


def test_action_param():
    """Test individual action parameter transformation."""
    source = _strip(
        """
        PhysicalUniverse:
            T can Act using a String named str:
                T makes Owner's target Do Owner's arg.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionDeclaration)
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert len(action.parameters) == 1
    param = action.parameters[0]
    assert isinstance(param, ast.ActionParameter)
    assert param.param_type == "String"
    assert param.param_name == "str"


def test_action_body():
    """Test action body with multiple executions."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor can Act:
                Actor makes Owner's target Do Owner's arg1, Owner's arg2.
                Actor makes Owner's target Do Owner's arg3, Owner's arg4.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionDeclaration)
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert len(action.body) == 2
    assert all(isinstance(e, ast.ActionExecution) for e in action.body)


# Action Executions


def test_action_execution_simple():
    """Test basic action execution."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes Owner's target Do Owner's arg.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionExecution)
    assert len(statements) == 1
    exec_stmt = statements[0]
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert exec_stmt.actor == "Actor"
    assert isinstance(exec_stmt.target, ast.PropertyOrEntityReference)
    assert exec_stmt.target.owner == "Owner"
    assert exec_stmt.target.property_name == "target"
    assert exec_stmt.action_name == "Do"
    assert len(exec_stmt.arguments) == 1
    arg = exec_stmt.arguments[0]
    assert isinstance(arg, ast.PropertyOrEntityReference)
    assert arg.owner == "Owner"
    assert arg.property_name == "arg"


def test_action_execution_with_arguments():
    """Test action execution with multiple arguments."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes Owner's target Do Owner's arg1, Owner's arg2.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionExecution)
    assert len(statements) == 1
    exec_stmt = statements[0]
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert len(exec_stmt.arguments) == 2
    assert all(
        isinstance(arg, ast.PropertyOrEntityReference) for arg in exec_stmt.arguments
    )
    arg1 = exec_stmt.arguments[0]
    assert isinstance(arg1, ast.PropertyOrEntityReference)
    assert arg1.owner == "Owner"
    assert arg1.property_name == "arg1"
    arg2 = exec_stmt.arguments[1]
    assert isinstance(arg2, ast.PropertyOrEntityReference)
    assert arg2.owner == "Owner"
    assert arg2.property_name == "arg2"


def test_action_execution_with_no_arguments():
    """Test action execution with single argument (grammar requires at least one)."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes Owner's target Do Owner's arg.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionExecution)
    assert len(statements) == 1
    exec_stmt = statements[0]
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert len(exec_stmt.arguments) == 1


def test_argument_list():
    """Test argument list transformation."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor makes Owner's target Do Owner's arg1, Owner's arg2.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.ActionExecution)
    exec_stmt = statements[0]
    assert isinstance(exec_stmt, ast.ActionExecution)
    assert len(exec_stmt.arguments) == 2
    assert all(isinstance(arg, ast.ValueReference) for arg in exec_stmt.arguments)


# Token Discarding


def test_space_discarded():
    """Verify SPACE tokens are discarded."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    # If SPACE tokens weren't discarded, the transformation would fail
    # or produce incorrect results. The fact that we get a valid AST
    # confirms they are discarded.
    assert isinstance(program, ast.Program)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.TypeDeclaration)
    assert len(statements) == 1
    # Verify the structure is correct (no SPACE tokens in AST)
    decl = statements[0]
    assert isinstance(decl, ast.TypeDeclaration)
    assert decl.type_name == "Foo"
    assert decl.parent_type == "Bar"


def test_possessive_discarded():
    """Verify POSSESSIVE tokens are discarded."""
    source = _strip(
        """
        PhysicalUniverse:
            Actor knows Owner's property.
        """
    )
    program = _parse_and_transform(source)
    # If POSSESSIVE tokens weren't discarded, transformation would fail
    assert isinstance(program, ast.Program)
    universe = program.get_physical_universe()
    statements = universe.get_statements_by_type(ast.KnowledgeStatement)
    assert len(statements) == 1
    stmt = statements[0]
    assert isinstance(stmt, ast.KnowledgeStatement)
    # Verify the reference is correctly parsed without POSSESSIVE token
    assert stmt.owner == "Owner"
    assert stmt.entity_name == "property"


def test_indent_dedent_discarded():
    """Verify INDENT/DEDENT tokens are discarded."""
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                value: "test"
        """
    )
    program = _parse_and_transform(source)
    # If INDENT/DEDENT tokens weren't discarded, transformation would fail
    assert isinstance(program, ast.Program)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    assert len(statements) == 1
    entity = statements[0]
    assert isinstance(entity, ast.EntityCreation)
    # Verify nested structure is correctly parsed
    assert len(entity.properties) == 1


def test_newlines_discarded():
    """Verify _NEWLINES tokens are discarded."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    # If _NEWLINES tokens weren't discarded, transformation would fail
    assert isinstance(program, ast.Program)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.TypeDeclaration)
    assert len(statements) == 1


# Integration Tests


def test_full_program_transformation():
    """Test complete program with multiple universes."""
    source = _strip(
        """
        AbstractUniverse:
            Source is a ViewPoint.
            Source creates a String named helloWorld:
                value: "Hello, world!"

        PhysicalUniverse:
            Machine is a Computer.
            Machine knows Source's helloWorld.
            Machine makes Machine's terminal Output Source's helloWorld.
        """
    )
    program = _parse_and_transform(source)
    assert isinstance(program, ast.Program)
    assert len(program.universes) == 2

    abstract = program.get_abstract_universe()
    assert len(abstract.statements) == 2
    assert isinstance(abstract.statements[0], ast.TypeDeclaration)
    assert isinstance(abstract.statements[1], ast.EntityCreation)

    physical = program.get_physical_universe()
    assert len(physical.statements) == 3
    assert isinstance(physical.statements[0], ast.TypeDeclaration)
    assert isinstance(physical.statements[1], ast.KnowledgeStatement)
    assert isinstance(physical.statements[2], ast.ActionExecution)


def test_multiple_statements_in_universe():
    """Test multiple statement types in one universe."""
    source = _strip(
        """
        AbstractUniverse:
            Number is.
            Source is a ViewPoint.
            Source has a String named value.
            Source creates a String named helloWorld:
                value: "Hello, world!"
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    assert len(universe.statements) == 4
    assert isinstance(universe.statements[0], ast.CompilerTypeDeclaration)
    assert isinstance(universe.statements[1], ast.TypeDeclaration)
    assert isinstance(universe.statements[2], ast.PropertyDeclaration)
    assert isinstance(universe.statements[3], ast.EntityCreation)


def test_nested_structures():
    """Test complex nested structures (actions with entity references)."""
    source = _strip(
        """
        AbstractUniverse:
            Source creates a String named helloWorld:
                value: "Hello, world!"

        PhysicalUniverse:
            Machine can Output using a String named message:
                Machine makes Machine's terminal Output Machine's message, Machine's message.
            Machine makes Machine's terminal Output Source's helloWorld, Source's helloWorld.
        """
    )
    program = _parse_and_transform(source)
    assert isinstance(program, ast.Program)

    physical = program.get_physical_universe()
    statements = physical.get_statements_by_type(ast.ActionDeclaration)
    assert len(statements) == 1
    action = statements[0]
    assert isinstance(action, ast.ActionDeclaration)
    assert len(action.body) == 1
    exec_stmt = action.body[0]
    # Verify the action execution uses the parameter reference
    assert isinstance(exec_stmt.arguments[0], ast.PropertyOrEntityReference)
    # The parameter should be referenced by name, not as Owner's property
    # (This depends on how the grammar handles parameter references)


# Edge Cases


def test_program_with_multiple_universes():
    """Test program with AbstractUniverse and PhysicalUniverse."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.

        PhysicalUniverse:
            Baz is a Qux.
        """
    )
    program = _parse_and_transform(source)
    assert len(program.universes) == 2
    abstract = program.get_abstract_universe()
    physical = program.get_physical_universe()
    assert abstract.name == "AbstractUniverse"
    assert physical.name == "PhysicalUniverse"


def test_action_execution_error_handling():
    """Test that invalid action execution raises ValueError."""
    # Create a mock parse tree with invalid structure
    # This is tricky because we need to create a tree that would
    # produce invalid items for action_execution
    # We'll test by directly calling the transformer method with invalid data
    transformer = DefineTransformer()

    # Test with None actor
    with pytest.raises(ValueError, match="Invalid action execution structure"):
        transformer.action_execution([None, "makes", None, None])

    # Test with None target
    with pytest.raises(ValueError, match="Invalid action execution structure"):
        transformer.action_execution(["Actor", "makes", None, None])

    # Test with None action_name
    target_ref = ast.PropertyOrEntityReference(owner="Owner", property_name="target")
    with pytest.raises(ValueError, match="Invalid action execution structure"):
        transformer.action_execution(["Actor", "makes", target_ref, None])


def test_universe_name_token():
    """Test UNIVERSE_NAME token transformation."""
    source = _strip(
        """
        AbstractUniverse:
            Foo is a Bar.
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    assert isinstance(universe.name, str)
    assert universe.name == "AbstractUniverse"


def test_entity_creation_properties_default():
    """Test that entity creation handles missing properties gracefully."""
    # Note: The grammar requires at least one property_assignment,
    # but we test the transformer's handling of the items list
    source = _strip(
        """
        AbstractUniverse:
            Creator creates a Thing named instance:
                prop: "value"
        """
    )
    program = _parse_and_transform(source)
    universe = program.get_abstract_universe()
    statements = universe.get_statements_by_type(ast.EntityCreation)
    entity = statements[0]
    assert isinstance(entity, ast.EntityCreation)
    # Verify properties list exists even with single property
    assert len(entity.properties) == 1
