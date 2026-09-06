import comparison_completeness
import step_calculation

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

def HasSameRecencyParentDestroy (isOperation : ParticleOperation → Prop)
    (operation : ParticleOperation) : Prop :=
  ∃ parentOperation, isOperation parentOperation ∧ SameRecencyParentDestroy parentOperation operation

theorem sameRecencyParentDestroy_positions
    {parentOperation childOperation : ParticleOperation}
    (parent_destroy : SameRecencyParentDestroy parentOperation childOperation) :
    ∃ parent child,
      parentOperation.kind = .destroy parent ∧ childOperation.kind = .destroy child ∧
        ParentOrSame parent child ∧ parent ≠ child := by
  rcases parent_destroy with ⟨_, kinds⟩
  cases parent_kind : parentOperation.kind <;> cases child_kind : childOperation.kind <;>
    simp_all

def PreviousParentOperation (isOperation : ParticleOperation → Prop)
    (operation : ParticleOperation) (position : Position) (candidate : ParticleOperation) : Prop :=
  isOperation candidate ∧ MoreRecent operation candidate ∧
    ∃ operated, OperatesOn candidate operated ∧ ParentOrSame operated position

theorem StepPositionHistory.collected_parent_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation} {position target : Position}
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (emptied : EmptyPosition operation = some target) (related : Related position target)
    (operates : OperatesOn previousOperation position) (previous : MoreRecent operation previousOperation) :
    ∃ candidate operated,
      (history.calculation operation).InCollection candidate ∧
        ¬HasSameRecencyParentDestroy isOperation candidate ∧
        OperatesOn candidate operated ∧ ParentOrSame operated position ∧
        previousOperation.operationOrder ≤ candidate.operationOrder := by
  classical
  let eligible := PreviousParentOperation isOperation operation position
  have previous_eligible : eligible previousOperation :=
    ⟨previous_member, previous, position, operates, List.prefix_rfl⟩
  rcases exists_isMostRecent_of_bounded eligible operation.operationOrder
      (fun _ member => member.2.1) ⟨previousOperation, previous_eligible⟩ with ⟨latest, latest_recent⟩
  let lengths := fun length => ∃ candidate operated,
    IsMostRecent eligible candidate ∧ OperatesOn candidate operated ∧
      ParentOrSame operated position ∧ operated.length = length
  have some_length : ∃ length, lengths length := by
    rcases latest_recent.1.2.2 with ⟨operated, writes, parent⟩
    exact ⟨operated.length, latest, operated, latest_recent, writes, parent, rfl⟩
  have least_length : ∃ length, lengths length ∧ ∀ shorter, lengths shorter → length ≤ shorter := by
    rcases some_length with ⟨length, length_exists⟩
    induction length using Nat.strongRecOn with
    | ind length induction_hypothesis =>
        by_cases shorter_exists : ∃ shorter, shorter < length ∧ lengths shorter
        · rcases shorter_exists with ⟨shorter, smaller, exists_at_shorter⟩
          exact induction_hypothesis shorter smaller exists_at_shorter
        · refine ⟨length, length_exists, ?_⟩
          intro shorter exists_at_shorter
          by_cases at_least : length ≤ shorter
          · exact at_least
          · exact False.elim (shorter_exists ⟨shorter, by omega, exists_at_shorter⟩)
  rcases least_length with ⟨length, exists_at_length, least⟩
  rcases exists_at_length with
    ⟨candidate, operated, candidate_latest, candidate_operates, operated_parent, chosen_length⟩
  have no_parent : ¬HasSameRecencyParentDestroy isOperation candidate := by
    rintro ⟨parentOperation, parent_member, destroys⟩
    rcases sameRecencyParentDestroy_positions destroys with
      ⟨parent, child, parent_kind, child_kind, parent_of_child, different⟩
    have operated_equal : operated = child := by
      simpa [OperatesOn, child_kind] using candidate_operates
    subst child
    have parent_operates : OperatesOn parentOperation parent := by simp [OperatesOn, parent_kind]
    have parent_latest : IsMostRecent eligible parentOperation := by
      refine ⟨⟨parent_member, ?_, parent, parent_operates, parent_of_child.trans operated_parent⟩, ?_⟩
      · have recent := candidate_latest.1.2.1
        have same := destroys.1
        unfold MoreRecent at *
        omega
      · intro newer eligible_newer recent
        apply candidate_latest.2 newer eligible_newer
        have same := destroys.1
        unfold MoreRecent at *
        omega
    have shorter_choice : lengths parent.length :=
      ⟨parentOperation, parent, parent_latest, parent_operates,
        parent_of_child.trans operated_parent, rfl⟩
    have length_bound := least parent.length shorter_choice
    apply different
    exact parent_of_child.eq_of_length_le (by omega)
  have writer_latest : IsMostRecent (history.PreviousWriter operation.operationOrder operated)
      candidate := by
    refine ⟨⟨candidate_latest.1.1, candidate_latest.1.2.1, Or.inl candidate_operates⟩, ?_⟩
    intro newer writer recent
    rcases EntryWrittenBy.operated_parent writer.2.2 with ⟨name, writes, parent⟩
    exact candidate_latest.2 newer
      ⟨writer.1, writer.2.1, name, writes, parent.trans operated_parent⟩ recent
  have operated_related : Related operated target := by
    rcases related with position_parent | target_parent
    · exact Or.inl (operated_parent.trans position_parent)
    · exact related_of_parentOrSame_of_parentOrSame operated_parent target_parent
  refine ⟨candidate, operated, Or.inl ⟨operated, operation_member, target, emptied,
    operated_related, writer_latest⟩, no_parent, candidate_operates, operated_parent, ?_⟩
  by_cases at_least : previousOperation.operationOrder ≤ candidate.operationOrder
  · exact at_least
  · exact False.elim (candidate_latest.2 previousOperation previous_eligible
      (by unfold MoreRecent; omega))

