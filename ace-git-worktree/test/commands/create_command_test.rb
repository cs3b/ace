# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTest < Minitest::Test
  def setup
    setup_temp_dir
    @command = Ace::Git::Worktree::Commands::CreateCommand.new
  end

  def teardown
    teardown_temp_dir
  end

  def test_run_with_help_flag
    result = @command.run(["--help"])
    assert_equal 0, result
  end

  def test_run_with_no_arguments_shows_help
    result = @command.run([])
    # Should show help and return success
    assert_equal 0, result
  end

  def test_run_with_task_argument
    # Mock successful task creation
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree", "checkout_branch"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = command.run(["--task", "081"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_run_with_task_and_dry_run
    # Mock successful dry run
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/path/to/worktree",
        branch: "task-081"
      },
      steps_planned: ["create_worktree", "checkout_branch"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = command.run(["--task", "081", "--dry-run"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_run_with_traditional_branch
    # Mock successful traditional worktree creation
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    result = command.run(["feature-branch"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_branch_and_path
    # Mock successful traditional worktree creation with custom path
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    result = command.run(["feature-branch", "--path", "/custom/path"])
    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_run_with_invalid_task_id
    # Mock ace-task availability and task fetch
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, {
      success: false,
      error: "Task not found: invalid"
    }, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = command.run(["--task", "invalid"])
      # Should handle invalid task gracefully
      assert_equal 1, result
      mock_worktree_manager.verify
    end
  end

  def test_run_with_dangerous_task_id
    # Security test: Verify dangerous inputs are rejected BEFORE manager is called.
    # No manager mock needed - if validation fails and manager is called,
    # the test would error (manager would try real operations).
    dangerous_ids = [
      "081; rm -rf /",
      "081`whoami`",
      "081|cat /etc/passwd",
      "081$(whoami)",
      "../../etc/passwd"
    ]

    dangerous_ids.each do |dangerous_id|
      result = @command.run(["--task", dangerous_id])
      assert_equal 1, result, "Should reject dangerous task ID: #{dangerous_id}"
    end
  end

  def test_run_with_missing_task_argument
    result = @command.run(["--task"])
    assert_equal 1, result
  end

  def test_parse_arguments_with_task_flag
    # We can't directly test parse_arguments as it's private,
    # but we can test the behavior through run()
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/custom/path",
        branch: "task-081"
      },
      steps_planned: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
      assert_equal "081", task_ref
      assert_equal true, options[:dry_run]
      assert_equal "/custom/path", options[:path]
      mock_result
    end

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = command.run(["--task", "081", "--dry-run", "--path", "/custom/path"])
      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_handles_worktree_manager_errors
    # Mock worktree manager throwing an ace-git error
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, nil) do
      raise Ace::Git::GitError, "Git command failed"
    end

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    result = command.run(["--task", "081"])
    assert_equal 1, result
    mock_worktree_manager.verify
  end

  def test_argument_validation_errors
    # Test validation of contradictory arguments
    result = @command.run(["--task", "081", "feature-branch"])
    # Should fail because both task and branch specified
    assert_equal 1, result
  end

  def test_long_task_reference_formats
    task_formats = [
      "081",
      "task.081",
      "v.0.9.0+081",
      "v.0.9.0+task.081"
    ]

    task_formats.each do |task_format|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: task_format,
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

      command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

      command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = command.run(["--task", task_format, "--dry-run"])
        assert_equal 0, result, "Should accept task format: #{task_format}"
        mock_worktree_manager.verify
      end
    end
  end

  def test_security_validation_on_paths
    skip "Security validation only checks shell injection patterns, not absolute/system paths - needs design decision on whether to reject absolute paths"

    dangerous_paths = [
      "/etc/passwd",
      "../../../root",
      "/tmp; rm -rf /",
      "$(rm -rf /)",
      "`whoami`"
    ]

    dangerous_paths.each do |dangerous_path|
      result = @command.run(["--task", "081", "--path", dangerous_path, "--dry-run"])
      assert_equal 1, result, "Should reject dangerous path: #{dangerous_path}"
    end
  end

  def test_cli_override_flags_are_passed_through_task_creation
    # Test that CLI override flags are properly passed through the manager chain (critical for review feedback)
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      would_create: {
        worktree_path: "/path/to/worktree",
        branch: "task-081"
      },
      steps_planned: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
      assert_equal "081", task_ref
      # Test that all CLI override flags are properly passed through
      assert_equal true, options[:no_mise_trust], "Should pass through --no-mise-trust"
      assert_equal true, options[:no_status_update], "Should pass through --no-status-update"
      assert_equal true, options[:no_commit], "Should pass through --no-commit"
      assert_equal "Custom commit message", options[:commit_message], "Should pass through --commit-message"
      assert_equal true, options[:dry_run], "Should pass through --dry-run"
      mock_result
    end

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      result = command.run([
        "--task", "081",
        "--no-mise-trust",
        "--no-status-update",
        "--no-commit",
        "--commit-message", "Custom commit message",
        "--dry-run"
      ])

      assert_equal 0, result
      mock_worktree_manager.verify
    end
  end

  def test_cli_override_flags_are_passed_through_traditional_creation
    # Test that CLI override flags work for traditional worktree creation too
    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create, { success: true }) do |branch_name, options|
      assert_equal "feature-branch", branch_name
      # Test that relevant CLI override flags are properly passed through
      assert_equal true, options[:no_mise_trust], "Should pass through --no-mise-trust"
      assert_equal "/custom/path", options[:path], "Should pass through --path"
      assert_equal true, options[:force], "Should pass through --force"
      { success: true }
    end

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    result = command.run([
      "feature-branch",
      "--path", "/custom/path",
      "--no-mise-trust",
      "--force"
    ])

    assert_equal 0, result
    mock_worktree_manager.verify
  end

  def test_individual_override_flags_work
    # Test each override flag individually to ensure they work in isolation
    override_flags = [
      ["--no-mise-trust", :no_mise_trust],
      ["--no-status-update", :no_status_update],
      ["--no-commit", :no_commit]
    ]

    override_flags.each do |flag, option_key|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: "081",
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
        assert_equal true, options[option_key], "Should set #{option_key} to true for #{flag}"
        mock_result
      end

      command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

      command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = command.run(["--task", "081", flag, "--dry-run"])
        assert_equal 0, result, "Should handle #{flag} flag correctly"
        mock_worktree_manager.verify
      end
    end
  end

  def test_commit_message_override_works
    # Test that custom commit messages are properly passed through
    test_messages = [
      "Implement feature X",
      "Fix security vulnerability",
      "Update dependencies",
      "WIP: experimental changes"
    ]

    test_messages.each do |commit_message|
      mock_worktree_manager = Minitest::Mock.new
      mock_result = {
        success: true,
        task_id: "081",
        task_title: "Test task",
        would_create: {
          worktree_path: "/path/to/worktree",
          branch: "task-081"
        },
        steps_planned: ["create_worktree"]
      }
      mock_worktree_manager.expect(:create_task, mock_result) do |task_ref, options|
        assert_equal commit_message, options[:commit_message], "Should pass through custom commit message"
        mock_result
      end

      command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

      command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
        result = command.run([
          "--task", "081",
          "--commit-message", commit_message,
          "--dry-run"
        ])

        assert_equal 0, result, "Should handle commit message: #{commit_message}"
        mock_worktree_manager.verify
      end
    end
  end

  # PR worktree creation tests using PrMetadataFetcher
  def test_run_with_pr_argument_success
    # Mock gh CLI availability
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, true) do
        # Mock PR metadata fetch
        mock_metadata_result = {
          success: true,
          metadata: {
            "number" => 26,
            "title" => "Add authentication feature",
            "headRefName" => "feature/auth",
            "baseRefName" => "main",
            "isCrossRepository" => false,
            "headRepositoryOwner" => { "login" => "owner" }
          }
        }
        Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_metadata, mock_metadata_result) do
          # Mock worktree creation
          mock_worktree_manager = Minitest::Mock.new
          mock_worktree_manager.expect(:create_pr, {
            success: true,
            pr_number: 26,
            pr_title: "Add authentication feature",
            worktree_path: "/path/to/worktree",
            branch: "pr-26",
            tracking: "origin/feature/auth",
            directory_name: "ace-pr-26"
          }, [Integer, Hash, Hash])

          command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)
          result = command.run(["--pr", "26"])

          assert_equal 0, result
          mock_worktree_manager.verify
        end
      end
    end
  end

  def test_run_with_pr_fork_warning
    # Mock gh CLI availability
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, true) do
        # Mock PR metadata for a fork
        mock_metadata_result = {
          success: true,
          metadata: {
            "number" => 42,
            "title" => "Fork contribution",
            "headRefName" => "fix/issue",
            "baseRefName" => "main",
            "isCrossRepository" => true,
            "headRepositoryOwner" => { "login" => "contributor" }
          }
        }
        Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_metadata, mock_metadata_result) do
          mock_worktree_manager = Minitest::Mock.new
          mock_worktree_manager.expect(:create_pr, {
            success: true,
            pr_number: 42,
            pr_title: "Fork contribution",
            worktree_path: "/path/to/worktree",
            branch: "pr-42",
            tracking: "origin/fix/issue",
            directory_name: "ace-pr-42"
          }, [Integer, Hash, Hash])

          command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)
          # Capture output to verify fork warning
          output = capture_io do
            result = command.run(["--pr", "42"])
            assert_equal 0, result
          end.first

          assert_match(/fork/, output.downcase)
          assert_match(/contributor/, output)
          mock_worktree_manager.verify
        end
      end
    end
  end

  def test_run_with_pr_not_found_error
    # Mock gh CLI availability
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, true) do
        # Mock PR not found error
        Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_metadata, ->(id, **_opts) {
          raise Ace::Git::PrNotFoundError, "PR not found: #{id}"
        }) do
          output = capture_io do
            result = @command.run(["--pr", "99999"])
            assert_equal 1, result
          end.first

          assert_match(/PR not found/, output)
          assert_match(/Suggestions/, output)
        end
      end
    end
  end

  def test_run_with_pr_auth_error
    # Mock gh CLI availability
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, true) do
        # Mock auth error during fetch
        Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_metadata, ->(*_args) {
          raise Ace::Git::GhAuthenticationError, "Not authenticated with GitHub"
        }) do
          output = capture_io do
            result = @command.run(["--pr", "26"])
            assert_equal 1, result
          end.first

          assert_match(/Not authenticated/, output)
          assert_match(/gh auth status/, output)
        end
      end
    end
  end

  def test_run_with_pr_gh_not_installed
    # Mock gh CLI not installed
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, false) do
      output = capture_io do
        result = @command.run(["--pr", "26"])
        assert_equal 1, result
      end.first

      assert_match(/gh CLI is required/, output)
    end
  end

  def test_run_with_pr_not_authenticated
    # Mock gh CLI installed but not authenticated
    Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_installed?, true) do
      Ace::Git::Molecules::PrMetadataFetcher.stub(:gh_authenticated?, false) do
        output = capture_io do
          result = @command.run(["--pr", "26"])
          assert_equal 1, result
        end.first

        assert_match(/not authenticated/, output.downcase)
        assert_match(/gh auth login/, output)
      end
    end
  end

  def test_run_with_invalid_pr_number
    result = @command.run(["--pr", "abc"])
    assert_equal 1, result
  end

  def test_run_with_empty_pr_number
    result = @command.run(["--pr", ""])
    assert_equal 1, result
  end

  def test_pr_and_task_conflict
    result = @command.run(["--pr", "26", "--task", "081"])
    assert_equal 1, result
  end

  def test_run_with_pr_upper_bound_validation
    # Test that PR numbers above 999999 are rejected
    result = @command.run(["--pr", "1000000"])
    assert_equal 1, result
  end

  def test_run_with_pr_negative_number
    # Test that negative PR numbers are rejected (after to_i conversion, pattern matches digits only)
    result = @command.run(["--pr", "-1"])
    assert_equal 1, result
  end

  # Tmux integration tests

  def test_tmux_disabled_shows_cd_hint
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      command.stub(:tmux_enabled?, false) do
        output = capture_io do
          result = command.run(["--task", "081"])
          assert_equal 0, result
        end.first

        assert_match(/cd \/path\/to\/worktree/, output)
        mock_worktree_manager.verify
      end
    end
  end

  def test_tmux_enabled_with_ace_tmux_available_calls_exec
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    exec_called_with = nil
    mock_exec = ->(* args) { exec_called_with = args }

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      command.stub(:tmux_enabled?, true) do
        command.stub(:ace_tmux_available?, true) do
          Kernel.stub(:exec, mock_exec) do
            capture_io do
              result = command.run(["--task", "081"])
              assert_equal 0, result
            end
          end
        end
      end
    end

    assert_equal ["ace-tmux", "--root", "/path/to/worktree"], exec_called_with
    mock_worktree_manager.verify
  end

  def test_tmux_enabled_without_ace_tmux_shows_warning_and_cd
    mock_worktree_manager = Minitest::Mock.new
    mock_result = {
      success: true,
      task_id: "081",
      task_title: "Test task",
      worktree_path: "/path/to/worktree",
      branch: "task-081",
      steps_completed: ["create_worktree"]
    }
    mock_worktree_manager.expect(:create_task, mock_result, [String, Hash])

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    command.stub(:check_task_dependency_availability, { available: true, message: "mocked" }) do
      command.stub(:tmux_enabled?, true) do
        command.stub(:ace_tmux_available?, false) do
          output = capture_io do
            result = command.run(["--task", "081"])
            assert_equal 0, result
          end.first

          assert_match(/Warning.*tmux.*enabled.*ace-tmux.*not installed/, output)
          assert_match(/cd \/path\/to\/worktree/, output)
          mock_worktree_manager.verify
        end
      end
    end
  end

  def test_debug_output_on_error
    # Test that DEBUG mode provides additional error info without crashing
    # Note: TimeoutError has specific handling, so we use GitError to test the generic debug path
    original_debug = ENV["DEBUG"]
    ENV["DEBUG"] = "1"

    mock_worktree_manager = Minitest::Mock.new
    mock_worktree_manager.expect(:create_task, nil) do
      raise Ace::Git::GitError, "Unexpected git operation failed"
    end

    command = Ace::Git::Worktree::Commands::CreateCommand.new(manager: mock_worktree_manager)

    output = capture_io do
      result = command.run(["--task", "081"])
      assert_equal 1, result
    end.first

    # Debug mode should show the exception class for generic errors
    assert_match(/Debug:.*Ace::Git::GitError/, output)
    mock_worktree_manager.verify
  ensure
    if original_debug.nil?
      ENV.delete("DEBUG")
    else
      ENV["DEBUG"] = original_debug
    end
  end
end