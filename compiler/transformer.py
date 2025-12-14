"""Lark transformer to convert parse tree to AST nodes."""

from typing import Any

import lark
from lark.visitors import Discard, _DiscardType

from compiler import ast


class DefineTransformer(lark.Transformer):
    """Transforms Lark parse tree into AST nodes."""

    def start(self, items: list[Any]) -> ast.Program:
        """Transform the root start rule."""
        return ast.Program(items)

    def universe_section(self, items: list[Any]) -> ast.UniverseBlock:
        """Transform a universe section."""
        # Items: [UNIVERSE_NAME, statements...]
        return ast.UniverseBlock(name=items[0], statements=items[1:])

    def compiler_type_declaration(
        self, items: list[Any]
    ) -> ast.CompilerTypeDeclaration:
        """Transform a compiler type declaration (e.g., Number is.)."""
        # Items: [IDENTIFIER, "is."]
        return ast.CompilerTypeDeclaration(type_name=items[0])

    def type_declaration(self, items: list[Any]) -> ast.TypeDeclaration:
        """Transform a type declaration with parent type (e.g., Source is a ViewPoint.)."""
        # Items: [IDENTIFIER, IDENTIFIER]
        return ast.TypeDeclaration(type_name=items[0], parent_type=items[1])

    def property_declaration(self, items: list[Any]) -> ast.PropertyDeclaration:
        """Transform a property declaration."""
        # Items: [IDENTIFIER, IDENTIFIER, IDENTIFIER]
        return ast.PropertyDeclaration(
            type_name=items[0], property_type=items[1], property_name=items[2]
        )

    def entity_creation(self, items: list[Any]) -> ast.EntityCreation:
        """Transform an entity creation."""
        # Items: [IDENTIFIER, IDENTIFIER, IDENTIFIER, PropertyAssignment, ...]
        return ast.EntityCreation(
            creator=items[0],
            type_name=items[1],
            entity_name=items[2],
            properties=items[3:],
        )

    def property_assignment(self, items: list[Any]) -> ast.PropertyAssignment:
        """Transform a property assignment."""
        # Items: [IDENTIFIER, value_reference]
        return ast.PropertyAssignment(name=items[0], value=items[1])

    def property_or_entity_reference(
        self, items: list[Any]
    ) -> ast.PropertyOrEntityReference:
        """Transform a property/entity reference."""
        # Items: [IDENTIFIER, IDENTIFIER]
        return ast.PropertyOrEntityReference(owner=items[0], property_name=items[1])

    def knowledge_statement(self, items: list[Any]) -> ast.KnowledgeStatement:
        """Transform a knowledge statement."""
        # Items: [IDENTIFIER, property_or_entity_reference]
        pe_ref = items[1]
        return ast.KnowledgeStatement(
            knower=items[0], owner=pe_ref.owner, entity_name=pe_ref.property_name
        )

    def action_declaration(self, items: list[Any]) -> ast.ActionDeclaration:
        """Transform an action declaration."""
        # Items: [IDENTIFIER, IDENTIFIER, list[ActionParameter]?, list[ActionExecution]]
        parameters = []
        body: list[ast.ActionExecution] = []

        for item in items:
            if isinstance(item, list) and len(item) > 0:
                if isinstance(item[0], ast.ActionParameter):
                    parameters = item
                elif isinstance(item[0], ast.ActionExecution):
                    body = item

        return ast.ActionDeclaration(items[0], items[1], parameters, body)

    def action_parameters(self, items: list[Any]) -> list[ast.ActionParameter]:
        """Transform action parameters."""
        return items

    def action_param(self, items: list[Any]) -> ast.ActionParameter:
        """Transform an action parameter."""
        # Items: [IDENTIFIER, IDENTIFIER] (after "a", SPACE, "named", SPACE are discarded/not included)
        return ast.ActionParameter(param_type=items[0], param_name=items[1])

    def action_body(self, items: list[Any]) -> list[ast.ActionExecution]:
        """Transform an action body."""
        return items

    def action_execution(self, items: list[Any]) -> ast.ActionExecution:
        """Transform an action execution."""
        # Items: [IDENTIFIER, ValueReference, IDENTIFIER, list[ValueReference]] (after SPACE, "makes", SPACE, ".", _NEWLINE are discarded/not included)
        actor = items[0]
        target = (
            items[1]
            if len(items) > 1 and isinstance(items[1], ast.ValueReference)
            else None
        )
        action_name = items[2] if len(items) > 2 else None
        arguments = []

        # Collect arguments from items[3] if present (argument_list is transformed to list[ValueReference])
        if len(items) > 3:
            if isinstance(items[3], list):
                arguments = items[3]
            elif isinstance(items[3], ast.ValueReference):
                # Single argument
                arguments = [items[3]]

        if actor is None or target is None or action_name is None:
            raise ValueError("Invalid action execution structure")

        return ast.ActionExecution(actor, target, action_name, arguments)

    def argument_list(self, items: list[Any]) -> list[ast.ValueReference]:
        """Transform an argument list."""
        return items

    # Terminal tokens
    # Method names must match token names (uppercase) - noqa: N802

    def SPACE(  # noqa: N802
        self, _token: lark.Token
    ) -> _DiscardType:  # Returns Discard singleton
        """Discard SPACE tokens - parser validates spacing, transformer doesn't need them."""
        return Discard

    def POSSESSIVE(  # noqa: N802
        self, _token: lark.Token
    ) -> _DiscardType:  # Returns Discard singleton
        """Discard POSSESSIVE tokens - parser validates them, transformer doesn't need them."""
        return Discard

    def IDENTIFIER(self, token: lark.Token) -> str:  # noqa: N802
        """Transform an identifier token."""
        return token

    def STRING(self, token: lark.Token) -> ast.StringLiteral:  # noqa: N802
        """Transform a string token."""
        return ast.StringLiteral(token)

    def NUMBER(self, token: lark.Token) -> ast.NumberLiteral:  # noqa: N802
        """Transform a number token."""
        return ast.NumberLiteral(token)

    def UNIVERSE_NAME(self, token: lark.Token) -> str:  # noqa: N802
        """Transform a universe name token."""
        return token

    def INDENT(  # noqa: N802
        self, _token: lark.Token
    ) -> _DiscardType:  # Returns Discard singleton
        """Discard INDENT tokens - parser validates indentation, transformer doesn't need it."""
        return Discard

    def DEDENT(  # noqa: N802
        self, _token: lark.Token
    ) -> _DiscardType:  # Returns Discard singleton
        """Discard DEDENT tokens - parser validates indentation, transformer doesn't need it."""
        return Discard

    def _NEWLINES(  # noqa: N802
        self, _token: lark.Token
    ) -> _DiscardType:  # Returns Discard singleton
        """Discard the _NEWLINES token - parser validates newlines, transformer doesn't need them."""
        return Discard
