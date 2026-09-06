# Simultaneous Individual Destruction

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](requirement-construction.md). Source-semantic
arguments must still be distinguished from results about those former models.

## Scope and distinction

The specification's Particle Operation Dependency Graph has a vertex for each
individual particle destruction, not one vertex that destroys a particle and
every particle in its transitive child positions. Simultaneous Transitive
Destruction selects all those particles logically together. Only the graph rules
order their individual destructions. In particular, a destructor's accesses to
contracted positions can impose an ordering; neither a parent name nor an
enumeration chosen for the proof imposes one.

This proof separates the common occupancy change from individual execution.
Destructions with identical recency have the same set of previous operations,
although Collection queries different names for their different targets.
Destructor Particle Operations participate in that previous set according to
their own recency; they do not supply an exception to the recency rules.

## Selection and individual effects

Let `S` be the occupied positions immediately before destruction begins, and let
`T` be the positions whose particles are selected directly. Define

```text
D = {q in S | some t in T satisfies t ⪯ q}.
```

For a calculation containing only the selected destructions, represent the
original particle at `q` by its position in that common state. Processing its
vacancy vertex removes `q` from the set of unprocessed vacancies; it does not
end the original particle's existence. This is not a predicate describing
occupancy available to replacement particles. The completed simultaneous change
is `S \ D`. Here each `q` is a position in the common pre-destruction state. No
Move occurs in this calculation, so it does not supply an interpretation of `q`
across movement or a rule for executing a Destroy at a different position.

These definitions are `SelectedForDestruction`, `IndividualDestructionAfter`,
and `SimultaneousDestructionAfter` in
[`simultaneous_destruction.lean`](../definitions/simultaneous_destruction.lean).
They describe the selected destructions without intervening Create or Move
operations, not arbitrary interleavings with destructor code.

## Individual destructions commute

For distinct selected positions `p` and `q`, removing `p` does not change the
occupancy of `q`, and conversely. Therefore both orders are enabled. Both leave
exactly `S \ {p,q}`. The proof uses inequality of the selected positions, not
whether their names are related.

More generally, let `L` enumerate every member of a finite `D` exactly once.
Induct on `L`. Its first position is occupied initially. Removing it preserves
every remaining position because the enumeration has no duplicates, so the
induction hypothesis applies to the rest. A separate induction gives the final
occupancy `S \ L`, hence `S \ D`. Every permutation remains duplicate-free and
has the same members, so the result holds for every permutation, including any
permutation that respects additional dependencies.

The Lean theorems are `destructionSequenceEnabled_of_nodup`,
`destructionSequenceAfter_iff`, and
`simultaneousDestruction_permuted_execution`. The concrete
`simultaneousDestruction_parent_first` theorem checks a parent followed by its
child, the order that an aggregate parent-removal transition would incorrectly
make undefined.

This is an occupancy result. It does not authorize reordering destructor
accesses or other observations against their dependencies.

## Prefix closure belongs at common-state boundaries

Assume `S` is prefix-closed. If `q` survives and `p ⪯ q`, then `p` was occupied.
If `p` had been selected, some `t` in `T` would satisfy `t ⪯ p`; transitivity
would then select `q` too, a contradiction. Thus the completed state is
prefix-closed.

The set of original positions with unprocessed vacancy vertices after the
parent's Destroy but before the child's need not be prefix-closed. It must not
be identified with the positions occupied for subsequent source operations: the
replacement rules explicitly distinguish those observations.

`simultaneousDestruction_preserves_prefixClosure` proves the common-state
result. `simultaneousDestruction_single_target` identifies the completed change
with the old aggregate `OccupancyAfter` transition. This equality is between
completed states; it does not identify the individual graph vertices.

`ResolvedStepHistory` in
[`simultaneous_history.lean`](../definitions/simultaneous_history.lean) indexes
these common-state boundaries. Its destruction members share a proof index;
their list order imposes no execution order. Induction on steps proves prefix
closure and supplies `ValidOccupancyTrace`: selected positions are occupied
before destruction, selected transitive child positions are empty after the
completed step, and destruction creates no newly occupied position. This is the
occupancy interface used by minimality, not the serial execution interface used
by the old completeness argument.

## Common-state dependency calculation

Fix the entries `E` and queryable names before an unordered set of individual
destructions. For the destruction at `q`, collect `E(p)` for queryable `p`
related to `q`, then apply the Empty Rule's Comparison and Move Correction.
There is no Fill Dependency. Do not update `E` between these calculations merely
because their implementation enumerates the destructions.

