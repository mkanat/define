# Shared Definitions for the Operation Graph Proofs

## Purpose

The conceptual definitions apply throughout the operation graph proofs. The
resolved-name mathematical model later in this document describes the former
Fill, Empty, and Move calculation. The revised
[requirement construction](../theorems/requirement-construction.md) preserves
actual references and relative occupancy instead. Neither model may assume its
graph's correctness as a premise.

The relevant specification sections are:

- [Position References](../../../define/spec/spec.md#position-references);
- [Moving Particles](../../../define/spec/spec.md#moving-particles);
- [Destroying Particles](../../../define/spec/spec.md#destroying-particles);
- [Action Contracts](../../../define/spec/spec.md#action-contracts); and
- [Deterministic Automatic Concurrency](../../../define/spec/spec.md#deterministic-automatic-concurrency).

## Conceptual meaning of particles, positions, and operations

The mathematical representations below must preserve the following conceptual
meaning. This is the interpretation of the specification used by these proofs,
not an additional set of dependency rules.

A particle is a concrete thing that exists in the program's universe. It has
qualities, which can include defining positions and actions.

A position is a location in space that may be empty or occupied by one particle.
A particle can define other positions relative to itself, and those positions
may be occupied by other particles.

Replacing a particle does not by itself make its positions different spatial
locations. If a particle at `p` defines the position quality `/c`, and a
replacement particle at `p` defines that same quality, its `p::/c` is the same
spatial position. However, the specification's Simultaneous Transitive
Destruction rules distinguish the original particles from replacements. Once the
original parent's individual destruction empties `p`, its old child no longer
occupies the replacement's `p::/c`. Unfinished destruction work continues to act
on the original particles and positions, not on replacements. A model must
therefore distinguish occupancy available to subsequent operations from
particles and positions retained for unfinished destruction work.

The Particle Operations have these conceptual effects:

- **Create:** bring a new particle into existence in an empty position,
  assigning the required qualities.
- **Move:** move an existing particle from an occupied source to an empty
  destination, leaving the source empty. The particle retains its identity and
  qualities. The positions it defines move with it, along with the particles
  occupying those positions, transitively. Their spatial relationships to the
  moved particle remain unchanged; their spatial relationships to the rest of
  the universe change. Empty positions defined by the particle move too.
- **Destroy:** represent the selected particle vacating its position, not the
  end of its existence or completion of its destructors. The vacancies in a
  simultaneous destruction are selected from one common preceding state. A
  later-executing Destroy does not select a replacement particle. The original
  particles remain available to destructors as though in their positions
  immediately before destruction, including movements performed by those
  destructors. Actual destruction must respect the last interactions specified
  by Destruction Ordering During Destructors; it is not another interpretation
  of the vacancy vertex.

Position names and references describe these spatial relationships; they are not
the relationships themselves. When a particle moves from `a` to `b`, the change
from a child reference `a::c` to `b::c` represents movement, not merely a
different spelling for an unchanged location. Preserving a particle's identity
does not make it independently addressable at any position. In particular, a
written Destroy Particle Statement at `b::c` cannot execute while `b` is empty.
An additional child Destroy selected by simultaneous destruction has no newly
written `b::c` reference: it selects the original position defined by its parent
particle, which can itself move. These two kinds of occurrence must not be
identified merely because a displayed graph gives them the same full name.

### Correspondence required of every proof model

The [operation-requirement derivation](operation-requirements.md) distinguishes
the requirements of actual position references from particle identity and
existence requirements. In particular, preserving a direct implied-position
reference does not require preserving the defining particle's spatial location
in the serial reference execution.

These checks apply to existing English arguments and Lean formalizations as well
as new ones:

- Distinguish a particle's identity, its position, positions it defines, and the
  names used to describe those positions. State which of these each mathematical
  object represents.
- Represent a Move's transitive spatial effect, not just its source and
  destination occupancy or a renaming of an otherwise unchanged state. A model
  that records only occupied positions may omit empty positions only where that
  omission does not affect the property being proved.
- A reordered execution must execute the same Particle Operations with their
  required positions and occupancy. Do not silently retarget an operation or add
  an independent binding to a particle's identity to make a schedule work. For
  pending destruction work, use the specification's explicit preservation of the
  original particles and positions; do not look up replacements through their
  reused names. This exception does not waive a written reference's requirements
  at a Move destination. An implicit child selection, like a direct implied
  reference, does not acquire that written reference from its displayed name.
- Distinguish a completed simultaneous destruction from each individual
  destruction. A result about permuting only the selected Destroys does not
  establish that those Destroys may also be reordered across Creates or Moves.
- Distinguish a Destroy's vacancy from the end of the original particle's
  existence. A destructor's last-use requirement constrains the latter; it does
  not by itself impose an edge to or from the vacancy vertex. Destructors that
  interact with the same original particle share its changing state, not
  independent copies of the state before destruction.
- Separate graph facts from execution facts. Acyclicity, transitive minimality,
  and reachability characterization do not by themselves establish that the
  allowed executions preserve these concepts or provide maximum safe
  concurrency.

A representation is an abstraction of these concepts, not a replacement for
them. Its correspondence must be established for the claimed result before a
theorem about that representation is described as a theorem about Define.

## Scope

The specification defines a Particle Operation as a Create Particle Statement, a
Move Particle Statement, or an individual particle destruction. A Destroy
Particle Statement can therefore contribute several Particle Operations.

The serial model defined below predates that distinction: its Destroy transition
removes the target and its occupied transitive child positions in one step. This
is an aggregate occupancy transition, not the effect of each individual
destruction. Its completeness and scheduling theorems must not be applied to
simultaneous individual destructions by giving them arbitrary distinct
occurrence indices. See the
[simultaneous destruction proof](../theorems/simultaneous-destruction-proof.md)
for the individual transitions and their common-state interpretation.

The model does not treat an action as one operation. If an Action Execution
contributes five Particle Operations, those are five distinct occurrences. Two
Action Executions of the same Action Definition also contribute distinct
occurrences, even when they execute the same written statement.

Automatic Destruction selects the applicable particles simultaneously at the end
of an Action Statements Block. Particle Operations performed by a destructor are
ordinary resolved occurrences. When a Destruction Contract causes another
destructor to be verified at the recorded destruction, its Particle Operations
are likewise resolved at that destruction. The Destruction Contract, Destruction
Fact, and Child State are not themselves graph vertices.

Action Requirements and Action Guarantees are also not graph vertices. They
determine which source programs and Action Executions are valid and how a
callee's positions and Particle Operations are related to its caller. After
resolution, the graph contains only the resulting concrete Particle Operation
occurrences.

## Resolved positions

A _resolved position_ identifies the position on which a resolved Particle
Operation acts. Different Action Executions do not necessarily use different
resolved positions. For example, two actions can operate on the same implied
position of the same particle, and successive executions of one action reuse its
interface positions. Those accesses must retain the same resolved position so
the graph rules account for their previous Particle Operations.

For the proof, represent a resolved position by its sequence of position-name
components. Action names that occur between position names in Define syntax do
not add another position component. Components distinguish separate positions,
including different actions' interface positions and local positions belonging
to separate Action Executions, while preserving shared positions across
executions. Replacing a position's particle does not erase the most recent
previous Particle Operation at that position name. Constructing these components
from source remains part of the source-to-history obligations below.

Write

```text
p ⪯ q
```

when `p` is `q` or a transitive parent position of `q`. Equivalently, the
sequence for `p` is a prefix of the sequence for `q`. Write `p ≺ q` when `p` is
a strict transitive parent position of `q`.

Write

```text
p ~ q
```

when `p ⪯ q` or `q ⪯ p`. We then say that `p` and `q` are _related_. Relatedness
is reflexive and symmetric, but not transitive: two different child positions of
one parent position need not be related to each other.

When `p ⪯ q`, write `q = p · r`, where `r` is the remaining sequence of
position-name components. A Move from `p` to `t` moves each transitive child
position of the moved particle. The change from `p · r` to `t · r` represents
that spatial change. These sequences describe positions, not permanent particle
identities that can be used without regard to movement.

## Resolved Particle Operation occurrences

Let the occurrence indices be either a finite initial segment of the natural
numbers or all natural numbers. Write `Oᵢ` for the occurrence at index `i`, and
let `V` be the set of those occurrences. Each `Oᵢ` has exactly one of these
kinds:

```text
Create(p)
Destroy(p)
Move(s, t)
```

Define `positions(O)` as follows:

```text
positions(Create(p))  = {p}
positions(Destroy(p)) = {p}
positions(Move(s,t))  = {s,t}
```

Occurrences remain distinct even if their kinds and positions are equal.

Each occurrence also records its _Action Parent position_: the position of the
particle to which that occurrence's Action Execution is assigned. This is
metadata for the resolution definitions; the proofs excluding the Action Parent
Rule do not use it to constrain the occurrence's operated positions or supply
spatial relationships that have not been derived from the specification.

## The previous-operation order

The words “previous,” “most recent,” and “more recent” in the graph rules
require an order. Represent that order by listing the occurrences once, either
stopping after a finite number of occurrences or continuing without end:

```text
O₀, O₁, O₂, ...
```

Write `A < O` when `A` has the smaller index. A “previous operation” of `O` is
an `A` for which `A < O`. A most-recent member of a set is the member with the
greatest index. Every `Oᵢ` has exactly `i` previous occurrences. Therefore every
nonempty set of previous occurrences has a unique most-recent member even when
the complete history is infinite.

This is a _previous-operation order_, not a promise that a runtime executes all
operations sequentially in this order. The dependency graph exists to permit
other execution orders and concurrent execution.

For the serial model, source correspondence would have to derive this logical
order from the specification's rules taken together: Particle Operations in an
Action Statements Block have their logical statement order; Action Requirements
are satisfied before an action triggers; Action Guarantees become available
after the callee's relevant final operation; constructors have an assignment
order; destructors have stated timing; and the concurrency rules state when a
caller operation may proceed after a callee operation. The source-to-model proof
must compose those existing clauses and show that each use of “previous” by a
graph rule agrees with the resulting occurrence order. This cannot be done by
arbitrarily ordering simultaneous individual destructions. Only the Particle
Operation Dependency Graph rules order those destructions, including
dependencies resulting from a destructor's accesses to contracted positions. A
Destruction Contract records a Destruction Fact and Child State; it does not
impose an additional destruction order.

Nothing here says that an execution terminates. A nonterminating execution has
the infinite order `O₀, O₁, O₂, ...`. Quantifiers may likewise contribute an
unbounded number of occurrences. The proofs reason about an arbitrary occurrence
`Oᵢ` and its finite earlier prefix; they do not require a final occurrence or a
finite complete program execution.

## Occupancy states

An occupancy state `S` is the set of resolved positions that are occupied.

A position `p` is _available_ in `S` when every strict transitive parent
position needed to name `p` is occupied. A state is _prefix-closed_ when

```text
q in S and p ⪯ q imply p in S.
```

Prefix closure says that an occupied child position has every transitive parent
position required by its position reference.

The three Particle Operations have the following occupancy preconditions and
effects.

### Create

`Create(p)` requires `p` to be available and empty. Its next state is

```text
S union {p}.
```

Because `S` is prefix-closed, an empty `p` has no occupied transitive child
position.

### Destroy

The serial model's aggregate `Destroy(p)` requires `p` to be occupied. The
completed Simultaneous Transitive Destruction empties `p` and all its transitive
child positions. Its final state is

```text
{q in S | not p ⪯ q}.
```

This is the completed state change, not an individual graph vertex's effect. An
individual destruction at `q` removes only `q` from the selected occupancy; each
other selected particle has its own destruction. Prefix closure is required at
the common-state boundaries, not between arbitrarily scheduled individual
destructions. Destructor operations must also respect their graph dependencies.

### Move

`Move(s,t)` requires:

- `s` to be occupied;
- `t` to be available and empty;
- `s` and `t` to be different; and
- `s` not to be a prefix of `t`.

The last condition is the specification's prohibition against moving a particle
to a position it defines. Prefix closure and the other preconditions also rule
out `t` being a strict transitive parent position of `s`: such a `t` would have
to be occupied. Therefore the source and target positions of a valid Move are
unrelated.

For every occupied `s · r`, the next state has `t · r`. Occupied positions that
do not have `s` as a prefix are unchanged. In set notation, the next state is

```text
{t · r | s · r in S}
  union {q in S | not s ⪯ q and not t ⪯ q}.
```

This represents movement of the particle and the occupied positions it defines
transitively, preserving their relative spatial relationships. It is not merely
a renaming of stationary particles and positions. The second condition on the
unchanged set removes the old occupied target-based names before the moved
occupancy is added. A valid pre-Move state already has no such occupied
positions, because the target is empty and the state is prefix-closed. The set
records occupancy only; it does not separately represent particle identity or
the movement of empty positions. Claims requiring those distinctions need a
correspondence argument beyond this transition.

Destination Position Constraints and particle qualities affect whether source
code is valid, but they do not change this occupancy transition.

## Resolved histories

A _resolved history_ consists of:

1. occurrences indexed by a finite initial segment of the natural numbers or by
   all natural numbers;
2. a state `Sᵢ` before every `Oᵢ` and a state `Sᵢ₊₁` after it;
3. for each index `i`, the resolved position names whose most-recent Particle
   Operation may be queried immediately before `Oᵢ`; and
4. the Action Parent position of every occurrence.

`Sᵢ` is the state immediately before `Oᵢ`, and `Sᵢ₊₁` is the state after it. A
resolved history is _valid_ when:

- `S₀` is prefix-closed;
- every occupied and operated position has a resolved name that may be queried
  at the corresponding index;
- a resolved name operated on at an earlier index remains queryable at every
  later index, even while its position is empty;
- the set of names that may be queried is prefix-closed;
- every `Oᵢ` satisfies its occupancy preconditions in `Sᵢ`;
- `Sᵢ₊₁` is exactly the state produced by the operation's effect;
- the history contains every Particle Operation occurrence contributed by its
  resolved Action Executions and destructions, exactly once.

This definition mentions no dependency edge and no graph rule.

The set of names that may be queried is not an occupancy state. Its final
position may be empty. Source resolution derives the set from Position
Definitions, Action Executions, the position-reference rules, and Move name
changes. In particular, a Move changes the names of positions already defined by
the moved particle; it does not retroactively change a resolved position name
first contributed by a later Action Execution.

The Lean representation pads a finite history with indices containing no
operation and requires the occupancy state to remain unchanged at those indices.
The padding does not add occurrences; it only lets finite and unbounded
histories use the same natural-number-indexed state function.

## Dependency graphs

A dependency graph has vertex set `V`. Write

```text
O -> D
```

when `O` directly depends on `D`. The edge direction means that `D` must execute
before `O`.

Write `O > D` when there is a nonempty directed path from `O` to `D`. The graph
is acyclic when no `O > O`. It is _transitively minimal_ when removing any
direct edge changes reachability. This is equivalent to saying that no direct
edge has an alternate path between the same two occurrences, even for an
infinite graph, because every graph path is finite.

Define the rule-independent relation `R` by

```text
O R A exactly when A < O and
some p in positions(O) and q in positions(A) satisfy p ~ q.
```

`R` depends only on the resolved history's previous-operation order and operated
positions. It does not depend on the Fill, Empty, or Move Rules.

The serial model's completeness theorem proves every `R` pair reachable. This is
not the correct universal completeness claim for simultaneous individual
destruction: arbitrary enumeration can create an `R` pair where the
specification requires no path. The minimality theorem must independently prove
that no direct edge calculated by the rules is redundant. Only the later
characterization theorem may combine those results.

Minimality and completeness proceed by induction on the natural index of the
operation under consideration, so neither result needs the whole history to be
finite. The maximum-safe-concurrency argument likewise proves each finite prefix
by finitely many adjacent exchanges; this determines every observation in an
unbounded schedule without asserting a final state.

## Boundaries that later proofs must discharge

These shared definitions leave four separate obligations visible:

1. **Source correspondence.** Resolving valid Define source must produce a valid
   finite or infinite history whose occurrence order agrees with the
   specification's sequencing rules.
2. **Calculation correctness.** Applying the three resolved graph rules to any
   valid history must produce exactly the calculation used by the graph proofs.
3. **Graph results.** Minimality and completeness must be proved independently
   for that calculated graph.
4. **Compiler conformance.** Observable compiler behavior must agree with the
   specification-level calculation.

The Lean definitions, valid-history structure, and graph calculation begin after
the first boundary. The calculation derives its candidate selections from the
history instead of accepting them as fields. The next construction-correctness
component must prove that the calculated graph satisfies the obligations still
accepted as fields by the downstream minimality and completeness structures.
