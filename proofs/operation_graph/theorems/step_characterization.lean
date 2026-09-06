import characterization
import comparison_completeness
import step_completeness
import step_minimality

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

theorem StepPositionHistory.child_destroy_has_no_dependents
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation childDestroy parentDestroy : ParticleOperation} {parent child : Position}
    (parent_member : isOperation parentDestroy)
    (child_kind : childDestroy.kind = .destroy child)
    (parent_kind : parentDestroy.kind = .destroy parent)
    (identical_recency : parentDestroy.operationOrder = childDestroy.operationOrder)
    (parent_of_child : ParentOrSame parent child) (strict : parent ≠ child) :
    ¬history.orderedCalculations.Dependency operation childDestroy := by
  intro edge
  exact history.child_destroy_not_afterComparison parent_member child_kind parent_kind
    identical_recency parent_of_child strict
    (history.orderedCalculations.dependency_afterComparison edge)

theorem StepPositionHistory.child_destroy_has_no_path_to_it
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation childDestroy parentDestroy : ParticleOperation} {parent child : Position}
    (parent_member : isOperation parentDestroy)
    (child_kind : childDestroy.kind = .destroy child)
    (parent_kind : parentDestroy.kind = .destroy parent)
    (identical_recency : parentDestroy.operationOrder = childDestroy.operationOrder)
    (parent_of_child : ParentOrSame parent child) (strict : parent ≠ child) :
    ¬Reaches history.orderedCalculations.Dependency operation childDestroy := by
  intro path
  induction path with
  | direct edge =>
      exact history.child_destroy_has_no_dependents parent_member child_kind parent_kind
        identical_recency parent_of_child strict edge
  | step _ _ induction_hypothesis => exact induction_hypothesis child_kind identical_recency

theorem StepPositionHistory.reaches_iff_reaches_afterComparison
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation} :
    Reaches history.orderedCalculations.Dependency operation candidate ↔
      Reaches (fun current previous => (history.calculation current).AfterComparison previous)
        operation candidate :=
  history.orderedCalculations.reaches_iff_reaches_afterComparison

def RelatedPreviousWithoutSameRecencyParentDestroy
    (isOperation : ParticleOperation → Prop) (operation previousOperation : ParticleOperation) : Prop :=
  isOperation operation ∧ isOperation previousOperation ∧ RelatedPrevious operation previousOperation ∧
    ¬HasSameRecencyParentDestroy isOperation previousOperation

theorem StepPositionHistory.dependency_related_previous_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation}
    (edge : history.orderedCalculations.Dependency operation candidate) :
    RelatedPreviousWithoutSameRecencyParentDestroy isOperation operation candidate := by
  have members := history.resolvedGraph.directDependency_operations edge
  refine ⟨members.1, members.2, ⟨history.orderedCalculations.pointsBackward _ _ edge,
    history.resolvedGraph.directDependencyPositionsRelated edge⟩, ?_⟩
  rintro ⟨parentOperation, parent_member, destroys⟩
  rcases sameRecencyParentDestroy_positions destroys with
    ⟨parent, child, parent_kind, child_kind, parent_of_child, strict⟩
  exact history.child_destroy_has_no_dependents parent_member child_kind parent_kind
    destroys.1 parent_of_child strict edge

theorem StepPositionHistory.reaches_iff_related_previous_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation} :
    Reaches history.orderedCalculations.Dependency operation candidate ↔
      Reaches (RelatedPreviousWithoutSameRecencyParentDestroy isOperation) operation candidate := by
  constructor
  · exact Reaches.mono fun _ _ edge =>
      history.dependency_related_previous_without_same_recency_parent_destroy edge
  · intro path
    induction path with
    | direct pair =>
        exact history.reaches_related_previous_without_same_recency_parent_destroy
          pair.1 pair.2.1 pair.2.2.2 pair.2.2.1.1 pair.2.2.1.2
    | step pair _ induction_hypothesis =>
        exact (history.reaches_related_previous_without_same_recency_parent_destroy
          pair.1 pair.2.1 pair.2.2.2 pair.2.2.1.1 pair.2.2.1.2).trans induction_hypothesis

theorem StepPositionHistory.dependency_is_unique
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {otherDependency : ParticleOperation → ParticleOperation → Prop}
    (other_points_backward : PointsBackward ParticleOperation.operationOrder otherDependency)
    (other_minimal : TransitivelyMinimal otherDependency)
    (same_reachability : ∀ operation candidate,
      Reaches otherDependency operation candidate ↔
        Reaches (RelatedPreviousWithoutSameRecencyParentDestroy isOperation)
          operation candidate) :
    ∀ operation candidate, history.orderedCalculations.Dependency operation candidate ↔
      otherDependency operation candidate := by
  exact dependency_iff_unique history.orderedCalculations.pointsBackward other_points_backward
    history.calculated_is_minimal_DAG.2 other_minimal
    (fun operation candidate => history.reaches_iff_related_previous_without_same_recency_parent_destroy.trans
      (same_reachability operation candidate).symm)

end Define.OperationGraph
