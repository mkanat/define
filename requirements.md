# Requirements for Define

These are invariants that the language must not break.

## Nullity

Accessing undefined variables is a constant source of error in many other programming languages.

It must be impossible for a program to access an undefined variable. The compiler must catch it.

This means there is no concept of "null" in define, there is only "a variable that has not been set," which the compiler will forbid any interaction with other than setting the variable.

## Separation of Universes

It must be impossible to do abstract-universe activities in the physical universe, and vice versa.

For example, the physical universe cannot do math---the abstract universe does math. The physical universe cannot instantiate objects that have only an abstract representation. The abstract universe cannot render any image, output any text, access any part of the network, etc.

Code in the physical universe part of a program must be about something concrete that exists in the physical universe.

Code in the abstract universe must be abstract and have nothing to do with the physical universe.

Of course, the two universes provide data to each other. The restriction here is about what code can execute in each universe.

## Knowledge Does Not Have Side Effects

Knowing a symbol must never cause code to execute. There are no "static initializers" in define. Simply loading a file of define code does not run the code (other than what the compiler and runtime need to do behind the scenes to make the symbols available or do any optimizations).

The only way action occurs is by a user triggering an action by requesting that it run, and then the programmer triggering other actions inside of that action.