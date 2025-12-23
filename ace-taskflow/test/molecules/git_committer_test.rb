# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/git_committer"

class GitCommitterTest < AceTaskflowTestCase
  def setup
    super
    @committer = Ace::Taskflow::Molecules::GitCommitter.new(debug: false)
  end

  # Fast unit tests with stubbed operations

  def test_execute_commit_with_valid_path_success
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        commit_result = { success: true, output: "", error: "" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test.md", "Add test")

          assert result.success?
          assert_equal "Committed: Add test", result.message
          assert_nil result.error
        end
      end
    end
  end

  def test_execute_commit_with_nonexistent_path
    @committer.stub :path_exists?, false do
      result = @committer.execute_commit("/nonexistent/file.md", "Test commit")

      refute result.success?
      assert_nil result.message
      assert_match(/Path does not exist/, result.error)
    end
  end

  def test_execute_commit_outside_git_repository
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, false do
        result = @committer.execute_commit("/tmp/test.md", "Test commit")

        refute result.success?
        assert_nil result.message
        assert_equal "Not in a git repository", result.error
      end
    end
  end

  def test_execute_commit_with_nothing_to_commit
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        # Git commit returns non-zero when nothing to commit, but message in error/output
        commit_result = { success: false, output: "nothing to commit", error: "" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test.md", "No changes")

          assert result.success?
          assert_equal "Nothing to commit", result.message
        end
      end
    end
  end

  def test_execute_commit_with_no_changes_added_to_commit
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        # Git may return "no changes added to commit" instead of "nothing to commit"
        commit_result = { success: false, output: "no changes added to commit", error: "" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test.md", "No changes")

          assert result.success?
          assert_equal "Nothing to commit", result.message
        end
      end
    end
  end

  def test_execute_commit_when_git_add_fails
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: false, output: "", error: "Failed to stage" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, add_result do
          result = @committer.execute_commit("/tmp/test.md", "Test")

          refute result.success?
          assert_match(/Failed to stage/, result.error)
        end
      end
    end
  end

  def test_execute_commit_when_git_commit_fails
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        commit_result = { success: false, output: "", error: "Commit failed" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test.md", "Test")

          refute result.success?
          assert_match(/Failed to commit/, result.error)
        end
      end
    end
  end

  def test_result_struct_success_predicate
    success_result = Ace::Taskflow::Molecules::GitCommitter::Result.new(true, "Success", nil)
    failure_result = Ace::Taskflow::Molecules::GitCommitter::Result.new(false, nil, "Error")

    assert success_result.success?
    refute failure_result.success?
  end

  def test_result_struct_fields
    result = Ace::Taskflow::Molecules::GitCommitter::Result.new(true, "Test message", "Test error")

    assert_equal true, result.success
    assert_equal "Test message", result.message
    assert_equal "Test error", result.error
  end

  def test_result_struct_backward_compatible_with_git_executor
    # Ensure the Result struct has the same fields and interface as GitExecutor::Result
    result = Ace::Taskflow::Molecules::GitCommitter::Result.new(true, "Committed: message", nil)

    # Test the same interface
    assert_respond_to result, :success
    assert_respond_to result, :message
    assert_respond_to result, :error
    assert_respond_to result, :success?
  end

  def test_execute_commit_with_directory
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        commit_result = { success: true, output: "", error: "" }

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test_directory", "Add directory")

          assert result.success?
          assert_equal "Committed: Add directory", result.message
        end
      end
    end
  end

  def test_execute_commit_with_multiline_message
    @committer.stub :path_exists?, true do
      Ace::Git::Atoms::RepositoryChecker.stub :in_git_repo?, true do
        add_result = { success: true, output: "", error: "" }
        commit_result = { success: true, output: "", error: "" }

        multiline_message = "Add feature\n\nThis is a detailed description\nwith multiple lines"

        Ace::Git::Atoms::CommandExecutor.stub :execute, ->(cmd, *args) {
          if args.first == "add"
            add_result
          elsif args.first == "commit"
            # Verify the multiline message is passed correctly
            assert_equal multiline_message, args.last
            commit_result
          else
            { success: false, output: "", error: "unknown command" }
          end
        } do
          result = @committer.execute_commit("/tmp/test.md", multiline_message)

          assert result.success?
          assert_equal "Committed: #{multiline_message}", result.message
        end
      end
    end
  end

  # Integration test - one real git workflow test
  def test_integration_real_git_workflow
    temp_dir = Dir.mktmpdir
    original_dir = Dir.pwd
    begin
      Dir.chdir(temp_dir) do
        # Initialize git repo
        `git init -q`
        `git config user.name "Test User"`
        `git config user.email "test@example.com"`

        # Create a file
        test_file = File.join(temp_dir, "test.md")
        File.write(test_file, "# Test Content")

        result = @committer.execute_commit(test_file, "Add test file")

        assert result.success?
        assert_equal "Committed: Add test file", result.message
        assert_nil result.error
      end
    ensure
      # Always restore original directory and cleanup temp dir
      Dir.chdir(original_dir) if Dir.exist?(original_dir)
      FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end
  end
end
