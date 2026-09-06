import entry_calculation_correctness
import vanished_child_name_witness

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph.EntryRetirementWitness

open VanishedChildName

def definedBefore : Nat → Position → Prop
  | 1, position | 2, position | 3, position | 5, position =>
      position = [] ∨ position = parentPosition ∨ position = childPosition
  | _, position => position = [] ∨ position = parentPosition

def history : PositionEntryHistory isOperation where
  execution := occupancy
  definedBefore := definedBefore
theorem child_position_retires :
    history.definedBefore 3 childPosition ∧ ¬history.definedBefore 4 childPosition := by
  constructor
  · exact Or.inr (Or.inr rfl)
  · simp [history, definedBefore, childPosition, parentPosition]

theorem replacement_child_retains_previous_operation :
    history.entriesBefore 5 childPosition = some destroyChild := by
  simp [PositionEntryHistory.entriesBefore, history, occupancy, operationAt, definedBefore,
    entryAfter, EntryWrittenBy, OperatesOn, parentPosition, childPosition,
    destroyChild, destroyParent, recreateParent]

theorem recreated_parent_has_current_entry :
    history.entriesBefore 5 parentPosition = some recreateParent := by
  simp [PositionEntryHistory.entriesBefore, history, occupancy, operationAt, definedBefore,
    entryAfter, EntryWrittenBy, OperatesOn, recreateParent]

theorem old_child_destruction_is_collected :
    history.SourceCandidateAt destroyAgain destroyChild childPosition := by
  exact ⟨by simp [isOperation], parentPosition, rfl,
    Or.inr ⟨[0], rfl⟩, replacement_child_retains_previous_operation⟩

theorem parent_create_is_collected :
    history.SourceCandidateAt destroyAgain recreateParent parentPosition := by
  exact ⟨by simp [isOperation], parentPosition, rfl,
    Or.inl List.prefix_rfl, recreated_parent_has_current_entry⟩

theorem collection_iff (candidate : ParticleOperation) :
    (history.calculation destroyAgain).InCollection candidate ↔
      candidate = recreateParent ∨ candidate = destroyChild := by
  have no_fill : (history.calculation destroyAgain).fillCandidate = none :=
    history.calculation_well_formed destroyAgain
  constructor
  · rintro (⟨position, _, _, _, _, entry⟩ | fill)
    · by_cases at_parent : position = parentPosition
      · subst position
        exact Or.inl (Option.some.inj (recreated_parent_has_current_entry.symm.trans entry)).symm
      · by_cases at_child : position = childPosition
        · subst position
          exact Or.inr (Option.some.inj (replacement_child_retains_previous_operation.symm.trans entry)).symm
        · change history.entriesBefore 5 position = some candidate at entry
          simp [PositionEntryHistory.entriesBefore, history, occupancy, operationAt,
            entryAfter, EntryWrittenBy, OperatesOn, recreateParent, destroyParent,
            destroyChild, createChild, createParent, at_parent, at_child] at entry
    · simp [RuleCalculation.IsFillCandidate, no_fill] at fill
  · rintro (rfl | rfl)
    · exact Or.inl ⟨parentPosition, parent_create_is_collected⟩
    · exact Or.inl ⟨childPosition, old_child_destruction_is_collected⟩

theorem comparison_removes_old_child_destruction :
    ¬(history.calculation destroyAgain).AfterComparison destroyChild := by
  intro surviving
  exact surviving.2.1 recreateParent (Or.inl ⟨parentPosition, parent_create_is_collected⟩)
    (by change 2 < 4; decide)
    ⟨parentPosition, childPosition, rfl, rfl, Or.inl ⟨[0], rfl⟩⟩

theorem comparison_iff (candidate : ParticleOperation) :
    (history.calculation destroyAgain).AfterComparison candidate ↔ candidate = recreateParent := by
  constructor
  · intro surviving
    rcases (collection_iff candidate).mp surviving.1 with equal | equal
    · exact equal
    · subst candidate
      exact False.elim (comparison_removes_old_child_destruction surviving)
  · rintro rfl
    refine ⟨(collection_iff recreateParent).mpr (Or.inl rfl), ?_, ?_⟩
    · intro newer collected recent _
      rcases (collection_iff newer).mp collected with rfl | rfl
      · exact Nat.lt_irrefl _ recent
      · change 4 < 2 at recent
        omega
    · intro other _
      cases kind : other.kind <;> simp [SameRecencyParentDestroy, kind, recreateParent]

theorem dependency_iff_parent_create
    (dependency : ParticleOperation → ParticleOperation → Prop) (candidate : ParticleOperation) :
    (history.calculation destroyAgain).Dependency dependency candidate ↔ candidate = recreateParent := by
  change (history.calculation destroyAgain).AfterMoveCorrection dependency candidate ↔ _
  constructor
  · intro retained
    exact (comparison_iff candidate).mp retained.1
  · rintro rfl
    exact ⟨(comparison_iff recreateParent).mpr rfl, Or.inl (by simp [IsMove, recreateParent])⟩

theorem calculated_graph_is_minimal_DAG :
    Acyclic history.orderedCalculations.Dependency ∧
      TransitivelyMinimal history.orderedCalculations.Dependency :=
  history.calculated_is_minimal_DAG

end Define.OperationGraph.EntryRetirementWitness
