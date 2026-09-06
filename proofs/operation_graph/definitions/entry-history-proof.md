# Collection After Replacing a Particle

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](../theorems/requirement-construction.md).
Source-semantic arguments must still be distinguished from results about those
former models.

## Claim and scope

The serial `PositionEntryHistory` calculation retains the most recent previous
Particle Operation at each position name. Collection selects those operations at
related names without a further current-definedness filter. Its entry selection
is derived from the exact updates below, not from a proposed graph property.

This model supplies a serial aggregate occupancy execution and the positions
defined before each operation. The latter set is used only for the Move clause
about the moved particle's transitive child positions. There are no hypotheses
requiring an operated position to remain defined or requiring a disappearing
name to have an operated parent.

The serial model still does not represent individual simultaneous destructions.
The [common-state calculation](../theorems/step-calculation-proof.md) supplies
the separate construction for that case. Both constructions query previously
operated names even when no particle currently defines them. Collection supplies
no current-definedness filter; the Comparison exclusions determine which
collected operations remain.

## Exact updates and most-recent selection

Initially there is no previous operation at any name. For an operation `O`,
update the entry at `p` to `O` exactly when:

- `O` directly operates on `p`; or
- `O` is a Move, and `p` is the changed name of a transitive child position of
  the moved particle.

Every other entry remains unchanged. Destroying or replacing a parent does not
erase an earlier child operation, and Collection does not discard it merely
because the defining particle was replaced. Comparison applies afterward.

`entry_iff_most_recent_previous` proves that the entry is `A` if and only if `A`
is a previous actual writer at the name and no more recent previous operation
writes there. The forward direction is induction on these updates. For the
converse, a previous writer guarantees that an entry exists: subsequent updates
may replace it but never erase it. If the recorded entry and the proposed most
recent writer differed, one would be newer, contradicting one of their
most-recent properties. Equal indices identify the same operation in this serial
execution.

For any earlier operation on `p`, `previous_operation_entry` therefore supplies
an entry at that very name with an index at least as large. No representative at
a different position or position-retirement premise is needed.

## Calculation facts and graph results

For Empty at `s`, Collection selects the most recent entries at names related to
`s`. A selected writer operates at that name or a parent position; if it is not
a Move, it operates at the name itself. The most-recent-entry theorem supplies
the coverage fact needed by minimality.

For Fill at `t`, take the most recent previous operation directly on `t` or a
transitive parent position. This selection does not use the additional entries
from Collection's Move clause. Existence follows from bounded previous indices,
and uniqueness from the serial execution's single operation at each index.

`OrderedCalculations` constructs dependencies by recursion on the source
operation's index. Collection members are earlier, and every dependency is a
Collection member. All edges therefore point backward. Paths among earlier
candidates are identical in the earlier graph and the completed graph, so the
Move Correction and Fill Dependency removal calculate the same result against
either. This establishes the exact-dependency equation without assuming
minimality or completeness.

`PositionEntryHistory.resolvedGraph` and `completeGraph` supply the derived
facts to the independent graph theorems. They give acyclicity, transitive
minimality, and the serial related-and-previous characterization. The serial
finite and unbounded occupancy-scheduling results then apply. These are
conditional serial results, not a proof of arbitrary individual-destruction
interleavings.

## Checked replacement example

`entry_retirement_witness.lean` creates a parent and child, destroys the child
and parent separately, creates a replacement parent, and destroys it. Collection
for the final Destroy contains exactly the replacement Create and the old child
Destroy. Comparison removes the old child Destroy, leaving exactly the parent
Create as a dependency.

The witness calculates the complete candidate and dependency sets and applies
the general minimality theorem to the constructed graph. It does not supply
dependencies as assumptions.
