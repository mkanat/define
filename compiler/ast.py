"""Abstract Syntax Tree node definitions for the Define language."""

import enum
from dataclasses import dataclass, field


@enum.unique
class PropertyValueType(enum.Enum):
    """Enumeration of valid property value types."""

    STRING = "string"
    """A string literal value."""

    NUMBER = "number"
    """A numeric literal value (integer or floating-point)."""

    ENTITY = "entity"
    """A reference to an entity by name."""

    PROPERTY_REFERENCE = "property_reference"
    """A reference to a property of an entity (e.g., Owner's propertyName)."""


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
class Entity(ASTNode):
    """Represents a value that can be assigned to a property or passed to an action.

    This can be a string literal, number, or entity reference.
    """

    value_type: PropertyValueType
    value: str | float | int

    def __repr__(self) -> str:
        """Return string representation of Entity."""
        return f"Entity({self.value_type.value}: {self.value})"


@dataclass
class PropertyReference(ASTNode):
    """Represents a property reference (e.g., Owner's propertyName)."""

    owner: str
    property_name: str

    def __repr__(self) -> str:
        """Return string representation of PropertyReference."""
        return f"PropertyReference({self.owner}'s {self.property_name})"


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
    value: Entity

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
    target: Entity
    action_name: str
    arguments: list[Entity]

    def __repr__(self) -> str:
        """Return string representation of ActionExecution."""
        return (
            f"ActionExecution({self.actor} makes {self.target} {self.action_name} "
            f"with {len(self.arguments)} arguments)"
        )
