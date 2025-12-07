# Requirements for Define

These are invariants that the language must not break.

## Nullity

Accessing undefined variables is a constant source of error in many other programming languages.

It must be impossible for a program to access an undefined variable. The compiler must catch it.

This means there is no concept of "null" in define, there is only "a variable that has not been set," which the compiler will forbid any interaction with other than setting the variable.