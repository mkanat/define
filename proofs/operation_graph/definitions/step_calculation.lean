import entry_update
import ordered_calculations
import simultaneous_history

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

structure StepPositionHistory (isOperation : ParticleOperation → Prop) where
  steps : ResolvedStepHistory isOperation
  definedBefore : Nat → Position → Prop

def StepPositionHistory.PreviousWriter
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    (index : Nat) (position : Position) (candidate : ParticleOperation) : Prop :=
  isOperation candidate ∧ candidate.operationOrder < index ∧
    EntryWrittenBy candidate (history.definedBefore candidate.operationOrder) position

def StepPositionHistory.SourceCandidateAt
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    (operation candidate : ParticleOperation) (position : Position) : Prop :=
  isOperation operation ∧ ∃ target, EmptyPosition operation = some target ∧
    Related position target ∧ IsMostRecent (history.PreviousWriter operation.operationOrder position) candidate

def StepPositionHistory.FillEntry
    {isOperation : ParticleOperation → Prop} (_history : StepPositionHistory isOperation)
    (operation candidate : ParticleOperation) : Prop :=
  isOperation operation ∧ isOperation candidate ∧ MoreRecent operation candidate ∧
    ∃ target position, FillPosition operation = some target ∧
      OperatesOn candidate position ∧ ParentOrSame position target

theorem StepPositionHistory.most_recent_writer_unique
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {index : Nat} {position : Position} {first second : ParticleOperation}
    (first_latest : IsMostRecent (history.PreviousWriter index position) first)
    (second_latest : IsMostRecent (history.PreviousWriter index position) second) : first = second := by
  rcases Nat.lt_trichotomy first.operationOrder second.operationOrder with earlier | equal | later
  · exact False.elim (first_latest.2 second second_latest.1 earlier)
  · rcases history.steps.same_order_equal_or_distinct_destroys first_latest.1.1 second_latest.1.1 equal with
      same | ⟨firstPosition, secondPosition, first_kind, second_kind, different⟩
    · exact same
    · have first_writes := first_latest.1.2.2
      have second_writes := second_latest.1.2.2
      simp [EntryWrittenBy, OperatesOn, first_kind] at first_writes
      simp [EntryWrittenBy, OperatesOn, second_kind] at second_writes
      exact False.elim (different (first_writes.symm.trans second_writes))
  · exact False.elim (second_latest.2 first first_latest.1 later)

theorem StepPositionHistory.latest_source_candidate
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation} {position target : Position}
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (emptied : EmptyPosition operation = some target) (related : Related position target)
    (operates : OperatesOn previousOperation position) (previous : MoreRecent operation previousOperation) :
    ∃ candidate, history.SourceCandidateAt operation candidate position ∧
      previousOperation.operationOrder ≤ candidate.operationOrder := by
  have previous_writer : history.PreviousWriter operation.operationOrder position previousOperation :=
    ⟨previous_member, previous, Or.inl operates⟩
  rcases exists_isMostRecent_of_bounded (history.PreviousWriter operation.operationOrder position)
      operation.operationOrder (fun _ writer => writer.2.1) ⟨previousOperation, previous_writer⟩ with
    ⟨candidate, latest⟩
  refine ⟨candidate, ⟨operation_member, target, emptied, related, latest⟩, ?_⟩
  by_cases recent : previousOperation.operationOrder ≤ candidate.operationOrder
  · exact recent
  · exact False.elim (latest.2 previousOperation previous_writer (by unfold MoreRecent; omega))

theorem StepPositionHistory.later_fill_after_destroyed_parent
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation destroyed : ParticleOperation} {parent target : Position}
    (operation_member : isOperation operation) (destroyed_member : isOperation destroyed)
    (destroy_kind : destroyed.kind = .destroy parent) (previous : MoreRecent operation destroyed)
    (filled : FillPosition operation = some target) (parent_of_target : ParentOrSame parent target)
    (strict : parent ≠ target) :
    ∃ candidate, history.FillEntry operation candidate ∧ MoreRecent candidate destroyed := by
  have empty_after := history.steps.destroy_position_empty_after destroyed_member destroy_kind
  have occupied_before := history.steps.fill_position_available operation_member filled parent
    parent_of_target strict
  rcases exists_occupancy_transition (fun index => history.steps.occupiedBefore index parent)
      (Nat.succ_le_of_lt previous) empty_after occupied_before with
    ⟨index, after_destroy, before_operation, empty_before, filled_after⟩
  rcases history.steps.newly_occupied_has_parent_operation empty_before filled_after with
    ⟨candidate, position, member, order, operates, parent_of_parent⟩
  exact ⟨candidate, ⟨operation_member, member, by unfold MoreRecent; omega,
    target, position, filled, operates, parent_of_parent.trans parent_of_target⟩,
    by unfold MoreRecent; omega⟩

