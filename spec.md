# Language Specification

## Introduction

This specification defines the syntax and semantics needed to compile define programs.

For broader context on the language's design philosophy, requirements, and principles, see [philosophy.md](philosophy.md), [requirements.md](requirements.md), and [principles.md](principles.md).

## Strictness

define is intended to be a very strict language. Any syntax or behavior not specified in this spec is an error.

## Universes

A define program consists of one or more universe blocks. Each universe block defines a separate conceptual space with distinct capabilities and restrictions.

### Universe Types

There are two universe types:
- **AbstractUniverse**: The abstract universe where computation occurs and abstract concepts exist. For example, in the AbstractUniverse, a rectangle is a set of coordinates that you can do math with.
- **PhysicalUniverse**: The physical universe where things happen with the components of the computer, like the screen, keyboard, network, etc. For example, in the PhysicalUniverse, you don't have a "rectangle," you have actual lines drawn on a screen.

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