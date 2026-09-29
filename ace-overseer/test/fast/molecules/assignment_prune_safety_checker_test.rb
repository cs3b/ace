# frozen_string_literal: true

require_relative "../../test_helper"

class AssignmentPruneSafetyCheckerTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id, :name, :cache_dir, :task_id) do
    def managed?
      !task_id.nil? && !task_id.to_s.strip.empty?
    end
  end
  FakeQueueState = Struct.new(:assignment_state) do
    def summary
      {total: 3, done: 3, failed: 0, active: 0, pending: 0}
    end
  end
  FakeAssignmentInfo = Struct.new(:assignment, :queue_state) do
    def completed?
      queue_state.assignment_state == :completed
    end
  end

  class FakeDiscoverer
    def initialize(infos)
      @infos = infos
    end

    def find_all(include_completed: false)
      @infos
    end
  end

  class FakeAttempt
    attr_reader :attempt_id, :state

    def initialize(attempt_id:, state:)
      @attempt_id = attempt_id
      @state = state
    end

    def active?
      %w[reserved running].include?(state)
    end

    def uncertain?
      state == "uncertain"
    end
  end

  class FakeJournal
    def initialize(ref_value:, attempts: [])
      @ref_value = ref_value
      @attempts = attempts
    end

    def ref_value
      @ref_value
    end

    def derived_attempts(_assignment_id)
      @attempts
    end
  end

  class FakeManager
    def initialize(attempts, error)
      @attempts = attempts
      @error = error
    end

    def attempts(_assignment_id)
      raise @error if @error

      @attempts
    end
  end

  class FakeJournalShell
    def initialize(journal, error)
      @journal = journal
      @error = error
    end

    def ref_value
      raise @error if @error

      @journal&.ref_value
    end

    def derived_attempts(assignment_id)
      raise @error if @error

      @journal&.derived_attempts(assignment_id)
    end
  end

  def test_completed_assignment_is_safe_to_prune
    info = FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(:completed)
    )
    checker = build_checker(info)

    candidate = checker.check(assignment_id: "abc12")

    assert candidate.safe_to_prune?
    assert_equal "abc12", candidate.assignment_id
    assert_equal "work-on-task-230", candidate.assignment_name
    assert_equal "completed", candidate.assignment_state
    assert_empty candidate.reasons
  end

  def test_running_assignment_is_not_safe_to_prune
    info = FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12"),
      FakeQueueState.new(:running)
    )
    checker = build_checker(info)

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons, "assignment still running"
  end

  def test_missing_assignment_returns_not_found
    checker = Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([]) }
    )

    candidate = checker.check(assignment_id: "missing")

    refute candidate.safe_to_prune?
    assert_equal "not_found", candidate.assignment_state
    assert_includes candidate.reasons, "assignment not found"
  end

  def test_active_attempt_blocks_completed_assignment
    checker = build_checker(
      completed_info,
      attempts: [FakeAttempt.new(attempt_id: "at1", state: "running")]
    )

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    refute candidate.attempts_terminal
    assert_includes candidate.reasons.join(" "), "attempt at1 is running"
  end

  def test_uncertain_attempt_blocks_completed_assignment
    checker = build_checker(
      completed_info,
      attempts: [FakeAttempt.new(attempt_id: "at2", state: "uncertain")]
    )

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "uncertain"
  end

  def test_unreadable_attempt_state_blocks
    checker = build_checker(completed_info, attempts_error: Errno::EACCES.new("/cache/abc12/attempts"))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "unreadable"
  end

  def test_managed_assignment_requires_durable_evidence_ref
    checker = build_checker(completed_info("148"), journal: FakeJournal.new(ref_value: nil))

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "no durable evidence ref"
  end

  def test_managed_assignment_journal_active_attempt_blocks
    journal = FakeJournal.new(
      ref_value: "e" * 40,
      attempts: [FakeAttempt.new(attempt_id: "at9", state: "running")]
    )
    checker = build_checker(completed_info("148"), journal: journal)

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "journaled attempt at9"
  end

  def test_managed_assignment_unreadable_journal_blocks
    checker = build_checker(
      completed_info("148"),
      journal_error: Ace::Assign::AttemptErrors::EvidenceUnavailable.new("broken git")
    )

    candidate = checker.check(assignment_id: "abc12")

    refute candidate.safe_to_prune?
    assert_includes candidate.reasons.join(" "), "durable evidence unreadable"
  end

  def test_managed_assignment_with_terminal_evidence_passes
    journal = FakeJournal.new(ref_value: "e" * 40, attempts: [])
    checker = build_checker(completed_info("148"), journal: journal)

    candidate = checker.check(assignment_id: "abc12")

    assert candidate.safe_to_prune?
    assert_empty candidate.reasons
  end

  def test_taskless_assignment_without_journal_ref_passes_when_attempts_terminal
    checker = build_checker(completed_info, journal: nil)

    candidate = checker.check(assignment_id: "abc12")

    assert candidate.safe_to_prune?
  end

  private

  def completed_info(task_id = nil)
    FakeAssignmentInfo.new(
      FakeAssignment.new("abc12", "work-on-task-230", "/cache/abc12", task_id),
      FakeQueueState.new(:completed)
    )
  end

  def build_checker(info, attempts: [], journal: nil, attempts_error: nil, journal_error: nil)
    manager = FakeManager.new(attempts, attempts_error)
    journal_shell = FakeJournalShell.new(journal, journal_error)

    Ace::Overseer::Molecules::AssignmentPruneSafetyChecker.new(
      assignment_discoverer_factory: -> { FakeDiscoverer.new([info]) },
      assignment_manager_factory: -> { manager },
      journal_factory: -> { journal_shell }
    )
  end
end
