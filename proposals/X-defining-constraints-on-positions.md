# Define Language Proposal 17: Defining Constraints on Positions

- **Author:** Max Kanat-Alexander
- **Status:** Draft
- **Date Proposed:** January 9, 2026
- **Date Finalized:**

## Problems

We have to have a way to define constraints. To narrow down the problem we are
solving, we will start off with saying we just need to be able to constrain the
qualities allowed in a position. (Meaning we would constrain which dimension
points are allowed to be there.)

The simplest sorts of problems here are super straightforward:

- Saying that a dimension point must have a quality.
- Saying that a dimension point must not have a quality.

However, this gets into complexities quite fast.

### 1: Open World vs Closed World

We have to decide whether the world is open (view points can do anything they
want by default) or closed (view points can do nothing, constraints have to
allow all actions explicitly).

You have to decide this for both universes: the universe of reflection and the
program's universe.

Closing the universe of reflection by default creates a paradox: you can't
define positions or constraints. So the universe of reflection is obviously open
by default.

Thus we only have to decide whether the real program's universe is open or
closed by default. This would apply to any action taken on dimension points,
such as creating, changing, or destroying them.

### 2: Compound Statements

We need to be able to make compound statements:

- "This ball must be green or red."
- "This ball must be green and heavy."

Basically, we just need the traditional boolean logic of most programming
languages.

### 3: Exclusivity

You have to be able to say "This ball must be red and must have no other
qualities."

### 4: Mixing Required and Allowed Values

We have to allow statements like "This ball must be green. It may also be red,
yellow or orange, but those are the only options."

That requires some form of "may" syntax one way or another.

