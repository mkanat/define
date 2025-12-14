# Language Specification

## Introduction

This specification defines the syntax and semantics needed to compile define programs.

For broader context on the language's design philosophy, requirements, and principles, see [philosophy.md](philosophy.md), [requirements.md](requirements.md), and [principles.md](principles.md).

## General Rules

### Strictness

define is intended to be a very strict language. Any syntax or behavior not specified in this spec is an error.

### Reserved Words

All specific keywords and names listed in this spec are reserved only for the use they are given in this spec. For exmaple, if the spec says that something is named `Foo`, then that thing must always be named `Foo` and nothing else may use the name `Foo` in any program.

Any term listed in a syntax specification but not defined is considered to be a reserved word. Some reserved "words" have spaces in them, such as `has a`, `is a`, `creates a`, etc.

## Declaration

All named things (types, entities, properties, etc.) must be declared in a program before they can be referenced in any other statement.

## Scopes

Within a universe, identifiers must be unique. `TODO: scopes`

## Parsing

### Character Set

Define source files are written in UTF-8 with no BOM.

All text that affects the execution of the program must be written in the following Unicode codepoints:

* Decimal 10 (Line Feed)
* Decimals 31 - 126 (traditional ASCII character set, minus control characters)

Only literal strings and comments may contain other UTF-8 characters.

This simplifies parsing the language and avoids various security issues where special Unicode characters confuse the programmer into believing they are doing something safe when they are not.

### Identifiers

All names of anything and all reserved words in define may only consist of ASCII letters, numbers, and the underscore character.

### Comments

A comment is a line of text starting with any number of spaces and then the character `#`. Comments must not have any effect on the behavior of a program. Do not use comments to implement any sort of metaprogramming language on top of define--define is already a metaprogramming language and should be flexible enough to support anything you need.

### Newlines

Define files only contain `\n` (ASCII LF) as their newline marker. Define files do not accept `\r` (ASCII CR) anywhere in their text other than in literal strings and comments. For comments, the final character sequence at the end of a line must be `\n` and never `\r\n`.

A space (Unicode decimal 32) may not appear before a newline except in literal strings.

The last character of a define file must be a newline.

### Trailing Spaces

Trailing spaces (Uniccode decinal 32) at the end of a line before the terminating newline are forbidden.

### Spaces Between Tokens

Except where explicitly stated otherwise, all syntax uses exactly one ASCII space (decimal 32) between tokens. Multiple spaces in a row are not allowed except where explicitly specified.

## Universes

A define program consists of one or more universe blocks. Each universe block defines a separate conceptual space with distinct capabilities and restrictions.

### Universe Types

There are two universe types:
- **AbstractUniverse**: The abstract universe where computation occurs and abstract concepts exist. For example, in the AbstractUniverse, a rectangle is a set of coordinates that you can do math with.
- **PhysicalUniverse**: The physical universe where things happen with the components of the computer, like the screen, keyboard, network, etc. For example, in the PhysicalUniverse, you don't have a "rectangle," you have actual lines drawn on a screen.

A reasonable test for whether or not something belongs in the PhysicalUniverse is: would it be possible for a human to perceive this? For example, the number `1` is an abstract concept, but the pixels representing that number exist in the physical universe. A human cannot _see_ the abstract concept of `1`, but _can_ see the pixels representing it on a screen.

### Syntax

A universe block begins with the universe name followed by a colon (`:`), and all statements within that universe are indented by exactly four spaces:

```
UniverseName:
    statement1
    statement2
    ...
```

The universe name must be exactly one of the two valid universe identifiers: `AbstractUniverse` or `PhysicalUniverse`. No other identifiers are permitted as universe names.

A file may contain at most one `AbstractUniverse` block and at most one `PhysicalUniverse` block. The compiler must reject any file that contains multiple blocks of the same universe type.

Universe blocks mat noy be nested inside of another universe block.

## Entities and Type Declarations: Overview

Entities are things that exist within a universe. For example, in the physical universe, the monitor you are reading this on is an entity. In an abstract universe, the number `1` is an entity, as is the string `Hello, world!`.

Every entity has a type that classifies what sort of entity it is. For example, your monitor might have the type `Screen`. The number `1` would have the type "Number," and the string "Hello, world!" would have the type "String."

## Types

The syntax for declaring a new type is:

`NewTypeName is a ExistingTypeName`

`NewTypeName` and `ExistingTypeName` are placeholders; they can be any valid identifier.

This statement declares that _`NewTypeName`_ is a subclass of the type _`ExistingTypeName`_.

For example, `Source is a ViewPoint.` means that `Source` is a subclass of `ViewPoint`.

This is called a "type declaration."

### Subclass

A subclass is a type that _is_ another type, but has some changes or additional functionality. Anywhere the spec says that something accepts a particular type, subclasses of that type are also accepted, unless specified otherwise.

### Basic Types

The most basic type is `Consideration`, representing any persistent idea in the abstract or physical universe.

Below that are the two common subclasses that make up most programs:

* `ViewPoint` represents a thing capable of creating other things and knowing about them.
* `DimensionPoint` represents something that a ViewPoint can create and know about.

The behavior of both of these types are described more later in the specification.

### Compiler Types

There are a very few types where the syntax looks like: `TypeName is.` with no ExistingTypeName. These are compiler-defined types. They are reserved for use only in the implementation of define itself. This syntax may not be used unless you are implementing define itself.