theorem ResolvedStepHistory.parent_occupied_after_child_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {operation : ParticleOperation} {parent child : Position}
    (member : isOperation operation)
    (no_parent_destroy : ¬HasSameRecencyParentDestroy isOperation operation)
    (operates : OperatesOn operation child)
    (parent_of_child : ParentOrSame parent child) (strict : parent ≠ child) :
    history.occupiedBefore (operation.operationOrder + 1) parent := by
  rcases history.member_step operation member with ⟨step, step_at, in_step⟩
  have enabled := history.step_enabled _ step step_at
  have before_closed := history.prefix_closed operation.operationOrder
  have after_closed := history.prefix_closed (operation.operationOrder + 1)
  have transition := history.step_transition _ step step_at
  cases step with
  | destruction operations =>
      rcases enabled.1 operation in_step with ⟨target, kind, occupied⟩
      have target_equal : child = target := by simpa [OperatesOn, kind] using operates
      subst target
      apply (transition parent).mpr
      refine ⟨before_closed parent child parent_of_child occupied, ?_⟩
      rintro ⟨parentOperation, parent_in_step, parent_kind⟩
      have parent_facts := history.step_member _ _ parentOperation step_at parent_in_step
      exact no_parent_destroy ⟨parentOperation, parent_facts.1, parent_facts.2,
        by simpa [parent_kind, kind] using And.intro parent_of_child strict⟩
  | single only =>
      have same : operation = only := in_step
      subst only
      have not_child_parent : ¬ParentOrSame child parent :=
        fun child_parent => strict (parentOrSame_antisymm parent_of_child child_parent)
      cases kind : operation.kind with
      | destroy target => exact False.elim (enabled.1 target kind)
      | create target =>
          have target_equal : child = target := by simpa [OperatesOn, kind] using operates
          subst target
          apply after_closed parent child parent_of_child
          apply (transition child).mpr
          simp [ResolvedStep.OccupancyAfter, OccupancyAfter, kind]
      | move source target =>
          have source_occupied := operationEnabled_emptyPosition_occupied enabled.2
            (show EmptyPosition operation = some source by simp [EmptyPosition, kind])
          have target_empty := operationEnabled_fillPosition_empty enabled.2
            (show FillPosition operation = some target by simp [FillPosition, kind])
          rcases (show child = source ∨ child = target by simpa [OperatesOn, kind] using operates) with
            source_equal | target_equal
          · subst source
            have not_target_parent : ¬ParentOrSame target parent := by
              intro target_parent
              exact target_empty (before_closed target child (target_parent.trans parent_of_child)
                source_occupied)
            apply (transition parent).mpr
            simp only [ResolvedStep.OccupancyAfter, OccupancyAfter, kind]
            exact Or.inr ⟨not_child_parent, not_target_parent,
              before_closed parent child parent_of_child source_occupied⟩
          · subst target
            apply after_closed parent child parent_of_child
            apply (transition child).mpr
            simp only [ResolvedStep.OccupancyAfter, OccupancyAfter, kind]
            exact Or.inl ⟨[], by simp, by simpa using source_occupied⟩

