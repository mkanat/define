# Particle Operation Dependency Graph Calculation

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](../theorems/requirement-construction.md).
Source-semantic arguments must still be distinguished from results about those
former models.

## Purpose

This document defines the Fill, Empty, and Move Rules for one arbitrary valid
resolved Particle Operation history. It proves that the rules determine one
dependency graph, one occurrence at a time.

This component does not prove that the resulting graph is minimal or complete.
It also does not assume either property. Those results require separate proofs
about the graph defined here.

The occurrence-by-occurrence construction in this document is the conditional
serial `ValidResolvedHistory` construction. Its queryable-name trace is an
input, not a derived fact about all Define executions. In particular, that trace
must not be used to invent a current-definedness filter for Collection or to
treat historical names as positions belonging to a moved particle. The separate
[common-state calculation](../theorems/step-calculation-proof.md) selects
previous operations directly and permits individual destructions to share an
index.

## Required refinement to resolved histories

Occupancy is not enough to calculate the graph. The Empty Rule also queries
empty transitive child positions, and a Move counts as an operation on the
transitive child positions whose applicable names it changes. The calculation
must therefore know which resolved position names the rules may query at each
operation index.

For each index `i`, let `Qᵢ` be that set of names immediately before `Oᵢ`.
Membership in `Qᵢ` means only that a graph rule may ask for the most recent
Particle Operation on that resolved name. It does not mean that the position is
occupied.

Applying this model to source would require deriving `Qᵢ` from Position
Definitions, Action Executions, resolved names retained for graph history, and
Move name changes. In particular, that application would need:

1. every position operated on by `Oᵢ` has an applicable resolved name at index
   `i`;
2. every occupied position in `Sᵢ` has an applicable resolved name at index `i`;
3. if a name is applicable, every transitive parent position needed by that name
   is also applicable; and
4. once a resolved name has been operated on, the name remains queryable at
   every later occurrence, even while the position is empty; and
5. a Move from `s` to `t` changes the applicable name `s · r` to `t · r` for
   every position belonging to the moved particle, while a resolved position
   name contributed by a later Action Execution is not retroactively treated as
   moved.

The shared history interface and its paired Lean structure record `Qᵢ`; they do
not derive it from source. This limits the claims of the former resolved-name
model. The requirement-based proof instead keeps actual references and positions
identified by their defining particles, as described in the
[ordinary correspondence](../theorems/ordinary-requirements-proof.md).

## Most-recent-operation entries

For every index `i` and resolved position name `p`, let

```text
Eᵢ(p)
```

be either the Particle Operation recorded as most recent on `p` immediately
before `Oᵢ`, or `none` when there has been no such operation. The bookkeeping
function remains defined while a name cannot be referenced, so an earlier entry
can become visible if that name can be referenced again. Graph rules consult the
function only at names in `Qᵢ`. Initially every entry is `none`.

The entry changes after an operation as follows.

### Create and Destroy

After `Create(p)` or `Destroy(p)`, the entry for `p` is that operation. Every
other entry is unchanged.

Each individual destruction updates its own position's entry. Simultaneous
Transitive Destruction and Automatic Destruction may contribute several such
operations; their calculations must use the spec's meaning of previous, not an
order chosen by enumerating the destructions. The serial recursion here does not
establish that construction. Destroying a parent particle does not erase entries
for its child-position names; Comparison accounts for intervening operations on
related positions.

### Move

Suppose `Oᵢ = Move(s,t)`. The Move becomes the entry for:

- `s`, because the Move operates directly on its source;
- `t`, because the Move operates directly on its target; and
- every `t · r` for which `s · r` names a transitive child position of the moved
  particle immediately before the Move.

All other applicable entries are unchanged. This is the Empty Rule's statement
that a Move is considered a Particle Operation on each transitive child position
of the moved particle. The old and new names are related by the same suffix `r`;
the rule does not assign Move entries to positions first introduced by resolving
a later Action Execution.

### Entry invariant

For every `p` in `Qᵢ`, `Eᵢ(p) = A` exactly when `A` is the most recent previous
occurrence that the specification treats as an operation on the current resolved
name `p`.

This follows by induction on `i`. The initial case has no previous occurrence.
Each induction step is exactly one of the Create, Destroy, or Move updates
above. No dependency edge is used in this induction.

## The Fill Rule

Let `Oᵢ` fill `t`. Consider the finite set of entries

```text
{Eᵢ(p) | p is in Qᵢ, p ⪯ t, and Eᵢ(p) is not none}.
```

The Fill Dependency is the occurrence in this set with the greatest index. If
the set is empty, there is no Fill Dependency.

The set is finite because `t` has only finitely many parent-name prefixes. Its
members are previous occurrences, whose indices are distinct, so a nonempty set
has exactly one greatest member. This is precisely the single most recent
previous Particle Operation among the operations on `t` and its transitive
parent positions.

## The Empty Rule

Let `Oᵢ` empty `s`.

### Collection

The Collection is

```text
Cᵢ(s) = {
  A
  | there is a p in Qᵢ such that p ~ s and Eᵢ(p) = A
}.
```

Thus the rule takes the most-recent entry for `s` and for every applicable
transitive parent and child position. Repeated entries contribute one candidate
occurrence, not multiple copies.

The set of queried position names need not be finite. The candidate set is
nevertheless finite: every entry is one of the `i` previous occurrences, so
`Cᵢ(s)` has at most `i` distinct members. This local bound is all later stages
need.

### Comparison

For any finite candidate set `C`, define

