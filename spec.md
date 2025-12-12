# Language Specification

## Introduction

This specification defines the syntax and semantics needed to compile define programs.

For broader context on the language's design philosophy, requirements, and principles, see [philosophy.md](philosophy.md), [requirements.md](requirements.md), and [principles.md](principles.md).

## General Rules

### Strictness

define is intended to be a very strict language. Any syntax or behavior not specified in this spec is an error.

### Reserved Words

All specific keywords and names listed in this spec are reserved only for the use they are given in this spec. For exmaple, if the spec says that something is named `Foo`, then that thing must always be named `Foo` and nothing else may use the name `Foo` in any program.

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
