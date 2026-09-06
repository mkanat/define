import minimality
import step_calculation

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

noncomputable def StepPositionHistory.resolvedGraph
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation) :
    ResolvedDefineGraph where
  toRuleGraph := history.orderedCalculations.toRuleGraph
  occupancy := history.steps.toValidOccupancyTrace
  sourceCandidateAt := history.SourceCandidateAt
  source_candidate_iff := fun _ _ => Iff.rfl
  source_candidate_empty_position := by
    rintro operation candidate position ⟨_, target, emptied, related, _⟩
    exact ⟨target, emptied, related⟩
  source_candidate_operated_position := by
    rintro operation candidate position ⟨_, _, _, _, latest⟩
    exact latest.1.2.2.operated_parent
  non_move_source_candidate_operates_on_position := by
    rintro operation candidate position ⟨_, _, _, _, latest⟩ not_move
    exact latest.1.2.2.non_move_operates not_move
  source_candidate_is_previous := by
    rintro operation candidate position ⟨_, _, _, _, latest⟩
    exact latest.1.2.1
  source_candidate_operations := by
    rintro operation candidate position ⟨member, _, _, _, latest⟩
    exact ⟨member, latest.1.1⟩
  latest_source_candidate := by
    intro operation target position previousOperation operation_member previous_member
      emptied related operates previous
    rcases history.latest_source_candidate operation_member previous_member emptied related operates previous with
      ⟨candidate, collected, recent⟩
    exact ⟨candidate, position, collected, List.prefix_rfl, recent⟩
  fill_candidate_operated_position := by
    intro operation candidate fill
    rcases ((history.fill_candidate_iff operation candidate).mp fill).1 with
      ⟨_, _, _, target, position, filled, operates, parent⟩
    exact ⟨target, position, filled, operates, parent⟩
  fill_candidate_is_previous := by
    intro operation candidate fill
    exact ((history.fill_candidate_iff operation candidate).mp fill).1.2.2.1
  fill_candidate_operations := by
    intro operation candidate fill
    have entry := ((history.fill_candidate_iff operation candidate).mp fill).1
    exact ⟨entry.1, entry.2.1⟩

theorem StepPositionHistory.calculated_is_minimal_DAG
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation) :
    Acyclic history.orderedCalculations.Dependency ∧
      TransitivelyMinimal history.orderedCalculations.Dependency :=
  history.resolvedGraph.isMinimalDAG

theorem StepPositionHistory.no_path_between_same_step_operations
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {first second : ParticleOperation} (same_step : first.operationOrder = second.operationOrder) :
    ¬Reaches history.orderedCalculations.Dependency first second := by
  intro path
  have earlier := reaches_decreases_order history.orderedCalculations.pointsBackward path
  rw [same_step] at earlier
  exact Nat.lt_irrefl _ earlier

end Define.OperationGraph
