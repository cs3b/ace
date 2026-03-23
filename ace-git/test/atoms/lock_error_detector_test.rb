# frozen_string_literal: true

require_relative "../test_helper"

class LockErrorDetectorTest < AceGitTestCase
  def setup
    super
    @detector = Ace::Git::Atoms::LockErrorDetector
  end

  def test_detects_unable_to_create_lock_error
    stderr = "fatal: Unable to create '.git/index.lock': File exists."
    assert @detector.lock_error?(stderr), "Should detect 'Unable to create' lock error"
  end

  def test_detects_cannot_create_lock_error
    stderr = "fatal: cannot create .git/index.lock: File exists"
    assert @detector.lock_error?(stderr), "Should detect 'cannot create' lock error"
  end

  def test_detects_another_git_process_error
    stderr = "fatal: Another git process seems to be running in this repository"
    assert @detector.lock_error?(stderr), "Should detect 'another git process' error"
  end

  def test_detects_generic_index_lock_error
    stderr = "error: .git/index.lock exists"
    assert @detector.lock_error?(stderr), "Should detect generic index.lock error"
  end

  def test_returns_false_for_non_lock_errors
    stderr = "error: pathspec 'unknown' did not match any file(s) known to git"
    refute @detector.lock_error?(stderr), "Should not detect non-lock errors as lock errors"
  end

  def test_returns_false_for_empty_string
    refute @detector.lock_error?(""), "Should return false for empty string"
  end

  def test_returns_false_for_nil
    refute @detector.lock_error?(nil), "Should return false for nil"
  end

  def test_lock_error_result_returns_true_for_lock_error
    result = {success: false, error: "fatal: Unable to create '.git/index.lock': File exists.", exit_code: 128}
    assert @detector.lock_error_result?(result), "Should detect lock error from result hash"
  end

  def test_lock_error_result_returns_false_for_success
    result = {success: true, output: "test\n", error: "", exit_code: 0}
    refute @detector.lock_error_result?(result), "Should return false for successful result"
  end

  def test_lock_error_result_returns_false_for_non_lock_error
    result = {success: false, error: "error: pathspec unknown", exit_code: 128}
    refute @detector.lock_error_result?(result), "Should not detect non-lock errors from result hash"
  end

  def test_lock_error_result_returns_false_for_nil_result
    refute @detector.lock_error_result?(nil), "Should return false for nil result"
  end

  def test_lock_error_result_returns_false_for_empty_error
    result = {success: false, error: "", exit_code: 1}
    refute @detector.lock_error_result?(result), "Should return false when error is empty"
  end

  def test_lock_error_result_returns_false_for_nil_error
    result = {success: false, error: nil, exit_code: 1}
    refute @detector.lock_error_result?(result), "Should return false when error is nil"
  end

  def test_case_insensitive_pattern_matching
    stderr = "FATAL: UNABLE TO CREATE '.GIT/INDEX.LOCK': FILE EXISTS."
    assert @detector.lock_error?(stderr), "Should detect lock error case-insensitively"
  end

  def test_detects_lock_error_with_additional_context
    stderr = "error: Could not write to '.git/index.lock': File exists.\n" \
             "Hint: Another git process may be running."
    assert @detector.lock_error?(stderr), "Should detect lock error with additional context"
  end
end
