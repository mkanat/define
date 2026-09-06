import simultaneous_calculation

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph.SimultaneousDestructionWitness

def parent : Position := [0]
def child : Position := [0, 0]

def createChild : ParticleOperation := ⟨0, [], .create child⟩
def destroyParent : ParticleOperation := ⟨1, [], .destroy parent⟩
def destroyChild : ParticleOperation := ⟨2, [], .destroy child⟩

def entries (position : Position) : Option ParticleOperation :=
  if position = child then some createChild else none

def selected (operation : ParticleOperation) : Prop :=
  operation = destroyParent ∨ operation = destroyChild

def priorDependency (_operation _candidate : ParticleOperation) : Prop := False

def dependency : ParticleOperation → ParticleOperation → Prop :=
  DependencyWithSimultaneousDestruction entries (fun _ => True) priorDependency selected

theorem source_candidate_iff {operation : ParticleOperation} {target : Position}
    (child_related : Related child target) (candidate : ParticleOperation) :
    (simultaneousDestroyCalculation entries (fun _ => True) operation target).sourceCandidate candidate ↔
      candidate = createChild := by
  constructor
  · rintro ⟨position, _, _, entry⟩
    by_cases is_child : position = child
    · simpa [entries, is_child, eq_comm] using entry
    · simp [entries, is_child] at entry
  · rintro rfl
    exact ⟨child, trivial, child_related, by simp [entries]⟩

theorem individual_dependency_iff {operation : ParticleOperation} {target : Position}
    (operation_selected : selected operation)
    (destroy_kind : operation.kind = .destroy target)
    (child_related : Related child target) (candidate : ParticleOperation) :
    SimultaneousDestroyDependency entries (fun _ => True) priorDependency selected operation candidate ↔
      candidate = createChild := by
  constructor
  · intro edge
    rcases simultaneousDestroyDependency_has_prior_entry edge with ⟨position, _, entry⟩
    by_cases is_child : position = child
    · simpa [entries, is_child, eq_comm] using entry
    · simp [entries, is_child] at entry
  · rintro rfl
    refine ⟨operation_selected, target, destroy_kind, ?_⟩
    simp only [RuleCalculation.Dependency, simultaneousDestroyCalculation, destroy_kind]
    change (simultaneousDestroyCalculation entries (fun _ => True) operation target).AfterMoveCorrection
      priorDependency createChild
    refine ⟨⟨Or.inl ((source_candidate_iff child_related createChild).mpr rfl), ?_, ?_⟩, Or.inl ?_⟩
    · intro newer in_collection newer_than related
      rcases in_collection with source | fill
      · have equal := (source_candidate_iff child_related newer).mp source
        subst newer
        exact Nat.lt_irrefl _ newer_than
      · cases fill
    · intro other _
      cases kind : other.kind <;> simp [SameRecencyParentDestroy, kind, createChild]
    · rintro ⟨source, destination, kind⟩
      cases kind

theorem parent_dependency_iff (candidate : ParticleOperation) :
    dependency destroyParent candidate ↔ candidate = createChild := by
  change False ∨ _ ↔ _
  rw [false_or]
  exact individual_dependency_iff (Or.inl rfl) rfl
    (Or.inr ⟨[0], rfl⟩) candidate

theorem child_dependency_iff (candidate : ParticleOperation) :
    dependency destroyChild candidate ↔ candidate = createChild := by
  change False ∨ _ ↔ _
  rw [false_or]
  exact individual_dependency_iff (Or.inr rfl) rfl (related_refl child) candidate

theorem entries_precede_selection (position : Position) (operation : ParticleOperation)
    (_queried : True) (entry : entries position = some operation) : ¬selected operation := by
  by_cases is_child : position = child
  · have operation_equal : operation = createChild := by
      simpa [entries, is_child, eq_comm] using entry
    subst operation
    simp [selected, createChild, destroyParent, destroyChild]
  · simp [entries, is_child] at entry

theorem neither_destruction_orders_the_other :
    ¬Reaches dependency destroyParent destroyChild ∧
      ¬Reaches dependency destroyChild destroyParent := by
  constructor
  · exact simultaneousDestruction_no_order_without_dependency_path
      entries_precede_selection (fun _ _ impossible => False.elim impossible) (Or.inr rfl)
  · exact simultaneousDestruction_no_order_without_dependency_path
      entries_precede_selection (fun _ _ impossible => False.elim impossible) (Or.inl rfl)

theorem related_previous_does_not_imply_reachability :
    RelatedPrevious destroyChild destroyParent ∧
      ¬Reaches dependency destroyChild destroyParent := by
  refine ⟨⟨by change 1 < 2; decide, ?_⟩, neither_destruction_orders_the_other.2⟩
  exact ⟨child, parent, rfl, rfl, Or.inr ⟨[0], rfl⟩⟩

