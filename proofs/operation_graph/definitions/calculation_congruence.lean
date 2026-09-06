import calculation

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

theorem RuleCalculation.afterMoveCorrection_congr (calculation : RuleCalculation)
    {first second : ParticleOperation → ParticleOperation → Prop}
    (same_paths : ∀ source target,
      calculation.InCollection source → calculation.InCollection target →
        (Reaches first source target ↔ Reaches second source target))
    (candidate : ParticleOperation) :
    calculation.AfterMoveCorrection first candidate ↔ calculation.AfterMoveCorrection second candidate := by
  constructor
  · rintro ⟨compared, not_move | no_path⟩
    · exact ⟨compared, Or.inl not_move⟩
    · refine ⟨compared, Or.inr ?_⟩
      intro other other_compared different path
      exact no_path other other_compared different
        ((same_paths other candidate other_compared.1 compared.1).mpr path)
  · rintro ⟨compared, not_move | no_path⟩
    · exact ⟨compared, Or.inl not_move⟩
    · refine ⟨compared, Or.inr ?_⟩
      intro other other_compared different path
      exact no_path other other_compared different
        ((same_paths other candidate other_compared.1 compared.1).mp path)

theorem RuleCalculation.moveRuleDependency_congr (calculation : RuleCalculation)
    {first second : ParticleOperation → ParticleOperation → Prop}
    (same_paths : ∀ source target,
      calculation.InCollection source → calculation.InCollection target →
        (Reaches first source target ↔ Reaches second source target))
    (candidate : ParticleOperation) :
    calculation.MoveRuleDependency first candidate ↔ calculation.MoveRuleDependency second candidate := by
  have correction := calculation.afterMoveCorrection_congr same_paths
  constructor
  · rintro ⟨corrected, no_removal⟩
    refine ⟨(correction candidate).mp corrected, ?_⟩
    rintro ⟨fill, other, source, other_corrected, different, path⟩
    exact no_removal ⟨fill, other, source, (correction other).mpr other_corrected, different,
      (same_paths other candidate (Or.inl source) corrected.1.1).mpr path⟩
  · rintro ⟨corrected, no_removal⟩
    refine ⟨(correction candidate).mpr corrected, ?_⟩
    rintro ⟨fill, other, source, other_corrected, different, path⟩
    exact no_removal ⟨fill, other, source, (correction other).mp other_corrected, different,
      (same_paths other candidate (Or.inl source) corrected.1.1).mp path⟩

theorem RuleCalculation.dependency_congr (calculation : RuleCalculation)
    {first second : ParticleOperation → ParticleOperation → Prop}
    (same_paths : ∀ source target,
      calculation.InCollection source → calculation.InCollection target →
        (Reaches first source target ↔ Reaches second source target))
    (candidate : ParticleOperation) :
    calculation.Dependency first candidate ↔ calculation.Dependency second candidate := by
  cases kind : calculation.operation.kind with
  | create target => simp [RuleCalculation.Dependency, kind]
  | destroy target =>
      simpa [RuleCalculation.Dependency, kind] using calculation.afterMoveCorrection_congr same_paths candidate
  | move source target =>
      simpa [RuleCalculation.Dependency, kind] using calculation.moveRuleDependency_congr same_paths candidate

end Define.OperationGraph