```text
Compare(C) = {
  A in C
  | there is no B in C such that
      (A < B and some operated positions of A and B are related)
      or
      (A and B are Destroys with identical recency and
       B's position is a strict transitive parent of A's position)
}.
```

Every member of the original `C` participates in determining exclusions,
including members that are themselves excluded. This defines the result, not a
pairwise implementation algorithm. Identical recency does not become an order
between Destroys: the second condition selects dependencies of a later operation
without adding an edge between the equally recent candidates.

The serial model has distinct indices for distinct operations, so its second
condition is never satisfied. The common-state calculation must apply both
conditions. The Lean `AfterComparison` definition includes both conditions;
`afterComparison_iff_of_distinct_recency` proves the reduction for the serial
model rather than assuming it for simultaneous destructions.

### Move Correction

Let `Gᵢ` be the dependency graph of occurrences before `Oᵢ`. Define

```text
Correctᵢ(C) = {
  A in Compare(C)
  | A is not a Move, or
    no distinct B in Compare(C) reaches A in Gᵢ
}.
```

Only candidates remaining after the Comparison participate. When `A` is a Move
and another remaining candidate reaches it, the graph order makes that other
candidate more recent, so retaining only the other candidate implements the Move
Correction.

The dependencies of a Destroy are `Correctᵢ(Cᵢ(s))`.

## The Move Rule

Let `Oᵢ = Move(s,t)`. Define:

```text
Sourceᵢ = Cᵢ(s)
Combinedᵢ = Sourceᵢ union {the Fill Dependency for t, if one exists}
Remainingᵢ = Correctᵢ(Combinedᵢ).
```

The Comparison and Move Correction each run once on the combined set.

If the Fill Dependency `F` remains and there is a distinct `A` such that

```text
A is in Sourceᵢ,
A is in Remainingᵢ, and
A reaches F in Gᵢ,
```

remove `F`. Otherwise leave `Remainingᵢ` unchanged. The resulting set is the
Move's dependency set.

Source membership is remembered separately from membership in the combined set.
This matters when one occurrence was collected on the source side and was also
selected as the Fill Dependency.

## Create dependencies

The dependency set of a Create is the singleton containing its Fill Dependency,
when one exists, or the empty set otherwise. A Create has no Empty Rule
Collection.

## Recursive graph construction

Let `G₀` be the graph with no vertices. Given `Gᵢ`, calculate the final
dependency set of `Oᵢ` using only `Eᵢ` and reachability among the previous
occurrences in `Gᵢ`. Add `Oᵢ` and one edge from `Oᵢ` to each member of that set,
producing `Gᵢ₊₁`.

Every candidate is an entry in `Eᵢ`, so every candidate is one of
`O₀, ..., Oᵢ₋₁`. Therefore the construction never asks whether a new or future
occurrence is reachable. Its apparent reference to the dependency graph is
well-founded.

For a history that stops after `n` occurrences, the calculated graph is `Gₙ`.
For an unbounded history, its graph is the union of all finite-prefix graphs: an
edge belongs to the graph exactly when it belongs to the step that added its
source occurrence. No final occurrence or finite complete vertex set is needed.

## Theorem: the calculation is well-defined and exact

For every valid resolved history equipped with the applicable-name trace
described above, the recursive construction determines exactly one dependency
relation. At every occurrence, that relation applies, in order:

1. the Fill Rule or Empty Rule Collection appropriate to the operation kind;
2. the simultaneous Comparison;
3. the Move Correction;
4. for a Move, the Fill Dependency removal.

### Proof

Proceed by induction on the occurrence index.

At index zero, there is no previous operation. Every entry and candidate set is
empty, so the first occurrence has one determined, empty dependency set.

For the induction step, assume `Eᵢ` and `Gᵢ` have been determined. The operation
kind determines whether the calculation uses the Fill Rule, the Empty Rule, or
the combined Move Rule. Every candidate set is a subset of the `i` previous
occurrences, so the sets are finite. Greatest-indexed entries, when requested,
are unique. Comparison and Move Correction are set predicates, so they have
unique results. The Move Rule's final removal is one stated condition with one
stated result. Hence `Oᵢ` has one final dependency set.

Adding those edges uniquely determines `Gᵢ₊₁`. Applying the operation's entry
update uniquely determines `Eᵢ₊₁`. This completes the induction. Every stage
used in the construction is the corresponding specification stage listed above,
so the resulting relation is exactly the relation calculated by the three
resolved rules. ∎

## What this theorem does not establish

The theorem defines the graph and proves that the definition is not circular. It
does not prove:

- that the direct dependency set is a reachability antichain;
- that every direct dependency is necessary;
- that every related previous occurrence is reachable;
- transitive minimality, completeness, or uniqueness; or
- that the compiler constructs this relation.

Those are results for the calculation-correctness, minimality, completeness,
characterization, and compiler-conformance components respectively.

The Action Parent Rule is not part of this resolved calculation. As the
specification notes, it lets a compiler defer dependency selection while
resolving one action without its caller's complete history. Compiler conformance
must show that resolving that deferred information produces the dependency
selected by the three rules above; it does not add another kind of edge to the
resolved graph.

The paired Lean formalization in [`calculation.lean`](calculation.lean) records
`Qᵢ` in `ValidResolvedHistory`, defines the entry relation in closed form, and
constructs the prefix graphs by natural-number recursion. The remaining
source-to-history proof must derive the recorded names from resolved Define
source; they are not arbitrary additional positions.
