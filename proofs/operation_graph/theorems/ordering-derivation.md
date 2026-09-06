# Deriving Ordering from Particle Operations

## Scope

This derives requirements for the graph construction now written in the
specification. The former Fill, Empty, Comparison, and Move calculation remains
represented by the older resolved-name Lean proofs; those are not a
formalization of this replacement. The specification identifies Destroy vertices
with vacancy, separately from the end of a particle's existence.

The goal is to derive ordering from the semantics before choosing a graph
construction. A candidate construction must prove safety and necessity before
its transitive reduction can be called a maximum-concurrency graph. Graph
minimality alone proves neither property.

The [operation requirements](../definitions/operation-requirements.md) now
separate direct implied access, explicit reference occupancy, particle
existence, and vacancy. The
[requirement construction](requirement-construction.md) applies those
distinctions to ordinary operations, simultaneous selection, and retained
destructor state, with their semantic correspondence developed in the
[scheduling proof](requirement-scheduling-proof.md).

## Consequences that do not depend on a construction

1. A Create requires its target empty and each intermediate position reference
   occupied. Its new particle is not interchangeable with an earlier particle in
   that position. The proof must preserve the particles selected by source
   operations, not merely the final set of occupied names.
2. A Move requires its source particle and an empty destination. It changes the
   spatial positions of its defined positions and their particles transitively,
   including empty positions. It is not a deferred destruction or a change of
   spelling. An operation cannot assume the post-Move spatial relationships
   before that Move, or the preceding relationships after it. A later Move may
   restore a relationship; necessity must be proved for the proposed ordering,
   not assumed for every pair that ever affects the same particle.
3. A Destroy denotes vacancy. Its former particle can remain available to
   destructors after that vacancy. Reuse of the vacated position does not access
   the retained original particle. The vacancy must still follow ordinary
   operations whose required occupancy it would invalidate.
4. A destructor's interactions determine how long original particles must remain
   available. Moving an implied particle interacts with its transitive child
   particles. Moving one child does not imply moving its siblings. Calls made by
   the destructor are ordinary actions and retain their actual effects.
5. Original particles are shared between destructors. Availability after vacancy
   does not make two conflicting Moves independent. A model that gives each
   destructor a separate copy of its required particle changes Define's
   semantics even if both copies are later discarded.

These statements follow from Position References, Moving Particles, Simultaneous
Transitive Destruction, and Destruction Ordering During Destructors. None uses
the current graph's reachability as evidence that an ordering is necessary.

## An ordering choice remains even when every particle survives

Suppose two destructors, `A` and `B`, are assigned to the same particle. Each
implies the occupied position `/marker`. The particle there has no child
positions. Each destructor has an independent local position `held` and this
body:

```text
define the position<held>.
move the particle in position</marker> to position<held>.
move the particle in position<held> to position</marker>.
```

Denote their Moves by `Aout`, `Aback`, `Bout`, and `Bback`. All four Moves act
on the same original marker particle. Distinguish the local positions as
`A.held` and `B.held` for this mathematical argument. No constructor or
destructor is assigned to the marker particle itself. The outer vacancy can
already have occurred; the original marker remains available to both actions.

Both of these orders are valid, with exactly the same original particle restored
to `/marker` and both local positions empty:

```text
Aout, Aback, Bout, Bback
Bout, Bback, Aout, Aback
```

But this interleaving is invalid:

```text
Aout, Bout, Aback, Bback
```

After `Aout`, the particle is in `A.held` and `/marker` is empty, so `Bout` has
no source particle. Keeping the particle alive does not enable the Move.

### No precedence graph can admit both valid orders and exclude the bad order

Every graph edge must be respected by every admitted order. In the two valid
orders, each operation of `A` changes its relative order with every operation of
`B`. Therefore a graph admitting both orders can have no edge between the two
actions' Moves. It can require `Aout` before `Aback` and `Bout` before `Bback`,
but the invalid interleaving respects both requirements. The ordinary Creates
and vacancies can be placed in a common prefix of all three schedules. Edges
involving that prefix cannot distinguish their subsequent interleavings.

Thus the graph must choose one of the two safe orientations. Either resulting
four-operation chain is transitively minimal and cannot be weakened while
preserving safety: reversing either destructor's adjacent Moves attempts to
return a particle from an empty local position, and reversing the adjacent
return and next departure attempts to depart from an empty `/marker`. Removing
any chain edge admits the corresponding adjacent reversal. Neither contains all
the safe executions admitted by the other. This is a limitation of precedence
graphs, not a missing lifetime edge.