theorem StepPositionHistory.most_recent_fill_unique
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation first second : ParticleOperation}
    (first_latest : IsMostRecent (history.FillEntry operation) first)
    (second_latest : IsMostRecent (history.FillEntry operation) second) : first = second := by
  rcases Nat.lt_trichotomy first.operationOrder second.operationOrder with earlier | equal | later
  · exact False.elim (first_latest.2 second second_latest.1 earlier)
  · rcases history.steps.same_order_equal_or_distinct_destroys first_latest.1.2.1
        second_latest.1.2.1 equal with same | ⟨firstPosition, secondPosition, first_kind, second_kind, different⟩
    · exact same
    · rcases first_latest.1 with ⟨operation_member, first_member, first_previous,
        target, firstOperated, filled, first_operates, first_parent⟩
      rcases second_latest.1 with ⟨_, second_member, second_previous,
        secondTarget, secondOperated, second_filled, second_operates, second_parent⟩
      have target_equal := Option.some.inj (second_filled.symm.trans filled)
      subst secondTarget
      have first_equal : firstOperated = firstPosition := by simpa [OperatesOn, first_kind] using first_operates
      have second_equal : secondOperated = secondPosition := by simpa [OperatesOn, second_kind] using second_operates
      subst firstOperated
      subst secondOperated
      rcases related_of_parentOrSame_of_parentOrSame first_parent second_parent with parent | parent
      · have strict : firstPosition ≠ target := by
          intro same_target
          subst target
          exact different (parentOrSame_antisymm parent second_parent)
        rcases history.later_fill_after_destroyed_parent operation_member first_member first_kind
            first_previous filled first_parent strict with ⟨candidate, entry, recent⟩
        exact False.elim (first_latest.2 candidate entry recent)
      · have strict : secondPosition ≠ target := by
          intro same_target
          subst target
          exact different (parentOrSame_antisymm first_parent parent)
        rcases history.later_fill_after_destroyed_parent operation_member second_member second_kind
            second_previous filled second_parent strict with ⟨candidate, entry, recent⟩
        exact False.elim (second_latest.2 candidate entry recent)
  · exact False.elim (second_latest.2 first first_latest.1 later)

noncomputable def StepPositionHistory.calculation
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    (operation : ParticleOperation) : RuleCalculation where
  operation := operation
  sourceCandidate := fun candidate => ∃ position, history.SourceCandidateAt operation candidate position
  fillCandidate := uniqueOption (IsMostRecent (history.FillEntry operation))

theorem StepPositionHistory.fill_candidate_iff
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    (operation candidate : ParticleOperation) :
    (history.calculation operation).IsFillCandidate candidate ↔
      IsMostRecent (history.FillEntry operation) candidate := by
  exact uniqueOption_eq_some_iff (IsMostRecent (history.FillEntry operation))
    (fun _ _ => history.most_recent_fill_unique) candidate

theorem StepPositionHistory.calculation_well_formed
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    (operation : ParticleOperation) : (history.calculation operation).WellFormed := by
  cases kind : operation.kind with
  | create target =>
      simp only [RuleCalculation.WellFormed, calculation, kind]
      rintro candidate ⟨position, _, emptied, empty_position, _⟩
      simp [EmptyPosition, kind] at empty_position
  | destroy target =>
      simp only [RuleCalculation.WellFormed, calculation, kind]
      apply (uniqueOption_eq_none_iff _).mpr
      rintro candidate ⟨⟨_, _, _, filled, _, fill_position, _⟩, _⟩
      simp [FillPosition, kind] at fill_position
  | move source target => simp [RuleCalculation.WellFormed, calculation, kind]

theorem StepPositionHistory.collection_facts
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation}
    (collected : (history.calculation operation).InCollection candidate) :
    isOperation operation ∧ isOperation candidate ∧ MoreRecent operation candidate := by
  rcases collected with ⟨position, member, _, _, _, latest⟩ | fill
  · exact ⟨member, latest.1.1, latest.1.2.1⟩
  · have latest := (history.fill_candidate_iff operation candidate).mp fill
    exact ⟨latest.1.1, latest.1.2.1, latest.1.2.2.1⟩

