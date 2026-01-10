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

## Statements Do Not Start With Names

We do not create syntax in define that looks like:

`type<name> takes some action`

It's much harder to parse that successfully than if we start the statement with
keywords and put the name inside of the statement.

For example, it makes it much harder for developers to do dumb parsing of files.
For example, imagine you want to write a regular expression to successfully find
all dimension point creations. It's much harder for programmers to get it right
if the name starts the line. The regex `/^(\w+<\w+>) now has a dimension point/`
is much harder than `/^create a dimension point in (.+)\./`. Also, the first
regex is what developers would probably write and it would actually be wrong,
because names can be configured to have more characters allowed than `\w`.

It's also the only way we can both be consistent _and_ create intuitive
sentences. We want there to be one right way in Define, and so if names are
going to start lines, I would want them to _always_ start lines. However, in
most situations, starting lines with the name forces developers to write a bunch
of passive statements like `quality<foo> is defined as`, when really the
programmer is taking decisive action by providing statements of intent.

Finally (and this isn't the most important point, but it's still true) it
requires more lookahead from the parser.

### Constraints May Not Reference Themselves

No constraint at any time may ever reference _itself_. For example,
`constraint<foo>` may not contain statements about `constraint<foo>`.

Almost every failure in history of logical systems comes about from forms of
logic that allow things to refer to themselves. For example, Russell's Paradox
("consider the set of all sets that do not contain themselves") comes about
because in set theory, sets could refer to themselves. The Godel Incompleteness
Theorem comes about by allowing logical statements to refer to themselves. We
have ample evidence in history that this is a bad idea. Don't allow it.