Every retained dependency was in that Collection. If `E` contains none of the
selected destructions, none of the newly calculated edges can target a selected
destruction. Giving the destruction a different occurrence identifier leaves its
Collection and retained dependencies unchanged: Comparison compares the previous
candidates, not arbitrary identifiers of the new destructions.

These statements are `simultaneousDestroyDependency_has_prior_entry`,
`simultaneousDestroyDependency_no_implicit_order`, and
`simultaneousDestroyCalculation_enumeration_independent` in
[`simultaneous_calculation.lean`](../definitions/simultaneous_calculation.lean).

Let `G` contain the already calculated dependencies and let `G'` add these
common-state destruction edges. If no edge of `G` targets a selected
destruction, no edge of `G'` does either. Consequently there is no nonempty path
to a selected destruction, including no path between two selected destructions.
This is `simultaneousDestruction_no_order_without_dependency_path`.

Under the same hypothesis, paths starting at an unselected operation are
unchanged: their first edge cannot be a newly added destruction edge, and their
next operation is again unselected. Induction on paths proves the assertion. If
`G` is acyclic, a cycle in `G'` could neither visit a selected destruction nor
remain wholly among the unselected operations. Thus adding this set of
destructions preserves acyclicity. The corresponding Lean theorems are
`simultaneousDestruction_reaches_from_unselected_iff` and
`simultaneousDestruction_preserves_acyclicity`.

## Recency also constrains destructor-induced paths

Every Fill candidate is previous to the current operation. Every Collection
candidate is likewise previous. Comparison, Move Correction, and Fill Dependency
removal only remove candidates; they never add an edge to a different operation.
Thus every dependency points to a strictly less recent operation. Induction on
the length of a dependency path proves the same for every nonempty path.

Consequently two operations with identical recency cannot reach each other, even
through Particle Operations performed by destructors. If a destruction depends
on a destructor operation `A`, and `A` reaches another destruction, then that
other destruction must be strictly less recent than the first. Such a path
cannot order two members of the same simultaneous destruction. This follows from
the graph rules; it is not a separate prohibition on destructors.

`OrderedCalculations.no_path_of_identical_recency` formalizes this consequence
using `reaches_decreases_order`. Its backward-edge premise is derived from the
actual candidate calculation, independently of occupancy or minimality.

The common preceding graph contains only operations of smaller recency, so it
has neither a source nor a target among the selected destructions. Destructor
operations in that preceding graph satisfy the same restriction. The snapshot
lemmas above still state their hypotheses explicitly, but source correspondence
must derive those hypotheses from recency, not assume an exception for
destructor accesses.

## Why the serial completeness relation cannot be reused

Consider an occupied parent and child. Suppose the common entries contain only
the earlier Create at the child. Both individual destructions collect and retain
that Create. Neither reaches the other. The Lean witness
[`simultaneous_destruction_witness.lean`](../witnesses/simultaneous_destruction_witness.lean)
calculates both dependency sets through the actual `RuleCalculation.Dependency`
stages and proves both absent paths.

If an enumeration assigns the parent destruction a smaller index, the old
`RelatedPrevious` relation nevertheless relates the child destruction to it. The
theorem `related_previous_does_not_imply_reachability` proves that this pair is
not reachable. Enumeration is therefore not a valid repair for the old
completeness premise. The conditional serial-history Lean theorems remain true,
but they do not prove completeness or maximum safe concurrency for this
simultaneous semantics. The replacement completeness relation is proved below
without making every earlier related Destroy reachable.

