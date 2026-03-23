# frozen_string_literal: true

require "test_helper"

# Try to load ace-git for integration tests
begin
  require "ace/git"
rescue LoadError
  # ace-git not available in this context
end

# Contract tests for Git-related mock structures
#
# These tests ensure that mock fixtures match the actual API of git-related commands.
# If the real API changes, these tests will fail, alerting us to update mocks.
class GitContractTest < AceTestCase
  # Test that mock_command_result has correct structure
  def test_mock_command_result_structure
    result = Ace::TestSupport::Fixtures::GitMocks.mock_command_result(
      output: "test output",
      error: "test error",
      exit_status: 0
    )

    # Verify structure
    assert_kind_of Hash, result, "Result should be a Hash"
    assert result.key?(:success), "Result should have :success key"
    assert result.key?(:output), "Result should have :output key"
    assert result.key?(:error), "Result should have :error key"
    assert result.key?(:exit_code), "Result should have :exit_code key"

    # Verify types
    assert [TrueClass, FalseClass].include?(result[:success].class), ":success should be Boolean"
    assert_kind_of String, result[:output], ":output should be String"
    assert_kind_of String, result[:error], ":error should be String"
    assert_kind_of Integer, result[:exit_code], ":exit_code should be Integer"
  end

  # Test that success flag matches exit status
  def test_mock_command_result_success_logic
    # Success case
    success_result = Ace::TestSupport::Fixtures::GitMocks.mock_command_result(exit_status: 0)
    assert success_result[:success], "exit_status 0 should set success to true"
    assert_equal 0, success_result[:exit_code], "exit_code should match provided exit_status"

    # Failure case
    failure_result = Ace::TestSupport::Fixtures::GitMocks.mock_command_result(exit_status: 1)
    refute failure_result[:success], "exit_status 1 should set success to false"
    assert_equal 1, failure_result[:exit_code], "exit_code should match provided exit_status"
  end

  # Test that mock constants are valid git command outputs
  def test_mock_constants_are_realistic
    # Verify worktree list format
    assert Ace::TestSupport::Fixtures::GitMocks::MOCK_WORKTREE_LIST.include?("/"),
      "MOCK_WORKTREE_LIST should contain paths"
    assert Ace::TestSupport::Fixtures::GitMocks::MOCK_WORKTREE_LIST.include?("["),
      "MOCK_WORKTREE_LIST should contain branch indicators"

    # Verify branch list format
    assert Ace::TestSupport::Fixtures::GitMocks::MOCK_BRANCH_LIST.include?("*"),
      "MOCK_BRANCH_LIST should indicate current branch with *"

    # Verify status outputs
    assert Ace::TestSupport::Fixtures::GitMocks::MOCK_STATUS_CLEAN.include?("clean"),
      "MOCK_STATUS_CLEAN should indicate clean status"

    assert Ace::TestSupport::Fixtures::GitMocks::MOCK_STATUS_DIRTY.include?("modified"),
      "MOCK_STATUS_DIRTY should show modifications"
  end

  # Test create_task result structure for normal execution
  def test_mock_create_task_result_structure_normal
    result = Ace::TestSupport::Fixtures::GitMocks.mock_create_task_result(
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      dry_run: false
    )

    # Verify required keys
    assert result.key?(:success), "Result should have :success key"
    assert result.key?(:task_id), "Result should have :task_id key"
    assert result.key?(:task_title), "Result should have :task_title key"
    assert result.key?(:worktree_path), "Result should have :worktree_path key"
    assert result.key?(:branch), "Result should have :branch key"
    assert result.key?(:steps_completed), "Normal execution should have :steps_completed key"

    # Verify dry-run specific keys are absent
    refute result.key?(:would_create), "Normal execution should not have :would_create key"
    refute result.key?(:steps_planned), "Normal execution should not have :steps_planned key"

    # Verify types
    assert_equal true, result[:success], ":success should be true for successful operation"
    assert_kind_of String, result[:task_id], ":task_id should be String"
    assert_kind_of String, result[:task_title], ":task_title should be String"
    assert_kind_of String, result[:worktree_path], ":worktree_path should be String"
    assert_kind_of String, result[:branch], ":branch should be String"
    assert_kind_of Array, result[:steps_completed], ":steps_completed should be Array"
  end

  # Test create_task result structure for dry-run
  def test_mock_create_task_result_structure_dry_run
    result = Ace::TestSupport::Fixtures::GitMocks.mock_create_task_result(
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      dry_run: true
    )

    # Verify dry-run specific keys
    assert result.key?(:would_create), "Dry-run should have :would_create key"
    assert result.key?(:steps_planned), "Dry-run should have :steps_planned key"

    # Verify normal execution keys are absent
    refute result.key?(:steps_completed), "Dry-run should not have :steps_completed key"

    # Verify types
    assert_kind_of Hash, result[:would_create], ":would_create should be Hash"
    assert_kind_of Array, result[:steps_planned], ":steps_planned should be Array"

    # Verify would_create structure
    assert result[:would_create].key?(:worktree_path), ":would_create should have :worktree_path"
    assert result[:would_create].key?(:branch), ":would_create should have :branch"
  end

  # Test error result structure
  def test_mock_error_result_structure
    result = Ace::TestSupport::Fixtures::GitMocks.mock_error_result("Test error message")

    # Verify structure
    assert_kind_of Hash, result, "Error result should be a Hash"
    assert result.key?(:success), "Error result should have :success key"
    assert result.key?(:error), "Error result should have :error key"

    # Verify values
    assert_equal false, result[:success], "Error result :success should be false"
    assert_kind_of String, result[:error], ":error should be String"
    assert_equal "Test error message", result[:error], ":error should contain provided message"
  end

  # Integration test: Verify stub_git_command works correctly
  def test_stub_git_command_integration
    skip "ace-git not available" unless defined?(Ace::Git::Atoms::CommandExecutor)

    Ace::TestSupport::Fixtures::GitMocks.stub_git_command(output: "test output", exit_status: 0) do
      # In a real test, this would execute a command
      # Here we just verify the stub is active
      result = Ace::Git::Atoms::CommandExecutor.execute(["git", "status"])

      assert result[:success], "Stubbed command should return success"
      assert_equal "test output", result[:output], "Stubbed command should return mocked output"
    end
  end

  # Integration test: Verify stub_ace_core_config works correctly
  def test_stub_ace_core_config_integration
    skip "Ace::Core.get not available" unless defined?(Ace::Core) && Ace::Core.respond_to?(:get)

    test_config = {"test" => "value"}

    Ace::TestSupport::Fixtures::GitMocks.stub_ace_core_config(test_config) do
      # Verify stub returns mocked config
      result = Ace::Core.get
      assert_equal test_config, result, "Stubbed config should return mocked data"
    end
  end
end
