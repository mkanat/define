# Language Specification

## Introduction

This specification defines the syntax and semantics needed to compile define programs.

For broader context on the language's design philosophy, requirements, and principles, see [philosophy.md](philosophy.md), [requirements.md](requirements.md), and [principles.md](principles.md).

## General Rules

### Strictness

define is intended to be a very strict language. Any syntax or behavior not specified in this spec is an error.

### Reserved Words

All specific keywords and names listed in this spec are reserved only for the use they are given in this spec. For exmaple, if the spec says that something is named `Foo`, then that thing must always be named `Foo` and nothing else may use the name `Foo` in any program.

## Declaration

All named things (types, entities, properties, etc.) must be declared in a program before they can be referenced in any other statement.

## Scopes

Within a universe, identifiers must be unique. `TODO: scopes`

## Parsing

### Character Set

Define source files are written in UTF-8 with no BOM.

All text that affects the execution of the program must be written in ASCII. Only literal strings and comments may contain non-ASCII characters. This simplifies parsing the language and avoids various security issues where special Unicode characters confuse the programmer into believing they are doing something safe when they are not.

### Identifiers

All names of anything and all reserved words in define may only consist of ASCII letters, numbers, and the underscore character.

### Comments

A comment is a line of text starting with any number of spaces and then the character `#`. Comments must not have any effect on the behavior of a program. Do not use comments to implement any sort of metaprogramming language on top of define--define is already a metaprogramming language and should be flexible enough to support anything you need.

### Newlines

Define files only contain `\n` as their newline marker. Define files do not accept `\r` anywhere in their text other than in literal strings and comments.

The last character of a define file must be a newline.

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

There are a very few types where the syntax looks like: `TypeName is.` with no ExistingTypeName. These are compiler-defined types. They are reserved for use only in the implementation of define itself and may not be used by programs other than those that implement define itself.
