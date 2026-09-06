# Particle Operation Dependency Graph Completeness

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](requirement-construction.md). Source-semantic
arguments must still be distinguished from results about those former models.

## Reachability preserved after Comparison

For the Fill, Empty, and Move calculations supplied to `OrderedCalculations`,
let `C(O,A)` mean that `A` remains after Comparison for `O`. The calculated
graph has exactly the transitive closure of `C` as its reachability relation.

This result uses the rule stages, well-formed Collections, and the fact that
Collection selects previous operations. It does not assume a serial occupancy
execution or give different indices to simultaneous destructions. In particular,
it does not assert that every operation selected during Collection is reachable.

### Proof

Every final dependency remains after Comparison. For Create, there is at most
one Fill Dependency and no source-side candidate, so that dependency also
remains after Comparison. Thus every graph path is a `C` path.

Conversely, take an operation `A` remaining after Comparison for `O`. For
Create, `A` is its Fill Dependency, so the edge is present. For Destroy or Move,
if Move Correction removes `A`, it does so because another remaining candidate
reaches `A`. Follow such removing candidates until one remains after Move
Correction. Each step moves strictly toward a more recent candidate, all earlier
than `O`, so this process terminates. For Move, the same argument follows any
Fill Dependency removal: the removing Empty Dependency reaches the removed Fill
Dependency. The resulting final dependency reaches `A`, or equals `A`.
Prepending its edge from `O` gives a path from `O` to `A`. Applying this to
every edge of a `C` path proves the converse. ∎

The Lean theorems are `OrderedCalculations.reaches_of_afterComparison`,
`dependency_afterComparison`, and `reaches_iff_reaches_afterComparison` in
[`comparison_completeness.lean`](comparison_completeness.lean). They consume the
calculated graph, not an assumed reachability relation. This establishes what
the graph-path-based removal stages preserve. Establishing occupancy safety and
necessity for simultaneous individual destructions still requires a separate
semantic argument; this theorem does not supply that conclusion by definition.

### Identical-recency exclusion

Both Comparison exclusions precede this reachability argument. Excluding an
equally recent child Destroy requires no path from the retained parent Destroy
to it. The argument starts with operations that remain after both exclusions,
and follows only the later removals that explicitly require a path. It therefore
continues to apply to the revised Comparison without making excluded Destroys
reachable.

For Create, the sole possible candidate cannot exclude itself under either
condition: it is not more recent than itself, and its position is not a strict
transitive parent of itself. This discharges the singleton case above.

The Lean formalization includes both exclusions. The separate serial survivor
chase requires distinct recencies, derived from the serial history; that
requirement is not used by this post-Comparison reachability theorem.

## Completeness with simultaneous individual destructions

For a common-state history, let `K` be the set of operations other than Destroys
that have an equally recent Destroy at a strict transitive parent position.
Membership in `K` is determined from the operations, their recencies, and their
positions, not from the dependency graph. All Creates and Moves belong to `K`.
Within each destruction step, its members in `K` are exactly the Destroys whose
positions have no strict parent among that step's destruction targets.