def recreateParent : ParticleOperation := ⟨3, [], .create parent⟩
def destroyAgain : ParticleOperation := ⟨4, [], .destroy parent⟩

def destroyedEntries (position : Position) : Option ParticleOperation :=
  if position = parent then some destroyParent
  else if position = child then some destroyChild else none

def replacementFillEntry (candidate : ParticleOperation) : Prop :=
  ∃ position, ParentOrSame position parent ∧ destroyedEntries position = some candidate

theorem replacement_fill_entry_iff (candidate : ParticleOperation) :
    replacementFillEntry candidate ↔ candidate = destroyParent := by
  constructor
  · rintro ⟨position, parent_of_target, entry⟩
    by_cases at_parent : position = parent
    · simpa [destroyedEntries, at_parent, eq_comm] using entry
    · by_cases at_child : position = child
      · subst position
        have impossible : ¬ParentOrSame child parent := by
          show ¬([0, 0] : List Nat) <+: [0]
          decide
        exact False.elim (impossible parent_of_target)
      · simp [destroyedEntries, at_parent, at_child] at entry
  · rintro rfl
    exact ⟨parent, List.prefix_rfl, by simp [destroyedEntries]⟩

def replacementEntries (position : Position) : Option ParticleOperation :=
  if position = parent then some recreateParent
  else if position = child then some destroyChild else none

noncomputable def replacementCreateCalculation : RuleCalculation where
  operation := recreateParent
  sourceCandidate := fun _ => False
  fillCandidate := uniqueOption (IsMostRecent replacementFillEntry)

theorem replacement_fill_candidate :
    replacementCreateCalculation.fillCandidate = some destroyParent := by
  apply (uniqueOption_eq_some_iff (IsMostRecent replacementFillEntry) ?_ destroyParent).mpr
  · refine ⟨(replacement_fill_entry_iff destroyParent).mpr rfl, ?_⟩
    intro newer entry
    have equal := (replacement_fill_entry_iff newer).mp entry
    subst newer
    exact Nat.lt_irrefl _
  · intro first second first_recent second_recent
    exact ((replacement_fill_entry_iff first).mp first_recent.1).trans
      ((replacement_fill_entry_iff second).mp second_recent.1).symm

def replacementDestroyCalculation : RuleCalculation :=
  simultaneousDestroyCalculation replacementEntries (fun _ => True) destroyAgain parent

theorem replacement_collection_iff (candidate : ParticleOperation) :
    replacementDestroyCalculation.InCollection candidate ↔
      candidate = recreateParent ∨ candidate = destroyChild := by
  constructor
  · rintro (⟨position, _, _, entry⟩ | impossible)
    · by_cases at_parent : position = parent
      · exact Or.inl (by simpa [replacementEntries, at_parent, eq_comm] using entry)
      · by_cases at_child : position = child
        · subst position
          exact Or.inr (by simpa [replacementEntries, parent, child, eq_comm] using entry)
        · simp [replacementEntries, at_parent, at_child] at entry
    · cases impossible
  · rintro (rfl | rfl)
    · exact Or.inl ⟨parent, trivial, related_refl parent, by simp [replacementEntries]⟩
    · exact Or.inl ⟨child, trivial, Or.inr ⟨[0], rfl⟩,
        by simp [replacementEntries, parent, child]⟩

theorem replacement_comparison_iff (candidate : ParticleOperation) :
    replacementDestroyCalculation.AfterComparison candidate ↔ candidate = recreateParent := by
  constructor
  · intro surviving
    rcases (replacement_collection_iff candidate).mp surviving.1 with equal | equal
    · exact equal
    · subst candidate
      exact False.elim (surviving.2.1 recreateParent
        ((replacement_collection_iff recreateParent).mpr (Or.inl rfl))
        (by change 2 < 3; decide)
        ⟨parent, child, rfl, rfl, Or.inl ⟨[0], rfl⟩⟩)
  · rintro rfl
    refine ⟨(replacement_collection_iff recreateParent).mpr (Or.inl rfl), ?_, ?_⟩
    · intro newer collected recent _
      rcases (replacement_collection_iff newer).mp collected with rfl | rfl
      · exact Nat.lt_irrefl _ recent
      · change 3 < 2 at recent
        omega
    · intro other _
      cases kind : other.kind <;> simp [SameRecencyParentDestroy, kind, recreateParent]

theorem replacement_destroy_dependency_iff
    (previousDependency : ParticleOperation → ParticleOperation → Prop) (candidate : ParticleOperation) :
    replacementDestroyCalculation.Dependency previousDependency candidate ↔ candidate = recreateParent := by
  change replacementDestroyCalculation.AfterMoveCorrection previousDependency candidate ↔ _
  constructor
  · intro retained
    exact (replacement_comparison_iff candidate).mp retained.1
  · rintro rfl
    exact ⟨(replacement_comparison_iff recreateParent).mpr rfl,
      Or.inl (by simp [IsMove, recreateParent])⟩

