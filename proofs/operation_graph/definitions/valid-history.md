# Valid Resolved Particle Operation Histories

The graph calculations in this document describe the former Fill, Empty, and
Move Rules and their existing Lean models. They do not formalize the revised
[requirement-based construction](../theorems/requirement-construction.md).
Source-semantic arguments must still be distinguished from results about those
former models.

## Theorem statement

Let

```text
H = (O₀, O₁, O₂, ...; S₀, S₁, S₂, ...)
```

be a valid resolved history as defined in the
[shared definitions](definitions.md#resolved-histories). The occurrence sequence
may stop after a finite number of terms or continue without end. Then all of the
following hold:

1. every state `Sᵢ` is prefix-closed;
2. an operation that empties a position finds that position occupied;
3. an operation that fills a position finds that position available and empty;
4. after a non-Move operates on `p`, every strict transitive child position of
   `p` is empty;
5. every position that changes from empty to occupied at one step was filled by
   that step's operation or became occupied through the Move's transitive
   spatial effect; and
6. a Move preserves occupancy throughout the moved particle's transitive child
   positions under the source-to-target name change.

These results use only Particle Operation preconditions and occupancy effects.
They do not use dependency edges or any clause of the Fill, Empty, or Move
Rules.

The source-to-target name substitution represents movement of positions and
their particles, as described in the
[conceptual definitions](definitions.md#conceptual-meaning-of-particles-positions-and-operations).
This occupancy-only model does not separately track particle identities or empty
positions moving with a particle. Its theorems must not be used to infer
properties that require those distinctions without proving the correspondence.

In particular, the resolved position of each operation in this model does not
record how its source reference obtains that position. It therefore cannot be
used to prove that a direct implied-position operation must retain its serial
reference execution's spatial location. The
[operation-requirement derivation](operation-requirements.md) proves a
constructor/Move exchange that this fixed-position scheduling interpretation
does not represent.

Here `ValidResolvedHistory` is the serial model with aggregate Destroy
transitions. Its states are not the intermediate states between individual
simultaneous destructions. `ResolvedStepHistory` instead derives parts 1, 2, 4,
and 5 at common-state boundaries; the
[simultaneous destruction proof](../theorems/simultaneous-destruction-proof.md)
explains that distinction. Neither representation by itself resolves destructor
accesses from Define source.

A valid resolved history also records, at each index, the resolved position
names whose most-recent Particle Operation may be queried. Every occupied or
operated position has such a name, a name operated on earlier remains queryable
at later indices, and these names are prefix-closed. Remaining queryable does
not mean that the position remains occupied or that source code can currently
refer to it; the retained name preserves its graph identity. The occupancy
results below do not otherwise depend on that trace; the graph calculation does.

## Assumptions and their specification sources

The proof uses the following parts of the specification:

- A [position reference](../../../define/spec/spec.md#position-references)
  requires every intermediate position in its chained name to be occupied.
- A [Create Particle Statement](../../../define/spec/spec.md#creating-particles)
  fills its target, whose position reference must be empty.
- A
  [Destroy Particle Statement](../../../define/spec/spec.md#destroying-particles)
  requires an existing particle, and Simultaneous Transitive Destruction also
  selects the particles at transitive child positions.
- A [Move Particle Statement](../../../define/spec/spec.md#moving-particles)
  requires an occupied source and an empty target, preserves the moved particle,
  and may not move it to a position it defines.
- Automatic Destruction simultaneously selects the applicable remaining local
  particles at the end of the Action Statements Block.

Requirements involving qualities and Position Constraint Blocks are part of
source validity but are not needed for these occupancy conclusions.

## Lemma 1: valid operations preserve prefix closure

If `Sᵢ` is prefix-closed and `Oᵢ` satisfies its preconditions, then `Sᵢ₊₁` is
prefix-closed.

### Proof

There are three cases.

**Create.** Let `Oᵢ = Create(p)`. The only newly occupied position is `p`. Every
strict transitive parent position of `p` was occupied because `p` was available.
All positions that were already occupied retain their previously occupied parent
positions. Thus the next state is prefix-closed.

**Destroy.** Let `Oᵢ = Destroy(p)`. The operation removes exactly `p` and the
positions for which `p` is a transitive parent position. Suppose `q` remains
occupied and `r ⪯ q`. If `r` had been removed, then `p ⪯ r`; by transitivity,
`p ⪯ q`, so `q` would also have been removed. Therefore every parent position of
a remaining `q` remains occupied.

**Move.** Let `Oᵢ = Move(s,t)`. A position other than `s` and its transitive
child positions keeps the same name and the same occupied parent positions. None
of those parent positions can be `s` or one of its transitive child positions
unless the position itself is also `s` or one of its transitive child positions.

Now consider a moved occupied position `s · r`, whose new name is `t · r`. The
parent positions contributed by `t` were occupied because `t` was available.
Every later parent position along `r` is the renamed image of an occupied parent
position along `s · r`. Hence every parent position of `t · r` is occupied after
the Move.

All three operations preserve prefix closure. ∎

## Theorem part 1: every state is prefix-closed

### Proof

The initial state `S₀` is prefix-closed by the definition of a valid history.
Apply Lemma 1 successively to `O₀`, `O₁`, and so on. Induction on the operation
index proves that every `Sᵢ` is prefix-closed. ∎

## Theorem parts 2 and 3: operations receive the required occupancy

### Proof

A Destroy empties its target, and a Move empties its source. Their preconditions
require that position to be occupied immediately before the operation. This
proves part 2.

A Create fills its target, and a Move fills its target. Their preconditions
require that position to be available and empty immediately before the
operation. This proves part 3. ∎

## Lemma 2: a non-Move leaves strict child positions empty

Suppose a Create or Destroy operates on `p`. Immediately after the operation, no
strict transitive child position of `p` is occupied.

### Proof

For the serial aggregate Destroy transition, the completed Simultaneous
Transitive Destruction removes `p` and every transitive child position of `p`.
This statement does not apply immediately after just one individual destruction.

For a Create, `p` was empty immediately before the operation. Prefix closure
then implies that no strict transitive child position of `p` was occupied:
occupancy of such a child position would require `p` to be occupied. The Create
adds only `p`, so those child positions remain empty immediately afterward. ∎

This proves theorem part 4.

## Lemma 3: every newly occupied position has a responsible operation

Suppose `q` is empty in `Sᵢ` and occupied in `Sᵢ₊₁`. Then one of the following
holds:

- `Oᵢ` is `Create(q)`;
- `Oᵢ` is `Move(s,q)`; or
- `Oᵢ` is `Move(s,t)`, `q = t · r`, and `s · r` was occupied in `Sᵢ`.

In every case, `Oᵢ` operates on `q` or a transitive parent position of `q`.

### Proof

A Destroy creates no occupied position, so `Oᵢ` is not a Destroy.

A Create changes only its target from empty to occupied. Therefore a newly
occupied `q` must be that target.

A Move changes occupied names only by replacing the source prefix with the
target prefix. Thus a newly occupied `q` has the form `t · r`, and the
corresponding `s · r` was occupied before the Move. The case `r` empty is the
Move target itself. In all cases, the Move operates on `t`, which is `q` or a
transitive parent position of `q`. ∎

This proves theorem part 5.

## Lemma 4: a Move preserves its occupied child positions

Let `Oᵢ = Move(s,t)`. For every sequence `r`,

```text
s · r is occupied in Sᵢ
if and only if
t · r is occupied in Sᵢ₊₁.
```

### Proof

The forward direction is the Move effect: every occupied position with source
prefix `s` receives the corresponding target prefix `t`.

For the reverse direction, the Move target was empty before the operation.
Prefix closure therefore makes every position with target prefix `t` empty
before the operation. The only way for `t · r` to be occupied afterward is the
source-to-target name change applied to an occupied `s · r`. ∎

This proves theorem part 6.

## Corollaries used by the graph proofs

### Occupancy changes alternate

Fix a resolved position name during an interval in which no Move changes its
applicable name. Two consecutive changes affecting that name cannot both fill it
or both empty it. A fill requires it to be empty and leaves it occupied; an
emptying operation requires it to be occupied and leaves it empty.

When a Move changes the applicable name, Lemma 4 provides the corresponding
statement between the source and target names.

### Occupied child positions make their parents available

If `q` is occupied and `p ⪯ q`, then `p` is occupied by prefix closure. In
particular, an operation cannot use an occupied child position after a Destroy
has emptied one of its parent positions, unless an intervening operation has
filled the required parent position again.

### Replacing a parent particle does not preserve its earlier child occupancy

If a non-Move empties a parent position and a later Create fills that same
position, the later particle does not inherit the earlier particle's occupied
child positions. Lemma 2 makes those child positions empty after the emptying or
filling operation. This differs from a Move, for which Lemma 4 explicitly
preserves the corresponding occupancy under new names.

## Non-vacuity witness

Let the Action Parent position be the empty sequence and let `p = [0]`. Start
with only the Action Parent position occupied. At index zero, perform
`Create(p)`, and perform no later operation. Before index zero, `p` is available
and empty. After the Create, both the Action Parent position and `p` are
occupied, and that state remains unchanged. This is a nonempty valid resolved
history and assumes nothing about a dependency graph.

At every index in this witness, the Action Parent position and `p` are the two
resolved position names whose most-recent Particle Operation may be queried.
That set is prefix-closed and includes every occupied and operated position.

This witness shows that the history premises are mutually consistent. It does
not replace the source-to-history construction needed to show that every valid
Define program execution produces such a history.

## Resolution cases

The theorem above begins with a valid resolved history. To apply it to source
programs, resolution must account for every way a Particle Operation occurrence
arises.

### Written Particle Operations

Validation checks the occupied-or-empty requirements of written Create, Move,
and Destroy Particle Statements. Their resolved occurrences therefore satisfy
the corresponding preconditions. Replacing relative position names with the
caller's concrete prefix preserves parent and child relationships.

### Action Executions, Requirements, and Guarantees

Every Action Execution receives its own occurrence identities and resolved
positions. Action Requirements ensure that the first relevant use of a
contracted position begins with the occupancy required by the callee. Action
Guarantees describe the state visible to the caller after the callee's final
operation on the guaranteed position. Neither contract item adds a Particle
Operation occurrence.

An Action Requirement is satisfied before the action triggers. An Action
Guarantee becomes usable after the callee's final operation relevant to that
guarantee; the caller may then proceed without waiting for unrelated later
operations in the callee. These rules place the relevant callee occurrences
relative to the caller occurrences. The source-to-history proof must compose
these placements with the other sequencing rules and prove that graph-rule
queries use the resulting meaning of “previous.”

### Simultaneous Transitive Destruction and Automatic Destruction

Both forms select particles simultaneously, and each selected particle has its
own individual destruction. There is no prescribed parent-before-child or
child-before-parent order. Identical-recency destructions use the common
previous history; calculating one must not make it a previous operation of
another. The Child State records occupancy immediately before destruction
begins, not the state left by an arbitrary enumeration of individual
destructions.

### Destruction Contracts and destructors

A Destruction Contract records Destruction Facts and Child States, not an
additional execution order. A destructor behaves as an ordinary Action
Execution. Its accesses to contracted positions contribute dependencies under
the ordinary graph rules. Every dependency path strictly decreases recency, so
these accesses cannot create a path between identical-recency destructions. Its
written and automatic Particle Operations must be resolved using the ordinary
rules, and its requirements are verified using the recorded Child State and the
specification's contract rules.

## Limits of the resolved-history model

The occupancy induction is complete once a valid resolved history is supplied.
The resolved-history model alone does not establish the following claims about
every valid Define program execution:

1. every written Particle Operation, individual destruction from Simultaneous
   Transitive Destruction or Automatic Destruction, and destructor operation is
   represented exactly once;
2. the resolved meaning of “previous” preserves simultaneous individual
   destructions and dependency paths through destructor accesses, rather than
   replacing them with the serial model's strict total occurrence order;
3. the states at Action Requirement, Action Guarantee, and Destruction Contract
   boundaries agree with the resolved operation transitions; and
4. prefix replacement distinguishes separate local positions of Action
   Executions, preserves shared implied positions and reused interface
   positions, and preserves every parent and child relationship; and
5. the resolved position names that may be queried at each index are exactly
   those supplied by Position Definitions, Action Executions, valid position
   references, and Move name changes.

These are not missing specification requirements or consequences of graph
minimality. The serial model cannot represent simultaneous Destroys by replacing
their identical recency with its strict total order. It is therefore not the
source representation used for the requirement-based proof. The
[reference-shape](../theorems/reference-shape-proof.md),
[ordinary-requirements](../theorems/ordinary-requirements-proof.md), and
[retained-state](../theorems/retained-state-proof.md) arguments supply that
proof's source interpretation, while `particle_requirements.lean` and
`retained_requirements.lean` check the corresponding component transitions. This
does not turn the former resolved-history model into a source-language
formalization.
