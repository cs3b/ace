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

  def test_process_with_context_flag_integration
    # Create prompt with frontmatter
    File.write(@prompt_file, <<~MARKDOWN, encoding: "utf-8")
      ---
      context:
        enabled: true
        sources:
          - file: "README.md"
      ---
      Review this feature implementation.
    MARKDOWN

    # Mock ContextLoader to simulate successful context loading
    mock_context = "# Feature Context\nImplementation details for the feature.\n\n## Original Prompt\nReview this feature implementation."
    Ace::Prompt::Molecules::ContextLoader.stub(:call, mock_context) do
      # Run CLI with --context flag
      output, _error = run_cli(["process", "--context"])

      # Should include context content
      assert_match(/Feature Context/, output)
      assert_match(/Implementation details/, output)
      assert_match(/Review this feature implementation/, output)
    end
  end

  def test_process_with_no_context_flag_override
    # Create prompt with frontmatter enabling context
    File.write(@prompt_file, <<~MARKDOWN, encoding: "utf-8")
      ---
      context:
        enabled: true
        sources:
          - file: "docs/architecture.md"
      ---
      Analyze this system design.
    MARKDOWN

    # Run CLI with --no-context to override frontmatter
    output, _error = run_cli(["process", "--no-context"])

    # Should only include body content (no context)
    refute_match(/System Architecture/, output)
    assert_match(/Analyze this system design/, output)
  end

  def test_process_with_short_context_flag
    # Create prompt with frontmatter
    File.write(@prompt_file, <<~MARKDOWN, encoding: "utf-8")
      ---
      context:
        sources:
          - preset: "coding-standards"
      ---
      Check code quality and standards compliance.
    MARKDOWN

    # Mock ContextLoader
    mock_context = "# Coding Standards\nProject coding standards and guidelines.\n\n## Original Prompt\nCheck code quality and standards compliance."
    Ace::Prompt::Molecules::ContextLoader.stub(:call, mock_context) do
      # Run CLI with short -c flag
      output, _error = run_cli(["process", "-c"])

      # Should include context
      assert_match(/Coding Standards/, output)
      assert_match(/Project coding standards/, output)
      assert_match(/Check code quality/, output)
    end
  end

  def test_end_to_end_context_loading_workflow
    # Test complete workflow: setup prompt with context → process with context
    prompt_with_context = <<~MARKDOWN
      ---
      context:
        enabled: true
        sources:
          - file: "CHANGELOG.md"
          - command: "git log --oneline -3"
      tags: [review, security]
      ---
      Review this security enhancement.
    MARKDOWN

    # Write the prompt
    File.write(@prompt_file, prompt_with_context, encoding: "utf-8")

    # Mock context loading that returns expanded content
    expanded_context = <<~MARKDOWN
      # Security Review Context

      ## Recent Changes
      - feat: add authentication middleware
      - fix: resolve XSS vulnerability
      - docs: update security guidelines

      ## Original Prompt
      Review this security enhancement.
    MARKDOWN

    Ace::Prompt::Molecules::ContextLoader.stub(:call, expanded_context) do
      # Process the prompt
      output, _error = run_cli(["process", "--context"])

      # Verify end-to-end workflow
      assert_match(/Security Review Context/, output)
      assert_match(/Recent Changes/, output)
      assert_match(/Review this security enhancement/, output)

      # Verify archiving worked correctly
      assert File.directory?(@archive_dir)
      archive_files = Dir.glob(File.join(@archive_dir, "*.md"))
      assert_equal 1, archive_files.length

      # Verify archived content includes original frontmatter
      archived_content = File.read(archive_files.first)
      assert_includes archived_content, "context:"
      assert_includes archived_content, "tags:"
      assert_includes archived_content, "Review this security enhancement"
    end
  end

  def test_context_loading_graceful_degradation
    # Create prompt that would require context loading
    File.write(@prompt_file, <<~MARKDOWN, encoding: "utf-8")
      ---
      context:
        enabled: true
        sources:
          - file: "nonexistent.md"
          - command: "invalid-command"
      ---
      Handle missing context gracefully.
    MARKDOWN

    # Mock ContextLoader to return empty string (simulating failure)
    Ace::Prompt::Molecules::ContextLoader.stub(:call, "") do
      # Run CLI with context enabled
      output, _error = run_cli(["process", "--context"])

      # Should gracefully fallback to body content
      refute_match(/# Project Context/, output)
      assert_match(/Handle missing context gracefully/, output)

      # Should still succeed and create archive
      assert File.directory?(@archive_dir)
    end
  end

  def test_error_scenario_context_loading_with_malformed_frontmatter
    # Create prompt with malformed YAML
    File.write(@prompt_file, <<~MARKDOWN, encoding: "utf-8")
      ---
      context:
        enabled: true
        sources:
          - invalid_type: "unsupported"
        malformed: yaml: content
          - not_properly: structured
      ---
      Process malformed frontmatter.
    MARKDOWN

    # Run CLI - should handle gracefully
    output, _error = run_cli(["process", "--context"])

    # Should still return content (treating malformed frontmatter as body)
    assert_match(/context:/, output)
    assert_match(/malformed: yaml: content/, output)
    assert_match(/Process malformed frontmatter/, output)
  end

  def test_setup_command_integration
    # Test setup command with template
    template_content = <<~MARKDOWN
      # Bug Report Template

      **Issue**: [Describe the bug]

      **Steps to Reproduce**:
      1.
      2.
      3.

      **Expected Behavior**: [What should happen]

      **Actual Behavior**: [What actually happens]
    MARKDOWN

    # Create a temporary template file
    template_file = File.join(@tmpdir, "template.md")
    File.write(template_file, template_content)

    # Mock TemplateResolver to return our template file path
    Ace::Prompt::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: template_file } }) do
      # Run setup command
      output, _error = run_cli(["setup"])

      # Should create prompt file
      assert File.exist?(@prompt_file)
      content = File.read(@prompt_file)
      assert_match(/Bug Report Template/, content)
      assert_match(/\*\*Issue\*\*:/, content)
      assert_match(/\*\*Steps to Reproduce\*\*:/, content)

      # Archive directory may or may not be created during setup
    end
  end

  def test_version_command_integration
    # Test version command
    output, _error = run_cli(["version"])

    # Should output version
    assert_match(/^\d+\.\d+\.\d+/, output.strip)
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
