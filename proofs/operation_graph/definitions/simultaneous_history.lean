import simultaneous_destruction
import valid_history

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

/-!
Steps are proof indices, not extra execution-order constraints. A destruction
step records its common before/after occupancy without putting its individual
destructions into an execution order.
-/

inductive ResolvedStep where
  | single (operation : ParticleOperation)
  | destruction (operations : List ParticleOperation)

def ResolvedStep.HasOperation (step : ResolvedStep) (operation : ParticleOperation) : Prop :=
  match step with
  | .single member => operation = member
  | .destruction members => operation ∈ members

def DestructionTargets (operations : List ParticleOperation) (position : Position) : Prop :=
  ∃ operation, operation ∈ operations ∧ operation.kind = .destroy position

def ResolvedStep.Enabled (step : ResolvedStep) (occupied : Position → Prop) : Prop :=
  match step with
  | .single operation =>
      (∀ position, operation.kind ≠ .destroy position) ∧ OperationEnabled operation occupied
  | .destruction operations =>
      (∀ operation, operation ∈ operations →
        ∃ position, operation.kind = .destroy position ∧ occupied position) ∧
      (∀ parent child, DestructionTargets operations parent →
        ParentOrSame parent child → occupied child → DestructionTargets operations child) ∧
      operations.Pairwise (fun first second => first.kind ≠ second.kind)

def ResolvedStep.OccupancyAfter (step : ResolvedStep)
    (occupied : Position → Prop) (position : Position) : Prop :=
  match step with
  | .single operation => Define.OperationGraph.OccupancyAfter operation occupied position
  | .destruction operations => occupied position ∧ ¬DestructionTargets operations position

theorem destructionTargets_permuted_iff
    {operations reordered : List ParticleOperation} (permuted : operations.Perm reordered)
    (position : Position) :
    DestructionTargets operations position ↔ DestructionTargets reordered position := by
  constructor
  · rintro ⟨operation, member, kind⟩
    exact ⟨operation, permuted.mem_iff.mp member, kind⟩
  · rintro ⟨operation, member, kind⟩
    exact ⟨operation, permuted.mem_iff.mpr member, kind⟩

theorem ResolvedStep.destruction_after_permutation
    {operations reordered : List ParticleOperation} (permuted : operations.Perm reordered)
    (occupied : Position → Prop) (position : Position) :
    (ResolvedStep.destruction operations).OccupancyAfter occupied position ↔
      (ResolvedStep.destruction reordered).OccupancyAfter occupied position := by
  simp only [ResolvedStep.OccupancyAfter, destructionTargets_permuted_iff permuted]

theorem ResolvedStep.destruction_matches_common_snapshot
    {operations : List ParticleOperation} {occupied : Position → Prop}
    (enabled : (ResolvedStep.destruction operations).Enabled occupied)
    (position : Position) :
    (ResolvedStep.destruction operations).OccupancyAfter occupied position ↔
      SimultaneousDestructionAfter occupied (DestructionTargets operations) position := by
  have selection_iff :
      SelectedForDestruction occupied (DestructionTargets operations) position ↔
        DestructionTargets operations position := by
    constructor
    · rintro ⟨present, parent, selected, parent_of_child⟩
      exact enabled.2.1 parent position selected parent_of_child present
    · intro selected
      rcases selected with ⟨operation, member, kind⟩
      rcases enabled.1 operation member with ⟨target, target_kind, present⟩
      have target_equal : target = position := ParticleOperationKind.destroy.inj (target_kind.symm.trans kind)
      exact ⟨target_equal ▸ present, position, ⟨operation, member, kind⟩, List.prefix_rfl⟩
  simp only [ResolvedStep.OccupancyAfter, SimultaneousDestructionAfter, selection_iff]

theorem ResolvedStep.empty_position_occupied
    {step : ResolvedStep} {operation : ParticleOperation}
    {occupied : Position → Prop} {position : Position}
    (enabled : step.Enabled occupied) (member : step.HasOperation operation)
    (empty_position : EmptyPosition operation = some position) : occupied position := by
  cases step with
  | single only =>
      subst operation
      exact operationEnabled_emptyPosition_occupied enabled.2 empty_position
  | destruction operations =>
      rcases enabled.1 operation member with ⟨target, kind, present⟩
      have target_equal : target = position := by
        simpa [EmptyPosition, kind] using empty_position
      exact target_equal ▸ present

