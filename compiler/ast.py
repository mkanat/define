"""Abstract Syntax Tree node definitions for the Define language."""

from dataclasses import dataclass, field
from functools import cached_property


class ASTError(Exception):
    """Base class for all AST errors."""


class StringLiteralError(ASTError):
    """Raised when a string literal is invalid."""


class NumberLiteralError(ASTError):
    """Raised when a number literal is invalid."""


@dataclass(kw_only=True)
class ASTNode:
    """Base class for all AST nodes."""

    line: int | None = None
    column: int | None = None


@dataclass
class Program(ASTNode):
    """Represents the entire program (collection of universe blocks)."""

    universes: list["UniverseBlock"]

    def __repr__(self) -> str:
        """Return string representation of Program."""
        return f"Program({len(self.universes)} universes)"


@dataclass
class UniverseBlock(ASTNode):
    """Represents a universe block (e.g., AbstractUniverse:, PhysicalUniverse:)."""

    name: str
    statements: list[ASTNode]

    def __repr__(self) -> str:
        """Return string representation of UniverseBlock."""
        return f"UniverseBlock({self.name}, {len(self.statements)} statements)"


@dataclass
class CompilerTypeDeclaration(ASTNode):
    """Represents a compiler type declaration (e.g., Number is.)."""

    type_name: str

    def __repr__(self) -> str:
        """Return string representation of CompilerTypeDeclaration."""
        return f"CompilerTypeDeclaration({self.type_name} is.)"


@dataclass
class TypeDeclaration(CompilerTypeDeclaration):
    """Represents a type declaration with a parent type (e.g., Source is a ViewPoint)."""

    parent_type: str

    def __repr__(self) -> str:
        """Return string representation of TypeDeclaration."""
        return f"TypeDeclaration({self.type_name} is a {self.parent_type})"


@dataclass
class PropertyDeclaration(ASTNode):
    """Represents a property declaration (e.g., String has a String named value)."""

    type_name: str
    property_type: str
    property_name: str

    def __repr__(self) -> str:
        """Return string representation of PropertyDeclaration."""
        return (
            f"PropertyDeclaration({self.type_name} has a {self.property_type} "
            f"named {self.property_name})"
        )


@dataclass
class ValueReference(ASTNode):
    """Base class for values that can be assigned to a property or passed to an action.

    This can be a string literal, number, or property/entity reference.
    """


@dataclass
class StringLiteral(ValueReference):
    """Represents a string literal value."""

    raw_value: str

    @cached_property
    def value(self) -> str:
        """Parse the raw string value by removing quotes and unescaping."""
        if not (self.raw_value.startswith('"') and self.raw_value.endswith('"')):
            raise StringLiteralError(f"Invalid string literal: '{self.raw_value}'")
        # TODO: Better string literal parsing
        return self.raw_value[1:-1].replace('\\"', '"').replace("\\\\", "\\")


@dataclass
class NumberLiteral(ValueReference):
    """Represents a numeric literal value (integer or floating-point)."""

    raw_value: str

    @cached_property
    def value(self) -> float | int:
        """Parse the raw number value to int or float."""
        try:
            if "." in self.raw_value:
                return float(self.raw_value)
            return int(self.raw_value)
        except ValueError as e:
            raise NumberLiteralError(
                f"Invalid number literal: '{self.raw_value}'"
            ) from e


@dataclass
class PropertyOrEntityReference(ValueReference):
    """Represents a reference to a property or entity (e.g., Owner's propertyName)."""

    owner: str
    property_name: str


@dataclass
class EntityCreation(ASTNode):
    """Represents an entity creation (e.g., Source creates a String named helloWorld:)."""

    creator: str
    type_name: str
    entity_name: str
    properties: list["PropertyAssignment"]

    def __repr__(self) -> str:
        """Return string representation of EntityCreation."""
        return (
            f"EntityCreation({self.creator} creates a {self.type_name} "
            f"named {self.entity_name})"
        )


@dataclass
class PropertyAssignment(ASTNode):
    """Represents a property assignment (e.g., value: "Hello, world!")."""

    name: str
    value: ValueReference

    def __repr__(self) -> str:
        """Return string representation of PropertyAssignment."""
        return f"PropertyAssignment({self.name}: {self.value})"


@dataclass
class KnowledgeStatement(ASTNode):
    """Represents a knowledge statement (e.g., Machine knows Source's helloWorld)."""

    knower: str
    owner: str
    entity_name: str

    def __repr__(self) -> str:
        """Return string representation of KnowledgeStatement."""
        return (
            f"KnowledgeStatement({self.knower} knows {self.owner}'s {self.entity_name})"
        )


@dataclass
class ActionParameter(ASTNode):
    """Represents an action parameter (e.g., a String named str)."""

    param_type: str
    param_name: str

    def __repr__(self) -> str:
        """Return string representation of ActionParameter."""
        return f"ActionParameter({self.param_type} named {self.param_name})"


@dataclass
class ActionDeclaration(ASTNode):
    """Represents an action declaration (e.g., Terminal can Output using a String named str:)."""

    type_name: str
    action_name: str
    parameters: list[ActionParameter]
    body: list["ActionExecution"] = field(default_factory=list)

    def __repr__(self) -> str:
        """Return string representation of ActionDeclaration."""
        return (
            f"ActionDeclaration({self.type_name} can {self.action_name} "
            f"using {len(self.parameters)} parameters)"
        )


@dataclass
class ActionExecution(ASTNode):
    """Represents an action execution (e.g., Machine makes terminal Output helloWorld.)."""

    actor: str
    target: ValueReference
    action_name: str
    arguments: list[ValueReference]

    def __repr__(self) -> str:
        """Return string representation of ActionExecution."""
        return (
            f"ActionExecution({self.actor} makes {self.target} {self.action_name} "
            f"with {len(self.arguments)} arguments)"
        )
