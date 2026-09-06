import definitions

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

/-!
Positions identify the original particles in the common pre-destruction state.
During individual execution the predicate records unprocessed vacancy vertices,
not particle lifetimes or occupancy available to replacements. Removing another
selected position here would incorrectly discard its unprocessed vertex.
Interleaved replacements and destructor actions require a separate execution
model.
-/

def SelectedForDestruction (occupied targets : Position → Prop)
    (position : Position) : Prop :=
  occupied position ∧ ∃ target, targets target ∧ ParentOrSame target position

def IndividualDestructionAfter (target : Position)
    (occupied : Position → Prop) (position : Position) : Prop :=
  position ≠ target ∧ occupied position

def SimultaneousDestructionAfter (occupied targets : Position → Prop)
    (position : Position) : Prop :=
  occupied position ∧ ¬SelectedForDestruction occupied targets position

def DestructionSequenceAfter : List Position → (Position → Prop) → Position → Prop
  | [], occupied => occupied
  | target :: remaining, occupied =>
      DestructionSequenceAfter remaining (IndividualDestructionAfter target occupied)

inductive DestructionSequenceEnabled : List Position → (Position → Prop) → Prop
  | nil (occupied : Position → Prop) : DestructionSequenceEnabled [] occupied
  | cons {target : Position} {remaining : List Position} {occupied : Position → Prop}
      (target_occupied : occupied target)
      (remaining_enabled :
        DestructionSequenceEnabled remaining (IndividualDestructionAfter target occupied)) :
      DestructionSequenceEnabled (target :: remaining) occupied

theorem individualDestruction_preserves_other_occupancy
    {target position : Position} {occupied : Position → Prop}
    (different : position ≠ target) :
    IndividualDestructionAfter target occupied position ↔ occupied position := by
  simp [IndividualDestructionAfter, different]

theorem individualDestructions_commute (first second : Position)
    (occupied : Position → Prop) (position : Position) :
    IndividualDestructionAfter second
        (IndividualDestructionAfter first occupied) position ↔
      IndividualDestructionAfter first
        (IndividualDestructionAfter second occupied) position := by
  simp only [IndividualDestructionAfter]
  exact and_left_comm

theorem destructionSequenceAfter_iff (positions : List Position)
    (occupied : Position → Prop) (position : Position) :
    DestructionSequenceAfter positions occupied position ↔
      occupied position ∧ position ∉ positions := by
  induction positions generalizing occupied with
  | nil => simp [DestructionSequenceAfter]
  | cons target remaining induction_hypothesis =>
      rw [DestructionSequenceAfter, induction_hypothesis]
      simp only [IndividualDestructionAfter, List.mem_cons, not_or]
      constructor
      · rintro ⟨⟨different, present⟩, not_remaining⟩
        exact ⟨present, different, not_remaining⟩
      · rintro ⟨present, different, not_remaining⟩
        exact ⟨⟨different, present⟩, not_remaining⟩

theorem destructionSequenceEnabled_of_nodup
    {positions : List Position} {occupied : Position → Prop}
    (distinct : positions.Nodup)
    (all_occupied : ∀ position, position ∈ positions → occupied position) :
    DestructionSequenceEnabled positions occupied := by
  induction positions generalizing occupied with
  | nil => exact .nil occupied
  | cons target remaining induction_hypothesis =>
      have distinct_parts := List.nodup_cons.mp distinct
      apply DestructionSequenceEnabled.cons (all_occupied target List.mem_cons_self)
      apply induction_hypothesis distinct_parts.2
      intro position position_member
      refine ⟨?_, all_occupied position (List.mem_cons_of_mem target position_member)⟩
      intro same
      exact distinct_parts.1 (same ▸ position_member)

theorem simultaneousDestruction_exact_individual_execution
    {occupied targets : Position → Prop} {positions : List Position}
    (distinct : positions.Nodup)
    (exact_selection :
      ∀ position, position ∈ positions ↔ SelectedForDestruction occupied targets position) :
    DestructionSequenceEnabled positions occupied ∧
      ∀ position,
        DestructionSequenceAfter positions occupied position ↔
          SimultaneousDestructionAfter occupied targets position := by
  constructor
  · apply destructionSequenceEnabled_of_nodup distinct
    intro position position_member
    exact ((exact_selection position).mp position_member).1
  · intro position
    rw [destructionSequenceAfter_iff, exact_selection]
    rfl

theorem simultaneousDestruction_permuted_execution
    {occupied targets : Position → Prop} {positions schedule : List Position}
    (distinct : positions.Nodup)
    (exact_selection :
      ∀ position, position ∈ positions ↔ SelectedForDestruction occupied targets position)
    (permuted : positions.Perm schedule) :
    DestructionSequenceEnabled schedule occupied ∧
      ∀ position,
        DestructionSequenceAfter schedule occupied position ↔
          SimultaneousDestructionAfter occupied targets position := by
  apply simultaneousDestruction_exact_individual_execution
    (permuted.nodup_iff.mp distinct)
  intro position
  exact (permuted.mem_iff).symm.trans (exact_selection position)

theorem simultaneousDestruction_preserves_prefixClosure
    {occupied targets : Position → Prop} (prefix_closed : PrefixClosed occupied) :
    PrefixClosed (SimultaneousDestructionAfter occupied targets) := by
  intro parent child parent_of_child child_survives
  have parent_occupied := prefix_closed parent child parent_of_child child_survives.1
  refine ⟨parent_occupied, ?_⟩
  rintro ⟨_, target, target_selected, target_of_parent⟩
  exact child_survives.2
    ⟨child_survives.1, target, target_selected, target_of_parent.trans parent_of_child⟩

theorem simultaneousDestruction_single_target
    (occupied : Position → Prop) (target position : Position)
    (operation : ParticleOperation) (destroy_kind : operation.kind = .destroy target) :
    SimultaneousDestructionAfter occupied (fun selected => selected = target) position ↔
      OccupancyAfter operation occupied position := by
  simp only [SimultaneousDestructionAfter, SelectedForDestruction,
    OccupancyAfter, destroy_kind]
  constructor
  · rintro ⟨present, not_selected⟩
    exact ⟨fun parent => not_selected ⟨present, target, rfl, parent⟩, present⟩
  · rintro ⟨not_child, present⟩
    refine ⟨present, ?_⟩
    rintro ⟨_, selected, rfl, child⟩
    exact not_child child

theorem simultaneousDestruction_parent_first :
    DestructionSequenceEnabled [[0], [0, 0]]
        (fun position => position = [] ∨ position = [0] ∨ position = [0, 0]) ∧
      ∀ position,
        DestructionSequenceAfter [[0], [0, 0]]
            (fun position => position = [] ∨ position = [0] ∨ position = [0, 0])
            position ↔
          SimultaneousDestructionAfter
            (fun position => position = [] ∨ position = [0] ∨ position = [0, 0])
            (fun position => position = [0]) position := by
  apply simultaneousDestruction_exact_individual_execution (by decide)
  intro position
  simp only [List.mem_cons, List.not_mem_nil, or_false,
    SelectedForDestruction]
  constructor
  · rintro (rfl | rfl)
    · exact ⟨Or.inr (Or.inl rfl), [0], rfl, List.prefix_rfl⟩
    · exact ⟨Or.inr (Or.inr rfl), [0], rfl, ⟨[0], rfl⟩⟩
  · rintro ⟨present, target, rfl, parent⟩
    rcases present with rfl | rfl | rfl
    · simp [ParentOrSame] at parent
    · exact Or.inl rfl
    · exact Or.inr rfl

end Define.OperationGraph