theorem ResolvedStep.preserves_prefixClosure
    {step : ResolvedStep} {occupied : Position → Prop}
    (enabled : step.Enabled occupied) (prefix_closed : PrefixClosed occupied) :
    PrefixClosed (step.OccupancyAfter occupied) := by
  cases step with
  | single operation =>
      apply occupancyAfter_preserves_prefixClosure prefix_closed
      · exact fun _ position => operationEnabled_fillPosition_available enabled.2 position
      · exact fun _ _ kind => operationEnabled_move_source_not_parent_of_target enabled.2 kind
  | destruction operations =>
      intro parent child parent_of_child child_survives
      have parent_present := prefix_closed parent child parent_of_child child_survives.1
      refine ⟨parent_present, ?_⟩
      intro parent_selected
      exact child_survives.2 (enabled.2.1 parent child parent_selected parent_of_child child_survives.1)

theorem ResolvedStep.non_move_strict_child_unoccupied_after
    {step : ResolvedStep} {operation : ParticleOperation}
    {occupied : Position → Prop} {parent child : Position}
    (enabled : step.Enabled occupied) (prefix_closed : PrefixClosed occupied)
    (member : step.HasOperation operation) (not_move : ¬IsMove operation)
    (operates : OperatesOn operation parent) (parent_of_child : ParentOrSame parent child)
    (different : parent ≠ child) : ¬step.OccupancyAfter occupied child := by
  cases step with
  | single only =>
      subst operation
      cases kind : only.kind with
      | create target =>
          have parent_equal : parent = target := by simpa [OperatesOn, kind] using operates
          subst parent
          intro child_after
          simp only [ResolvedStep.OccupancyAfter, Define.OperationGraph.OccupancyAfter, kind] at child_after
          rcases child_after with child_equal | child_present
          · exact different child_equal.symm
          · exact (operationEnabled_fillPosition_empty enabled.2 (by simp [FillPosition, kind]))
              (prefix_closed target child parent_of_child child_present)
      | destroy target => exact False.elim (enabled.1 target kind)
      | move source target => exact False.elim (not_move ⟨source, target, kind⟩)
  | destruction operations =>
      rcases enabled.1 operation member with ⟨target, kind, _⟩
      have parent_equal : parent = target := by simpa [OperatesOn, kind] using operates
      subst parent
      intro child_after
      exact child_after.2
        (enabled.2.1 target child ⟨operation, member, kind⟩ parent_of_child child_after.1)

theorem ResolvedStep.newly_occupied_has_operation
    {step : ResolvedStep} {occupied : Position → Prop} {position : Position}
    (previously_empty : ¬occupied position) (now_occupied : step.OccupancyAfter occupied position) :
    ∃ operation operatedPosition,
      step.HasOperation operation ∧ OperatesOn operation operatedPosition ∧
        ParentOrSame operatedPosition position := by
  cases step with
  | destruction operations => exact False.elim (previously_empty now_occupied.1)
  | single operation =>
      cases kind : operation.kind with
      | create target =>
          change Define.OperationGraph.OccupancyAfter operation occupied position at now_occupied
          simp only [Define.OperationGraph.OccupancyAfter, kind] at now_occupied
          rcases now_occupied with rfl | already_present
          · exact ⟨operation, position, rfl, by simp [OperatesOn, kind], List.prefix_rfl⟩
          · exact False.elim (previously_empty already_present)
      | destroy target =>
          simp only [ResolvedStep.OccupancyAfter, Define.OperationGraph.OccupancyAfter, kind] at now_occupied
          exact False.elim (previously_empty now_occupied.2)
      | move source target =>
          change Define.OperationGraph.OccupancyAfter operation occupied position at now_occupied
          simp only [Define.OperationGraph.OccupancyAfter, kind] at now_occupied
          rcases now_occupied with ⟨suffix, position_equal, _⟩ | unchanged
          · exact ⟨operation, target, rfl, by simp [OperatesOn, kind],
              ⟨suffix, position_equal.symm⟩⟩
          · exact False.elim (previously_empty unchanged.2.2)

