import simultaneous_destruction
import step_characterization
import witness_support

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph.StepHistoryWitness

def parent : Position := [0]
def child : Position := [0, 0]
def createChild : ParticleOperation := ⟨0, [], .create child⟩
def destroyParent : ParticleOperation := ⟨1, [], .destroy parent⟩
def destroyChild : ParticleOperation := ⟨1, [], .destroy child⟩

def isOperation (operation : ParticleOperation) : Prop :=
  operation = createChild ∨ operation = destroyParent ∨ operation = destroyChild

def occupiedBefore : Nat → Position → Prop
  | 0, position => position = [] ∨ position = parent
  | 1, position => position = [] ∨ position = parent ∨ position = child
  | _, position => position = []

def stepAt : Nat → Option ResolvedStep
  | 0 => some (.single createChild)
  | 1 => some (.destruction [destroyParent, destroyChild])
  | _ => none

def steps : ResolvedStepHistory isOperation where
  stepAt := stepAt
  occupiedBefore := occupiedBefore
  member_step := by
    intro operation member
    rcases member with rfl | rfl | rfl
    · exact ⟨.single createChild, rfl, rfl⟩
    · exact ⟨.destruction [destroyParent, destroyChild], rfl, by simp [ResolvedStep.HasOperation]⟩
    · exact ⟨.destruction [destroyParent, destroyChild], rfl, by simp [ResolvedStep.HasOperation]⟩
  step_member := by
    intro index step operation step_at member
    rcases index with _ | _ | index
    · have step_equal : step = .single createChild := (Option.some.inj step_at).symm
      subst step
      subst operation
      exact ⟨Or.inl rfl, rfl⟩
    · have step_equal : step = .destruction [destroyParent, destroyChild] := (Option.some.inj step_at).symm
      subst step
      rcases List.mem_cons.mp member with rfl | member
      · exact ⟨Or.inr (Or.inl rfl), rfl⟩
      · have equal : operation = destroyChild := List.mem_singleton.mp member
        subst operation
        exact ⟨Or.inr (Or.inr rfl), rfl⟩
    · simp [stepAt] at step_at
  initially_prefix_closed := by
    intro first second parent_of_child second_present
    rcases second_present with rfl | rfl
    · exact Or.inl (List.eq_nil_of_prefix_nil parent_of_child)
    · exact prefix_singleton_iff.mp parent_of_child
  step_enabled := by
    intro index step step_at
    rcases index with _ | _ | index
    · have equal : step = .single createChild := (Option.some.inj step_at).symm
      subst step
      refine ⟨?_, ?_, ?_⟩
      · intro position impossible
        cases impossible
      · intro position parent_of_child different
        rcases prefix_pair_iff.mp parent_of_child with rfl | rfl | rfl
        · exact Or.inl rfl
        · exact Or.inr rfl
        · exact False.elim (different rfl)
      · simp [occupiedBefore, parent, child]
    · have equal : step = .destruction [destroyParent, destroyChild] := (Option.some.inj step_at).symm
      subst step
      refine ⟨?_, ?_, ?_⟩
      · intro operation member
        rcases List.mem_cons.mp member with rfl | member
        · exact ⟨parent, rfl, Or.inr (Or.inl rfl)⟩
        · have equal : operation = destroyChild := List.mem_singleton.mp member
          subst operation
          exact ⟨child, rfl, Or.inr (Or.inr rfl)⟩
      · intro selectedPosition position selected parent_of_child present
        rcases present with rfl | rfl | rfl
        · have selected_empty := List.eq_nil_of_prefix_nil parent_of_child
          subst selectedPosition
          simp [DestructionTargets, destroyParent, destroyChild, parent, child] at selected
        · exact ⟨destroyParent, by simp, rfl⟩
        · exact ⟨destroyChild, by simp, rfl⟩
      · simp [destroyParent, destroyChild, parent, child]
    · simp [stepAt] at step_at
  step_transition := by
    intro index step step_at position
    rcases index with _ | _ | index
    · have equal : step = .single createChild := (Option.some.inj step_at).symm
      subst step
      simp [occupiedBefore, ResolvedStep.OccupancyAfter, OccupancyAfter, createChild,
        or_comm, or_assoc]
    · have equal : step = .destruction [destroyParent, destroyChild] := (Option.some.inj step_at).symm
      subst step
      simp only [occupiedBefore, ResolvedStep.OccupancyAfter]
      constructor
      · rintro rfl
        exact ⟨Or.inl rfl, by simp [DestructionTargets, destroyParent, destroyChild, parent, child]⟩
      · rintro ⟨present, not_selected⟩
        rcases present with rfl | rfl | rfl
        · rfl
        · exact False.elim (not_selected ⟨destroyParent, by simp, rfl⟩)
        · exact False.elim (not_selected ⟨destroyChild, by simp, rfl⟩)
    · simp [stepAt] at step_at
  no_step_transition := by
    intro index no_step position
    rcases index with _ | _ | index
    · simp [stepAt] at no_step
    · simp [stepAt] at no_step
    · rfl

