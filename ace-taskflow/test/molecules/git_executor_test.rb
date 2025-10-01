# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/git_executor"

class GitExecutorTest < AceTaskflowTestCase
  def setup
    @executor = Ace::Taskflow::Molecules::GitExecutor.new(debug: false)
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_execute_commit_with_valid_file_in_git_repo
    Dir.chdir(@temp_dir) do
      # Initialize git repo
      `git init`
      `git config user.name "Test User"`
      `git config user.email "test@example.com"`

      # Create a file
      test_file = File.join(@temp_dir, "test.md")
      File.write(test_file, "# Test Content")

      result = @executor.execute_commit(test_file, "Add test file")

      assert result.success?
      assert_equal "Committed: Add test file", result.message
      assert_nil result.error
    end
  end

  def test_execute_commit_with_nonexistent_file
    Dir.chdir(@temp_dir) do
      `git init`

      result = @executor.execute_commit("/nonexistent/file.md", "Test commit")

      refute result.success?
      assert_nil result.message
      assert_match(/File does not exist/, result.error)
    end
  end

  def test_execute_commit_outside_git_repository
    Dir.chdir(@temp_dir) do
      # Don't initialize git repo
      test_file = File.join(@temp_dir, "test.md")
      File.write(test_file, "Content")

      result = @executor.execute_commit(test_file, "Test commit")

      refute result.success?
      assert_nil result.message
      assert_equal "Not in a git repository", result.error
    end
  end

  def test_execute_commit_with_nothing_to_commit
    Dir.chdir(@temp_dir) do
      `git init`
      `git config user.name "Test User"`
      `git config user.email "test@example.com"`

      # Create and commit a file
      test_file = File.join(@temp_dir, "test.md")
      File.write(test_file, "Content")
      `git add #{test_file}`
      `git commit -m "Initial commit"`

      # Try to commit again without changes
      result = @executor.execute_commit(test_file, "No changes")

      assert result.success?
      assert_equal "Nothing to commit", result.message
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
    Dir.chdir(@temp_dir) do
      `git init`
      `git config user.name "Test User"`
      `git config user.email "test@example.com"`

      test_file = File.join(@temp_dir, "test.md")
      File.write(test_file, "Content")

      multiline_message = "First line\n\nSecond paragraph"
      result = @executor.execute_commit(test_file, multiline_message)

      assert result.success?
      assert_includes result.message, "Committed"
    end
  end

  def test_execute_commit_handles_special_characters_in_filename
    Dir.chdir(@temp_dir) do
      `git init`
      `git config user.name "Test User"`
      `git config user.email "test@example.com"`

      # Create file with spaces in name
      test_file = File.join(@temp_dir, "test file with spaces.md")
      File.write(test_file, "Content")

      result = @executor.execute_commit(test_file, "Add file with spaces")

      assert result.success?
      assert_equal "Committed: Add file with spaces", result.message
    end
  end
end
