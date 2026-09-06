# Particle Operation Maximum Safe Concurrency

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](requirement-construction.md). Source-semantic
arguments must still be distinguished from results about those former models.

This argument uses the serial aggregate Destroy transition and the
related-and-previous characterization. It is not a scheduling proof for all
individual destructions under the current specification. In particular, the
claim below that related operations cannot execute in both orders does not apply
to individual parent and child destructions selected simultaneously: their
individual occupancy effects commute. The
[simultaneous destruction proof](simultaneous-destruction-proof.md) proves that
case separately, without discarding destructor-induced dependencies.

There is a further limitation even for ordinary operations. Resolving every
operation to a fixed spatial-name target does not preserve the requirements of
direct implied references when their defining particle moves. The
[constructor/Move exchange](../definitions/operation-requirements.md#an-exchange-proved-from-these-requirements)
is safe without preserving the Create's reference-execution spatial location.
The serial model below does not admit that exchange and therefore cannot prove
source-level maximum concurrency for all ordinary Define operations.

## A Move changes the positions of the transitive child particles

Consider a particle at `a` that defines an occupied child position `c`, an empty
position `b`, and these operations, without constructors or destructors:

```text
C  = Create the child particle at a::c
M  = Move the parent particle from a to b
D  = Destroy the parent particle at b
E  = the simultaneous destruction of its child particle
```

Take the earlier creation of the parent as already complete. The former
calculation gives `M -> C`, `D -> M`, and `E -> M`. In particular, Collection
for `E` sees `M` at `b` and at `b::c` under the moved-child clause; Comparison
retains `M`. There is no dependency between `D` and `E`.

For the requirement-based construction, replacing `E -> M` with `E -> C` admits:

```text
C, E, M, D
```

An earlier rejection of this order treated `E` as though the caller had written
`destroy ... b::c`. That would require a particle at `b` and would have to wait
for `M`. But `E` is an implicit child Destroy selected by the destruction of
`b`, not another written statement. It selects the original child position
defined by the parent particle. That position moves with its defining particle;
its spatial location need not stay fixed to the location in the serial reference
execution.

The
[generated-child exchange](retained-state-proof.md#an-implicit-child-vacancy-and-an-ordinary-ancestor-move)
checks both orders. Vacating the child first means `M` moves an empty child
position; moving first means the selected vacancy happens after that position
moves. The written target Destroy `D` still waits for `M`. Detachment and the
distinction between a selected position and an actual written reference are
essential here. Particle identity alone would not justify dropping the
requirements of a genuinely written `b::c` reference.

The integration test
[`test_destruction_cascade_branches_from_one_preceding_move`](../../../define/compiler/validator/reference_graph/reference_graph_validator_tests/operation_graph_single_action_integration_test.py)
contains the two-child version. Its existing expectation makes each child
Destroy depend on the Move. This documents the earlier graph expectation, not
evidence that this edge is necessary under detachment.

The common-state graph results do not by themselves prove safety or maximum safe
concurrency for arbitrary interleavings. The
[requirement-based scheduling proof](requirement-scheduling-proof.md) supplies
the execution argument respecting movement and the positions on which each
operation acts.

## Individual occupancy effects do not include every reference precondition

Suppose a particle at `p` defines `p::c`, with no constructors or destructors.
Compare these endings after creating the child:

```text
destroy the particle in position<p>.
```

and

```text
destroy the particle in position<p>::position</c>.
destroy the particle in position<p>.
```

Both contribute exactly the same two individual destructions at the same
positions: one destroys the child, and one destroys the parent. The second
ending gives the child Destroy earlier recency. It does not change the
particles, their positions, or the individual destruction effects.

Let `C` be the child Create, `Dc` the child Destroy, and `Dp` the parent
Destroy. Take the parent's earlier creation as complete. The first ending gives
`Dc -> C` and `Dp -> C`. In the second ending, Collection for `Dp` selects `Dc`
at the child position. Comparison removes the older parent Create, and Move
Correction cannot remove `Dc`. The calculated graph is therefore
`Dp -> Dc -> C`.

The individual occupancy effects commute, but that fact alone does not show that
the second ending can execute in both orders. Its written child position
reference requires `p` to contain a particle. Executing `Dp` first invalidates
that precondition. The implicit child Destroy in the first ending has no such
written reference. A source-correspondence argument must account for these
preconditions instead of inferring full semantic equivalence solely from the two
occupancy-removal functions.

The English calculation is tracked by
[`test_separately_requested_destroys_at_unchanged_positions`](../../../define/compiler/validator/reference_graph/reference_graph_validator_tests/operation_graph_single_action_integration_test.py).
The existing `later_destroy_dependency_iff` witness checks the corresponding
graph ordering with an additional transitive child Destroy.
`occupancy_only_destruction_permutation` shows that the occupancy-removal model
alone accepts both orders, while `later_destroy_invalidates_parent_reference`
shows the lost reference precondition. Both are in
[`step_history_witness.lean`](../witnesses/step_history_witness.lean).

Consequently, this example does not justify ignoring prior Destroys during
Collection. The proof must preserve reference preconditions as well as the
spatial effects described in the conceptual definitions. The current
individual-destruction model proves only the limited occupancy result stated in
its scope, not a complete source-level scheduling theorem.

## Reusing a child position after simultaneous destruction

The replacement rules in Simultaneous Transitive Destruction resolve the former
occupancy counterexample without changing Fill or Comparison.

Let `p` require the position quality `/c`, with no constructors or destructors.
Start with `p` empty and execute this valid source sequence serially:

```text
create a particle in position<p>.
create a particle in position<p>::position</c>.
destroy the particle in position<p>.
create a particle in position<p>.
create a particle in position<p>::position</c>.
```

Call the first two Creates `P0` and `C0`, the simultaneous parent and child
Destroys `Dp` and `Dc`, and the replacement Creates `P1` and `C1`. Both child
Creates operate on the same spatial position, as specified in the
[conceptual definitions](../definitions/definitions.md#conceptual-meaning-of-particles-positions-and-operations).
The original child is not a child of the replacement particle, even while its
individual destruction remains unfinished.

The former rules derive these dependencies (an arrow points to a prerequisite):

```text
C0 -> P0
Dp -> C0
Dc -> C0
P1 -> Dp
C1 -> P1
```

Both Destroys collect `C0` and `P0`; Comparison retains `C0`. The Fill for `P1`
considers `Dp` at `p`, not `Dc` at its child. The Fill for `C1` considers both
`Dc` at its own position and `P1` at its parent, but selects only `P1` because
it is more recent. There is no path from `P1` to `Dc`.

Consequently, the graph permits this execution prefix:

```text
P0, C0, Dp, P1, C1
```

At `C1`, `Dc` has not executed. Nevertheless, `Dp` has emptied `p` and the
original child no longer occupies a position defined by the replacement. `C1`
therefore creates at an empty position. When `Dc` eventually executes, it
destroys the original child, not the replacement child. This follows from the
specification's explicit distinction between replacement and unfinished
destruction work, not merely from different particle identities.

The previously proposed dependency `C1 -> Dc` is unnecessary. `C1 -> P1`
provides the parent particle for the new child reference, and `P1 -> Dp` ensures
that the original parent has vacated `p`. Neither simultaneous Destroy needs to
wait for the other. This argument is for this example without destructors or
Moves, not a general scheduling theorem.

The integration test
[`test_child_refill_is_independent_of_old_child_destroy`](../../../define/compiler/validator/reference_graph/reference_graph_validator_tests/operation_graph_single_action_integration_test.py)
records that graph, including the final automatic Destroys. Every edge is
necessary: it either makes an operated position occupied or empty as required,
or supplies the parent particle needed for a written reference. The independent
Destroys act on their original particles. Thus the expected graph admits their
safe orders without adding parent-before-child or child-before-parent
destruction ordering.

The [retained-state proof](retained-state-proof.md) represents the original
particles retained for destruction separately from occupancy used by
replacements. A single predicate over spatial position names cannot represent
both during this execution prefix. This distinction replaces the rejected Fill
and Move changes.

## Vacancy and final destructor use require different relations

Consider a parent particle at `p` with an occupied implied position `/c` and a
destructor assigned to the parent. Its entire body is:

```text
define the position<held>.
move the particle in position</c> to position<held>.
move the particle in position<held> to position</c>.
```

There are no other qualities or destructors. The caller creates the parent,
creates its child, and destroys the parent. Name those operations `P`, `C`,
`Dp`, and the implicit child destruction `Dc`; name the destructor's Moves `M1`
and `M2`. The two Moves together restore the same child particle and qualities,
so the destructor satisfies its unchanged Action Guarantee. The destructor has
no reference to the parent particle it is assigned to. Its `/c` reference is an
implied position, not a written `p::/c` reference that requires `p` occupied.

An earlier calculation treated the Destroy vertices as completion of destruction
and placed `M1` and `M2` before them. For that choice of previous entries, the
graph calculation gives:

```text
C -> P
M1 -> C
M2 -> M1
Dp -> M2
Dc -> M2
```

For `Dp`, Collection contains `P` at `p` and `M2` at `p::/c`. The destructor's
local `held` is not a child name of `p`, but querying it too would add only the
same `M2`. Comparison excludes `P` because `M2` is newer and operates on its
child position. `M2` is the only survivor, so Move Correction cannot remove it.
The Lean calculation `DestructorParentWitness.parent_destroy_dependency_iff`
checks this candidate calculation. It does not establish that this previous
entry state is the one for a vacancy vertex under the clarified semantics.

Destroy now means vacancy. The destruction semantics permit vacancy before the
retained destructor accesses:

```text
P, C, the simultaneous vacancies Dp and Dc, M1, M2
```

After `Dp`, the original child and its implied position remain available to the
destructor. `M1` moves that child into the destructor's empty local position;
`M2` returns it to the original implied position. The end of the original
child's existence waits for that final use; its vacancy `Dc` does not. No Move
of the parent occurs, no replacement is accessed, and no particle is destroyed
while the destructor still requires it. The parent particle need not survive
solely because the destructor uses a position it defined: the specification
expressly permits those implied-position accesses afterward.

Both vacancies must follow `C`: the parent vacancy would invalidate the caller's
written child reference, and the child vacancy requires the selected child to
have been created. Neither vacancy needs to wait for `M2` solely to preserve the
original child's existence. The earlier assertion that `Dc -> M2` must remain
conflated lifetime and vacancy and is withdrawn.

The integration test
[`test_destructor_fragments_finish_before_cascade_frees_positions`](../../../define/compiler/validator/reference_graph/reference_graph_validator_tests/operation_graph_destructor_integration_test.py)
contains the two-independent-child version. Its expected vacancies depend on the
caller's child Creates rather than the destructor Moves. The original particles
must still be retained through their final destructor uses. Such lifetime
obligations are not additional interpretations of the vacancy nodes.

The [ordering derivation](ordering-derivation.md) starts from this distinction.
The existing graph theorems remain facts about their specified candidate
calculations; neither the old serial execution model nor those graph facts alone
establish source correspondence for retained destructor accesses.

## What the serial proof establishes

Consider any valid resolved Particle Operation history. The history may stop or
may continue without end. This document proves three results about occupancy:

1. Every execution schedule allowed by the relation defined below gives each
   operation the same occupancy that it has in the history's previous-operation
   order. When the history stops, every such schedule also leaves the same final
   occupancy.
2. No ordering constraint in that relation can simply be removed. Removing one
   allows an execution order in which two adjacent operations are reversed, and
   that execution is undefined.
3. The Particle Operation Dependency Graph represents the relation with exactly
   its cover edges. It is therefore the unique inclusion-minimal graph with the
   same reachability. For a history that stops, it is also the unique graph with
   the fewest edges and that reachability.

These results give a precise, limited meaning to “maximum safe concurrency.” The
relation is inclusion-minimal among occupancy-safe precedence relations obtained
by removing constraints that follow the program's operation order. It does not
follow that every occupancy-equivalent total order is allowed. The
counterexample in “Why the Result Is Not a Global Maximum” shows why that
stronger claim is false.

The Lean theorem `exchange_unrelated_enabled_operations` in
[`occupancy_exchange.lean`](occupancy_exchange.lean) formalizes the central
adjacent-exchange result: exchanging enabled operations on pairwise unrelated
positions preserves their preconditions, their occupancy observations, and the
occupancy state after the pair. `ScheduleExecution.swap_adjacent_unrelated` in
[`finite_scheduling.lean`](finite_scheduling.lean) lifts that exchange through
any finite schedule prefix and suffix. The theorem
`respecting_permutations_connected` in
[`finite_schedule_order.lean`](finite_schedule_order.lean) proves that any two
duplicate-free finite schedules containing the same occurrences and respecting
the same precedence relation are connected by such adjacent incomparable
exchanges. `finite_respecting_schedule_execution` in
[`calculated_schedule_execution.lean`](calculated_schedule_execution.lean)
combines those components for the calculated graph: every dependency-respecting
permutation of a defined finite schedule of distinct operations from one valid
resolved history has the same observations and final occupancy. The canonical
schedule in [`finite_history_schedule.lean`](finite_history_schedule.lean) lists
the occurrences before a stopping index directly from the history, proves that a
stopping index makes this exactly the history's complete operation set, and
proves that the schedule is duplicate-free, respects calculated reachability,
and executes with the history's observations and final occupancy.
`stopped_history_finite_schedule_execution` combines these results, formalizing
the stopped-history case of the theorem below. The natural-number schedule and
finite-prefix completion theorem in
[`unbounded_schedule_order.lean`](unbounded_schedule_order.lean), together with
`unbounded_respecting_schedule_execution`, formalize the unbounded-history case
one finite prefix at a time. The generic cover definition and omitted-cover-pair
theorem are in [`cover_order.lean`](cover_order.lean), while
[`cover_schedule_order.lean`](cover_schedule_order.lean) formalizes the
dependency-respecting finite construction that makes each calculated cover pair
adjacent. `related_enabled_operations_not_reversible` formalizes the four
occupancy cases showing that two related operations cannot execute consecutively
in both orders.
`calculated_coverPair_has_irreversible_adjacent_finite_execution` in
[`cover_schedule_necessity.lean`](cover_schedule_necessity.lean) combines those
results for every calculated cover pair.
`proper_transitive_subrelation_allows_undefined_historyPrefix` formalizes the
finite-prefix counterexample for every proper transitive subrelation, and
`stopped_proper_transitive_subrelation_allows_undefined_schedule` extends it to
a schedule of every Particle Operation in a stopped history. The theorem
`exists_unboundedSchedule_with_prefix` in
[`unbounded_history_schedule.lean`](unbounded_history_schedule.lean) formalizes
the unbounded splice and its bijection and precedence obligations.
`unbounded_proper_transitive_subrelation_allows_undefined_schedule` extends the
same counterexample to a complete natural-number-indexed schedule for an
unbounded history. The generic reachability, necessity, and transitive
minimality results for cover graphs are in
[`cover_graph.lean`](cover_graph.lean).
[`calculated_cover_graph.lean`](calculated_cover_graph.lean) applies them to the
calculated dependency relation, proving that it is exactly the cover graph and
is contained in every relation with the same reachability. Finally,
[`finite_relation_edge_count.lean`](finite_relation_edge_count.lean) proves the
generic finite counting lemmas, and
[`stopped_dependency_edge_count.lean`](stopped_dependency_edge_count.lean) uses
them to formalize the unique fewest-edge result for stopped histories.

## Definitions

### Operations and positions

Let `V` be the set of resolved Particle Operation occurrences in a
[valid resolved history](../definitions/definitions.md#resolved-histories). Each
execution of a Particle Operation statement is a separate member of `V`. As in
the [shared definitions](../definitions/definitions.md), index the occurrences
by a finite initial segment of the natural numbers or by all natural numbers.
Assume that executing the operations in index order is defined.

Let `<` be that strict linear order. For an operation `O`, let `positions(O)` be
the positions it operates on. A Create or Destroy operates on one position. A
Move operates on its source and target positions.

Write `p <= q` when `p` is `q` or a transitive parent position of `q`. Write
`p ~ q` when `p <= q` or `q <= p`.

Define `R` by

```text
(O, A) is in R exactly when A < O and
some position of O is related by ~ to some position of A.
```

Write `O >R A` when there is a nonempty `R` path from `O` to `A`. In execution
terms, `O >R A` requires `A` to execute before `O`. Every step in an `R` path
moves to an earlier operation, so `>R` is a strict partial order.

For readability, call `A` before `O` a _cover pair_ when `O >R A` and there is
no operation `X` for which both `O >R X` and `X >R A`. A cover pair is an
ordering with no required operation between its two members.

### Occupancy and equivalence

An occupancy state records which available resolved positions are occupied. A
child position is available only while every transitive parent position needed
to name it is occupied.

- A Create on `p` requires `p` to be available and empty, then makes `p`
  occupied.
- A Destroy on `p` requires `p` to be occupied, then empties `p` and all of its
  transitive child positions.
- A Move from `s` to `t` requires `s` to be occupied and `t` to be available and
  empty. It empties `s`, fills `t`, and replaces the source prefix of every
  occupied transitive child-position name with the target prefix.

The occupancy observed by an operation is the occupancy of its operated
positions immediately before it executes. An execution order is undefined if an
operated position is unavailable or if an operation's occupied-or-empty
requirement is not met.

An _execution schedule_ lists every member of `V` exactly once. For an unbounded
history, this means a sequence indexed by the natural numbers; in particular,
every scheduled operation has only finitely many operations before it. A
schedule respects `>R` when it places `A` before `O` whenever `O >R A`.

Two schedules of a history that stops are _occupancy-equivalent_ when both are
defined, each operation observes the same occupancy in both schedules, and both
schedules leave the same final occupancy. For an unbounded history, equivalence
means that both schedules are defined at every finite index and that each
operation observes the same occupancy; there is no final state to compare.

This definition deliberately ignores particle identity, qualities, Action
triggering, destructor effects, and every other possible observation.

## Lemma: Operations on Unrelated Positions Commute

Suppose `A` followed immediately by `O` is defined, and every position operated
on by `A` is unrelated to every position operated on by `O`. Then `O` followed
by `A` is also defined. The exchange preserves both operations' occupancy
observations and the occupancy state after the pair.

### Proof

For an operated position `p`, an operation can change occupancy only at `p` and
its transitive child positions. If a Move uses `p` as its source or target, the
same statement holds for the child-position names that the Move removes or
creates.

Now take unrelated positions `p` and `q`. Their sets of transitive child
positions are disjoint. Otherwise some position would have both `p` and `q` as
prefixes, and two prefixes of one position name are always related. This would
contradict `p` and `q` being unrelated.

It follows that `A` and `O` change disjoint sets of position names. Neither can
change the occupancy or availability required by the other: changing a parent
position of one of `O`'s operated positions would itself require operating on a
position related to that operated position, contrary to the hypothesis. The same
reasoning applies with `A` and `O` exchanged.

Both operations therefore have the same preconditions and observations after the
exchange. Because their changes are disjoint, applying the two changes in either
order also gives the same state after the pair. This includes two Moves: their
source-prefix removals and target-prefix replacements act on disjoint position
names. ∎

## Lemma: Moving a Particle Does Not Lose Its Orderings

Two operations on the same particle are ordered by `>R`, even if that particle's
position name changes between the operations.

### Proof

Let `A < O` operate on the same particle. If the particle has the same
applicable position name at both operations, then `A` and `O` operate on the
same position, so `(O, A)` is in `R`.

Otherwise, consider in order the Moves that change the particle's applicable
name. Such a Move either moves the particle itself or moves a particle that
defines one of its transitive parent positions.

Before the first such Move, `A` operates on the Move's source position or one of
its transitive child positions. After the last such Move, `O` operates on the
Move's target position or one of its transitive child positions. The same is
true between consecutive Moves: the earlier Move's target side and the later
Move's source side describe the particle between those Moves.

Each consecutive pair in the sequence consisting of `A`, those Moves, and `O`
therefore operates on related positions. The later and earlier operations of
each pair form a member of `R`. Chaining those members gives `O >R A`. ∎

## Theorem: Every Consistent Schedule Is Occupancy-Equivalent

Every execution schedule that respects `>R` is occupancy-equivalent to the
history's previous-operation order.

### Proof

The history's previous-operation order respects `>R`, because every `R` edge
points from a later operation to an earlier one.

First suppose the history stops. Apply the
[finite linear-extension correspondence](external-results.md#finite-schedules-and-adjacent-exchanges)
to `>R`: it is a strict partial order, and both schedules list every member of
the finite occurrence set exactly once. The cited connectivity result supplies
adjacent incomparable exchanges between them.

Operations incomparable under `>R` have pairwise unrelated operated positions.
If they had related positions, whichever operation is later under `<` would form
an `R` pair with the earlier one, so they would be comparable.

Starting from the defined previous-operation order, apply the commutation lemma
to each adjacent exchange. An exchange preserves the observations of the
exchanged operations and the state received by all later operations. Induction
over the sequence of exchanges proves that the desired schedule is defined,
gives every operation the same occupancy observation, and leaves the same final
occupancy.

Now suppose the history is unbounded. Fix any finite prefix `P` of the desired
schedule. Let `k` be greater than the previous-operation index of every
operation in `P`, and let `L` be the finite list of history operations whose
indices are less than `k`. Thus `P` is a duplicate-free subcollection of `L`.

Remove the operations of `P` from `L` without changing the order of the
remaining operations, obtaining `T`. Then `P` followed by `T` contains exactly
the operations of `L`. It also respects `>R`. The prefix `P` respects `>R` by
hypothesis, and `T` respects `>R` because it retains the relative order from
`L`. For the remaining cross case, suppose an operation `p` in `P` were required
to follow an operation `t` in `T`. The complete desired schedule contains `t`
and respects `>R`, so it places `t` before `p`. Because `p` occurs in the fixed
prefix `P`, `t` would then also occur in `P`, contradicting its membership in
`T`.

The finite case applied to `L` and `P` followed by `T` proves that this
completed finite schedule is defined with the history's observations. Its prefix
`P` is therefore defined with those observations. Since the choice of finite
prefix was arbitrary, every operation in the desired schedule is defined and
observes the same occupancy as it does in the previous-operation order. An
unbounded history has no final occupancy claim. ∎

## Theorem: Every Cover Ordering Is Necessary

For every cover pair `A` before `O`, there is a `>R`-consistent execution order
in which `A` is immediately before `O`. Reversing that adjacent pair makes the
execution undefined.

### Proof

First, `(O, A)` must itself be in `R`. If every `R` path from `O` to `A` had at
least two edges, any intermediate operation on such a path would lie strictly
between `A` and `O`, contrary to the definition of a cover pair.

Next, a cover pair can be adjacent in a schedule that respects `>R`. Let `L` be
the finite history prefix ending with `O`. Every predecessor of `O` belongs to
`L`, because reachability always moves to a smaller previous-operation index.
From `L`, take the other predecessors of `O` in their history order, then place
`A` and `O`, and finally place the other members of `L` in their history order.

This permutation of `L` respects `>R`. The other predecessors retain their
relative history order. None is required to follow `A`, because together with
its path from `O` that would put it strictly between the cover pair. Nothing
placed before `O` is required to follow `O`, because reachability moves to a
smaller index. Finally, if an operation moved after `O` were required before any
operation in the new prefix, transitivity would make it a predecessor of `O`, so
it would already have been placed before `A`.

Let `b` be one greater than the index of `O`. The adjacent permutation contains
exactly the operations with indices below `b`, once each, and therefore has
length `b`. If the history stops at index `N`, append the operations with
indices from `b` through `N - 1` in history order. If the history is unbounded,
define the operation at each schedule index below `b` from the corresponding
entry of the adjacent permutation, and define the operation at every schedule
index `n` at least `b` to be the history operation with index `n`.

In the unbounded case this is a bijection. Two entries in the permuted prefix
are distinct; a prefix entry has history index below `b`, whereas a suffix entry
has history index at least `b`; and two suffix entries have their distinct
history indices. Every history operation appears either in the permuted prefix
when its index is below `b`, or at its own schedule index otherwise. Thus these
constructions are respectively a complete finite schedule and a schedule indexed
by all natural numbers.

The appended operations retain their history order. No operation in the permuted
prefix is required to follow an appended operation: reachability would give the
appended operation a smaller index, which would put it in the prefix already.
Thus both completed schedules respect `>R`, and the preceding theorem makes the
original adjacent order a defined execution with `A` immediately before `O`.

Because `(O, A)` is in `R`, choose an operated position `p` of `A` and an
operated position `q` of `O` such that `p <= q` or `q <= p`. Every operated
position is one of two kinds for its operation:

- its _Empty Position_, which must be occupied before the operation; or
- its _Fill Position_, which must be available and empty before the operation.

A Move's source is its Empty Position and its target is its Fill Position. A
Create has only a Fill Position, and a Destroy has only an Empty Position.

After an enabled operation, its Fill Position is occupied. Its Empty Position
and every child position of that Empty Position are empty. The latter statement
also holds for a Move. The Move precondition says that its source is not a
parent position of its target. Its target cannot be a parent position of its
source either: prefix closure and the occupied source would then make the target
occupied, contrary to the Move precondition. The source and target are therefore
unrelated, so moving particles to target-based names cannot restore an old
source-based name.

The history's initial occupancy is prefix-closed. The proof of
[valid-history Lemma 1](../definitions/valid-history.md#lemma-1-valid-operations-preserve-prefix-closure)
shows that each enabled Create, Destroy, or Move preserves prefix closure.
Applying that lemma successively to the finite schedule prefix before `A` proves
that the occupancy immediately before the adjacent pair is prefix-closed. We can
now consider the four possible roles of `p` and `q`.

1. Suppose both are Empty Positions. If `p <= q`, executing `A` empties `q`, so
   `O` cannot be enabled next. The original order is defined, so this direction
   is impossible. We must have `q <= p`; executing `O` first then empties `p`,
   so `A` is not enabled.
2. Suppose `p` is an Empty Position and `q` is a Fill Position. If `q <= p`,
   prefix closure makes `q` occupied before `A`, whereas executing `O` first
   requires `q` to be empty. Otherwise, relatedness makes `p` a strict parent
   position of `q`. Then `O` requires `p` to be occupied after `A` so that `q`
   is available, but `A` empties `p`. Thus either the reversed order is
   undefined or the assumed original order was already undefined.
3. Suppose `p` is a Fill Position and `q` is an Empty Position. If `p <= q`,
   executing `O` first requires `q` to be occupied, so prefix closure makes `p`
   occupied, whereas `A` requires `p` to be empty. Otherwise, relatedness makes
   `q` a strict parent position of `p`. Executing `O` first then empties `q`, so
   `p` is unavailable when `A` attempts to fill it.
4. Suppose both are Fill Positions. If `p = q`, executing `A` fills the position
   that `O` requires to be empty, contradicting the assumed original execution.
   If `p` is a strict parent position of `q`, executing `O` first requires `p`
   to be occupied, whereas `A` requires it to be empty. If `q` is a strict
   parent position of `p`, `A` requires `q` to be occupied so that `p` is
   available, whereas executing `O` first requires `q` to be empty.

The four cases exhaust the possible roles of the selected operated positions. In
every case, `A` followed by `O` and `O` followed by `A` cannot both be defined
from the same occupancy. Because the original adjacent order is defined, the
exchanged order is undefined. ∎

### Consequence: no program-oriented constraint can be removed

Let `P` be the precedence relation represented by `>R`, and let `Q` be a strict
partial order that is a proper subrelation of `P`. Choose `(O,A)` in `P` but not
in `Q` for which the natural-number difference between the indices of `O` and
`A` is as small as possible. Such a choice exists because `Q` is a proper
subrelation and the natural numbers are well ordered.

This minimal omitted pair is a cover pair. Otherwise, some `X` would satisfy
both `(O,X)` in `P` and `(X,A)` in `P`. If both pairs were in `Q`, transitivity
would put `(O,A)` in `Q`. At least one is therefore omitted by `Q`. Reachability
always moves to a smaller index, so both the `O`-to-`X` and `X`-to-`A` index
differences are smaller than the chosen `O`-to-`A` difference. Either omitted
pair would contradict the minimal choice. Thus `Q` omits a cover pair.

Take the `P`-consistent order in which that pair is adjacent and exchange the
pair. Before the exchange the order respects `Q` because `Q` is a subrelation of
`P`. The exchange changes only the relative order of the adjacent pair, and that
pair is not in `Q`, so the exchanged order still respects `Q`. The theorem above
says that it is undefined. Thus no proper subrelation of `P` guarantees a
defined execution for all of its linear orders.

This is the necessity result used by the “maximum safe concurrency” claim.

## Why the Result Is Not a Global Maximum

Occupancy-equivalence can treat two complete Create-and-Destroy pairs as
interchangeable. Let one position `p` be initially empty, with program order

```text
C1 = Create p
D1 = Destroy p
C2 = Create p
D2 = Destroy p
```

Because all four operations use `p`, `>R` requires

```text
C1 before D1 before C2 before D2.
```

But this order is also defined:

```text
C2 before D2 before C1 before D1.
```

In both orders, each Create observes `p` empty, each Destroy observes `p`
occupied, and the final state has `p` empty. The orders are therefore equivalent
under this document's occupancy-only definition even though the second order
reverses constraints in `>R`.

The equivalence cannot be exposed by removing only the constraint between `D1`
and `C2`. That would also allow interleavings with two consecutive Creates or
two consecutive Destroys, which are undefined. A precedence graph cannot express
the choice “run either complete pair first, but do not interleave the pairs”
without choosing one pair order. Occupancy alone gives no reason to prefer the
program's pair order over the reverse order.

Thus `>R` is inclusion-minimal among safe subrelations of the program-oriented
relation, but it is not the intersection of all occupancy-equivalent total
orders and is not a unique global optimum over differently oriented precedence
relations.

## The Unique Transitively Reduced Graph for This Reachability

Among graphs on `V` whose reachability is exactly `>R`, the transitive reduction
is the unique inclusion-minimal graph. When `V` is finite, it is consequently
also the unique graph with the fewest edges.

### Proof

For finite `V`, this is directly the
[finite transitive-reduction theorem](external-results.md#finite-transitive-reduction).
Take `>R` as the edge relation: it is transitive and its strictly decreasing
occurrence indices exclude cycles and loops. Its positive-length reachability is
itself. The theorem supplies uniqueness, inclusion-minimality, and the
fewest-edge conclusion. No algorithm from the paper is a construction step.

For unbounded `V`, retain the following rank-difference argument; the finite
theorem does not apply.

Every cover pair must be a direct edge in any graph with reachability `>R`.
Without that edge, a path between the pair would have an intermediate operation,
contrary to the definition of a cover pair.

Conversely, the graph consisting of the cover-pair edges has reachability `>R`.
Prove this for each `(O,A)` in `>R` by induction on the difference between their
natural-number indices. If `(O,A)` is a cover pair, its edge is the required
one-edge path. Otherwise, the negation of the cover condition supplies an
operation `X` such that `(O,X)` and `(X,A)` are both in `>R`. The index of `X`
is strictly between the endpoint indices, so both differences are smaller. Apply
the induction hypothesis to the two pairs and join their finite cover paths.
This argument uses only the finite index difference of the chosen pair; it does
not require `V` itself to be finite.

No cover edge is redundant. An alternate path containing two or more edges would
put its first intermediate operation strictly between the cover pair's
endpoints, contradicting the cover condition. A different one-edge path with the
same endpoints is the same relation entry, not an alternate edge.

The transitive reduction therefore consists of exactly the cover-pair edges.
Every graph with the same reachability contains those edges; any different such
graph also has at least one additional edge. The cover graph is therefore the
unique inclusion-minimal graph with that reachability. ∎

By
[Particle Operation Dependency Graph Characterization](characterization-proof.md),
the Fill, Empty, and Move Rules produce this transitive reduction. The graph
therefore allows every reordering obtained by commuting operations on unrelated
positions, and no constraint in its reachability can be removed while keeping
every allowed order occupancy-safe.

## Scope

This proof concerns occupancy for one resolved Particle Operation history, which
may stop or continue without end. It assumes the history's previous-operation
order is defined and uses only the specified occupancy effects of Create, Move,
and Destroy. An unbounded history has observations and states at every finite
index but no final occupancy state.

It does not prove correctness of the runtime's concurrent execution, Action
Requirement inference, or any behavior other than occupancy. In particular, it
does not compare particle identity, qualities, Action triggering, destructor
effects, or the ordering of other effects. Those observations may require
additional constraints, and they may distinguish the two orders in the
Create-and-Destroy counterexample.
