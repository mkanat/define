import calculation

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

/-!
Individual destructions with identical recency query the common previous entries.
Merely enumerating their calculation must not publish one destruction's entry
before calculating another. Destructor accesses contribute ordinary Particle
Operation dependencies, which also point to strictly earlier operations. This
construction proves facts about a common query state, not that every destructor
can be resolved from source into the model.
-/

def simultaneousDestroyCalculation
    (entries : Position → Option ParticleOperation)
    (queryable : Position → Prop) (operation : ParticleOperation)
    (target : Position) : RuleCalculation where
  operation := operation
  sourceCandidate := fun candidate =>
    ∃ position, queryable position ∧ Related position target ∧
      entries position = some candidate
  fillCandidate := none

def SimultaneousDestroyDependency
    (entries : Position → Option ParticleOperation)
    (queryable : Position → Prop)
    (priorDependency : ParticleOperation → ParticleOperation → Prop)
    (selected : ParticleOperation → Prop)
    (operation candidate : ParticleOperation) : Prop :=
  selected operation ∧ ∃ target,
    operation.kind = .destroy target ∧
      (simultaneousDestroyCalculation entries queryable operation target).Dependency
        priorDependency candidate

def DependencyWithSimultaneousDestruction
    (entries : Position → Option ParticleOperation)
    (queryable : Position → Prop)
    (priorDependency : ParticleOperation → ParticleOperation → Prop)
    (selected : ParticleOperation → Prop)
    (operation candidate : ParticleOperation) : Prop :=
  priorDependency operation candidate ∨
    SimultaneousDestroyDependency entries queryable priorDependency selected
      operation candidate

theorem simultaneousDestroyDependency_has_prior_entry
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    {operation candidate : ParticleOperation}
    (dependency : SimultaneousDestroyDependency entries queryable priorDependency
      selected operation candidate) :
    ∃ position, queryable position ∧ entries position = some candidate := by
  rcases dependency with ⟨_, target, _, rule_dependency⟩
  rcases RuleCalculation.dependency_isInCollection rule_dependency with
    source_candidate | fill_candidate
  · rcases source_candidate with ⟨position, queried, _, entry⟩
    exact ⟨position, queried, entry⟩
  · cases fill_candidate

theorem simultaneousDestroyDependency_no_implicit_order
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (entries_precede_selection :
      ∀ position operation, queryable position → entries position = some operation →
        ¬selected operation)
    {first second : ParticleOperation} (second_selected : selected second) :
    ¬SimultaneousDestroyDependency entries queryable priorDependency selected first second := by
  intro dependency
  rcases simultaneousDestroyDependency_has_prior_entry dependency with
    ⟨position, queried, entry⟩
  exact entries_precede_selection position second queried entry second_selected

theorem simultaneousDestroyCalculation_enumeration_independent
    (entries : Position → Option ParticleOperation)
    (queryable : Position → Prop)
    (priorDependency : ParticleOperation → ParticleOperation → Prop)
    {first second : ParticleOperation} {target : Position}
    (first_destroy : first.kind = .destroy target)
    (second_destroy : second.kind = .destroy target)
    (candidate : ParticleOperation) :
    (simultaneousDestroyCalculation entries queryable first target).Dependency
        priorDependency candidate ↔
      (simultaneousDestroyCalculation entries queryable second target).Dependency
        priorDependency candidate := by
  simp only [RuleCalculation.Dependency, simultaneousDestroyCalculation,
    first_destroy, second_destroy, RuleCalculation.AfterMoveCorrection,
    RuleCalculation.AfterComparison, RuleCalculation.InCollection,
    RuleCalculation.IsFillCandidate]

theorem prior_reaches_with_simultaneous_destruction
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    {operation predecessor : ParticleOperation}
    (path : Reaches priorDependency operation predecessor) :
    Reaches (DependencyWithSimultaneousDestruction entries queryable priorDependency selected)
      operation predecessor := by
  induction path with
  | direct edge => exact .direct (Or.inl edge)
  | step edge _ induction_hypothesis => exact .step (Or.inl edge) induction_hypothesis

theorem simultaneousDestruction_no_order_without_dependency_path
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (entries_precede_selection :
      ∀ position operation, queryable position → entries position = some operation →
        ¬selected operation)
    (prior_has_no_selected_target :
      ∀ operation candidate, priorDependency operation candidate → ¬selected candidate)
    {first second : ParticleOperation} (second_selected : selected second) :
    ¬Reaches (DependencyWithSimultaneousDestruction entries queryable priorDependency selected)
      first second := by
  intro path
  have no_selected_target :
      ∀ operation candidate,
        DependencyWithSimultaneousDestruction entries queryable priorDependency selected
          operation candidate → ¬selected candidate := by
    intro operation candidate edge candidate_selected
    rcases edge with old_edge | destruction_edge
    · exact prior_has_no_selected_target operation candidate old_edge candidate_selected
    · exact simultaneousDestroyDependency_no_implicit_order entries_precede_selection
        candidate_selected destruction_edge
  induction path with
  | direct edge => exact no_selected_target _ _ edge second_selected
  | step _ _ induction_hypothesis => exact induction_hypothesis second_selected

