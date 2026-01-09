# Define Language Proposal 16: Statement Terminators

- **Author:** Max Kanat-Alexander
- **Status:** Draft
- **Date Proposed:** January 9, 2026
- **Date Finalized:**

## Problem

We need a way to clearly indicate where statements end in Define. Statements
that create new blocks (like `define` statements that open curly braces) have
their boundaries marked by the block delimiters, but statements that don't
create blocks need some terminator to indicate where they end.

## Solution

We will use the semicolon (`;`) followed by a newline as the statement
terminator for all statements that don't require new blocks. (This means we
don't allow trailing spaces at the end of lines, which is intentional.)

For example:

```
define the position<x>;
create a dimension point in position<x>;
assign the quality<mv:example.com:example:/foo> to the dimension point in position<x>;
```

## A Real Program

See above.

## Why This is the Right Solution

Semicolons allow for clear boundaries between statements and they allow for
lines to be broken up over more than one actual line in the file. Since Define
is so verbose, that could be a frequent problem.

Semicolons are visually distinct from other punctuation marks and we don't
expect them to have any other use.

### Alternatives Discarded

#### Period (`.`)

I initially considered using a period as the statement terminator, as it would
feel intuitive to read. However, Gemini convinced me that periods are visually
very similar to commas, which can lead to subtle bugs that are difficult to
catch.

This is not merely a theoretical concern. COBOL used periods to terminate
statements, and had a well-documented history of bugs caused by the fact that
they look so similar to commas. I'm sure it's very frustrating to look at code
and not be able to _see_ where the missing line terminator is.

#### Newline-Based Termination (Python/Go style)

I also considered using newlines to terminate statements, as Python and Go do. I
personally like and prefer this syntax. We may switch to it in the future.
However, it creates more complexities for the parser and does create a few
(mostly unimportant) limitations on what syntax you can have, like "curly braces
must be on the same line as the statement or we can't tell a block is starting."

One problems I've run into with the syntax over the years is that it makes it
either ugly (Python) or confusing (Go) to have multi-line statements, and you do
sometimes need multi-line statements.

Another major issue (at least with Python, less with Go) is that it makes
writing an auto-formatter that wraps code at a certain line length _way_ harder
to write. This is not a theoretical concern; I worked on an auto-formatter for
Python at Google and this was a constant source of pain, bugs, and ugly choices
we had to make in the formatter.

## Forward Compatibility

The use of semicolons as statement terminators is the least ambiguous option for
statement termination. If we ever needed to change this syntax in the future, we
could automatically transform all semicolons to any new terminator syntax we
might adopt, since the semicolons are explicitly marked and their positions are
clearly defined.

## Refactoring Existing Systems

There are no existing systems. We could refactor code that used any existing
line terminator into this syntax, although newline-based terminators are a bit
harder to parse reliably.
