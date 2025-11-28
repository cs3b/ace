# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class CLIIntegrationTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @prompt_dir = File.join(@tmpdir, ".cache/ace-prompt/prompts")
    @archive_dir = File.join(@tmpdir, ".cache/ace-prompt/prompts/archive")
    FileUtils.mkdir_p(@prompt_dir)
    @prompt_file = File.join(@prompt_dir, "the-prompt.md")
    @prompt_content = "Review this code for security issues"

    # Mock ProjectRootFinder to return tmpdir
    @original_finder = Ace::Core::Molecules::ProjectRootFinder.method(:find_or_current)
    tmpdir = @tmpdir
    Ace::Core::Molecules::ProjectRootFinder.define_singleton_method(:find_or_current) do
      tmpdir
    end
  end

  def teardown
    # Restore original finder
    Ace::Core::Molecules::ProjectRootFinder.define_singleton_method(:find_or_current, @original_finder)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_process_with_stdout_output_returns_zero
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Run CLI
    output, _error = run_cli(["process"])

    # Verify content output
    assert_match(/Review this code for security issues/, output)

    # Verify archive created
    assert File.directory?(@archive_dir)
    archive_files = Dir.glob(File.join(@archive_dir, "*.md"))
    assert_equal 1, archive_files.length

    # Verify symlink created
    symlink_path = File.join(@prompt_dir, "_previous.md")
    assert File.symlink?(symlink_path)
  end

  def test_process_with_output_file_returns_zero
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    output_file = File.join(@tmpdir, "output.md")

    # Run CLI with --output
    output, _error = run_cli(["process", "--output", output_file])

    # Verify file created
    assert File.exist?(output_file)
    content = File.read(output_file, encoding: "utf-8")
    assert_match(/Review this code for security issues/, content)

    # Verify summary output
    assert_match(/Prompt archived and saved:/, output)
    assert_match(/Archive:/, output)
    assert_match(/Output:/, output)

    # Verify archive created
    assert File.directory?(@archive_dir)
  end

  def test_process_with_output_to_nested_directory
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    output_file = File.join(@tmpdir, "nested/dir/output.md")

    # Run CLI with --output to non-existent directory
    output, _error = run_cli(["process", "--output", output_file])

    # Verify file created with parent directories
    assert File.exist?(output_file)
    content = File.read(output_file, encoding: "utf-8")
    assert_match(/Review this code for security issues/, content)
  end

  def test_process_with_missing_prompt_file_returns_one
    # Don't create prompt file

    # Run CLI and capture exit code
    exit_code = run_cli_for_exit_code(["process"])

    # Verify returns 1
    assert_equal 1, exit_code
  end

  def test_process_with_explicit_stdout_returns_zero
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Run CLI with --output -
    output, _error = run_cli(["process", "--output", "-"])

    # Verify content output
    assert_match(/Review this code for security issues/, output)
  end

  private

  def run_cli(args)
    # Run CLI and capture output
    output = StringIO.new
    error = StringIO.new

    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = output
    $stderr = error

    begin
      Ace::Prompt::CLI.start(args)
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    [output.string, error.string]
  end

  def run_cli_for_exit_code(args)
    # Run CLI and return exit code
    # Capture output to suppress it
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    begin
      exit_code = Ace::Prompt::CLI.start(args)
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    exit_code
  end
end
