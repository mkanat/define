# Requirements for Define

These are invariants that the language must not break.

## Nullity

Accessing undefined variables is a constant source of error in many other
programming languages.

It must be impossible for a program to access an undefined variable. The
compiler must catch it.

This means there is no concept of "null" in define, there is only "a variable
that has not been set," which the compiler will forbid any interaction with
other than setting the variable.

## Knowledge Does Not Have Side Effects

Knowing a symbol must never cause code to execute. There are no "static
initializers" in define. Simply loading a file of define code does not run the
code (other than what the compiler and runtime need to do behind the scenes to
make the symbols available or do any optimizations).

The only way action occurs is by a user triggering an action by requesting that
it run, and then the programmer triggering other actions inside of that action.

## Ambiguity is Forbidden

The language must never "figure out" on the developer's behalf what they meant.
It must require the developer to always specify exactly what their intention is,
in the code.

Generally this means that all ambiguity is an error if no intention is
specified. Name conflicts are not allowed.

Define attempts to forbid even the _possibility_ of ambiguity. For example, its
system of global and local names are attempt to prevent any _possible_ naming
conflict where two logically separate things have the same name. Requiring that
universes have a single project root is also an attempt to prevent the
possibility of ambiguity.