structure ResolvedStepHistory (isOperation : ParticleOperation → Prop) where
  stepAt : Nat → Option ResolvedStep
  occupiedBefore : Nat → Position → Prop
  member_step :
    ∀ operation, isOperation operation →
      ∃ step, stepAt operation.operationOrder = some step ∧ step.HasOperation operation
  step_member :
    ∀ index step operation, stepAt index = some step → step.HasOperation operation →
      isOperation operation ∧ operation.operationOrder = index
  initially_prefix_closed : PrefixClosed (occupiedBefore 0)
  step_enabled :
    ∀ index step, stepAt index = some step → step.Enabled (occupiedBefore index)
  step_transition :
    ∀ index step, stepAt index = some step →
      ∀ position, occupiedBefore (index + 1) position ↔ step.OccupancyAfter (occupiedBefore index) position
  no_step_transition :
    ∀ index, stepAt index = none →
      ∀ position, occupiedBefore (index + 1) position ↔ occupiedBefore index position

theorem ResolvedStepHistory.prefix_closed
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    (index : Nat) : PrefixClosed (history.occupiedBefore index) := by
  induction index with
  | zero => exact history.initially_prefix_closed
  | succ index induction_hypothesis =>
      cases step_at : history.stepAt index with
      | none =>
          intro parent child parent_of_child child_present
          exact (history.no_step_transition index step_at parent).mpr
            (induction_hypothesis parent child parent_of_child
              ((history.no_step_transition index step_at child).mp child_present))
      | some step =>
          have after_closed := ResolvedStep.preserves_prefixClosure
            (history.step_enabled index step step_at) induction_hypothesis
          intro parent child parent_of_child child_present
          exact (history.step_transition index step step_at parent).mpr
            (after_closed parent child parent_of_child
              ((history.step_transition index step step_at child).mp child_present))

def ResolvedStepHistory.toValidOccupancyTrace
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation) :
    ValidOccupancyTrace isOperation where
  occupiedBefore := history.occupiedBefore
  empty_position_is_occupied_before := by
    intro operation source member empty_position
    rcases history.member_step operation member with ⟨step, step_at, step_member⟩
    exact ResolvedStep.empty_position_occupied
      (history.step_enabled _ step step_at) step_member empty_position
  non_move_strict_child_unoccupied_after := by
    intro operation parent child member not_move operates parent_of_child different after
    rcases history.member_step operation member with ⟨step, step_at, step_member⟩
    exact ResolvedStep.non_move_strict_child_unoccupied_after
      (history.step_enabled _ step step_at) (history.prefix_closed _)
      step_member not_move operates parent_of_child different
      ((history.step_transition _ step step_at child).mp after)
  newly_occupied_has_operation := by
    intro index position previously_empty now_occupied
    cases step_at : history.stepAt index with
    | none =>
        exact False.elim
          (previously_empty ((history.no_step_transition index step_at position).mp now_occupied))
    | some step =>
        rcases ResolvedStep.newly_occupied_has_operation previously_empty
            ((history.step_transition index step step_at position).mp now_occupied) with
          ⟨operation, operatedPosition, member, operates, related⟩
        have operation_facts := history.step_member index step operation step_at member
        exact ⟨operation, operatedPosition, operation_facts.1, operation_facts.2, operates, Or.inl related⟩

theorem ResolvedStepHistory.fill_position_available
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {operation : ParticleOperation} {position : Position}
    (member : isOperation operation) (filled : FillPosition operation = some position) :
    Available (history.occupiedBefore operation.operationOrder) position := by
  rcases history.member_step operation member with ⟨step, step_at, operation_in_step⟩
  have enabled := history.step_enabled _ step step_at
  cases step with
  | single only =>
      subst operation
      exact operationEnabled_fillPosition_available enabled.2 filled
  | destruction operations =>
      rcases enabled.1 operation operation_in_step with ⟨target, kind, _⟩
      simp [FillPosition, kind] at filled