def history : StepPositionHistory isOperation where
  steps := steps
  definedBefore := fun index position =>
    position = [] ∨ position = parent ∨ (index < 2 ∧ position = child)

theorem source_candidate_iff (operation : ParticleOperation)
    (selected : operation = destroyParent ∨ operation = destroyChild) (candidate : ParticleOperation) :
    (history.calculation operation).sourceCandidate candidate ↔ candidate = createChild := by
  have operation_order : operation.operationOrder = 1 := by rcases selected with rfl | rfl <;> rfl
  have writer_iff : ∀ position writer,
      history.PreviousWriter operation.operationOrder position writer ↔
        writer = createChild ∧ position = child := by
    intro position writer
    constructor
    · rintro ⟨member, previous, written⟩
      rcases member with rfl | rfl | rfl
      · exact ⟨rfl, by simpa [EntryWrittenBy, OperatesOn, createChild] using written⟩
      · simp [operation_order, destroyParent] at previous
      · simp [operation_order, destroyChild] at previous
    · rintro ⟨rfl, rfl⟩
      exact ⟨Or.inl rfl, by simp [operation_order, createChild], Or.inl rfl⟩
  constructor
  · rintro ⟨position, _, _, _, _, latest⟩
    exact ((writer_iff position candidate).mp latest.1).1
  · rintro rfl
    have latest : IsMostRecent (history.PreviousWriter operation.operationOrder child) createChild := by
      refine ⟨(writer_iff child createChild).mpr ⟨rfl, rfl⟩, ?_⟩
      intro newer writer recent
      have equal := ((writer_iff child newer).mp writer).1
      subst newer
      exact Nat.lt_irrefl _ recent
    rcases selected with rfl | rfl
    · exact ⟨child, Or.inr (Or.inl rfl), parent, rfl, Or.inr ⟨[0], rfl⟩, latest⟩
    · exact ⟨child, Or.inr (Or.inr rfl), child, rfl, related_refl child, latest⟩

theorem destruction_dependency_iff (operation : ParticleOperation)
    (selected : operation = destroyParent ∨ operation = destroyChild) (candidate : ParticleOperation) :
    history.orderedCalculations.Dependency operation candidate ↔ candidate = createChild := by
  have kind : ∃ position, operation.kind = .destroy position := by
    rcases selected with rfl | rfl
    · exact ⟨parent, rfl⟩
    · exact ⟨child, rfl⟩
  rcases kind with ⟨position, kind⟩
  have no_fill := history.calculation_well_formed operation
  simp only [RuleCalculation.WellFormed, StepPositionHistory.calculation, kind] at no_fill
  rw [history.orderedCalculations.exact_dependency]
  change (history.calculation operation).Dependency history.orderedCalculations.Dependency candidate ↔ _
  simp only [RuleCalculation.Dependency, StepPositionHistory.calculation, kind]
  change (history.calculation operation).AfterMoveCorrection history.orderedCalculations.Dependency candidate ↔ _
  constructor
  · intro retained
    rcases retained.1.1 with source | fill
    · exact (source_candidate_iff operation selected candidate).mp source
    · simp [RuleCalculation.IsFillCandidate, StepPositionHistory.calculation, no_fill] at fill
  · rintro rfl
    refine ⟨⟨Or.inl ((source_candidate_iff operation selected createChild).mpr rfl), ?_, ?_⟩,
      Or.inl (by simp [IsMove, createChild])⟩
    · intro newer collected recent _
      rcases collected with source | fill
      · have equal := (source_candidate_iff operation selected newer).mp source
        subst newer
        exact Nat.lt_irrefl _ recent
      · simp [RuleCalculation.IsFillCandidate, StepPositionHistory.calculation, no_fill] at fill
    · intro other _
      cases other_kind : other.kind <;> simp [SameRecencyParentDestroy, other_kind, createChild]

theorem same_step_destructions_are_unordered :
    ¬Reaches history.orderedCalculations.Dependency destroyParent destroyChild ∧
      ¬Reaches history.orderedCalculations.Dependency destroyChild destroyParent :=
  ⟨history.no_path_between_same_step_operations rfl, history.no_path_between_same_step_operations rfl⟩

theorem calculated_graph_is_minimal_DAG :
    Acyclic history.orderedCalculations.Dependency ∧
      TransitivelyMinimal history.orderedCalculations.Dependency :=
  history.calculated_is_minimal_DAG

