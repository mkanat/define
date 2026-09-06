import entry_history
import ordered_calculations

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

def PositionEntryHistory.SourceCandidateAt
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    (operation candidate : ParticleOperation) (position : Position) : Prop :=
  isOperation operation ∧ ∃ target,
    EmptyPosition operation = some target ∧ Related position target ∧
      history.entriesBefore operation.operationOrder position = some candidate

def PositionEntryHistory.FillEntry
    {isOperation : ParticleOperation → Prop} (_history : PositionEntryHistory isOperation)
    (operation candidate : ParticleOperation) : Prop :=
  isOperation operation ∧ isOperation candidate ∧ MoreRecent operation candidate ∧
    ∃ target position, FillPosition operation = some target ∧
      OperatesOn candidate position ∧ ParentOrSame position target

theorem PositionEntryHistory.equal_of_same_order
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {first second : ParticleOperation} (first_member : isOperation first)
    (second_member : isOperation second) (same_order : first.operationOrder = second.operationOrder) :
    first = second := by
  have first_at := history.execution.member_operation_at first first_member
  have second_at := history.execution.member_operation_at second second_member
  rw [same_order] at first_at
  exact Option.some.inj (first_at.symm.trans second_at)

theorem PositionEntryHistory.fill_entry_facts
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {operation candidate : ParticleOperation} (entry : history.FillEntry operation candidate) :
    isOperation operation ∧ isOperation candidate ∧ MoreRecent operation candidate := by
  exact ⟨entry.1, entry.2.1, entry.2.2.1⟩

theorem PositionEntryHistory.most_recent_fill_unique
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {operation first second : ParticleOperation}
    (first_most_recent : IsMostRecent (history.FillEntry operation) first)
    (second_most_recent : IsMostRecent (history.FillEntry operation) second) : first = second := by
  rcases Nat.lt_trichotomy first.operationOrder second.operationOrder with earlier | equal | later
  · exact False.elim (first_most_recent.2 second second_most_recent.1 earlier)
  · exact history.equal_of_same_order (history.fill_entry_facts first_most_recent.1).2.1
      (history.fill_entry_facts second_most_recent.1).2.1 equal
  · exact False.elim (second_most_recent.2 first first_most_recent.1 later)

noncomputable def PositionEntryHistory.calculation
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    (operation : ParticleOperation) : RuleCalculation where
  operation := operation
  sourceCandidate := fun candidate => ∃ position, history.SourceCandidateAt operation candidate position
  fillCandidate := uniqueOption (IsMostRecent (history.FillEntry operation))

theorem PositionEntryHistory.fill_candidate_iff
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    (operation candidate : ParticleOperation) :
    (history.calculation operation).IsFillCandidate candidate ↔
      IsMostRecent (history.FillEntry operation) candidate := by
  exact uniqueOption_eq_some_iff (IsMostRecent (history.FillEntry operation))
    (fun _ _ => history.most_recent_fill_unique) candidate

theorem PositionEntryHistory.calculation_well_formed
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    (operation : ParticleOperation) : (history.calculation operation).WellFormed := by
  cases kind : operation.kind with
  | create target =>
      simp only [RuleCalculation.WellFormed, calculation, kind]
      change ∀ candidate, ¬∃ position, history.SourceCandidateAt operation candidate position
      rintro candidate ⟨position, _, emptied, empty_position, _, _⟩
      simp [EmptyPosition, kind] at empty_position
  | destroy target =>
      simp only [RuleCalculation.WellFormed, calculation, kind]
      change uniqueOption (IsMostRecent (history.FillEntry operation)) = none
      apply (uniqueOption_eq_none_iff _).mpr
      rintro candidate ⟨⟨_, _, _, filled, _, fill_position, _⟩, _⟩
      simp [FillPosition, kind] at fill_position
  | move source target => simp [RuleCalculation.WellFormed, calculation, kind]

theorem PositionEntryHistory.collection_facts
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {operation candidate : ParticleOperation} (in_collection : (history.calculation operation).InCollection candidate) :
    isOperation operation ∧ isOperation candidate ∧ MoreRecent operation candidate := by
  rcases in_collection with source | fill
  · rcases source with ⟨position, member, target, _, _, entry⟩
    have facts := history.entry_facts entry
    exact ⟨member, facts.1, facts.2.1⟩
  · exact history.fill_entry_facts ((history.fill_candidate_iff operation candidate).mp fill).1

noncomputable def PositionEntryHistory.orderedCalculations
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation) :
    OrderedCalculations isOperation where
  calculation := history.calculation
  calculation_operation := fun _ => rfl
  calculation_well_formed := history.calculation_well_formed
  collection_operations := by
    intro operation candidate collected
    have facts := history.collection_facts collected
    exact ⟨facts.1, facts.2.1⟩
  collection_previous := fun _ _ collected => (history.collection_facts collected).2.2

end Define.OperationGraph