theorem ResolvedStepHistory.newly_unoccupied_has_parent_operation
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {index : Nat} {position : Position}
    (occupied_before : history.occupiedBefore index position)
    (empty_after : ¬history.occupiedBefore (index + 1) position) :
    ∃ operation operated, isOperation operation ∧ operation.operationOrder = index ∧
      OperatesOn operation operated ∧ ParentOrSame operated position := by
  classical
  cases step_at : history.stepAt index with
  | none => exact False.elim (empty_after ((history.no_step_transition index step_at position).mpr occupied_before))
  | some step =>
      have empty_effect : ¬step.OccupancyAfter (history.occupiedBefore index) position :=
        fun effect => empty_after ((history.step_transition index step step_at position).mpr effect)
      cases step with
      | destruction operations =>
          have selected : DestructionTargets operations position :=
            Classical.byContradiction fun not_selected => empty_effect ⟨occupied_before, not_selected⟩
          rcases selected with ⟨operation, member, kind⟩
          have facts := history.step_member index _ operation step_at member
          exact ⟨operation, position, facts.1, facts.2, by simp [OperatesOn, kind], List.prefix_rfl⟩
      | single operation =>
          have facts := history.step_member index _ operation step_at rfl
          cases kind : operation.kind with
          | create target =>
              simp only [ResolvedStep.OccupancyAfter, OccupancyAfter, kind] at empty_effect
              exact False.elim (empty_effect (Or.inr occupied_before))
          | destroy target =>
              have enabled := history.step_enabled index _ step_at
              exact False.elim (enabled.1 target kind)
          | move source target =>
              simp only [ResolvedStep.OccupancyAfter, OccupancyAfter, kind] at empty_effect
              by_cases source_parent : ParentOrSame source position
              · exact ⟨operation, source, facts.1, facts.2, by simp [OperatesOn, kind], source_parent⟩
              · have target_parent : ParentOrSame target position :=
                  Classical.byContradiction fun not_target =>
                    empty_effect (Or.inr ⟨source_parent, not_target, occupied_before⟩)
                exact ⟨operation, target, facts.1, facts.2, by simp [OperatesOn, kind], target_parent⟩

theorem StepPositionHistory.fill_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation}
    (fill : (history.calculation operation).IsFillCandidate candidate) :
    ¬HasSameRecencyParentDestroy isOperation candidate := by
  rintro ⟨parentOperation, parent_member, destroys⟩
  rcases sameRecencyParentDestroy_positions destroys with
    ⟨parent, child, parent_kind, child_kind, parent_of_child, different⟩
  exact history.child_destroy_not_fill_candidate parent_member child_kind parent_kind
    destroys.1 parent_of_child different fill