That either requires closing the world by default (so that "those are the only
options" is the default) or creating a syntax to say "those are the only
options."

### 5: Mutually Exclusive States

You have to be able to make the statement, "This traffic light is red or green
or yellow, but only one of those at a time."

This is problematic with normal boolean `XOR` syntax, because `x XOR y XOR z` is
actually _true_ if x, y, and z are all true. (This happens for any odd-numbered
chain of XORs.) But if you try to define this with just `AND` and `OR`, the
syntax becomes really awful.

For example, to express "exactly one of red, green, or yellow" using only AND
and OR, you would need something like:

```
(
    light is red;
    AND NOT light is green;
    AND NOT light is yellow;
)
OR (
    light is green;
    AND NOT light is red;
    AND NOT light is yellow;
)
OR (
    light is yellow;
    AND NOT light is red;
    AND NOT light is green;
)
```

This is error-prone and becomes intractable as the number of mutually-exclusive
options increases.

### 6: Constraints that Involve More Than One Dimension Point

Constraints might want to refer to multiple names in the program. So you need
some syntax for defining them that isn't just "this applies to this dimension
point only."

## Solution

There are multiple parts to this. Note that this proposal only covers the syntax
for defining constraints. It doesn't discuss the implementation of when and how
they are enforced, which would be part of a later proposal.

### Definition Syntax

We define a new type of name: `constraint`.

Defining a constraint will use the syntax of the universe of reflection:
`define the constraint<foo>`. However, the `<foo>` part will be optional for
constraints. They do not need to be named unless they are referenced elsewhere.
So you can just write `define the constraint`.

```
define the constraint<foo> {

}
```

### The World is Open

The world is open by default---everything is allowed unless a constraint says
otherwise. This is because this is how most universes function---they allow you
to do everything until a specific restriction is intended.

### Constraint Statements

There are three statements we will presently be able to make about qualities:

- `the position<name> has the quality<name>`
- `the position<name> has any quality`
- `the position<name> has no other quality`

The first two have obvious meanings: we are checking if the dimension point has
a specific quality, or if the dimension point has any quality at all.

Why do we have the last one, the `no other quality` one? Because we need a way
to close the world. Basically, you need some mechanism to be able to say "this
dimension point has the quality red or blue, but nothing else." This is the "but
nothing else" statement. All the compiler has to know about this statement is
that it closes the world for quality comparisons within the context that it's
in.

This statement is phrased negatively because the positive statement "has any
other quality" is completely redundant in an open world.

### Basic Boolean Logic

We use standard boolean operators along with parentheses `()` to create compound
statements: `AND`, `OR` and `NOT`. These operators follow standard boolean
logic. They are case-sensitive. Unlike the rest of Define, they are capitalized,
to avoid syntax conflicts with other Define syntax in the future (because they
are just one word).

For single statements (non-parenthesized) `AND` and `OR` must be on the same
line as the statement that follows it. If they open a parenthesized statement,
they must be on their own line, with the opening parenthesis on the same line as
the operator, one space after it, with a newline after the parenthesis.

Parentheses must be used to resolve ambiguous binding orders of `AND` and `OR`.
The language does not specify a binding order, so if a binding is encountered
that would be ambiguous (such as `x AND y OR z`) the compiler throws an error
instructing the developer to add parentheses for clarity. This happens any time
there is both `AND` and `OR` in the same parenthetical scope.

Thus, the syntax for `AND` and `OR` looks like this:

```
(
    condition;
    AND condition;
)
OR (
    condition;
    AND condition;
)
```

```
condition;
OR condition;
OR (
    condition;
    AND condition;
)
```

Unnecessary parentheses are not allowed and must be collapsed. For example, this
is now allowed:

```
condition1;
AND (
    condition2;
    AND condition3;
)
```

`NOT` has the same rules as `AND` and `OR` for formatting, except that it may be
on the same line, prefixing `AND` or `OR` when that does not create ambiguity.
When `NOT` is prefixed to a single statement (as opposed to a parenthetical
statement), it modifies only that statement. For example:

```
NOT condition1;
AND condition2;
```

Means "the inverse of condition1 must be true, and condition2 must be true."
However, this:

```
NOT (
    condition1;
    AND condition2;
)
```

Means that both condition1 and condition2 must be false. And here's one more
formatting example:

```
condition1;
AND NOT (
    condition2;
    OR condition3;
)
```

This formatting is mandatory and enforced by the compiler.

### Exclusive OR

To solve the "3-term XOR" problem, we need a special syntax for XOR. Instead of
using normal XOR, we define this syntax:

```
ONE OF (
    condition1;
    condition2;
    condition3;
)
```

The conditions inside of `ONE OF` may not have `AND` or `OR` specified between
them. However, the conditions may themselves be parenthetical statements or
other ONE OF conditions.

`ONE OF` follows the same formatting and parenthetical rules as `NOT`.

### Duplicate and Overlapping Constraints

Note that theoretically, two constraints with identical contents are the same
constraint and can be optimized away or the compiler can warn/error about them.
I don't expect this to come up often in practice.

However, what I _do_ expect to happen often is that some constraints will
overlap---they will both check the same conditions on the same dimension points,
which should be optimized away.

## A Real Program

Let's see how this syntax solves various problems.

### Simplest Case

```
define the position<x>;
define the constraint {
    the position<x> has the quality<mv:example.com:example:/foo>;
}
```

### A Constraint That Must Not Be True

```
define the position<x>;
define the constraint {
    NOT the position<x> has the quality<mv:example.com:example:/foo>;
}
```

### Multiple Constraints That All Must Be True

```
define the position<x>;
define the constraint {
    the position<x> has the quality<mv:example.com:example:/foo>;
    AND the position<x> has the quality<mv:example.com:example:/bar>;
}
```

### Constraints Where Any One Must Be True

```
define the position<x>;
define the constraint {
    the position<x> has the quality<mv:example.com:example:/foo>;
    OR the position<x> has the quality<mv:example.com:example:/bar>;
}
```

### Complex Compound Statements

This one must have the quality `foo` OR one of `bar` or `baz`.

```
define the position<X>;
define the constraint {
    the position<x> has the quality<mv:example.com:example:/foo>;
    AND (
        the position<x> has the quality<mv:example.com:example:/bar>;
        OR the position<x> has the quality<mv:example.com:example:/baz>;
    )
}
```

You can of course nest these infinitely.

### Exclusivity

We want to say "this can have the quality foo and that's it."

```
define the position<x>;
define the constraint {
    the position<x> has the quality<mv:example.com:example:/foo>;
    AND the position<x> has no other quality;
}
```

### Mixing Required and Allowed Values

Here we want to say "this must be red. It can also be yellow or blue, but no
other colors."

```
define the position<x>;
define the constraint {
    the position<x> has the quality<mv:example.com:colors:/red>;
    AND (
            (
                the position<x> has the quality<mv:example.com:colors:/yellow>;
                OR the position<x> has the quality<mv:example.com:colors:/blue>;
            )
        AND the position<x> has no other quality;
    )
}
```

This is a little awkward, but possible.

## Why This is the Right Solution

I went back and forth on _so_ many options for the syntax for writing
constraints. What we have seems like the simplest option. I'll list the other
paths I went down, here and why I didn't go with them.

### Must/Must Not/May (Deontic Logic)

### Variant with `ALLOW` and `ALLOW ONLY`

### Block Syntax

Would make everything work like XOR.

### Set Theory

Set theory is not actually designed to prove constraints on specific objects. In
particular, set theory is designed to prove that statements are _not false_
across all possibilities in the universe, not that they are _true_ given a
specific situation.

For example, in set theory, if you make the statement, "Every real number that
is both even and odd is divisible by four," that statement is _true_, even
though it's impossible for a real number to be both even and odd. But in a
system of constraints, if I start a condition off with "check if this real
number is both even and odd," the constraint fails.

A dimension point either has a particular quality or it doesn't (at least, until
we implement [Define Approximately](../spec/concepts.md#distance)). Constraints
aren't looking at every possible universe---they are looking at the universe of
your program.

#### Set Membership

Okay, so we don't want formal set theory, but what about just checking if
qualities are members of sets? There's a theoretical syntax that looks something
like:

```
the qualities in position<x> are a subset of (Set)
the qualities in position<x> are a superset of (Set)
the qualities in position<X> intersect with (Set)
the qualities in position<x> are disjoint from (Set)
```

This is a little hard for the programmer to reason about if they don't think in
sets. Even I have to write out examples to figure out what I'm saying, with that
syntax. Here's essentially what each means:

- `are a subset of` means "every quality on this dimension point must be one of
  the qualities in this list." For example, imagine I want to ensure that a ball
  has the color `Red`, `Blue`, or both, but _no other colors_. I could say:
  `the qualities in position<ball> are a subset of {Red, Blue}`. A red ball
  would pass that constraint, as would a red and blue ball. A red and yellow
  ball would not.
- `are a superset of` means "the dimension point must have all of these
  qualities." I want to ensure that a ball is always _at least_ green and
  purple: `the qualities in position<ball> are a superset of {Green, Purple}`.
  In that case, a ball that is green, purple, and red passes. A ball that is
  just green fails.
- `intersect with` means "the dimension point must have at least one of these
  qualities."
- `are disjoint from` means "the dimension point must have none of these
  qualities."

If you take those and then include `AND`, and `OR`, you can express every
logical state. If I recall my experiments correctly, you don't even need `XOR`
or `NOT`. However, sometimes you have to really bend your mind to figure out how
to express your intention.

The complexity of reasoning isn't the only problem, though. The syntax also
forces you to restate things multiple times. For example, here's "This ball must
be green. It may also be red, yellow or orange, but those are the only options."

```
the qualities in position<ball> are a superset of (
    quality<mv:example.com:colors:/green>
);
AND
the qualities in position<ball> are a subset of (
    quality<mv:example.com:colors:/green>
    quality<mv:example.com:colors:/red>
    quality<mv:example.com:colors:/yellow>
    quality<mv:example.com:colors:/orange>
);
```

That's much briefer than the current syntax, which is nice. It looks a little
bit more like I'm expressing some sort of intention, which is also nice.
However, it makes you repeat the `green` quality. Not the worst problem, but it
is prone to human error by forgetting to specify that quality in both places. As
your constraints get more complex, this error becomes more likely and there's
more unnecessary repetition.

One of the main reasons I rejected this syntax is that it becomes very confusing
to use it for other types of future constraints. That is, if we want there to be
"one way to do things," ideally we don't want some of our constraints to be
based on set operations and others to be based on more traditional boolean
comparisons (equals, lesser than, greater than).

If you wanted to specify, for example, a constraint on some value and you wanted
to keep using set operations to do it, you'd have to be able to define infinite
sets as conditions. Instead of saying, `value < 10`, you would have to write
something like
`value is a subset of (the set of all natural numbers less than 10)`. This is
not a natural way for a programmer to think about a program. It likely requires
some very complex syntax and compiler activity to define those sets. It also
starts to fold constraints together---for example, the one I just described
indicates that the number is a natural number _and_ requires it to be less than
10, because there's no other way to express the infinite set.

There are languages today whose constraint systems look a _little bit_ like
this. (For example, Lean.) It's super cool and very powerful, but the problems
described above moved me away from it. I think developers will intuitively want
to express their constraints more as individual conditions, not as set
operations.

### Positive Syntax for Exclusions

### An "Except" Syntax on `has no quality`

### Traditional Programming Language Syntaxes

### Cardinal Syntax

### Defining Constraints During Position Definition

### Multi-Word Booleans

### Implicit `AND`

## Forward Compatibility

## Refactoring Existing Systems
