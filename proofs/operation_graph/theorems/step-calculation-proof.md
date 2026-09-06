# Graph Calculation at Common-State Destruction Boundaries

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](requirement-construction.md). Source-semantic
arguments must still be distinguished from results about those former models.

## Claim and scope

For a `StepPositionHistory`, calculate the Fill, Empty, and Move Rules as below.
The resulting graph is acyclic and transitively minimal. Its reachability is
exactly the transitive closure of the relation remaining after Comparison. It is
the unique transitively minimal graph with that reachability among graphs whose
edges point to smaller step indices.

Unlike the serial aggregate construction, a destruction step contributes one
Particle Operation per selected particle. All members use the same preceding
steps; their enumeration supplies no previous-operation or execution order.
Subsequent steps may replace a destroyed parent and operate on the replacement.
Earlier child operations remain eligible for Collection.

This construction covers common-state destruction calculations. Identical
recency gives the destructions the same preceding operations, including
destructor operations of smaller recency. The graph theorem does not establish
that arbitrary runtime interleavings preserve occupancy, or derive every
destructor's resolved operations from source. Those remain separate obligations,
not assumptions of this result.

## Inputs

`ResolvedStepHistory` supplies the resolved operations and the occupancy before
and after each logical step. A step is either one Create or Move, or a finite
group of individual destructions. Its destruction targets are occupied and
include every occupied transitive child position of a selected target. Each
selected position has exactly one destruction. The completed state removes
exactly those selected occupants.

The initial occupancy is prefix-closed. Each Create and Move satisfies its
specified occupied-or-empty and position-reference preconditions and has its
specified occupancy effect. Induction proves prefix closure at completed step
boundaries. It does not require prefix closure between individual destructions.

`StepPositionHistory` additionally supplies the positions defined before each
step, used only to identify the moved particle's transitive child positions in
Collection's Move clause. This set does not filter Collection. No input field
states a dependency, a reachability relation, minimality, or completeness.

Applying the theorem to Define source still requires its resolved names,
operations, and meaning of previous to match these inputs exactly. In
particular, distinct destructions must share an index exactly when their recency
is identical, not merely because their names are related. Collection queries
previously operated related names even when their defining particle has been
destroyed and no replacement has reintroduced them; the spec supplies no
current-definedness filter.

## Exact candidate selection

For a position name `p`, a previous writer is an earlier actual operation that
directly operates on `p`, or a Move that counts as an operation at `p` under the
transitive-child clause. The latter uses the source-to-target name change for a
position defined by the moved particle at that Move.

For Empty at `s`, select the most recent previous writer at every name related
to `s`. For Fill at `t`, select the single most recent previous operation that
directly operates on `t` or a transitive parent position. These definitions are
`SourceCandidateAt` and `FillEntry` in
[`step_calculation.lean`](../definitions/step_calculation.lean). They add no
current-definedness filter, parent-replacement reset, or pre-Comparison removal.

### Existence and uniqueness at each collected name

Every previous writer has a step index less than the current index. A nonempty
set of such indices has a greatest member, even if several operations share an
index. Thus a most recent previous writer exists whenever any previous writer
exists.

Two distinct operations with the same index must be destructions at different
positions: a single-operation step has only one member, and a destruction step
has unique targets. Two such destructions cannot both write at the same name.
Therefore the most recent previous writer at each name is unique. In particular,
every earlier operation on a name has a collected writer at least as recent
there when that name is related to the emptied position.

### Uniqueness of the Fill Dependency

Suppose two distinct Fill candidates tie for the greatest previous index. They
must be destructions at different positions `p` and `q`. Both positions are
prefixes of the filled position `t`, so one is a strict parent of the other.
Call that strict parent `p`; it is also a strict parent of `t`.

After the destruction step, `p` is empty. Before the current Fill, `p` must be
occupied for the reference to `t` to be available. Hence an intervening step
changes `p` from empty to occupied. That step is a Create or Move operating on
`p` or a parent position, as follows directly from their occupancy effects. Its
operation is a more recent Fill candidate for `t`, contradicting the supposed
greatest index. Thus the Fill Dependency is unique. This proof uses occupancy,
not graph completeness or a tie-breaking order on destructions.