theorem StepPositionHistory.related_same_recency_without_parent_destroys_equal
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {first second : ParticleOperation}
    (first_member : isOperation first) (second_member : isOperation second)
    (first_no_parent : ¬HasSameRecencyParentDestroy isOperation first)
    (second_no_parent : ¬HasSameRecencyParentDestroy isOperation second)
    (same_order : first.operationOrder = second.operationOrder)
    (related : OperationsRelated first second) : first = second := by
  rcases history.steps.same_order_equal_or_distinct_destroys first_member second_member same_order with
    same | ⟨firstPosition, secondPosition, first_kind, second_kind, different⟩
  · exact same
  · have positions_related : Related firstPosition secondPosition := by
      simpa [OperationsRelated, OperatesOn, first_kind, second_kind] using related
    rcases positions_related with first_parent | second_parent
    · exact False.elim (second_no_parent ⟨first, first_member, same_order,
        by simpa [first_kind, second_kind] using And.intro first_parent different⟩)
    · exact False.elim (first_no_parent ⟨second, second_member, same_order.symm,
        by simpa [first_kind, second_kind] using And.intro second_parent (Ne.symm different)⟩)

theorem StepPositionHistory.reaches_collected_without_parent_destroy_of_complete_before
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation candidate : ParticleOperation}
    (complete_before : ∀ newer older, isOperation newer → isOperation older →
      MoreRecent operation newer → MoreRecent newer older →
      ¬HasSameRecencyParentDestroy isOperation older → OperationsRelated newer older →
      Reaches history.orderedCalculations.Dependency newer older)
    (collected : (history.calculation operation).InCollection candidate)
    (no_parent : ¬HasSameRecencyParentDestroy isOperation candidate) :
    Reaches history.orderedCalculations.Dependency operation candidate := by
  classical
  let eligible := fun current => (history.calculation operation).InCollection current ∧
    ¬HasSameRecencyParentDestroy isOperation current ∧
      (current = candidate ∨ Reaches history.orderedCalculations.Dependency current candidate)
  rcases exists_isMostRecent_of_bounded eligible operation.operationOrder
      (fun _ member => (history.collection_facts member.1).2.2)
      ⟨candidate, collected, no_parent, Or.inl rfl⟩ with ⟨survivor, latest⟩
  have survivor_facts := history.collection_facts latest.1.1
  have survivor_retained : (history.calculation operation).AfterComparison survivor := by
    refine ⟨latest.1.1, ?_, ?_⟩
    · intro newer newer_collected recent related
      have newer_facts := history.collection_facts newer_collected
      have contradiction_of_candidate : ∀ replacement,
          (history.calculation operation).InCollection replacement →
          ¬HasSameRecencyParentDestroy isOperation replacement →
          MoreRecent replacement survivor → OperationsRelated replacement survivor → False := by
        intro replacement replacement_collected replacement_no_parent replacement_recent replacement_related
        have facts := history.collection_facts replacement_collected
        have path := complete_before replacement survivor facts.2.1 survivor_facts.2.1
          facts.2.2 replacement_recent latest.1.2.1 replacement_related
        have to_candidate : Reaches history.orderedCalculations.Dependency replacement candidate := by
          rcases latest.1.2.2 with same | tail
          · exact same ▸ path
          · exact path.trans tail
        exact latest.2 replacement
          ⟨replacement_collected, replacement_no_parent, Or.inr to_candidate⟩ replacement_recent
      by_cases newer_no_parent : ¬HasSameRecencyParentDestroy isOperation newer
      · exact contradiction_of_candidate newer newer_collected newer_no_parent recent related
      · have has_parent : HasSameRecencyParentDestroy isOperation newer :=
          Classical.byContradiction newer_no_parent
        rcases has_parent with ⟨parentOperation, parent_member, destroys⟩
        rcases sameRecencyParentDestroy_positions destroys with
          ⟨parent, child, parent_kind, child_kind, parent_of_child, different⟩
        rcases newer_collected with source | fill
        · rcases source with ⟨position, operation_member, target, emptied, position_related, writer_latest⟩
          have position_equal : position = child := by
            simpa [EntryWrittenBy, OperatesOn, child_kind] using writer_latest.1.2.2
          subst position
          rcases history.collected_parent_without_same_recency_parent_destroy operation_member
              newer_facts.2.1 emptied position_related
              (show OperatesOn newer child by simp [OperatesOn, child_kind]) newer_facts.2.2 with
            ⟨replacement, operated, replacement_collected, replacement_no_parent,
              replacement_operates, operated_parent, at_least⟩
          apply contradiction_of_candidate replacement replacement_collected replacement_no_parent
          · unfold MoreRecent at *
            omega
          · rcases related with ⟨newerPosition, survivorPosition, newer_operates, survivor_operates, related_positions⟩
            have newer_position_equal : newerPosition = child := by
              simpa [OperatesOn, child_kind] using newer_operates
            subst newerPosition
            refine ⟨operated, survivorPosition, replacement_operates, survivor_operates, ?_⟩
            rcases related_positions with child_parent | survivor_parent
            · exact Or.inl (operated_parent.trans child_parent)
            · exact related_of_parentOrSame_of_parentOrSame operated_parent survivor_parent
        · exact history.child_destroy_not_fill_candidate parent_member child_kind parent_kind
            destroys.1 parent_of_child different fill
    · intro other other_collected parent_destroy
      exact latest.1.2.1 ⟨other, (history.collection_facts other_collected).2.1, parent_destroy⟩
  have to_survivor := history.orderedCalculations.reaches_of_afterComparison survivor_retained
  rcases latest.1.2.2 with same | tail
  · exact same ▸ to_survivor
  · exact to_survivor.trans tail