The [common-state construction](step-calculation-proof.md) now derives the
candidate and minimality premises for a complete sequence of common-state
destruction steps. It proves graph minimality without serializing the members of
a step. The
[replacement completeness proof](completeness-proof.md#completeness-with-simultaneous-individual-destructions)
and
[characterization](characterization-proof.md#common-state-histories-with-individual-destructions)
now identify a relation defined independently of Comparison: earlier related
operations other than Destroys with equally recent parent Destroys. These are
graph results for that former construction, not a source-safety theorem. The
[requirement-based scheduling proof](requirement-scheduling-proof.md) proves
source safety using the distinct vacancy and shared-state requirements instead.

## A collected operation need not be reachable

### A Destroy with an equally recent parent Destroy has no dependents

Let `A` destroy at `q`, and let `B` destroy at a strict transitive parent `p`
with identical recency. Both are actual members of the common-state history. No
later operation has `A` as a dependency. This claim concerns dependencies _on_
`A`; `A` still has its own dependencies and must execute.

First, `A` cannot be a Fill Dependency. If its position `q` is a prefix of the
filled position `t`, then `p` is a strict prefix of `t`. The destruction step
leaves `p` empty, whereas the later Fill requires `p` occupied to reference `t`.
The already-proved intervening-fill lemma supplies a more recent operation at
`p` or a parent of `p`. That operation is a more recent Fill candidate for `t`,
contradicting the selection of `A`.

Second, suppose Empty Collection selects `A` at `q` for emptying `s`. Then `q`
and `s` are related. Since `p` is a parent of `q`, `p` and `s` are also related:
if `q` is a prefix of `s`, so is `p`; otherwise `p` and `s` are both prefixes of
`q`, and prefixes of one name are comparable.

Collection therefore also selects the most recent previous writer `W` at `p`.
Such a writer exists because `B` operated at `p`. Its recency is at least that
of `B`. If it is identical, uniqueness of a writer at one name within a step
gives `W = B`, and the identical-recency Comparison condition excludes `A`. If
it is greater, writer provenance says that `W` operates at `p` or a parent of
`p`, which is related to `q`; the strict-recency condition excludes `A`. This
argument uses every collected candidate, whether or not `W` itself survives
Comparison.

Create uses only its Fill Dependency. Destroy and Move retain only candidates
that survive Comparison. The two cases therefore prove the claim for every
operation kind. They also prove that there is no nonempty dependency path to
`A`: such a path would have a final edge to `A`, which has just been ruled out.
No enumeration order, minimality theorem, or completeness theorem is used.

The candidate exclusions are formalized by `child_destroy_not_fill_candidate`
and `child_destroy_not_afterComparison` in `step_calculation.lean`.
`child_destroy_has_no_dependents` and `child_destroy_has_no_path_to_it` in
`step_characterization.lean` apply them to the calculated graph. These two
corollaries do not use the characterization or minimality theorems.

This result explains why these Destroys can remain unfinished while later
operations proceed. It does not alone prove that destroying their selected
particles early or late preserves every occupancy observation; that still
requires the scheduling argument.

### Replacement example

The same witness continues after the simultaneous destruction: Create a
replacement parent defining the same child name, then Destroy the replacement
parent. The Fill Rule gives the replacement Create exactly the parent Destroy as
its dependency. Collection for the final Destroy contains the replacement Create
and the old child Destroy. Comparison removes the child Destroy in favor of the
newer parent Create. The final Destroy therefore depends only on that Create.

Neither simultaneous destruction depends on the other, and none of the added
edges targets the old child Destroy. Consequently the final Destroy does not
reach that collected operation. The theorem
`collected_operation_need_not_be_reachable` checks this with the Fill,
Comparison, and Move Correction calculations, without the Action Parent Rule.

This invalidates the serial completeness proof's intermediate claim that every
Collection member is reachable in this setting. It is not repaired by giving the
simultaneous destructions a common index: the failed reachability is from a
strictly later operation. Nor can Collection be changed to omit the old child
Destroy. The spec collects it and Comparison removes it. A replacement
completeness argument must establish the necessary dependencies without assuming
that every operation removed by Comparison is reachable. This is a graph
counterexample, not a scheduling result. A Destruction Fact distinguishes the
original particle from the replacement particle, but this occupancy-only graph
witness does not prove that an interleaved execution preserves that distinction
and operates at the required positions.

The graph-level replacement in
[`comparison_completeness.lean`](comparison_completeness.lean) proves that every
operation remaining after Comparison is reachable. More precisely, the final
graph's reachability equals the transitive closure of the relation selected by
Comparison. Its proof follows only Move Correction and Fill Dependency removal,
where removal explicitly requires a dependency path. It does not apply that
argument to Comparison, which requires no such path. The separate occupancy
argument must distinguish original particles retained for destruction from the
positions available to replacement particles. The
[child-position reuse example](maximum-safe-concurrency-proof.md#reusing-a-child-position-after-simultaneous-destruction)
is safe under the specification's replacement rules. It does not justify
changing Fill. The Lean witness above formalizes the distinct graph-reachability
counterexample, not a full model of replacement and pending destructor actions.
