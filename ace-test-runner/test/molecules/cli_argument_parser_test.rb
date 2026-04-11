# frozen_string_literal: true

require_relative "../test_helper"
require "ace/test_runner/molecules/cli_argument_parser"
require "tmpdir"
require "fileutils"

class CliArgumentParserTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @project_root = find_mono_repo_root
  end

  def teardown
    Dir.chdir(@original_dir) if Dir.pwd != @original_dir
  end

  # Test parsing package names

  def test_parses_package_name
    Dir.chdir(@project_root) do
      argv = ["ace-bundle", "atoms"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle"), "Should resolve package"
      assert_equal "atoms", result[:target]
    end
  end

  def test_parses_package_with_options
    Dir.chdir(@project_root) do
      argv = ["ace-bundle", "--verbose"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle")
      assert_includes argv, "--verbose", "Should preserve options in argv"
    end
  end

  # Test parsing direct file paths

  def test_parses_direct_file_path
    Dir.chdir(@project_root) do
      test_file = "ace-bundle/test/atoms/content_checker_test.rb"
      argv = [test_file]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:files]&.include?(test_file), "Should include file path"
      assert_nil result[:package_dir], "Should not set package_dir for direct file"
    end
  end

  def test_parses_relative_file_path_with_dot_slash
    Dir.chdir(@project_root) do
      test_file = "./ace-bundle/test/atoms/content_checker_test.rb"
      argv = [test_file]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:files]&.include?(test_file), "Should include ./path file"
    end
  end

  def test_parses_file_with_line_number
    Dir.chdir(@project_root) do
      test_file = "ace-bundle/test/atoms/content_checker_test.rb:10"
      argv = [test_file]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:files]&.include?(test_file), "Should include file:line"
    end
  end

  # Test parsing package-prefixed file paths (when not in project root)

  def test_parses_package_prefixed_path_from_different_dir
    ace_search_dir = File.join(@project_root, "ace-search")
    Dir.chdir(ace_search_dir) do
      argv = ["ace-bundle/test/atoms/content_checker_test.rb"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle")
      assert result[:files]&.include?("test/atoms/content_checker_test.rb")
    end
  end

  # Regression test: package arg + package-prefixed file path
  # Example: ace-test ace-bundle ace-bundle/test/file.rb
  # The second arg should be recognized as a file within the already-resolved package

  def test_parses_package_with_prefixed_file_path
    Dir.chdir(@project_root) do
      argv = ["ace-bundle", "ace-bundle/test/atoms/content_checker_test.rb"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle"), "Should resolve package from first arg"
      assert_equal ["test/atoms/content_checker_test.rb"], result[:files],
        "Should strip package prefix and add as relative file path"
      assert_nil result[:target], "Should not treat prefixed file as target"
    end
  end

  def test_parses_package_with_prefixed_file_path_and_line_number
    Dir.chdir(@project_root) do
      argv = ["ace-bundle", "ace-bundle/test/atoms/content_checker_test.rb:42"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle")
      assert_equal ["test/atoms/content_checker_test.rb:42"], result[:files],
        "Should handle file:line syntax with package prefix"
    end
  end

  def test_parses_package_with_multiple_prefixed_files
    Dir.chdir(@project_root) do
      # Find two existing test files in ace-bundle
      argv = [
        "ace-bundle",
        "ace-bundle/test/atoms/content_checker_test.rb",
        "ace-bundle/test/atoms/preset_validator_test.rb"
      ]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:package_dir]&.end_with?("ace-bundle")
      assert_equal 2, result[:files]&.size, "Should handle multiple prefixed files"
      assert_includes result[:files], "test/atoms/content_checker_test.rb"
      assert_includes result[:files], "test/atoms/preset_validator_test.rb"
    end
  end

  # Test parsing targets

  def test_parses_target_only
    Dir.chdir(File.join(@project_root, "ace-bundle")) do
      argv = ["atoms"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert_equal "atoms", result[:target]
      assert_nil result[:package_dir]
    end
  end

  def test_known_target_method
    parser = Ace::TestRunner::Molecules::CliArgumentParser.new([])

    assert parser.known_target?("atoms")
    assert parser.known_target?("molecules")
    assert parser.known_target?("fast")
    assert parser.known_target?("feat")
    assert parser.known_target?("unit")
    assert parser.known_target?("integration")
    assert parser.known_target?("int")
    assert parser.known_target?("all")
    refute parser.known_target?("foo")
    refute parser.known_target?("e2e")
    refute parser.known_target?("all-with-e2e")
    refute parser.known_target?("ace-bundle")
  end

  # Test error handling

  def test_raises_error_for_invalid_explicit_path
    Dir.chdir(@project_root) do
      argv = ["/nonexistent/path/to/package"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)

      error = assert_raises(ArgumentError) { parser.parse }
      assert_match(/Package not found/, error.message)
    end
  end

  def test_raises_error_for_nonexistent_file_with_line
    Dir.chdir(@project_root) do
      argv = ["atoms", "nonexistent_file.rb:10"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)

      error = assert_raises(ArgumentError) { parser.parse }
      assert_match(/File not found/, error.message)
    end
  end

  # Test relative path handling

  def test_parses_relative_path_with_double_dot
    ace_context_dir = File.join(@project_root, "ace-bundle")
    Dir.chdir(ace_context_dir) do
      test_file = "../ace-support-nav/test/cli_test.rb"
      next unless File.exist?(test_file) # Skip if file doesn't exist

      argv = [test_file]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      result = parser.parse

      assert result[:files]&.include?(test_file)
    end
  end

  # Test that options are preserved

  def test_preserves_option_flags_in_argv
    Dir.chdir(@project_root) do
      argv = ["ace-bundle", "--verbose", "--profile", "10"]
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(argv)
      parser.parse

      assert_includes argv, "--verbose"
      assert_includes argv, "--profile"
      assert_includes argv, "10"
    end
  end

  def test_normalizes_legacy_targets_to_new_public_names
    Dir.chdir(File.join(@project_root, "ace-bundle")) do
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(["unit"])
      assert_equal "fast", parser.parse[:target]

      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(["integration"])
      assert_equal "feat", parser.parse[:target]

      parser = Ace::TestRunner::Molecules::CliArgumentParser.new(["int"])
      assert_equal "feat", parser.parse[:target]
    end
  end
end
