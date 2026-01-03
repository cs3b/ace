# frozen_string_literal: true

require_relative "test_helper"

# Test the test helper methods themselves to ensure they work correctly
class TestHelperTest < AceTaskflowTestCase
  # Include ConfigHelpers for with_real_config
  include Ace::TestSupport::ConfigHelpers

  def test_with_real_test_project_yields_directory
    with_real_test_project do |dir|
      refute_nil dir
      assert_kind_of String, dir
      assert Dir.exist?(dir)
      # Verify we're chdir'd into a directory that contains the yielded path
      # On macOS, /var and /private/var are the same, so we check basename
      assert_equal File.basename(dir), File.basename(Dir.pwd)
    end
  end

  def test_with_real_test_project_creates_taskflow_structure
    with_real_test_project do |dir|
      taskflow_dir = File.join(dir, ".ace-taskflow")
      assert Dir.exist?(taskflow_dir)
    end
  end

  def test_with_real_test_project_has_test_fixtures
    with_real_test_project do |dir|
      # Should have sample tasks from test fixtures
      tasks_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t")
      assert Dir.exist?(tasks_dir)

      # Should have at least one task file
      task_files = Dir.glob(File.join(tasks_dir, "**", "*.s.md"))
      refute_empty task_files
    end
  end

  def test_with_real_test_project_cleanup_after_execution
    dir_before = nil
    with_real_test_project do |dir|
      dir_before = dir
      assert Dir.exist?(dir)
    end

    # Directory should still exist (cleanup happens in teardown, not immediately)
    # But we should verify the block completed successfully
    refute_nil dir_before
  end

  def test_with_real_test_project_nests_helpers_correctly
    # This test verifies the nesting works correctly
    with_real_test_project do |dir|
      refute_nil dir
      # We're inside all three helpers now
      assert Dir.exist?(File.join(dir, ".ace-taskflow"))
    end
  end

  def test_with_real_tmpdir_yields_directory
    with_real_tmpdir do |dir|
      refute_nil dir
      assert_kind_of String, dir
      assert Dir.exist?(dir)
      # Verify we're chdir'd into a directory that contains the yielded path
      # On macOS, /var and /private/var are the same, so we check basename
      assert_equal File.basename(dir), File.basename(Dir.pwd)
    end
  end

  def test_with_real_tmpdir_has_no_taskflow_fixtures
    with_real_tmpdir do |dir|
      taskflow_dir = File.join(dir, ".ace-taskflow")
      refute Dir.exist?(taskflow_dir), "with_real_tmpdir should not create taskflow fixtures"
    end
  end

  def test_with_real_tmpdir_allows_custom_setup
    with_real_tmpdir do |dir|
      # Create a custom file
      test_file = File.join(dir, "custom.txt")
      File.write(test_file, "test content")
      assert File.exist?(test_file)
      assert_equal "test content", File.read(test_file)
    end
  end

  def test_with_test_project_has_documentation
    # Verify the base helper is available
    assert_respond_to self, :with_test_project, "should have with_test_project method"
    # Check it comes from TestFactory
    with_test_project do |dir|
      assert Dir.exist?(dir)
    end
  end

  def test_with_clean_project_has_documentation
    # Verify the base helper is available
    assert_respond_to self, :with_clean_project, "should have with_clean_project method"
    # Check it creates a project (it may have minimal structure from TestFactory)
    with_clean_project do |dir|
      assert Dir.exist?(dir)
    end
  end
end