theorem simultaneousDestruction_reaches_from_unselected_iff
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (prior_has_no_selected_target :
      ∀ operation candidate, priorDependency operation candidate → ¬selected candidate)
    {first second : ParticleOperation} (first_unselected : ¬selected first) :
    Reaches (DependencyWithSimultaneousDestruction entries queryable priorDependency selected)
        first second ↔ Reaches priorDependency first second := by
  constructor
  · intro path
    induction path with
    | direct edge =>
        rcases edge with prior_edge | destruction_edge
        · exact .direct prior_edge
        · exact False.elim (first_unselected destruction_edge.1)
    | step edge _ induction_hypothesis =>
        rcases edge with prior_edge | destruction_edge
        · exact .step prior_edge
            (induction_hypothesis (prior_has_no_selected_target _ _ prior_edge))
        · exact False.elim (first_unselected destruction_edge.1)
  · exact prior_reaches_with_simultaneous_destruction

theorem simultaneousDestruction_preserves_acyclicity
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (entries_precede_selection :
      ∀ position operation, queryable position → entries position = some operation →
        ¬selected operation)
    (prior_has_no_selected_target :
      ∀ operation candidate, priorDependency operation candidate → ¬selected candidate)
    (prior_acyclic : Acyclic priorDependency) :
    Acyclic (DependencyWithSimultaneousDestruction entries queryable priorDependency selected) := by
  intro operation path
  by_cases operation_selected : selected operation
  · exact simultaneousDestruction_no_order_without_dependency_path
      entries_precede_selection prior_has_no_selected_target operation_selected path
  · exact prior_acyclic operation
      ((simultaneousDestruction_reaches_from_unselected_iff
        prior_has_no_selected_target operation_selected).mp path)

theorem simultaneousDestruction_reaches_from_selected_iff
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (entries_precede_selection :
      ∀ position operation, queryable position → entries position = some operation →
        ¬selected operation)
    (prior_has_no_selected_source :
      ∀ operation candidate, priorDependency operation candidate → ¬selected operation)
    (prior_has_no_selected_target :
      ∀ operation candidate, priorDependency operation candidate → ¬selected candidate)
    {operation predecessor : ParticleOperation} (operation_selected : selected operation) :
    Reaches (DependencyWithSimultaneousDestruction entries queryable priorDependency selected)
        operation predecessor ↔
      ∃ candidate,
        SimultaneousDestroyDependency entries queryable priorDependency selected operation candidate ∧
          (candidate = predecessor ∨ Reaches priorDependency candidate predecessor) := by
  constructor
  · intro path
    cases path with
    | direct edge =>
        rcases edge with prior_edge | destruction_edge
        · exact False.elim (prior_has_no_selected_source _ _ prior_edge operation_selected)
        · exact ⟨predecessor, destruction_edge, Or.inl rfl⟩
    | step edge remaining =>
        rcases edge with prior_edge | destruction_edge
        · exact False.elim (prior_has_no_selected_source _ _ prior_edge operation_selected)
        · rcases simultaneousDestroyDependency_has_prior_entry destruction_edge with
            ⟨position, queried, entry⟩
          exact ⟨_, destruction_edge, Or.inr
            ((simultaneousDestruction_reaches_from_unselected_iff
              prior_has_no_selected_target
              (entries_precede_selection _ _ queried entry)).mp remaining)⟩
  · rintro ⟨candidate, edge, equal | remaining⟩
    · subst predecessor
      exact .direct (Or.inr edge)
    · exact .step (Or.inr edge) (prior_reaches_with_simultaneous_destruction remaining)

theorem simultaneousDestruction_preserves_dependency_antichains
    {entries : Position → Option ParticleOperation}
    {queryable : Position → Prop}
    {priorDependency : ParticleOperation → ParticleOperation → Prop}
    {selected : ParticleOperation → Prop}
    (entries_precede_selection :
      ∀ position operation, queryable position → entries position = some operation →
        ¬selected operation)
    (prior_has_no_selected_source :
      ∀ operation candidate, priorDependency operation candidate → ¬selected operation)
    (prior_has_no_selected_target :
      ∀ operation candidate, priorDependency operation candidate → ¬selected candidate)
    (prior_antichains : DirectDependenciesAreAntichains priorDependency)
    (destruction_antichains :
      ∀ operation first second,
        SimultaneousDestroyDependency entries queryable priorDependency selected operation first →
        SimultaneousDestroyDependency entries queryable priorDependency selected operation second →
        first ≠ second → ¬Reaches priorDependency first second) :
    DirectDependenciesAreAntichains
      (DependencyWithSimultaneousDestruction entries queryable priorDependency selected) := by
  intro operation first second first_edge second_edge different path
  rcases first_edge with first_prior | first_destruction
  · have prior_path := (simultaneousDestruction_reaches_from_unselected_iff
        prior_has_no_selected_target (prior_has_no_selected_target _ _ first_prior)).mp path
    rcases second_edge with second_prior | second_destruction
    · exact prior_antichains operation first second first_prior second_prior different prior_path
    · exact prior_has_no_selected_source _ _ first_prior second_destruction.1
  · rcases simultaneousDestroyDependency_has_prior_entry first_destruction with
      ⟨position, queried, entry⟩
    have prior_path := (simultaneousDestruction_reaches_from_unselected_iff
        prior_has_no_selected_target (entries_precede_selection _ _ queried entry)).mp path
    rcases second_edge with second_prior | second_destruction
    · exact prior_has_no_selected_source _ _ second_prior first_destruction.1
    · exact destruction_antichains operation first second first_destruction second_destruction
        different prior_path

end Define.OperationGraph
