import calculation_congruence

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

structure OrderedCalculations (isOperation : ParticleOperation → Prop) where
  calculation : ParticleOperation → RuleCalculation
  calculation_operation : ∀ operation, (calculation operation).operation = operation
  calculation_well_formed : ∀ operation, (calculation operation).WellFormed
  collection_operations : ∀ operation candidate,
    (calculation operation).InCollection candidate → isOperation operation ∧ isOperation candidate
  collection_previous : ∀ operation candidate,
    (calculation operation).InCollection candidate → MoreRecent operation candidate

noncomputable def OrderedCalculations.dependencyBefore
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    (count : Nat) (operation candidate : ParticleOperation) : Prop :=
  if _ : operation.operationOrder < count then
    isOperation operation ∧
      (rules.calculation operation).Dependency (rules.dependencyBefore operation.operationOrder) candidate
  else False
termination_by count

def OrderedCalculations.Dependency
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    (operation candidate : ParticleOperation) : Prop :=
  isOperation operation ∧
    (rules.calculation operation).Dependency (rules.dependencyBefore operation.operationOrder) candidate

theorem OrderedCalculations.dependencyBefore_iff
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    (count : Nat) (operation candidate : ParticleOperation) :
    rules.dependencyBefore count operation candidate ↔
      operation.operationOrder < count ∧ rules.Dependency operation candidate := by
  rw [dependencyBefore]
  by_cases previous : operation.operationOrder < count <;> simp [previous, Dependency]

theorem OrderedCalculations.pointsBackward
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation) :
    PointsBackward ParticleOperation.operationOrder rules.Dependency := by
  intro operation candidate edge
  exact rules.collection_previous operation candidate (RuleCalculation.dependency_isInCollection edge.2)

theorem OrderedCalculations.prefix_reaches_iff
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    (count : Nat) {source target : ParticleOperation} (source_previous : source.operationOrder < count) :
    Reaches (rules.dependencyBefore count) source target ↔ Reaches rules.Dependency source target := by
  constructor
  · exact Reaches.mono fun operation candidate edge =>
      ((rules.dependencyBefore_iff count operation candidate).mp edge).2
  · intro path
    induction path with
    | direct edge =>
        exact .direct ((rules.dependencyBefore_iff count _ _).mpr ⟨source_previous, edge⟩)
    | step edge _ induction_hypothesis =>
        exact .step ((rules.dependencyBefore_iff count _ _).mpr ⟨source_previous, edge⟩)
          (induction_hypothesis (Nat.lt_trans (rules.pointsBackward _ _ edge) source_previous))

theorem OrderedCalculations.exact_dependency
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    (operation candidate : ParticleOperation) :
    rules.Dependency operation candidate ↔
      (rules.calculation operation).Dependency rules.Dependency candidate := by
  have same_calculation := (rules.calculation operation).dependency_congr
    (fun source target source_in_collection _target_in_collection =>
      rules.prefix_reaches_iff operation.operationOrder
        (rules.collection_previous operation source source_in_collection)) candidate
  constructor
  · intro edge
    exact same_calculation.mp edge.2
  · intro edge
    exact ⟨(rules.collection_operations operation candidate
      (RuleCalculation.dependency_isInCollection edge)).1, same_calculation.mpr edge⟩

def OrderedCalculations.toRuleGraph
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation) : RuleGraph where
  isOperation := isOperation
  dependency := rules.Dependency
  calculation := rules.calculation
  calculation_operation := rules.calculation_operation
  calculation_well_formed := rules.calculation_well_formed
  exact_dependency := rules.exact_dependency

theorem OrderedCalculations.acyclic
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation) :
    Acyclic rules.Dependency := acyclic_of_pointsBackward rules.pointsBackward

theorem OrderedCalculations.no_path_of_identical_recency
    {isOperation : ParticleOperation → Prop} (rules : OrderedCalculations isOperation)
    {first second : ParticleOperation}
    (identical_recency : first.operationOrder = second.operationOrder) :
    ¬Reaches rules.Dependency first second := by
  intro path
  have earlier := reaches_decreases_order rules.pointsBackward path
  omega

end Define.OperationGraph
