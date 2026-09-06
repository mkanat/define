import definitions

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

def EntryWrittenBy (operation : ParticleOperation) (definedBefore : Position → Prop)
    (position : Position) : Prop :=
  OperatesOn operation position ∨
    ∃ source target suffix,
      operation.kind = .move source target ∧ suffix ≠ [] ∧
        position = target ++ suffix ∧ definedBefore (source ++ suffix)

def OperatedParent (operation : ParticleOperation) (position : Position) : Prop :=
  ∃ operatedPosition, OperatesOn operation operatedPosition ∧ ParentOrSame operatedPosition position

noncomputable def entryAfter (operation : ParticleOperation)
    (definedBefore : Position → Prop)
    (entries : Position → Option ParticleOperation) (position : Position) : Option ParticleOperation := by
  classical
  exact if EntryWrittenBy operation definedBefore position then some operation else entries position

theorem EntryWrittenBy.operated_parent
    {operation : ParticleOperation} {definedBefore : Position → Prop} {position : Position}
    (written : EntryWrittenBy operation definedBefore position) : OperatedParent operation position := by
  rcases written with direct | ⟨source, target, suffix, kind, _, position_equal, _⟩
  · exact ⟨position, direct, List.prefix_rfl⟩
  · exact ⟨target, by simp [OperatesOn, kind], ⟨suffix, position_equal.symm⟩⟩

theorem EntryWrittenBy.non_move_operates
    {operation : ParticleOperation} {definedBefore : Position → Prop} {position : Position}
    (written : EntryWrittenBy operation definedBefore position) (not_move : ¬IsMove operation) :
    OperatesOn operation position := by
  rcases written with direct | ⟨source, target, _, kind, _⟩
  · exact direct
  · exact False.elim (not_move ⟨source, target, kind⟩)

theorem entryAfter_writes_operated_position
    {operation : ParticleOperation} {definedBefore : Position → Prop}
    {entries : Position → Option ParticleOperation} {position : Position}
    (operates : OperatesOn operation position) :
    entryAfter operation definedBefore entries position = some operation := by
  have written : EntryWrittenBy operation definedBefore position := Or.inl operates
  simp [entryAfter, written]

theorem entryAfter_unchanged_without_operated_parent
    {operation : ParticleOperation} {definedBefore : Position → Prop}
    {entries : Position → Option ParticleOperation} {position : Position}
    (no_parent : ¬OperatedParent operation position) :
    entryAfter operation definedBefore entries position = entries position := by
  have not_written : ¬EntryWrittenBy operation definedBefore position := by
    intro written
    exact no_parent written.operated_parent
  simp [entryAfter, not_written]

theorem entryAfter_provenance
    {operation candidate : ParticleOperation} {definedBefore : Position → Prop}
    {entries : Position → Option ParticleOperation} {position : Position}
    (entry : entryAfter operation definedBefore entries position = some candidate) :
    (candidate = operation ∧ EntryWrittenBy operation definedBefore position) ∨
      entries position = some candidate := by
  classical
  by_cases written : EntryWrittenBy operation definedBefore position
  · exact Or.inl ⟨by simpa [entryAfter, written, eq_comm] using entry, written⟩
  · exact Or.inr (by simpa [entryAfter, written] using entry)

end Define.OperationGraph