theorem StepPositionHistory.child_destroy_not_fill_candidate
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation childDestroy parentDestroy : ParticleOperation} {parent child : Position}
    (parent_member : isOperation parentDestroy)
    (child_kind : childDestroy.kind = .destroy child)
    (parent_kind : parentDestroy.kind = .destroy parent)
    (identical_recency : parentDestroy.operationOrder = childDestroy.operationOrder)
    (parent_of_child : ParentOrSame parent child) (strict : parent ≠ child) :
    ¬(history.calculation operation).IsFillCandidate childDestroy := by
  intro fill
  have latest := (history.fill_candidate_iff operation childDestroy).mp fill
  rcases latest.1 with ⟨operation_member, _, previous, target, position, filled, operates, child_of_target⟩
  have position_equal : position = child := by simpa [OperatesOn, child_kind] using operates
  subst position
  have parent_strict : parent ≠ target := by
    intro same
    subst target
    exact strict (parentOrSame_antisymm parent_of_child child_of_target)
  have parent_previous : MoreRecent operation parentDestroy := by
    unfold MoreRecent at *
    omega
  rcases history.later_fill_after_destroyed_parent operation_member parent_member parent_kind
      parent_previous filled (parent_of_child.trans child_of_target) parent_strict with
    ⟨newer, entry, recent⟩
  apply latest.2 newer entry
  unfold MoreRecent at *
  omega

theorem StepPositionHistory.child_destroy_not_afterComparison
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation childDestroy parentDestroy : ParticleOperation} {parent child : Position}
    (parent_member : isOperation parentDestroy)
    (child_kind : childDestroy.kind = .destroy child)
    (parent_kind : parentDestroy.kind = .destroy parent)
    (identical_recency : parentDestroy.operationOrder = childDestroy.operationOrder)
    (parent_of_child : ParentOrSame parent child) (strict : parent ≠ child) :
    ¬(history.calculation operation).AfterComparison childDestroy := by
  intro retained
  rcases retained.1 with source | fill
  · rcases source with ⟨position, operation_member, target, emptied, related, latest⟩
    have position_equal : position = child := by
      simpa [EntryWrittenBy, OperatesOn, child_kind] using latest.1.2.2
    subst position
    have parent_related : Related parent target := by
      rcases related with child_prefix | target_prefix
      · exact Or.inl (parent_of_child.trans child_prefix)
      · exact related_of_parentOrSame_of_parentOrSame parent_of_child target_prefix
    have parent_previous : MoreRecent operation parentDestroy := by
      have child_previous := latest.1.2.1
      unfold MoreRecent
      omega
    have parent_operates : OperatesOn parentDestroy parent := by simp [OperatesOn, parent_kind]
    rcases history.latest_source_candidate operation_member parent_member emptied parent_related
        parent_operates parent_previous with ⟨writer, candidate, at_least⟩
    have collected : (history.calculation operation).InCollection writer := Or.inl ⟨parent, candidate⟩
    rcases candidate with ⟨_, _, _, _, writer_latest⟩
    rcases Nat.lt_or_eq_of_le at_least with newer | equal
    · rcases EntryWrittenBy.operated_parent writer_latest.1.2.2 with
        ⟨operated, writer_operates, operated_of_parent⟩
      apply retained.2.1 writer collected
      · unfold MoreRecent
        omega
      · exact ⟨operated, child, writer_operates, by simp [OperatesOn, child_kind],
          Or.inl (operated_of_parent.trans parent_of_child)⟩
    · have parent_latest : IsMostRecent (history.PreviousWriter operation.operationOrder parent)
          parentDestroy := by
        refine ⟨⟨parent_member, parent_previous, Or.inl parent_operates⟩, ?_⟩
        intro newer newer_writer recent
        apply writer_latest.2 newer newer_writer
        unfold MoreRecent at *
        omega
      have same := history.most_recent_writer_unique writer_latest parent_latest
      subst writer
      exact retained.2.2 parentDestroy collected
        ⟨identical_recency, by simpa [child_kind, parent_kind] using And.intro parent_of_child strict⟩
  · exact history.child_destroy_not_fill_candidate parent_member child_kind parent_kind
      identical_recency parent_of_child strict fill

noncomputable def StepPositionHistory.orderedCalculations
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation) :
    OrderedCalculations isOperation where
  calculation := history.calculation
  calculation_operation := fun _ => rfl
  calculation_well_formed := history.calculation_well_formed
  collection_operations := fun _ _ collected =>
    ⟨(history.collection_facts collected).1, (history.collection_facts collected).2.1⟩
  collection_previous := fun _ _ collected => (history.collection_facts collected).2.2

end Define.OperationGraph