def dependencyAfterReplacementCreate (operation candidate : ParticleOperation) : Prop :=
  dependency operation candidate ∨
    (operation = recreateParent ∧ replacementCreateCalculation.Dependency dependency candidate)

def dependencyAfterReplacement (operation candidate : ParticleOperation) : Prop :=
  dependencyAfterReplacementCreate operation candidate ∨
    (operation = destroyAgain ∧
      replacementDestroyCalculation.Dependency dependencyAfterReplacementCreate candidate)

theorem replacement_has_no_edge_to_old_child (operation : ParticleOperation) :
    ¬dependencyAfterReplacement operation destroyChild := by
  rintro ((old | ⟨_, create_edge⟩) | ⟨_, destroy_edge⟩)
  · exact (simultaneousDestruction_no_order_without_dependency_path
      entries_precede_selection (fun _ _ impossible => False.elim impossible) (Or.inr rfl))
      (Reaches.direct old)
  · change replacementCreateCalculation.fillCandidate = some destroyChild at create_edge
    rw [replacement_fill_candidate] at create_edge
    cases create_edge
  · have equal := (replacement_destroy_dependency_iff _ destroyChild).mp destroy_edge
    cases equal

theorem collected_operation_need_not_be_reachable :
    replacementDestroyCalculation.InCollection destroyChild ∧
      ¬Reaches dependencyAfterReplacement destroyAgain destroyChild := by
  refine ⟨(replacement_collection_iff destroyChild).mpr (Or.inr rfl), ?_⟩
  intro path
  rcases Reaches.last_edge path with ⟨operation, _, edge⟩
  exact replacement_has_no_edge_to_old_child operation edge

end Define.OperationGraph.SimultaneousDestructionWitness

namespace Define.OperationGraph.DestructorParentWitness

def parent : Position := [0]
def child : Position := [0, 0]
def held : Position := [1]

def createParent : ParticleOperation := ⟨0, [], .create parent⟩
def returnChild : ParticleOperation := ⟨3, parent, .move held child⟩
def destroyParent : ParticleOperation := ⟨4, [], .destroy parent⟩

def entries (position : Position) : Option ParticleOperation :=
  if position = parent then some createParent
  else if position = child ∨ position = held then some returnChild else none

def parentCalculation : RuleCalculation :=
  simultaneousDestroyCalculation entries (fun _ => True) destroyParent parent

theorem collection_iff (candidate : ParticleOperation) :
    parentCalculation.InCollection candidate ↔
      candidate = createParent ∨ candidate = returnChild := by
  constructor
  · rintro (⟨position, _, _, entry⟩ | impossible)
    · by_cases at_parent : position = parent
      · exact Or.inl (by simpa [entries, at_parent, eq_comm] using entry)
      · by_cases at_move : position = child ∨ position = held
        · exact Or.inr (by simpa [entries, at_parent, at_move, eq_comm] using entry)
        · simp [entries, at_parent, at_move] at entry
    · cases impossible
  · rintro (rfl | rfl)
    · exact Or.inl ⟨parent, trivial, related_refl parent, by simp [entries]⟩
    · exact Or.inl ⟨child, trivial, Or.inr ⟨[0], rfl⟩,
        by simp [entries, parent, child]⟩

theorem comparison_iff (candidate : ParticleOperation) :
    parentCalculation.AfterComparison candidate ↔ candidate = returnChild := by
  constructor
  · intro surviving
    rcases (collection_iff candidate).mp surviving.1 with equal | equal
    · subst candidate
      exact False.elim (surviving.2.1 returnChild
        ((collection_iff returnChild).mpr (Or.inr rfl))
        (by change 0 < 3; decide)
        ⟨child, parent, Or.inr rfl, rfl, Or.inr ⟨[0], rfl⟩⟩)
    · exact equal
  · rintro rfl
    refine ⟨(collection_iff returnChild).mpr (Or.inr rfl), ?_, ?_⟩
    · intro newer collected recent _
      rcases (collection_iff newer).mp collected with rfl | rfl
      · change 3 < 0 at recent
        omega
      · exact Nat.lt_irrefl _ recent
    · intro other _
      cases kind : other.kind <;> simp [SameRecencyParentDestroy, kind, returnChild]

theorem parent_destroy_dependency_iff
    (previousDependency : ParticleOperation → ParticleOperation → Prop)
    (candidate : ParticleOperation) :
    parentCalculation.Dependency previousDependency candidate ↔ candidate = returnChild := by
  change parentCalculation.AfterMoveCorrection previousDependency candidate ↔ _
  constructor
  · intro retained
    exact (comparison_iff candidate).mp retained.1
  · rintro rfl
    refine ⟨(comparison_iff returnChild).mpr rfl, Or.inr ?_⟩
    intro other surviving different _
    exact different ((comparison_iff other).mp surviving)

end Define.OperationGraph.DestructorParentWitness