The bounded Lean witness `destructor_order_choice.lean` represents the three
positions and the one original particle explicitly. Each Move is enabled exactly
when that particle occupies its source; the destination is then empty because
the three positions are distinct and no other particle occupies them. It
verifies both safe orders, failure of the interleaving, and the graph
obstruction for every binary dependency relation. This correspondence is exact
for these four Moves; it does not model all of Define or assume safety of a
general graph construction.

The existing integration test
[`test_multiple_constructors_and_destructors_modify_same_implied_position`](../../../define/compiler/validator/reference_graph/reference_graph_validator_tests/operation_graph_destructor_integration_test.py)
contains this pair of destructor bodies. Its expectation chooses `B` before `A`.
That implementation choice is not a semantic premise for this proof.

## Consequence for the construction goal

The serial-model proof already distinguishes inclusion-minimal safety from a
[global maximum admitting every safe execution](maximum-safe-concurrency-proof.md#why-the-result-is-not-a-global-maximum).
The example above establishes the same issue with a single preserved particle
and unchanged destructor guarantees; it is not an artifact of ignoring particle
identity in the earlier Create-and-Destroy example.

The specification permits the compiler to choose any serial ordering of the
destructors triggered by a simultaneous destruction for determining recency. The
construction therefore takes one such ordering as input and must prove safety
and necessity relative to that choice. The unchanged Action Guarantees make each
complete destructor preserve the contracted state for the next one. They do not
make every interleaving of their Particle Operations safe, as the example
proves.

The chosen order is not a whole-destructor runtime barrier. Independent
operations from different destructors may interleave when the graph permits
them. The proof must establish that each remaining ordering is necessary within
the chosen orientation, not that one graph admits both serial orders above.
Different choices can give different transitively minimal graphs. No unique
precedence relation is claimed before that choice is fixed.

This choice does not move a destructor before the creation or destruction that
triggers it. For example, if a destructor creates a local particle with its own
destructor, that new destructor is triggered by a subsequent destruction. Its
serial execution remains within that subsequent destruction; it is not another
member of the earlier choice. The runtime graph can still relax this serial
placement wherever actual requirements permit.

## Graph facts available after semantic ordering is established

### An implied position during a Move

Consider a constructor assigned to the particle created in `source`. It implies
`/marker`, initially empty, and its body is:

```text
create a particle in position</marker>.
```

The caller subsequently executes:

```text
move the particle in position<source> to position<destination>.
```

Assume `destination` is empty and has no additional constraints. Under the
former Empty Rule, the Move follows the constructor's Create: that Create is the
most recent operation on a child position of `source` and excludes the earlier
Create at `source` during Comparison.

A direct implied-position reference requires the position defined by the
constructor's assigned particle, without requiring that particle to remain at
`source`. Thus both orders satisfy the source and destination occupancy
conditions. Creating the marker first makes the Move move both particles. Moving
first moves the empty defined position, and the constructor creates the marker
there afterward. Both end with the same particles in the same positions. They
differ in whether the marker already exists during the Move and where its
creation occurs spatially.

This is not the earlier rejected reordering of `Destroy destination::/marker`
before the Move. That explicit position reference requires a particle in
`destination`. The constructor's written reference is directly to its implied
position. Collapsing the two reference forms into the same full spatial name
before deriving their requirements would assume the issue away.

The [operation-requirement derivation](../definitions/operation-requirements.md)
proves this exchange by checking each operation's requirements, not just the
final state. Requiring the Create to retain its reference execution's spatial
location would add a requirement absent from its direct implied reference. This
does not establish anything about unspecified future value operations or
external calls. The former graph calculation specified an order; that fact alone
cannot prove its semantic necessity. The requirement-based rules instead
preserve the actual reference requirements used in this argument.

### Conditional graph and scheduling results

The [exact-effect model](../definitions/operation-effects.md) provides an
independent adjacent-exchange proof and an adjacent noncommutation proof for
precise requirements and genuine state changes. Its source-correspondence
obligations remain explicit; those algebraic theorems do not assume that the
translation from Define has already been proved.

For a chosen transitive precedence relation with natural-number ranks that
strictly decrease along its edges, `cover_graph.lean` already proves that its
cover pairs have exactly its reachability, are transitively minimal, and belong
to every graph with that reachability. The finite rank difference discharges the
finiteness needed between related occurrences even for an unbounded history.
These are reusable mathematical facts, not assumptions about which Particle
Operations need ordering.

Defining the candidate graph to be this cover graph is a mathematical baseline,
not a scalable compiler algorithm. The
[requirement construction](requirement-construction.md) derives collection and
Comparison and proves their equivalence to this baseline. This does not by
itself bound the cost of implementing Comparison's reachability queries. Neither
an all-pairs comparison nor a full graph transitive reduction is being proposed
as the compiler implementation.
