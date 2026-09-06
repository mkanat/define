import entry_update
import valid_history

set_option warningAsError true
set_option autoImplicit false

namespace Define.OperationGraph

structure PositionEntryHistory (isOperation : ParticleOperation → Prop) where
  execution : ExactOccupancyExecution isOperation
  definedBefore : Nat → Position → Prop
noncomputable def PositionEntryHistory.entriesBefore
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation) :
    Nat → Position → Option ParticleOperation
  | 0 => fun _ => none
  | index + 1 =>
      match history.execution.operationAt index with
      | none => history.entriesBefore index
      | some operation =>
          entryAfter operation (history.definedBefore index)
            (history.entriesBefore index)

theorem PositionEntryHistory.entry_facts
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {index : Nat} {position : Position} {candidate : ParticleOperation}
    (entry : history.entriesBefore index position = some candidate) :
    isOperation candidate ∧ candidate.operationOrder < index ∧
      OperatedParent candidate position ∧ (¬IsMove candidate → OperatesOn candidate position) := by
  induction index with
  | zero => simp [entriesBefore] at entry
  | succ index induction_hypothesis =>
      cases operation_at : history.execution.operationAt index with
      | none =>
          have previous_entry : history.entriesBefore index position = some candidate := by
            simpa [entriesBefore, operation_at] using entry
          rcases induction_hypothesis previous_entry with
            ⟨candidate_member, candidate_before, parent, non_move⟩
          exact ⟨candidate_member, Nat.lt_trans candidate_before (Nat.lt_succ_self index), parent, non_move⟩
      | some operation =>
          have after_entry :
              entryAfter operation (history.definedBefore index)
                (history.entriesBefore index) position = some candidate := by
            simpa [entriesBefore, operation_at] using entry
          rcases entryAfter_provenance after_entry with written | previous_entry
          · rcases written with ⟨candidate_equal, written⟩
            subst candidate
            have operation_order := history.execution.operation_at_has_order index operation operation_at
            exact ⟨history.execution.operation_at_is_member index operation operation_at,
              by omega, written.operated_parent, written.non_move_operates⟩
          · rcases induction_hypothesis previous_entry with
              ⟨candidate_member, candidate_before, parent, non_move⟩
            exact ⟨candidate_member,
              Nat.lt_trans candidate_before (Nat.lt_succ_self index), parent, non_move⟩

theorem PositionEntryHistory.entry_is_most_recent_previous
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {index : Nat} {position : Position} {candidate : ParticleOperation}
    (entry : history.entriesBefore index position = some candidate) :
    EntryWrittenBy candidate (history.definedBefore candidate.operationOrder) position ∧
      ∀ newerCandidate, isOperation newerCandidate →
        MoreRecent newerCandidate candidate → newerCandidate.operationOrder < index →
        ¬EntryWrittenBy newerCandidate (history.definedBefore newerCandidate.operationOrder) position := by
  induction index with
  | zero => simp [entriesBefore] at entry
  | succ index induction_hypothesis =>
      cases operation_at : history.execution.operationAt index with
      | none =>
          have previous_entry : history.entriesBefore index position = some candidate := by
            simpa [entriesBefore, operation_at] using entry
          rcases induction_hypothesis previous_entry with ⟨written, latest⟩
          refine ⟨written, ?_⟩
          intro newer newer_member newer_after newer_before
          have newer_not_current : newer.operationOrder ≠ index := by
            intro equal
            have newer_at := history.execution.member_operation_at newer newer_member
            rw [equal, operation_at] at newer_at
            cases newer_at
          exact latest newer newer_member newer_after (by omega)
      | some operation =>
          have operation_order := history.execution.operation_at_has_order index operation operation_at
          by_cases written : EntryWrittenBy operation (history.definedBefore index) position
          · have candidate_equal : candidate = operation := by
              simpa [entriesBefore, operation_at, entryAfter, written, eq_comm] using entry
            subst candidate
            refine ⟨by simpa [operation_order] using written, ?_⟩
            intro newer _ newer_after newer_before
            unfold MoreRecent at newer_after
            omega
          · have previous_entry : history.entriesBefore index position = some candidate := by
              simpa [entriesBefore, operation_at, entryAfter, written] using entry
            rcases induction_hypothesis previous_entry with ⟨candidate_written, latest⟩
            refine ⟨candidate_written, ?_⟩
            intro newer newer_member newer_after newer_before newer_written
            by_cases newer_current : newer.operationOrder = index
            · have newer_at := history.execution.member_operation_at newer newer_member
              rw [newer_current, operation_at] at newer_at
              have newer_equal : newer = operation := (Option.some.inj newer_at).symm
              subst newer
              exact written (by simpa [operation_order] using newer_written)
            · exact latest newer newer_member newer_after (by omega) newer_written