theorem ResolvedStepHistory.destroy_position_empty_after
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {operation : ParticleOperation} {position : Position}
    (member : isOperation operation) (kind : operation.kind = .destroy position) :
    ¬history.occupiedBefore (operation.operationOrder + 1) position := by
  rcases history.member_step operation member with ⟨step, step_at, operation_in_step⟩
  have enabled := history.step_enabled _ step step_at
  intro present
  have after := (history.step_transition _ step step_at position).mp present
  cases step with
  | single only =>
      subst operation
      exact enabled.1 position kind
  | destruction operations => exact after.2 ⟨operation, operation_in_step, kind⟩

theorem ResolvedStepHistory.newly_occupied_has_parent_operation
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {index : Nat} {position : Position}
    (previously_empty : ¬history.occupiedBefore index position)
    (now_occupied : history.occupiedBefore (index + 1) position) :
    ∃ operation operatedPosition, isOperation operation ∧ operation.operationOrder = index ∧
      OperatesOn operation operatedPosition ∧ ParentOrSame operatedPosition position := by
  cases step_at : history.stepAt index with
  | none =>
      exact False.elim
        (previously_empty ((history.no_step_transition index step_at position).mp now_occupied))
  | some step =>
      rcases ResolvedStep.newly_occupied_has_operation previously_empty
          ((history.step_transition index step step_at position).mp now_occupied) with
        ⟨operation, operatedPosition, member, operates, parent⟩
      have facts := history.step_member index step operation step_at member
      exact ⟨operation, operatedPosition, facts.1, facts.2, operates, parent⟩

theorem pairwise_kinds_unique {operations : List ParticleOperation}
    (distinct : operations.Pairwise (fun first second => first.kind ≠ second.kind))
    {first second : ParticleOperation} (first_member : first ∈ operations)
    (second_member : second ∈ operations) (same_kind : first.kind = second.kind) : first = second := by
  induction operations with
  | nil => simp at first_member
  | cons head tail induction_hypothesis =>
      rcases List.pairwise_cons.mp distinct with ⟨head_distinct, tail_distinct⟩
      rcases List.mem_cons.mp first_member with rfl | first_tail
      · rcases List.mem_cons.mp second_member with rfl | second_tail
        · rfl
        · exact False.elim (head_distinct second second_tail same_kind)
      · rcases List.mem_cons.mp second_member with rfl | second_tail
        · exact False.elim (head_distinct first first_tail same_kind.symm)
        · exact induction_hypothesis tail_distinct first_tail second_tail

theorem ResolvedStepHistory.same_order_equal_or_distinct_destroys
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {first second : ParticleOperation} (first_member : isOperation first)
    (second_member : isOperation second) (same_order : first.operationOrder = second.operationOrder) :
    first = second ∨ ∃ firstPosition secondPosition,
      first.kind = .destroy firstPosition ∧ second.kind = .destroy secondPosition ∧
        firstPosition ≠ secondPosition := by
  rcases history.member_step first first_member with ⟨step, step_at, first_in_step⟩
  rcases history.member_step second second_member with ⟨second_step, second_at, second_in_step⟩
  rw [← same_order, step_at] at second_at
  have equal := Option.some.inj second_at
  subst second_step
  have enabled := history.step_enabled _ step step_at
  cases step with
  | single only => exact Or.inl (first_in_step.trans second_in_step.symm)
  | destruction operations =>
      by_cases equal : first = second
      · exact Or.inl equal
      · rcases enabled.1 first first_in_step with ⟨firstPosition, first_kind, _⟩
        rcases enabled.1 second second_in_step with ⟨secondPosition, second_kind, _⟩
        refine Or.inr ⟨firstPosition, secondPosition, first_kind, second_kind, ?_⟩
        intro positions_equal
        subst secondPosition
        exact equal (pairwise_kinds_unique enabled.2.2 first_in_step second_in_step
          (first_kind.trans second_kind.symm))

end Define.OperationGraph
