import entry_calculation
import characterization

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

noncomputable def PositionEntryHistory.resolvedGraph
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation) :
    ResolvedDefineGraph where
  toRuleGraph := history.orderedCalculations.toRuleGraph
  occupancy := history.execution.toValidOccupancyTrace
  sourceCandidateAt := history.SourceCandidateAt
  source_candidate_iff := fun _ _ => Iff.rfl
  source_candidate_empty_position := by
    rintro operation candidate position ⟨_, target, emptied, related, _⟩
    exact ⟨target, emptied, related⟩
  source_candidate_operated_position := by
    rintro operation candidate position ⟨_, _, _, _, entry⟩
    exact (history.entry_facts entry).2.2.1
  non_move_source_candidate_operates_on_position := by
    rintro operation candidate position ⟨_, _, _, _, entry⟩ not_move
    exact (history.entry_facts entry).2.2.2 not_move
  source_candidate_is_previous := by
    rintro operation candidate position ⟨_, _, _, _, entry⟩
    exact (history.entry_facts entry).2.1
  source_candidate_operations := by
    rintro operation candidate position ⟨member, _, _, _, entry⟩
    exact ⟨member, (history.entry_facts entry).1⟩
  latest_source_candidate := by
    intro operation target position previousOperation operation_member previous_member
      emptied related operates previous
    rcases history.previous_operation_entry previous_member previous operates with
      ⟨candidate, entry, recent⟩
    exact ⟨candidate, position, ⟨operation_member, target, emptied, related, entry⟩,
      List.prefix_rfl, recent⟩
  fill_candidate_operated_position := by
    intro operation candidate fill
    have most_recent := (history.fill_candidate_iff operation candidate).mp fill
    rcases most_recent.1 with ⟨_, _, _, target, position, filled, operates, parent⟩
    exact ⟨target, position, filled, operates, parent⟩
  fill_candidate_is_previous := by
    intro operation candidate fill
    exact (history.fill_entry_facts ((history.fill_candidate_iff operation candidate).mp fill).1).2.2
  fill_candidate_operations := by
    intro operation candidate fill
    have facts := history.fill_entry_facts ((history.fill_candidate_iff operation candidate).mp fill).1
    exact ⟨facts.1, facts.2.1⟩

theorem PositionEntryHistory.latest_fill_candidate
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {operation previousOperation : ParticleOperation} {target position : Position}
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (filled : FillPosition operation = some target) (operates : OperatesOn previousOperation position)
    (parent : ParentOrSame position target) (previous : MoreRecent operation previousOperation) :
    ∃ candidate, (history.calculation operation).IsFillCandidate candidate ∧
      (candidate = previousOperation ∨ MoreRecent candidate previousOperation) := by
  have fill_entry : history.FillEntry operation previousOperation :=
    ⟨operation_member, previous_member, previous, target, position, filled, operates, parent⟩
  rcases exists_isMostRecent_of_bounded (history.FillEntry operation) operation.operationOrder
      (fun _ candidate_entry => (history.fill_entry_facts candidate_entry).2.2)
      ⟨previousOperation, fill_entry⟩ with ⟨candidate, most_recent⟩
  refine ⟨candidate, (history.fill_candidate_iff operation candidate).mpr most_recent, ?_⟩
  have previous_le_candidate : previousOperation.operationOrder ≤ candidate.operationOrder := by
    by_cases ordered : previousOperation.operationOrder ≤ candidate.operationOrder
    · exact ordered
    · exact False.elim (most_recent.2 previousOperation fill_entry (by unfold MoreRecent; omega))
  rcases Nat.eq_or_lt_of_le previous_le_candidate with equal | newer
  · exact Or.inl (history.equal_of_same_order (history.fill_entry_facts most_recent.1).2.1
      previous_member equal.symm)
  · exact Or.inr newer

noncomputable def PositionEntryHistory.completeGraph
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation) :
    CompleteResolvedDefineGraph where
  toResolvedDefineGraph := history.resolvedGraph
  execution := history.execution
  latest_fill_candidate := by
    intro operation target position previousOperation operation_member previous_member
      filled operates parent previous
    exact history.latest_fill_candidate operation_member previous_member filled operates parent previous

theorem PositionEntryHistory.calculated_is_minimal_DAG
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation) :
    Acyclic history.orderedCalculations.Dependency ∧
      TransitivelyMinimal history.orderedCalculations.Dependency :=
  history.resolvedGraph.isMinimalDAG

theorem PositionEntryHistory.calculated_reaches_iff
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {operation candidate : ParticleOperation} :
    Reaches history.orderedCalculations.Dependency operation candidate ↔
      Reaches (fun first second => isOperation first ∧ isOperation second ∧ RelatedPrevious first second)
        operation candidate :=
  history.completeGraph.reaches_iff_reaches_relatedPrevious

end Define.OperationGraph
