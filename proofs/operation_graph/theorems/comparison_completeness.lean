import completeness
import ordered_calculations

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

theorem OrderedCalculations.reaches_of_afterComparison
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    {operation candidate : ParticleOperation}
    (after_comparison : (rules.calculation operation).AfterComparison candidate) :
    Reaches rules.Dependency operation candidate := by
  have candidates_previous : ∀ previous, (rules.calculation operation).InCollection previous →
      MoreRecent (rules.calculation operation).operation previous := by
    intro previous collected
    rw [rules.calculation_operation]
    exact rules.collection_previous operation previous collected
  have paths_previous : ∀ newer older, Reaches rules.Dependency newer older → MoreRecent newer older :=
    fun _ _ path => reaches_decreases_order rules.pointsBackward path
  have calculation_kind : (rules.calculation operation).operation.kind = operation.kind :=
    congrArg ParticleOperation.kind (rules.calculation_operation operation)
  cases kind : operation.kind with
  | create target =>
      have no_source := rules.calculation_well_formed operation
      simp only [RuleCalculation.WellFormed, calculation_kind, kind] at no_source
      have fill : (rules.calculation operation).IsFillCandidate candidate := by
        rcases after_comparison.1 with source | fill
        · exact False.elim (no_source candidate source)
        · exact fill
      exact .direct ((rules.exact_dependency operation candidate).mpr
        (by simpa [RuleCalculation.Dependency, calculation_kind, kind] using fill))
  | destroy target =>
      rcases (rules.calculation operation).exists_afterMoveCorrection_orEq_reaching rules.Dependency
          candidates_previous paths_previous candidate after_comparison with ⟨survivor, retained, path⟩
      have edge : rules.Dependency operation survivor :=
        (rules.exact_dependency operation survivor).mpr
          (by simpa [RuleCalculation.Dependency, calculation_kind, kind] using retained)
      exact Reaches.reaches_of_edge_of_orEq edge path
  | move source target =>
      rcases (rules.calculation operation).exists_afterMoveCorrection_orEq_reaching rules.Dependency
          candidates_previous paths_previous candidate after_comparison with ⟨corrected, retained, path⟩
      rcases (rules.calculation operation).exists_moveRuleDependency_orEq_reaching rules.Dependency
          candidates_previous paths_previous corrected retained with ⟨survivor, final, final_path⟩
      have edge : rules.Dependency operation survivor :=
        (rules.exact_dependency operation survivor).mpr
          (by simpa [RuleCalculation.Dependency, calculation_kind, kind] using final)
      exact Reaches.reaches_of_edge_of_orEq edge (Reaches.orEq_trans final_path path)

theorem OrderedCalculations.dependency_afterComparison
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    {operation candidate : ParticleOperation} (edge : rules.Dependency operation candidate) :
    (rules.calculation operation).AfterComparison candidate := by
  have retained := (rules.exact_dependency operation candidate).mp edge
  have calculation_kind : (rules.calculation operation).operation.kind = operation.kind :=
    congrArg ParticleOperation.kind (rules.calculation_operation operation)
  cases kind : operation.kind with
  | create target =>
      have fill : (rules.calculation operation).IsFillCandidate candidate := by
        simpa [RuleCalculation.Dependency, calculation_kind, kind] using retained
      have no_source := rules.calculation_well_formed operation
      simp only [RuleCalculation.WellFormed, calculation_kind, kind] at no_source
      refine ⟨Or.inr fill, ?_, ?_⟩
      · intro newer collected recent _
        rcases collected with source | newer_fill
        · exact no_source newer source
        · have equal := Option.some.inj (newer_fill.symm.trans fill)
          subst newer
          exact Nat.lt_irrefl _ recent
      · intro other collected
        rcases collected with source | other_fill
        · exact False.elim (no_source other source)
        · have equal := Option.some.inj (other_fill.symm.trans fill)
          subst other
          exact sameRecencyParentDestroy_irrefl candidate
  | destroy target =>
      change (rules.calculation operation).AfterComparison candidate
      have corrected : (rules.calculation operation).AfterMoveCorrection rules.Dependency candidate := by
        simpa [RuleCalculation.Dependency, calculation_kind, kind] using retained
      exact corrected.1
  | move source target =>
      have final : (rules.calculation operation).MoveRuleDependency rules.Dependency candidate := by
        simpa [RuleCalculation.Dependency, calculation_kind, kind] using retained
      exact final.1.1

theorem OrderedCalculations.reaches_iff_reaches_afterComparison
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    {operation candidate : ParticleOperation} :
    Reaches rules.Dependency operation candidate ↔
      Reaches (fun current previous => (rules.calculation current).AfterComparison previous)
        operation candidate := by
  constructor
  · exact Reaches.mono fun _ _ edge => rules.dependency_afterComparison edge
  · intro path
    induction path with
    | direct after_comparison => exact rules.reaches_of_afterComparison after_comparison
    | step after_comparison _ induction_hypothesis =>
        exact (rules.reaches_of_afterComparison after_comparison).trans induction_hypothesis

end Define.OperationGraph
