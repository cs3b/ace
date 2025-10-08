# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/git_executor"

class GitExecutorTest < AceTaskflowTestCase
  def setup
    @executor = Ace::Taskflow::Molecules::GitExecutor.new(debug: false)
  end

  # Fast unit tests with stubbed operations

  def test_execute_commit_with_valid_file_success
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "File staged", nil)
        commit_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Committed: Add test", nil)

        @executor.stub :git_add, add_result do
          @executor.stub :git_commit, commit_result do
            result = @executor.execute_commit("/tmp/test.md", "Add test")

            assert result.success?
            assert_equal "Committed: Add test", result.message
            assert_nil result.error
          end
        end
      end
    end
  end

  def test_execute_commit_with_nonexistent_file
    @executor.stub :file_exists?, false do
      result = @executor.execute_commit("/nonexistent/file.md", "Test commit")

      refute result.success?
      assert_nil result.message
      assert_match(/File does not exist/, result.error)
    end
  end

  def test_execute_commit_outside_git_repository
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, false do
        result = @executor.execute_commit("/tmp/test.md", "Test commit")

        refute result.success?
        assert_nil result.message
        assert_equal "Not in a git repository", result.error
      end
    end
  end

  def test_execute_commit_with_nothing_to_commit
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "File staged", nil)
        commit_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Nothing to commit", nil)

        @executor.stub :git_add, add_result do
          @executor.stub :git_commit, commit_result do
            result = @executor.execute_commit("/tmp/test.md", "No changes")

            assert result.success?
            assert_equal "Nothing to commit", result.message
          end
        end
      end
    end
  end

  def test_execute_commit_when_git_add_fails
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(false, nil, "Failed to stage")

        @executor.stub :git_add, add_result do
          result = @executor.execute_commit("/tmp/test.md", "Test")

          refute result.success?
          assert_equal "Failed to stage", result.error
        end
      end
    end
  end

  def test_execute_commit_when_git_commit_fails
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "File staged", nil)
        commit_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(false, nil, "Commit failed")

        @executor.stub :git_add, add_result do
          @executor.stub :git_commit, commit_result do
            result = @executor.execute_commit("/tmp/test.md", "Test")

            refute result.success?
            assert_equal "Commit failed", result.error
          end
        end
      end
    end
  end

  def test_result_struct_success_predicate
    success_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Success", nil)
    failure_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(false, nil, "Error")

    assert success_result.success?
    refute failure_result.success?
  end

  def test_result_struct_fields
    result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Test message", "Test error")

    assert_equal true, result.success
    assert_equal "Test message", result.message
    assert_equal "Test error", result.error
  end

  def test_execute_commit_with_multiline_commit_message
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "File staged", nil)
        commit_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Committed: First line\n\nSecond", nil)

        @executor.stub :git_add, add_result do
          @executor.stub :git_commit, commit_result do
            multiline_message = "First line\n\nSecond paragraph"
            result = @executor.execute_commit("/tmp/test.md", multiline_message)

            assert result.success?
            assert_includes result.message, "Committed"
          end
        end
      end
    end
  end

  def test_execute_commit_handles_special_characters_in_filename
    @executor.stub :file_exists?, true do
      @executor.stub :git_repository?, true do
        add_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "File staged", nil)
        commit_result = Ace::Taskflow::Molecules::GitExecutor::Result.new(true, "Committed: Add file", nil)

        @executor.stub :git_add, add_result do
          @executor.stub :git_commit, commit_result do
            result = @executor.execute_commit("/tmp/test file with spaces.md", "Add file with spaces")

            assert result.success?
            assert_includes result.message, "Committed"
          end
        end
      end
    end
  end

  # Integration test - one real git workflow test
  def test_integration_real_git_workflow
    temp_dir = Dir.mktmpdir
    begin
      Dir.chdir(temp_dir) do
        # Initialize git repo
        `git init -q`
        `git config user.name "Test User"`
        `git config user.email "test@example.com"`

        # Create a file
        test_file = File.join(temp_dir, "test.md")
        File.write(test_file, "# Test Content")

        result = @executor.execute_commit(test_file, "Add test file")

        assert result.success?
        assert_equal "Committed: Add test file", result.message
        assert_nil result.error
      end
    ensure
      FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end
  end
end