theorem StepPositionHistory.reaches_source_related_of_complete_before
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation} {source position : Position}
    (complete_before : ∀ newer older, isOperation newer → isOperation older →
      MoreRecent operation newer → MoreRecent newer older →
      ¬HasSameRecencyParentDestroy isOperation older → OperationsRelated newer older →
      Reaches history.orderedCalculations.Dependency newer older)
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (previous_no_parent : ¬HasSameRecencyParentDestroy isOperation previousOperation)
    (previous : MoreRecent operation previousOperation)
    (emptied : EmptyPosition operation = some source)
    (operates : OperatesOn previousOperation position) (related : Related position source) :
    Reaches history.orderedCalculations.Dependency operation previousOperation := by
  rcases history.collected_parent_without_same_recency_parent_destroy operation_member previous_member
      emptied related operates previous with
    ⟨candidate, operated, collected, candidate_no_parent, candidate_operates, parent_of_position, at_least⟩
  have candidate_facts := history.collection_facts collected
  have candidate_related : OperationsRelated candidate previousOperation :=
    ⟨operated, position, candidate_operates, operates, Or.inl parent_of_position⟩
  have to_candidate := history.reaches_collected_without_parent_destroy_of_complete_before
    complete_before collected candidate_no_parent
  rcases Nat.lt_or_eq_of_le at_least with newer | same
  · exact to_candidate.trans (complete_before candidate previousOperation candidate_facts.2.1
      previous_member candidate_facts.2.2 newer previous_no_parent candidate_related)
  · have equal := history.related_same_recency_without_parent_destroys_equal
      candidate_facts.2.1 previous_member candidate_no_parent previous_no_parent same.symm candidate_related
    exact equal ▸ to_candidate

theorem ResolvedStepHistory.fill_position_empty
    {isOperation : ParticleOperation → Prop} (history : ResolvedStepHistory isOperation)
    {operation : ParticleOperation} {position : Position}
    (member : isOperation operation) (filled : FillPosition operation = some position) :
    ¬history.occupiedBefore operation.operationOrder position := by
  rcases history.member_step operation member with ⟨step, step_at, operation_in_step⟩
  have enabled := history.step_enabled _ step step_at
  cases step with
  | single only =>
      have same : operation = only := operation_in_step
      subst only
      exact operationEnabled_fillPosition_empty enabled.2 filled
  | destruction operations =>
      rcases enabled.1 operation operation_in_step with ⟨target, kind, _⟩
      simp [FillPosition, kind] at filled

