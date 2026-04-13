# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "tmpdir"
require "fileutils"

class PackageArgumentTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @project_root = find_mono_repo_root
    return if monorepo_fixture_available?

    skip "requires monorepo sibling packages (ace-bundle, ace-search)"
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
  end

  # Test running tests for a package by name from repo root
  # NOTE: This is the ONLY E2E test using REAL subprocess execution.
  # All other integration tests use mocked subprocess for speed (65x faster).
  # This test validates the actual CLI integration works end-to-end.
  # Rationale: Represents the most common usage pattern (package by name).

  def test_run_tests_for_package_by_name
    Dir.chdir(@project_root) do
      output, status = run_ace_test("ace-bundle", "atoms")

      assert status.success?, "Should run tests successfully, got: #{output}"
      assert_match(/Running tests in ace-bundle/, output)
    end
  end

  def test_run_all_tests_for_package
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("ace-bundle")

      assert status.success?, "Should run all tests successfully"
      assert_match(/Running tests in ace-bundle/, output)
    end
  end

  # Test running tests from different directory

  def test_run_tests_from_different_directory
    ace_search_dir = File.join(@project_root, "ace-search")
    Dir.chdir(ace_search_dir) do
      output, status = run_ace_test_with_mock("ace-bundle", "atoms")

      assert status.success?, "Should run tests from different directory"
      assert_match(/Running tests in ace-bundle/, output)
    end
  end

  # Test combining package with target
  # Uses mocked subprocess for speed (65x faster than real subprocess)

  def test_package_with_target
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("ace-support-nav", "atoms")

      assert status.success?, "Should run specific target for package"
      assert_match(/Running tests in ace-support-nav/, output)
    end
  end

  # Test combining package with options

  def test_package_with_profile_option
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock(
        "ace-bundle", "atoms", "--profile", "5",
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_success_output +
               Ace::TestSupport::Fixtures::TestRunnerMocks.mock_profile_output
      )

      assert status.success?, "Should run with profile option"
      assert_match(/Running tests in ace-bundle/, output)
      # Profile output should be present
      assert_match(/Slowest Tests/i, output)
    end
  end

  def test_package_with_verbose_option
    Dir.chdir(@project_root) do
      _, status = run_ace_test_with_mock("ace-bundle", "atoms", "--verbose")

      assert status.success?, "Should run with verbose option"
    end
  end

  # Test error handling for invalid packages

  def test_error_for_nonexistent_package_name
    # Non-existent package names that don't look like paths
    # are passed through to the PatternResolver as potential targets
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock(
        "nonexistent-package-xyz",
        success: false,
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_unknown_target_error("nonexistent-package-xyz")
      )

      refute status.success?, "Should fail for unknown target"
      # The error comes from PatternResolver, not PackageResolver
      assert_match(/Unknown target.*nonexistent-package-xyz/i, output)
    end
  end

  def test_removed_legacy_target_unit_fails_with_canonical_targets
    Dir.chdir(@project_root) do
      output, status = run_ace_test("ace-bundle", "unit")

      refute status.success?, "Should fail for removed legacy target"
      assert_match(/Unknown target: unit/, output)
      %w[all fast feat quick].each do |target|
        assert_match(/\b#{target}\b/, output)
      end
    end
  end

  def test_error_for_invalid_path
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock(
        "/nonexistent/path/to/package",
        success: false,
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_package_not_found_error("/nonexistent/path/to/package")
      )

      refute status.success?, "Should fail for invalid path"
      assert_match(/Package not found/, output)
    end
  end

  # Test relative path resolution

  def test_relative_path_with_dot_slash
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("./ace-bundle", "atoms",
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_success_output(package: "ace-bundle"))

      assert status.success?, "Should resolve ./ace-bundle"
      assert_match(/Running tests in ace-bundle/, output)
    end
  end

  def test_relative_path_with_double_dot
    ace_context_dir = File.join(@project_root, "ace-bundle")
    Dir.chdir(ace_context_dir) do
      output, status = run_ace_test_with_mock("../ace-support-nav", "atoms",
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_success_output(package: "ace-support-nav"))

      assert status.success?, "Should resolve ../ace-support-nav"
      assert_match(/Running tests in ace-support-nav/, output)
    end
  end

  # Test that existing behavior is preserved

  def test_target_still_works_without_package
    Dir.chdir(File.join(@project_root, "ace-bundle")) do
      output, status = run_ace_test_with_mock("atoms",
        output: "Finished tests in 0.001s\n2 tests, 4 assertions, 0 failures")

      assert status.success?, "Should run target without package"
      refute_match(/Running tests in/, output) # No package context message
    end
  end

  def test_specific_file_still_works
    Dir.chdir(File.join(@project_root, "ace-bundle")) do
      _, status = run_ace_test_with_mock(local_ace_bundle_atom_test_path)

      assert status.success?, "Should run specific file"
    end
  end

  def test_package_with_file_and_line_number
    # Verify that ace-test ace-bundle test/foo_test.rb:42 works correctly
    Dir.chdir(@project_root) do
      # Find a test file in ace-bundle with at least one test
      test_file = local_ace_bundle_atom_test_path
      # Line 10 should be within the test class
      output, status = run_ace_test_with_mock("ace-bundle", "#{test_file}:10")

      assert status.success?, "Should run package with file:line syntax, got: #{output}"
      assert_match(/Running tests in ace-bundle/, output)
      # Should only run tests near line 10
      assert_match(/\d+ tests?/, output)
    end
  end

  # Test package-prefixed file path syntax (ace-bundle/test/foo_test.rb)
  # Note: When a file path exists directly (e.g., from project root), it runs as a direct file.
  # Package context is only used when the file doesn't exist relative to current directory.
  # Uses mocked subprocess for speed (65x faster than real subprocess)

  def test_package_prefixed_file_path
    # When file exists from current directory, run it directly (no package context)
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock(ace_bundle_atom_test_path)

      assert status.success?, "Should run package-prefixed file path, got: #{output}"
      # File exists at this path, so runs directly without package context
      refute_match(/Package not found/, output)
    end
  end

  def test_package_prefixed_file_path_with_line_number
    # When file exists from current directory, run it directly with line number
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("#{ace_bundle_atom_test_path}:10")

      assert status.success?, "Should run package-prefixed file:line, got: #{output}"
      refute_match(/Package not found/, output)
      # Should only run tests near line 10
      assert_match(/\d+ tests?/, output)
    end
  end

  def test_package_prefixed_file_path_from_different_directory
    # From a different directory, package resolution is needed
    ace_search_dir = File.join(@project_root, "ace-search")
    Dir.chdir(ace_search_dir) do
      output, status = run_ace_test_with_mock(ace_bundle_atom_test_path)

      assert status.success?, "Should run package-prefixed file from different dir, got: #{output}"
      # Package context is used because file doesn't exist relative to current dir
      assert_match(/Running tests in ace-bundle/, output)
    end
  end

  # Test relative file path handling (bug fix: ./path/file.rb was misclassified as package)

  def test_relative_file_path_with_dot_slash
    # Verify ./ace-bundle/test/file.rb works without "Package not found" error
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("./#{ace_bundle_atom_test_path}",
        output: "Finished tests in 0.001s\n2 tests, 4 assertions, 0 failures")

      assert status.success?, "Should run ./path/file.rb directly, got: #{output}"
      # Should NOT show "Running tests in" because it's treated as a direct file path
      refute_match(/Package not found/, output)
    end
  end

  def test_relative_file_path_with_dot_slash_and_line_number
    # Verify ./ace-bundle/test/file.rb:10 works
    Dir.chdir(@project_root) do
      output, status = run_ace_test_with_mock("./#{ace_bundle_atom_test_path}:10",
        output: "Finished tests in 0.001s\n1 tests, 2 assertions, 0 failures")

      assert status.success?, "Should run ./path/file.rb:line directly, got: #{output}"
      refute_match(/Package not found/, output)
    end
  end

  def test_relative_file_path_from_subdirectory
    # Verify ../ace-bundle/test/file.rb works from within another package
    ace_search_dir = File.join(@project_root, "ace-search")
    Dir.chdir(ace_search_dir) do
      output, status = run_ace_test_with_mock("../#{ace_bundle_atom_test_path}",
        output: "Finished tests in 0.001s\n2 tests, 4 assertions, 0 failures")

      assert status.success?, "Should run ../path/file.rb directly, got: #{output}"
      refute_match(/Package not found/, output)
    end
  end

  # Test working directory restoration

  def test_original_directory_preserved
    Dir.chdir(@project_root) do
      original = Dir.pwd
      run_ace_test_with_mock("ace-bundle", "atoms")

      assert_equal original, Dir.pwd, "Should restore original directory"
    end
  end

  def test_directory_restored_on_error
    # Verify that working directory is restored even if tests fail
    Dir.chdir(@project_root) do
      original = Dir.pwd

      # Run tests that will fail (force an error by running nonexistent target)
      run_ace_test_with_mock("ace-bundle", "nonexistent-target-xyz",
        success: false,
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_unknown_target_error("nonexistent-target-xyz"))

      assert_equal original, Dir.pwd, "Should restore original directory even on error"
    end
  end

  def test_directory_restored_on_invalid_package
    # Verify that working directory is restored when package directory doesn't exist
    Dir.chdir(@project_root) do
      original = Dir.pwd

      # This will fail early because the path doesn't exist
      run_ace_test_with_mock("/nonexistent/path",
        success: false,
        output: Ace::TestSupport::Fixtures::TestRunnerMocks.mock_package_not_found_error("/nonexistent/path"))

      assert_equal original, Dir.pwd, "Should restore original directory on invalid package"
    end
  end

  private

  # Run ace-test with mocked subprocess (fast)
  def run_ace_test_with_mock(*args, success: true, output: nil)
    package = args.first || "ace-bundle"
    mock_output = output || Ace::TestSupport::Fixtures::TestRunnerMocks.mock_success_output(package: package)
    mock_status = success ?
      Ace::TestSupport::Fixtures::TestRunnerMocks.mock_success_status :
      Ace::TestSupport::Fixtures::TestRunnerMocks.mock_failure_status

    Open3.stub(:capture3, [mock_output, "", mock_status]) do
      run_ace_test(*args)
    end
  end

  # Run ace-test with real subprocess (slow, for end-to-end validation)
  def run_ace_test(*args)
    cmd = ["bundle", "exec", "ruby", File.join(@project_root, "ace-test-runner/exe/ace-test")] + args
    stdout, stderr, status = Open3.capture3(*cmd)
    [stdout + stderr, status]
  end

  def ace_bundle_atom_test_path
    fast = "ace-bundle/test/fast/atoms/content_checker_test.rb"
    legacy = "ace-bundle/test/atoms/content_checker_test.rb"
    return fast if File.exist?(File.join(@project_root, fast))
    return legacy if File.exist?(File.join(@project_root, legacy))

    fast
  end

  def local_ace_bundle_atom_test_path
    ace_bundle_atom_test_path.sub("ace-bundle/", "")
  end

  def monorepo_fixture_available?
    Dir.exist?(File.join(@project_root, "ace-bundle")) &&
      Dir.exist?(File.join(@project_root, "ace-search"))
  end
end
