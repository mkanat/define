Define Language Proposal 2: Universes

- **Author:** Max Kanat-Alexander
- **Status:** Draft
- **Date Proposed:** December 29, 2025
- **Date Finalized:**

## Problem

In some programming languages, it is very hard to understand whether a name you
are referring to is something from the standard library, an external library,
your current program, or is something "built in" to the language.

For example, are these Python imports part of your program, the standard
library, or a third-party library?

```Python
import clock
import enum
import pathlib
import typing
```

You can't tell just by looking at them. And even worse, the answer is: it
depends. Depending on what version of Python you're running and how you have
configured your Python interpreter, these could be inside of your codebase, from
the standard library, or from a third-party source.

Some programming languages make you _think_ you can figure this out, when in
reality you can't. For example, in Java you might see:

```Java
import com.yourcompany.SomeClass;
import com.yourcompany.SomeOtherClass;
```

You might simply assume that those are both inside of your codebase, since they
both have the domain name of your company attached to them. But they could be in
your codebase, in another codebase inside of your company, or even in an
open-source library that your company released.

## Solution

Introduce the concept of a named universe. Allow prefixing names with a universe
name to disambiguate which thing you are talking about. For example, if our
program was named `my_program` we could refer to the quality `/core/clock` as
`quality<my_program:/core/clock>` and the same concept in a library as
`quality<some_library:/core/clock>`.

Universe names should be restricted to ASCII letters, digits, and `_`. In
particular, the `:` character must not be allowed in universe names. We also
reserve the character `/` for potential future use, and thus universe names may
not contain `/`.

It may become necessary to allow other characters in universe names in order to
represent programs in other languages, in which case Define may provide a
compiler configuration to solve that problem.

When compiling code from files on a filesystem, there must be a configuration
file that contains the name of the universe and which can be located
deterministically by the compiler to both verify that things are named correctly
and to know where the "root" of the current universe is on the disk. In
non-filesystem contexts (such as compiling a string of code) this requirement
may be waived.

The language must reserve a universe name for the standard library.

Whether universe names are _required_ (and when they are required) I am leaving
for another proposal.

## A Real Program

Since I am writing this before Define exists, here is a theoretical program
using the syntax:

```
define the quality<my_program:/math/adder> {
    define the trigger<add> {
        takes args {
            position<first_addend> is a quality<standard:/integer>
            position<second_addend> is a quality<standard:/integer>
        }
        return position<first_addend> + position<second_addend>
    }
}
```

## Why This is the Right Solution

We use `:` because it will almost never be in any name in Define, and will
rarely be in a file or directory name on any computer.

I considered other syntaxes for universes. Here they are and why we didn't go
with them.

### URIs

We could have named things like
`universe://package/path/to/thing#nternal_member`. The advantage would be that
there is lots of code around to parse URIs and they are a well-known standard.
The disadvantage, however, is that they don't allow a lot of room for potential
future expansion. You've got the scheme, the authority, the path, and the
fragment, and you can't really add new components to it.

Often when people want to add new components to a URI they just start adding
query string variables, and that would be pretty awkward in a programming
language syntax (not to mention a bit too unbounded for the type of strictness
and specificity that we prefer in Define).

### Node (NPM)

Modules are named like `@namespace/universe` and then you can refer to a limited
set of things inside of them like `@namespace/universe/Class` or
`@namespace/universe/subdirectory` in your code.

I don't just want to re-use the `/` character because it makes it harder for us
to add something like a "galaxy" or a sub-universe in the future after the
current universe identifier. I wanted to use a character that was almost never
going to be in a name.

### Domain Names (Java)

Java has long used reversed domain names to disambiguate programs. It doesn't
work very well. You can't tell if a package is open-source or internal. You
can't tell if a package is in your codebase or elsewhere. Plus not everybody
actually has a domain name, so then people start making up other words to start
their package names with, giving you basically an uncontrolled set of potential
name conflicts.

### A New Type of Name

Probably the most Define-like way to solve the problem would be to create a new
type of name, like `universe<my_program>`. This is probably the mechanism that
guarantees the greatest forward compatibility. However, that would mean
prefixing every single global reference and every single global definition with
that. This might be more acceptable as `u<my_program>` but then that defeats
intuitive readability.

Yes, that looks like just three more characters on every name if we go with
`u<>`, but the problem is that you then have to separate it somehow from the
name it's qualifying, and right now the syntax I expect for that is `::`. So
it's actually five more characters on every name. I might come back to this and
decide that it's the right syntax, but the syntax I _have_ provided could be
deterministically converted to this "type of name" syntax, so I can change my
mind later.

## Forward Compatibility

It should be relatively straightforward to add components after the universe or
before it, in a name. Since we have the separator `:/` we can detect where the
name starts and where the universe ends.

For example, we could convert `quality<my_program:/path/to/quality>` to
`u<my_program>::quality</path/to/quality>` deterministically in every case--even
in comments.

The one ambiguity is if you have two universes with the same name, but I will
leave that problem for another proposal.

## Refactoring Existing Systems

Although no Define programs exist, it would be relatively straightforward to
change a program from referencing names as `quality</path/to/the/thing>` to
`quality<my_program:/path/to/the/thing>` as long as you can determine the
universe name of the current project.