theorem StepPositionHistory.exists_fill_candidate_at_least
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation} {target position : Position}
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (previous : MoreRecent operation previousOperation)
    (filled : FillPosition operation = some target)
    (operates : OperatesOn previousOperation position) (parent : ParentOrSame position target) :
    ∃ candidate, (history.calculation operation).IsFillCandidate candidate ∧
      previousOperation.operationOrder ≤ candidate.operationOrder := by
  have entry : history.FillEntry operation previousOperation :=
    ⟨operation_member, previous_member, previous, target, position, filled, operates, parent⟩
  rcases exists_isMostRecent_of_bounded (history.FillEntry operation) operation.operationOrder
      (fun _ member => member.2.2.1) ⟨previousOperation, entry⟩ with ⟨candidate, latest⟩
  refine ⟨candidate, (history.fill_candidate_iff operation candidate).mpr latest, ?_⟩
  by_cases at_least : previousOperation.operationOrder ≤ candidate.operationOrder
  · exact at_least
  · exact False.elim (latest.2 previousOperation entry (by unfold MoreRecent; omega))

theorem StepPositionHistory.reaches_fill_related_of_complete_before
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation} {target position : Position}
    (complete_before : ∀ newer older, isOperation newer → isOperation older →
      MoreRecent operation newer → MoreRecent newer older →
      ¬HasSameRecencyParentDestroy isOperation older → OperationsRelated newer older →
      Reaches history.orderedCalculations.Dependency newer older)
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (previous_no_parent : ¬HasSameRecencyParentDestroy isOperation previousOperation)
    (previous : MoreRecent operation previousOperation)
    (filled : FillPosition operation = some target)
    (operates : OperatesOn previousOperation position) (related : Related position target) :
    Reaches history.orderedCalculations.Dependency operation previousOperation := by
  have some_fill : ∃ candidate, (history.calculation operation).IsFillCandidate candidate ∧
      previousOperation.operationOrder ≤ candidate.operationOrder := by
    by_cases parent : ParentOrSame position target
    · exact history.exists_fill_candidate_at_least operation_member previous_member previous filled operates parent
    · have target_parent : ParentOrSame target position := related.resolve_left parent
      have strict : target ≠ position := by
        intro equal
        subst target
        exact parent List.prefix_rfl
      have occupied_after := history.steps.parent_occupied_after_child_without_same_recency_parent_destroy
        previous_member previous_no_parent operates target_parent strict
      have empty_before := history.steps.fill_position_empty operation_member filled
      rcases exists_emptying_transition (fun index => history.steps.occupiedBefore index target)
          (Nat.succ_le_of_lt previous) occupied_after empty_before with
        ⟨index, after_previous, before_operation, occupied, empty⟩
      rcases history.steps.newly_unoccupied_has_parent_operation occupied empty with
        ⟨intervening, operated, intervening_member, order, intervening_operates, intervening_parent⟩
      have intervening_previous : MoreRecent operation intervening := by unfold MoreRecent; omega
      rcases history.exists_fill_candidate_at_least operation_member intervening_member intervening_previous
          filled intervening_operates intervening_parent with ⟨candidate, fill, at_least⟩
      exact ⟨candidate, fill, by omega⟩
  rcases some_fill with ⟨candidate, fill, at_least⟩
  have candidate_no_parent := history.fill_without_same_recency_parent_destroy fill
  have candidate_facts := ((history.fill_candidate_iff operation candidate).mp fill).1
  rcases candidate_facts with
    ⟨_, candidate_member, candidate_previous, filledTarget, operated, candidate_fill, candidate_operates, parent⟩
  have target_equal := Option.some.inj (candidate_fill.symm.trans filled)
  subst filledTarget
  have candidate_related : OperationsRelated candidate previousOperation := by
    refine ⟨operated, position, candidate_operates, operates, ?_⟩
    rcases related with position_parent | target_parent
    · exact related_of_parentOrSame_of_parentOrSame parent position_parent
    · exact Or.inl (parent.trans target_parent)
  have to_candidate := history.reaches_collected_without_parent_destroy_of_complete_before
    complete_before (Or.inr fill) candidate_no_parent
  rcases Nat.lt_or_eq_of_le at_least with newer | same
  · exact to_candidate.trans (complete_before candidate previousOperation candidate_member previous_member
      candidate_previous newer previous_no_parent candidate_related)
  · have equal := history.related_same_recency_without_parent_destroys_equal candidate_member previous_member
      candidate_no_parent previous_no_parent same.symm candidate_related
    exact equal ▸ to_candidate