The
[no-dependents result](simultaneous-destruction-proof.md#a-destroy-with-an-equally-recent-parent-destroy-has-no-dependents)
proves that every dependency targets a member of `K`. The replacement
completeness claim is:

```text
If A belongs to K, A is previous to O, and their operated positions are related,
then O reaches A.
```

In contrast to the serial claim below, this does not demand a path to each
previous Destroy at a transitive child position. The exclusion is derived from
the specified simultaneous destruction and Comparison rules, not added as an
assumption of completeness.

### A collected member of K at a parent name

Suppose an operation before `O` directly operates at `y`, and `y` is related to
the position `s` emptied by `O`. Consider all previous operations that directly
operate at `y` or a parent of `y`. Choose a greatest recency, and among
operations of that recency choose an operated position `p` of least length.
These choices exist: the set is nonempty, previous recencies are bounded by that
of `O`, and position lengths are natural numbers. Call the chosen operation `W`.

`W` belongs to `K`. Otherwise an equally recent Destroy at a strict parent of
its destroyed position would be another choice with a shorter operated position.
Also, `W` is a most recent writer at `p`: any more recent writer there directly
operates at `p` or a parent of `p`, by writer provenance, and would contradict
the greatest chosen recency. Uniqueness of a writer at one name within a step
then identifies it as the Collection entry at `p`.

Since `p` is a prefix of `y` and `y` is related to `s`, `p` is related to `s`.
Thus `W` really is collected. Its recency is at least that of the original
operation at `y`. This is an existence argument about the specified Collection;
it neither changes Collection nor substitutes a different entry at `y`.

### Every collected member of K is reachable

Use induction on the recency of `O`, assuming the replacement completeness claim
for all strictly earlier operations. Fix a collected `A` in `K`. Among collected
members of `K` that equal or reach `A`, choose one, `X`, of greatest recency.
The set contains `A`, and its recencies are bounded by `O`.

The identical-recency Comparison condition cannot exclude `X`, by the definition
of `K`. Suppose the strict-recency condition excludes it using a newer candidate
`V` related to `X`.

If `V` belongs to `K`, the outer induction hypothesis gives a path from `V` to
`X`. Therefore `V` equals or reaches `A`, contradicting the choice of `X`.

Otherwise `V` is a Destroy at some `q` with an equally recent parent Destroy. It
cannot be a Fill Dependency, by the no-dependents proof. As a source candidate,
it is collected at `q`. The preceding collected-parent argument supplies a
collected member `W` of `K`, at least as recent as `V`, operating at `q` or a
parent of `q`. This position is related to the operated position of `X` that was
related to `q`: ancestors of one name are comparable. Consequently the outer
induction hypothesis gives a path from `W` to `X`, again contradicting the
choice of `X`.

Thus `X` survives Comparison. Post-Comparison reachability, proved independently
above, gives `O` a path to `X`, hence to `A`. This survivor argument uses only
strictly earlier instances of the replacement claim. It does not assume graph
minimality.

### Empty and Move source positions

Let the earlier member `A` of `K` operate at `y`, related to the emptied
position `s`. The collected-parent argument supplies a collected `W` in `K` of
at least `A`'s recency, operating at a prefix of `y`. If the recencies are
identical, `W = A`: distinct tied operations are Destroys, and two related
Destroys in one step cannot both belong to `K`. Otherwise the outer induction
hypothesis gives `W` a path to `A`. The preceding survivor argument gives `O` a
path to `W`, proving the claim.

### Fill positions

If `A` operates at the filled position `t` or a parent of `t`, the Fill Rule
selects an operation `F` at least as recent. `F` belongs to `K`, since a Destroy
with an equally recent parent Destroy cannot be a Fill Dependency. The two
operated prefixes of `t` are related. Equal recency therefore gives `F = A`;
otherwise induction gives `F` a path to `A`. For Create the Fill edge is direct;
for Move the survivor argument reaches the collected `F` even if the final Fill
Dependency removal removes its direct edge.

It remains to consider an operated position of `A` strictly below `t`.
Immediately after `A`'s logical step, `t` is occupied. For Create or Move this
follows from reference availability and their occupancy effects. For a Destroy
in `K`, that step cannot also destroy `t` or a parent of `t`, since that would
exclude `A` from `K`. Removing particles at other positions leaves `t` occupied.

Immediately before the current Fill, `t` is empty. Hence an intervening step
empties it. A Move doing so operates at `t` or a parent of `t`. A destruction
step that empties the occupied `t` includes its individual Destroy. Either way
there is a previous operation on a prefix of `t` strictly later than `A`. The
Fill Dependency `F` is at least that recent and is in `K`. Its operated prefix
of `t` is related to `A`'s child position. Induction therefore gives `F` a path
to `A`, and the preceding Fill argument gives `O` a path to `F`.

These cases complete the recency induction. The theorem
`StepPositionHistory.reaches_related_previous_without_same_recency_parent_destroy`
in [`step_completeness.lean`](step_completeness.lean) formalizes this argument.
Its intermediate completeness hypotheses are discharged by the outer recency
induction, not supplied as semantic assumptions. It does not use the minimality
theorem.

## Serial occupancy claim

For every valid resolved Particle Operation history, let `G` be the graph
calculated by the Fill, Empty, and Move Rules. If `A` is previous to `O` and
some position operated on by `A` is related to some position operated on by `O`,
then `O` reaches `A` in `G`.

This proof does not assume or prove transitive minimality. It proves only that
the calculated graph contains a dependency path for every such related and
previous pair.

This is a conditional theorem for the serial `ValidResolvedHistory` model, whose
Destroy transition is aggregate. It is not the completeness theorem for the
current specification's simultaneous individual destructions. In particular, the
filled-position strict-child lemma below requires the parent to remain occupied
after the child's individual operation; simultaneous parent and child
destruction does not have that property at its common-state boundary. The
[simultaneous destruction proof](simultaneous-destruction-proof.md) gives a
checked counterexample to deriving reachability from arbitrary occurrence
enumeration. The common-state completeness relation is proved above for the
former construction. For the requirement-based rules, conflict reachability is
proved in `effect_collection.lean` and applied to source requirements in the
[scheduling proof](requirement-scheduling-proof.md).

## Definitions and notation

Write `A < O` when `A` has a smaller occurrence index than `O`. Write `O > A`
when `O` reaches `A` through one or more dependency edges.

For occurrences `O` and `A`, write `O R A` when:

1. `A < O`; and
2. a position operated on by `O` is related to a position operated on by `A`.

The theorem is therefore `O R A` implies `O > A`. The relation `R` depends only
on the valid resolved history's occurrence order and operated positions. It does
not mention a graph rule.

For one operation `O`, its _Collection_ is the combined set on which its rule
stages operate: the source-side entries selected by the Empty Rule and the
optional Fill Dependency selected by the Fill Rule. A Create can have only the
Fill Dependency, a Destroy can have only source-side entries, and a Move can
have both.

## Inputs from the preceding proof components

[Particle Operation Dependency Graph Calculation Correctness](calculation-correctness-proof.md)
proves these facts for every valid resolved history:

1. Every Collection member is previous to `O` and is a concrete Particle
   Operation from the history.
2. Every dependency edge points to a previous occurrence.
3. Every candidate retained by the final applicable rule stage is exactly a
   direct dependency.
4. If a previous operation `A` operated on a name related to an emptied
   position, the source-side Collection contains a representative entry `C` at
   that name or a parent name. `C` is `A` or is more recent than `A`, and
   operates on the representative name or a parent position of it.
5. If `A` operated on a filled position or one of its parent positions, the Fill
   Dependency `C` exists, is `A` or is more recent than `A`, and operates on a
   parent position of the filled position.
6. Create, Destroy, and Move have their exact occupancy preconditions and
   transitions.

These inputs do not assume completeness, transitive minimality, or any desired
reachability relation.

The serial execution also makes equal occurrence indices identify the same
operation. Minimality does not require that identity: its representative-entry
premise requires only an index at least as large. Completeness uses the stronger
serial execution to turn equal indices into operation equality. Neither step can
introduce an ordering between simultaneous individual destructions.

## Backward paths

Every edge points from a greater occurrence index to a smaller one. Induction on
a dependency path therefore gives:

```text
X > Y implies Y < X.
```

This fact will make every rule-stage survivor chase terminate. It follows from
candidate recency, not from minimality.

## Rule-stage survivor lemma

Fix an operation `O`. Assume the completeness claim has already been proved for
every operation previous to `O`. Then `O` reaches every member of its
Collection.

### Comparison

In this serial model, distinct operations have distinct recency. The
identical-recency exclusion cannot apply. The following chase must not be used
for a collection containing distinct equally recent Destroys.

Start with any Collection member `A`. If the simultaneous Comparison retains
`A`, stop. Otherwise, some Collection member `B` excludes it: `B` is more recent
than `A`, and `B` and `A` operate on related positions.

Both operations are previous to `O`, so the induction hypothesis applies to the
pair `B R A` and gives `B > A`. Repeat from `B` if the Comparison also excludes
`B`.

Every repetition chooses a greater occurrence index while remaining below the
index of `O`. Only finitely many natural-number indices lie in that interval, so
the process ends at a Comparison survivor `S`. Joining the paths found at each
step gives either `S = A` or `S > A`.

The Comparison is simultaneous. Therefore an excluded operation can serve as one
step of this chase even when a still more recent operation also excludes it.

### Move Correction

Start with a Comparison survivor `A`. If the Move Correction retains it, stop.
Otherwise, the correction itself supplies a distinct Comparison survivor `B`
with `B > A`. A backward path makes `B` more recent than `A`.

Repeat from `B`. The same bounded-index argument ends at a Move Correction
survivor `S`, with `S = A` or `S > A`.

### Move Rule's Fill Dependency removal

Start with a Move Correction survivor `A`. If the Move Rule retains it, stop.
Otherwise, `A` is the Fill Dependency and the removal condition supplies a
distinct retained source-side candidate `B` with `B > A`.

Repeating from `B` again increases the occurrence index without reaching the
index of `O`. The chase ends at a final Move dependency `S`, with `S = A` or
`S > A`.

### Reaching the original Collection member

For a Create, every Collection member is its Fill Dependency and is already a
direct dependency.

For a Destroy, apply the Comparison chase and then the Move Correction chase.
For a Move, apply all three chases. In either case the final survivor `S` is a
direct dependency of `O`, and it equals or reaches the original Collection
member `A`. Thus `O -> S` followed by the accumulated path proves `O > A`.

This establishes the rule-stage survivor lemma. Notice that it uses the
completeness induction hypothesis only for operations strictly previous to `O`.
It does not assume the result for `O` itself.

## Empty-position lemma

Assume the completeness claim below `O`. Let `O` empty position `s`, and let a
previous operation `A` operate on position `a` with `a ~ s`. Then `O > A`.

### Proof

The latest-source-candidate property supplies a source-side entry `C` selected
at `q`, where `q ≼ a`. The rule-stage survivor lemma gives `O > C`.

If `C = A`, the result follows. Otherwise, `C` is more recent than `A`. The
operated-position provenance of `C` supplies a position `c` operated on by `C`
with `c ≼ q ≼ a`. Hence `c ~ a`, so `C R A`. Both `C` and `A` are previous to
`O`; the induction hypothesis gives `C > A`. Joining the two paths gives
`O > A`. ∎

## Filled-position parent lemma

Assume the completeness claim below `O`. Let `O` fill position `t`, and let a
previous operation `A` operate on `a` with `a ≼ t`. Then `O > A`.

### Proof

The latest-fill-candidate property supplies a Fill Dependency `C`. The
rule-stage survivor lemma gives `O > C`.

If `C = A`, the result follows. Otherwise, `C` is more recent than `A` and
operates on some `c ≼ t`. The positions `a` and `c` are both prefixes of `t`, so
one is a prefix of the other and they are related. Thus `C R A`. The induction
hypothesis gives `C > A`, and joining the paths gives `O > A`. ∎

## Filled-position strict-child lemma

Assume the completeness claim below `O`. Let `O` fill position `t`, and let a
previous operation `A` operate on a strict child position `a` of `t`. Then
`O > A`.

### Proof

Immediately after `A`, position `t` is occupied:

- a Create or Move to `a` requires `t` in order for `a` to be available;
- a Destroy at `a` requires `a`, and therefore `t`, to be occupied and does not
  destroy its strict parent positions; and
- a Move from `a` likewise requires `a` to be occupied and does not empty its
  strict parent positions.

Immediately before `O`, position `t` is empty because `O` fills it. Among the
finitely many transitions between those occurrence indices, choose the first one
that changes `t` from occupied to empty. The exact occupancy transition supplies
an operation `K` at that transition and a position `k` operated on by `K` with
`k ≼ t`.

The filled-position parent lemma gives `O > K`. Also, `K` is more recent than
`A`, and `k ≼ t ≺ a`, so `K R A`. The induction hypothesis gives `K > A`.
Joining those paths proves `O > A`. ∎

No termination assumption is hidden here: the interval from `A` to the
particular occurrence `O` contains only finitely many indices even when the
complete history is unbounded.

## Completeness theorem

Proceed by induction on the natural-number occurrence index of `O`. The
induction hypothesis is the completeness claim for every operation with a
smaller index. Fix `A` with `O R A`, and choose related operated positions `o`
of `O` and `a` of `A`.

There are three operation-kind cases.

### Create

A Create operates only on its filled position `o`.

- If `a ≼ o`, apply the filled-position parent lemma.
- Otherwise, relatedness gives `o ≺ a`; apply the filled-position strict-child
  lemma.

### Destroy

A Destroy operates only on its emptied position `o`. Apply the empty-position
lemma.

### Move

A Move operates on its source and target positions.

- If `o` is the source, apply the empty-position lemma.
- If `o` is the target and `a ≼ o`, apply the filled-position parent lemma.
- If `o` is the target and `o ≺ a`, apply the filled-position strict-child
  lemma.

These cases exhaust the operated positions and both directions of relatedness.
Every use of the induction hypothesis concerns an operation previous to `O`, so
the induction is well founded. Therefore `O R A` implies `O > A` for every pair
in every valid resolved history. ∎

## Coverage of resolved operation forms

An individual destruction uses the Destroy case only if the supplied history
actually satisfies the serial execution premises. Neither Automatic Destruction
nor a Destruction Contract justifies serializing simultaneous destructions to
obtain those premises. A Destruction Contract is not a graph vertex and does not
contribute an extra destruction merely by recording an existing Destruction
Fact.

Moved transitive-child names are covered by the source-entry provenance that
allows a Move on a parent position to be the entry selected for a child name.
The survivor lemma then treats that entry through the Move Correction like every
other Move candidate.

Action Requirements, Action Guarantees, and requirements or guarantees on
implied positions have already contributed their resolved names and concrete
Particle Operations when this theorem begins. The proof applies to the resulting
occurrences without treating those resolution mechanisms as graph vertices. The
Action Parent position is not used to assume additional spatial relationships or
add another completeness case.

## Scope

This theorem begins with a valid resolved history. The source-to-history proof
must separately show that resolving valid Define source produces that history,
including its occurrence order, concrete operations, resolved-name persistence,
and Move name changes. Compiler conformance must separately show that the
implemented graph is the graph calculated from that history.

The theorem does not say that reachability contains only paths required by `R`,
that any dependency is irredundant, or that the graph is unique. Those results
combine completeness with independent facts and belong to the later
characterization proof.