## Entities

The syntax for creating a new entity is:

```
Creator creates a TypeName named Name:
    propertyName: value
    propertyName2: value2
    ...
```

Where:
- `Creator` is a type that is a `ViewPoint` or a subclass of `ViewPoint`.
- `TypeName` is the type of entity being created.
- `Name` is the identifier for the created entity.
- After the colon (`:`), indented property assignments (by exactly four spaces) define the created entity's properties. See "Setting Properties" for information on the syntax and semantics of property assignments.

This is called an "entity declaration."

### Example

```
Source creates a String named helloWorld:
    content: "Hello, world!"
```

This statement creates a new `String` entity named `helloWorld` with a `content` property set to `"Hello, world!"`.

### ViewPoint Creation

`ViewPoint` entities are created by declaring them as a type. For example:

`Source is a ViewPoint`

That creates both a type called Source and a hidden entity that the compiler tracks. The language only allows referencing a ViewPoint as a type.

Only one instance of any given ViewPoint may exist in a program. In the above example, no other instances of Source may be created.

## Name Conflicts Between Types and Entities

Name conflicts are not allowed between types and entities. That is, there may not be two types with the same name, two entities with the same name, and an entity may not share a name with a type.

## Properties

Entities have properties that define their characteristics and state.

### Declaring Properties

Types declare what properties they have using this syntax:

`TypeName has a PropertyTypeName named Name.`

Where:
- `TypeName` is the name of the type that will have this property.
- `PropertyTypeName` is the type of property being defined.
- `Name` is the identifier for the defined property.

Within a type, property names must be unique.

### Setting Properties

Properties are assigned within the indented block that follows an entity creation statement.

Property assignment syntax:

```
    propertyName: value
```

Where:
- `propertyName` is an identifier indicating which property you want to set.
- The colon (`:`) separates the property name from its value.
- `value` is a value reference (see "Value References")

Properties must be indented by exactly four spaces relative to the creation statement that creates their parent entity.

Only properties defined on the type may be set.

## Value References

In define there are three types of values you can pass to a function or use to set a property: string literals, numeric literals, and entity/property references.

### String Literals

 A string literal begins with a double quote (`"`), contains zero or more UTF-8 characters, and ends with a double quote. Within a string literal, any character may appear except for a newline or an unescaped double quote. Double quotes may be escaped by prefixing them with the `\` character. A literal `\` may be included in a string by writing `\\`.

Example: `content: "Hello, world!"`

When the compiler needs to know the type of a string literal, it considers it to have the type `String`.

### Numeric Literals

Numeric literals represent numeric values. A numeric literal may be:
- An integer: a sequence of one or more decimal digits (`0` through `9`).
- A floating-point number: an integer part, optionally followed by a decimal point (`.`) and a fractional part consisting of one or more decimal digits.

It may optionally start with the character `-` to indicate the number is negative.

Examples: `width: 100`, `radius: 2.5`

When the compiler needs to know the type of a numeric literal, it considers it to have the type `Number`.

### Property and Entity References

Properties and entities are referenced in programs using only this syntax:

`Owner's propertyOrEntityName`

Where:
- `Owner` is an entity that has that property, or the ViewPoint that owns that entity.
- `'s` indicates we are referencing a propety belonging to Owner.
- `propertyOrEntityName` is the name of the property or entity.

## Knowledge

By default, ViewPoints can only access entities that they created.

Knowledge statements allow a ViewPoint to "know" about an entity that is owned by another ViewPoint and thus be able to access it.

The syntax for a knowledge statement is:

`Knower knows Owner's entityName.`

Where:
- `Knower` is a ViewPoint
- `Owner` is the ViewPoint that owns entityName
- `entityName` is the identifier of a an entity that Knower wishes to be able to access.

Knower and Owner must not be the same ViewPoint. entityName must be the name of an entity owned by Owner.

This knowledge statement does not create a new entity; it only creates a reference.

Once a ViewPoint knows about an entity, it may access any property or action that entity exposes. `TODO: access controls`

## Actions

Action statements make something happen in a universe.

### Defining Actions

Actions are defined on types so that entities of that type can later execute them.

Syntax:

```
TypeName can ActionName using a ParamType named paramName[, a AnotherType named otherParam, ...]:
    # action body
```

Where:
- `TypeName` is an existing type that will own the action.
- `ActionName` is the identifier for the action.
- `ParamType` and `AnotherType` are the types of the parameters required by the action.
- `paramName` and `otherParam` are the identifiers for those parameters.

The parameter list is started with the word `using`. Parameters in the list are separated by a comma followed by any number of spaces and up to one newline, followed by the letter `a`.

The parameter list ends immediately before the colon.

The colon is followed by an indented block (exactly four spaces) that contains the action body.

The action body may reference only the owning type's properties and the declared parameters.

This is called an "action declaration."

### Executing Actions

The syntax for executing an action is:

```
Actor makes Target Action Argument1, [Argument2, ... ArgumentN].
```

Where:
- `Actor` is a ViewPoint
- `Target` is an existing entity that can execute the specified action.
- `Action` is a reference to an action defined on Target.
- `Argument1` through `ArgumentN` are value references. Arguments are separated by a comma followed by any number of spaces and up to one newline.

No space or comma is allowed between the final argument and the period that ends the statement.