The checked lemmas are `most_recent_writer_unique`,
`later_fill_after_destroyed_parent`, and `most_recent_fill_unique`.

## Graph construction and minimality

Apply the specified Comparison, Move Correction, and Move Rule's Fill Dependency
removal to those candidates. Comparison excludes both older related operations
and equally recent child Destroys with a collected parent Destroy. All collected
operations participate in determining those exclusions. Move Correction then
uses only the survivors of both conditions.

`OrderedCalculations` constructs the graph by recursion on the operation's step
index. Every candidate is from a smaller index, so every edge points backward
and the graph is acyclic. Different destructions in one step cannot reach each
other through this construction. That conclusion follows from identical recency,
and applies even to paths through destructor operations. It does not exclude
paths between destructions of different recencies.

The candidate facts are derived directly from the selection definitions:

- every candidate is a previous actual operation;
- a collected writer operates on the collected name or a parent position;
- a non-Move writer operates on the collected name itself;
- each applicable earlier operation has a collected writer at least as recent at
  its operated name; and
- a Fill candidate directly operates on the filled position or a parent.

`ResolvedStepHistory` supplies the common-state occupancy facts consumed by the
independent [minimality argument](minimality-proof.md). In particular, an
occupied source that was empty after an earlier non-Move must have an
intervening filling operation. That argument does not require the serial
aggregate execution interface or related-and-previous completeness.

[`step_minimality.lean`](step_minimality.lean) constructs `ResolvedDefineGraph`
from those derived facts and applies the independent minimality theorem. There
is no assumption that the calculated dependencies form an antichain.

The English arguments and Lean graph calculation include both Comparison
exclusions. The later-Destroy example below checks their effect on candidates
derived from a common-state history.

## Reachability and uniqueness

The independent
[Comparison completeness result](completeness-proof.md#reachability-preserved-after-comparison)
establishes that every operation remaining after Comparison is reachable, and
that the graph has exactly the transitive closure of that relation. It does not
claim reachability of every operation initially collected.

Only [`step_characterization.lean`](step_characterization.lean) combines that
graph construction with minimality. The stronger
[replacement completeness theorem](completeness-proof.md#completeness-with-simultaneous-individual-destructions)
now proves that reachability is also the transitive closure of the
related-and-previous relation restricted to earlier operations without an
equally recent parent Destroy. This relation is defined from the history,
independently of candidate selection or Comparison. `dependency_is_unique` uses
this characterization. The proved generic uniqueness lemma then applies:
transitively minimal graphs pointing backward in the same index function and
having the same reachability have identical edges. That lemma requires strictly
decreasing indices along edges, not distinct indices for every vertex, so its
hypotheses match this construction without imposing a destruction order.

## Checked example

### A later Destroy compares equally recent parent and child Destroys

Start with particles at `p` and `p::c`, create the particle at `p::c::g`,
destroy the particle at `p::c`, and then destroy the particle at `p`. There are
no destructors. The first Destroy statement contributes the two equally recent
Destroys at `p::c` and `p::c::g`. Both depend on the Create at `p::c::g`.

For the later Destroy at `p`, the most recent previous operations at the two
child names are those Destroys. Collection therefore contains both. Neither is
strictly more recent, but the parent-position condition excludes the Destroy at
`p::c::g`. The only remaining dependency is the Destroy at `p::c`; Move
Correction cannot remove it because it is not a Move. The graph has no path
between the two equally recent Destroys, so the later Destroy does not reach the
excluded one either.

This calculation checks the new exclusion, not the general necessity of the
retained edge or the safety of every schedule. Those conclusions require the
separate particle-operation semantics argument.

### Common-state prefix

[`step_history_witness.lean`](../witnesses/step_history_witness.lean) begins
with an occupied parent, creates a child, and selects both particles for
destruction at one shared index. It supplies a complete `StepPositionHistory`,
proves that each destruction's sole dependency is the child Create, and applies
the general minimality theorem. Neither destruction reaches the other. The
example supplies operations and occupancy transitions, not a preselected graph.