def laterDestroy : ParticleOperation := ⟨2, [], .destroy []⟩

noncomputable def laterCalculation : RuleCalculation where
  operation := laterDestroy
  sourceCandidate := fun candidate => ∃ position,
    Related position [] ∧ IsMostRecent (history.PreviousWriter 2 position) candidate
  fillCandidate := none

theorem later_collection_iff (candidate : ParticleOperation) :
    laterCalculation.InCollection candidate ↔
      candidate = destroyParent ∨ candidate = destroyChild := by
  constructor
  · rintro (⟨position, _, latest⟩ | fill)
    · rcases latest.1.1 with rfl | rfl | rfl
      · have at_child : position = child := by
          simpa [EntryWrittenBy, OperatesOn, createChild] using latest.1.2.2
        subst position
        exact False.elim (latest.2 destroyChild
          ⟨Or.inr (Or.inr rfl), by decide, Or.inl rfl⟩ (by change 0 < 1; decide))
      · exact Or.inl rfl
      · exact Or.inr rfl
    · cases fill
  · intro selected
    have candidate_order : candidate.operationOrder = 1 := by
      rcases selected with rfl | rfl <;> rfl
    have no_newer : ∀ position newer, history.PreviousWriter 2 position newer →
        MoreRecent newer candidate → False := by
      intro position newer writer recent
      rw [MoreRecent, candidate_order] at recent
      have earlier := writer.2.1
      omega
    rcases selected with rfl | rfl
    · exact Or.inl ⟨parent, Or.inr List.nil_prefix,
        ⟨Or.inr (Or.inl rfl), by decide, Or.inl rfl⟩, no_newer parent⟩
    · exact Or.inl ⟨child, Or.inr List.nil_prefix,
        ⟨Or.inr (Or.inr rfl), by decide, Or.inl rfl⟩, no_newer child⟩

theorem later_comparison_iff (candidate : ParticleOperation) :
    laterCalculation.AfterComparison candidate ↔ candidate = destroyParent := by
  constructor
  · intro retained
    rcases (later_collection_iff candidate).mp retained.1 with equal | equal
    · exact equal
    · subst candidate
      apply False.elim
      apply retained.2.2 destroyParent ((later_collection_iff destroyParent).mpr (Or.inl rfl))
      exact ⟨rfl, ⟨[0], rfl⟩, by decide⟩
  · rintro rfl
    refine ⟨(later_collection_iff destroyParent).mpr (Or.inl rfl), ?_, ?_⟩
    · intro newer collected recent _
      rcases (later_collection_iff newer).mp collected with rfl | rfl <;>
        exact Nat.lt_irrefl _ recent
    · intro other collected
      rcases (later_collection_iff other).mp collected with rfl | rfl
      · exact sameRecencyParentDestroy_irrefl destroyParent
      · change ¬(1 = 1 ∧ ParentOrSame child parent ∧ child ≠ parent)
        simp [ParentOrSame, child, parent]

theorem later_destroy_dependency_iff (candidate : ParticleOperation) :
    laterCalculation.Dependency history.orderedCalculations.Dependency candidate ↔
      candidate = destroyParent := by
  change laterCalculation.AfterMoveCorrection history.orderedCalculations.Dependency candidate ↔ _
  constructor
  · intro retained
    exact (later_comparison_iff candidate).mp retained.1
  · rintro rfl
    exact ⟨(later_comparison_iff destroyParent).mpr rfl,
      Or.inl (by simp [IsMove, destroyParent])⟩

theorem occupancy_only_destruction_permutation :
    DestructionSequenceEnabled [parent, child, []] (occupiedBefore 1) ∧
      DestructionSequenceEnabled [[], parent, child] (occupiedBefore 1) ∧
      ∀ position,
        DestructionSequenceAfter [parent, child, []] (occupiedBefore 1) position ↔
          DestructionSequenceAfter [[], parent, child] (occupiedBefore 1) position := by
  constructor
  · apply destructionSequenceEnabled_of_nodup (by simp [parent, child])
    intro position member
    simpa [occupiedBefore, or_comm, or_left_comm, or_assoc] using member
  constructor
  · apply destructionSequenceEnabled_of_nodup (by simp [parent, child])
    intro position member
    simpa [occupiedBefore] using member
  · intro position
    simp [destructionSequenceAfter_iff, or_comm, or_left_comm, and_assoc]

theorem later_destroy_invalidates_parent_reference :
    ¬Available (IndividualDestructionAfter [] (occupiedBefore 1)) parent := by
  intro available
  have present := available [] List.nil_prefix (by simp [parent])
  exact present.1 rfl

end Define.OperationGraph.StepHistoryWitness