theorem StepPositionHistory.reaches_related_previous_without_same_recency_parent_destroy
    {isOperation : ParticleOperation → Prop} (history : StepPositionHistory isOperation)
    {operation previousOperation : ParticleOperation}
    (operation_member : isOperation operation) (previous_member : isOperation previousOperation)
    (previous_no_parent : ¬HasSameRecencyParentDestroy isOperation previousOperation)
    (previous : MoreRecent operation previousOperation)
    (related : OperationsRelated operation previousOperation) :
    Reaches history.orderedCalculations.Dependency operation previousOperation := by
  have main : ∀ index current, current.operationOrder = index → isOperation current →
      ∀ earlier, isOperation earlier → ¬HasSameRecencyParentDestroy isOperation earlier →
        MoreRecent current earlier → OperationsRelated current earlier →
        Reaches history.orderedCalculations.Dependency current earlier := by
    intro index
    induction index using Nat.strongRecOn with
    | ind index induction_hypothesis =>
        intro current current_order current_member earlier earlier_member earlier_no_parent previous related
        have complete_before : ∀ newer older, isOperation newer → isOperation older →
            MoreRecent current newer → MoreRecent newer older →
            ¬HasSameRecencyParentDestroy isOperation older → OperationsRelated newer older →
            Reaches history.orderedCalculations.Dependency newer older := by
          intro newer older newer_member older_member before_current before_newer no_parent pair_related
          exact induction_hypothesis newer.operationOrder (by unfold MoreRecent at before_current; omega)
            newer rfl newer_member older older_member no_parent before_newer pair_related
        rcases related with ⟨currentPosition, earlierPosition, current_operates, earlier_operates, positions_related⟩
        have related_reverse : Related earlierPosition currentPosition := positions_related.symm
        cases kind : current.kind with
        | create target =>
            have equal : currentPosition = target := by simpa [OperatesOn, kind] using current_operates
            subst target
            exact history.reaches_fill_related_of_complete_before complete_before current_member earlier_member
              earlier_no_parent previous (by simp [FillPosition, kind]) earlier_operates related_reverse
        | destroy target =>
            have equal : currentPosition = target := by simpa [OperatesOn, kind] using current_operates
            subst target
            exact history.reaches_source_related_of_complete_before complete_before current_member earlier_member
              earlier_no_parent previous (by simp [EmptyPosition, kind]) earlier_operates related_reverse
        | move source target =>
            rcases (show currentPosition = source ∨ currentPosition = target by
                simpa [OperatesOn, kind] using current_operates) with source_equal | target_equal
            · subst source
              exact history.reaches_source_related_of_complete_before complete_before current_member earlier_member
                earlier_no_parent previous (by simp [EmptyPosition, kind]) earlier_operates related_reverse
            · subst target
              exact history.reaches_fill_related_of_complete_before complete_before current_member earlier_member
                earlier_no_parent previous (by simp [FillPosition, kind]) earlier_operates related_reverse
  exact main operation.operationOrder operation rfl operation_member previousOperation previous_member
    previous_no_parent previous related

end Define.OperationGraph