theorem PositionEntryHistory.entry_exists_of_previous_writer
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {index : Nat} {position : Position} {writer : ParticleOperation}
    (writer_member : isOperation writer) (writer_before : writer.operationOrder < index)
    (written : EntryWrittenBy writer (history.definedBefore writer.operationOrder) position) :
    ∃ candidate, history.entriesBefore index position = some candidate := by
  induction index with
  | zero => omega
  | succ index induction_hypothesis =>
      by_cases writer_current : writer.operationOrder = index
      · have writer_at := history.execution.member_operation_at writer writer_member
        rw [writer_current] at writer_at
        have writes_now : EntryWrittenBy writer (history.definedBefore index) position := by
          simpa [writer_current] using written
        exact ⟨writer, by simp [entriesBefore, writer_at, entryAfter, writes_now]⟩
      · rcases induction_hypothesis (by omega) with ⟨candidate, previous_entry⟩
        cases operation_at : history.execution.operationAt index with
        | none => exact ⟨candidate, by simpa [entriesBefore, operation_at] using previous_entry⟩
        | some operation =>
            by_cases current_writes : EntryWrittenBy operation (history.definedBefore index) position
            · exact ⟨operation, by simp [entriesBefore, operation_at, entryAfter, current_writes]⟩
            · exact ⟨candidate, by simpa [entriesBefore, operation_at, entryAfter, current_writes]
                using previous_entry⟩

theorem PositionEntryHistory.entry_iff_most_recent_previous
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    (index : Nat) (position : Position) (candidate : ParticleOperation) :
    history.entriesBefore index position = some candidate ↔
      isOperation candidate ∧ candidate.operationOrder < index ∧
        EntryWrittenBy candidate (history.definedBefore candidate.operationOrder) position ∧
        ∀ newerCandidate, isOperation newerCandidate →
          MoreRecent newerCandidate candidate → newerCandidate.operationOrder < index →
          ¬EntryWrittenBy newerCandidate (history.definedBefore newerCandidate.operationOrder) position := by
  constructor
  · intro entry
    have facts := history.entry_facts entry
    exact ⟨facts.1, facts.2.1, history.entry_is_most_recent_previous entry⟩
  · rintro ⟨candidate_member, candidate_before, candidate_written, latest⟩
    rcases history.entry_exists_of_previous_writer candidate_member candidate_before candidate_written with
      ⟨actual, entry⟩
    have facts := history.entry_facts entry
    have actual_latest := history.entry_is_most_recent_previous entry
    rcases Nat.lt_trichotomy actual.operationOrder candidate.operationOrder with earlier | equal | later
    · exact False.elim (actual_latest.2 candidate candidate_member earlier candidate_before candidate_written)
    · have actual_at := history.execution.member_operation_at actual facts.1
      have candidate_at := history.execution.member_operation_at candidate candidate_member
      rw [equal] at actual_at
      exact entry.trans (congrArg some (Option.some.inj (actual_at.symm.trans candidate_at)))
    · exact False.elim (latest actual facts.1 later facts.2.1 actual_latest.1)

theorem PositionEntryHistory.previous_operation_entry
    {isOperation : ParticleOperation → Prop} (history : PositionEntryHistory isOperation)
    {index : Nat} {operation : ParticleOperation} {position : Position}
    (operation_member : isOperation operation) (operation_before : operation.operationOrder < index)
    (operates : OperatesOn operation position) :
    ∃ candidate, history.entriesBefore index position = some candidate ∧
      operation.operationOrder ≤ candidate.operationOrder := by
  rcases history.entry_exists_of_previous_writer operation_member operation_before (Or.inl operates) with
    ⟨candidate, entry⟩
  refine ⟨candidate, entry, ?_⟩
  by_cases recent : operation.operationOrder ≤ candidate.operationOrder
  · exact recent
  · exact False.elim ((history.entry_is_most_recent_previous entry).2 operation
      operation_member (by unfold MoreRecent; omega) operation_before (Or.inl operates))

end Define.OperationGraph
