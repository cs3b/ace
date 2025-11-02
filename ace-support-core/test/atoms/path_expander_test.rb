# frozen_string_literal: true

require "test_helper"
require "ace/core/atoms/path_expander"
require "tmpdir"
require "fileutils"

class PathExpanderTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @project_root = File.join(@tmpdir, "project")
    @config_dir = File.join(@project_root, ".ace", "config")
    @docs_dir = File.join(@project_root, "docs")

    # Create directory structure
    FileUtils.mkdir_p(@config_dir)
    FileUtils.mkdir_p(@docs_dir)

    # Create a .git marker for project root detection
    FileUtils.mkdir_p(File.join(@project_root, ".git"))

    # Create some test files
    @config_file = File.join(@config_dir, "test.yml")
    @doc_file = File.join(@docs_dir, "readme.md")
    FileUtils.touch(@config_file)
    FileUtils.touch(@doc_file)

    # Store original directory and environment
    @original_dir = Dir.pwd
    @original_project_root = ENV['PROJECT_ROOT_PATH']

    # Set test project root for ProjectRootFinder
    ENV['PROJECT_ROOT_PATH'] = @project_root
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)

    # Restore environment
    if @original_project_root
      ENV['PROJECT_ROOT_PATH'] = @original_project_root
    else
      ENV.delete('PROJECT_ROOT_PATH')
    end
  end

  # === Factory Method Tests ===

  def test_for_file_creates_instance_with_inferred_context
    Dir.chdir(@project_root) do
      expander = Ace::Core::Atoms::PathExpander.for_file(@config_file)

      assert_instance_of Ace::Core::Atoms::PathExpander, expander
      assert_equal @config_dir, expander.source_dir
      # Project root should be the test tmp directory (has .git marker)
      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
    end
  end

  def test_for_file_handles_relative_source_file
    Dir.chdir(@project_root) do
      relative_path = ".ace/config/test.yml"
      expander = Ace::Core::Atoms::PathExpander.for_file(relative_path)

      assert_equal File.realpath(@config_dir), File.realpath(expander.source_dir)
      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
    end
  end

  def test_for_cli_uses_current_directory_as_source_dir
    Dir.chdir(@docs_dir) do
      expander = Ace::Core::Atoms::PathExpander.for_cli

      assert_instance_of Ace::Core::Atoms::PathExpander, expander
      assert_equal File.realpath(@docs_dir), File.realpath(expander.source_dir)
      assert_equal File.realpath(@project_root), File.realpath(expander.project_root)
    end
  end

  # === Context Validation Tests ===

  def test_initialize_raises_error_when_source_dir_nil
    error = assert_raises(ArgumentError) do
      Ace::Core::Atoms::PathExpander.new(source_dir: nil, project_root: "/project")
    end

    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
    assert_match(/source_dir: nil/, error.message)
  end

  def test_initialize_raises_error_when_project_root_nil
    error = assert_raises(ArgumentError) do
      Ace::Core::Atoms::PathExpander.new(source_dir: "/source", project_root: nil)
    end

    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
    assert_match(/project_root: nil/, error.message)
  end

  def test_initialize_raises_error_when_both_nil
    error = assert_raises(ArgumentError) do
      Ace::Core::Atoms::PathExpander.new(source_dir: nil, project_root: nil)
    end

    assert_match(/requires both 'source_dir' and 'project_root'/, error.message)
  end

  def test_initialize_succeeds_with_valid_parameters
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    assert_equal @config_dir, expander.source_dir
    assert_equal @project_root, expander.project_root
  end

  # === Resolution Tests: Source-Relative Paths ===

  def test_resolve_source_relative_path_with_dot_slash
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("./local.yml")
    expected = File.join(@config_dir, "local.yml")

    assert_equal expected, result
  end

  def test_resolve_source_relative_path_with_parent
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("../other/file.md")
    expected = File.expand_path("../other/file.md", @config_dir)

    assert_equal expected, result
  end

  # === Resolution Tests: Project-Relative Paths ===

  def test_resolve_project_relative_path
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("docs/readme.md")
    expected = File.join(@project_root, "docs/readme.md")

    assert_equal expected, result
  end

  def test_resolve_project_relative_path_with_subdirs
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("ace-core/lib/ace/core.rb")
    expected = File.join(@project_root, "ace-core/lib/ace/core.rb")

    assert_equal expected, result
  end

  # === Resolution Tests: Absolute Paths ===

  def test_resolve_absolute_path
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    absolute = "/opt/custom/path.txt"
    result = expander.resolve(absolute)

    assert_equal absolute, result
  end

  # === Resolution Tests: Environment Variables ===

  def test_resolve_expands_env_var_dollar_format
    ENV['TEST_VAR'] = '/test/path'

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("$TEST_VAR/file.txt")
    expected = "/test/path/file.txt"

    assert_equal expected, result
  ensure
    ENV.delete('TEST_VAR')
  end

  def test_resolve_expands_env_var_brace_format
    ENV['TEST_VAR'] = '/test/path'

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("${TEST_VAR}/file.txt")
    expected = "/test/path/file.txt"

    assert_equal expected, result
  ensure
    ENV.delete('TEST_VAR')
  end

  def test_resolve_keeps_undefined_env_var
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    # Undefined variable should be left as-is and treated as project-relative
    result = expander.resolve("$UNDEFINED_VAR/file.txt")

    # Should be expanded from project root since $UNDEFINED_VAR stays literal
    assert result.include?(@project_root)
    assert result.include?("$UNDEFINED_VAR/file.txt")
  end

  # === Resolution Tests: Edge Cases ===

  def test_resolve_returns_nil_for_nil_path
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    assert_nil expander.resolve(nil)
  end

  def test_resolve_returns_nil_for_empty_path
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    assert_nil expander.resolve("")
  end

  def test_resolve_handles_whitespace_in_path
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    result = expander.resolve("docs/file with spaces.md")
    expected = File.join(@project_root, "docs/file with spaces.md")

    assert_equal expected, result
  end

  # === Multiple Resolutions with Same Instance ===

  def test_resolve_multiple_paths_with_same_instance
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    # Source-relative
    result1 = expander.resolve("./local.yml")
    assert result1.start_with?(@config_dir)

    # Project-relative
    result2 = expander.resolve("docs/readme.md")
    assert result2.start_with?(@project_root)

    # Absolute
    result3 = expander.resolve("/absolute/path")
    assert_equal "/absolute/path", result3

    # All should be resolved correctly
    assert_equal File.join(@config_dir, "local.yml"), result1
    assert_equal File.join(@project_root, "docs/readme.md"), result2
  end

  # === Attribute Readers ===

  def test_source_dir_reader
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    assert_equal @config_dir, expander.source_dir
  end

  def test_project_root_reader
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @config_dir,
      project_root: @project_root
    )

    assert_equal @project_root, expander.project_root
  end
end
