# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "dry/cli"
require "ace/git"

class CLIIntegrationTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @prompt_dir = File.join(@tmpdir, ".ace-local/prompt-prep/prompts")
    @archive_dir = File.join(@tmpdir, ".ace-local/prompt-prep/prompts/archive")
    FileUtils.mkdir_p(@prompt_dir)
    @prompt_file = File.join(@prompt_dir, "the-prompt.md")
    @prompt_content = "Review this code for security issues"

    # Reset config cache to ensure clean state
    Ace::PromptPrep.reset_config!

    # Store a mock default config for test isolation
    # This represents the gem defaults without loading project config
    @default_config = {
      "bundle" => { "enabled" => false },
      "enhance" => {
        "enabled" => false,
        "model" => "glite",
        "temperature" => 0.3,
        "system_prompt" => "prompt://prompt-enhance-instructions.system"
      },
      "task" => {
        "detection" => false,
        "branch_patterns" => ['^(\d+(?:\.\d+)?)-']
      },
      "security" => { "max_file_size_mb" => 10 },
      "debug" => { "enabled" => false, "bundle_loading" => false }
    }
  end

  def teardown
    Ace::PromptPrep.reset_config!
    FileUtils.rm_rf(@tmpdir)
  end

  private

  # Helper to run CLI with proper stubs for isolation
  def run_cli_isolated(args, config: nil)
    test_config = config || @default_config
    tmpdir = @tmpdir

    result = nil
    Ace::PromptPrep.stub :config, test_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, tmpdir do
        result = run_cli(args)
      end
    end
    result
  end

  # Helper to run CLI for exit code with proper stubs
  def run_cli_isolated_for_exit_code(args, config: nil)
    test_config = config || @default_config
    tmpdir = @tmpdir

    exit_code = nil
    Ace::PromptPrep.stub :config, test_config do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, tmpdir do
        exit_code = run_cli_for_exit_code(args)
      end
    end
    exit_code
  end

  public

  def test_process_with_stdout_output_returns_zero
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Run CLI
    output, _error = run_cli_isolated(["process"])

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
    output, _error = run_cli_isolated(["process", "--output", output_file])

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
    output, _error = run_cli_isolated(["process", "--output", output_file])

    # Verify file created with parent directories
    assert File.exist?(output_file)
    content = File.read(output_file, encoding: "utf-8")
    assert_match(/Review this code for security issues/, content)
  end

  def test_process_with_missing_prompt_file_shows_error
    # Don't create prompt file

    # Run CLI and capture output
    _stdout, stderr = run_cli_isolated(["process"])

    # Verify error message is shown (CLI raises Ace::Core::CLI::Error, caught and written to stderr)
    assert_match(/Prompt file not found|does not exist/i, stderr)
  end

  def test_process_with_explicit_stdout_returns_zero
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Run CLI with --output -
    output, _error = run_cli_isolated(["process", "--output", "-"])

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

    # Mock BundleLoader to simulate successful context loading
    mock_context = "# Feature Context\nImplementation details for the feature.\n\n## Original Prompt\nReview this feature implementation."
    Ace::PromptPrep::Molecules::BundleLoader.stub(:call, mock_context) do
      # Run CLI with --bundle flag
      output, _error = run_cli_isolated(["process", "--bundle"])

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

    # Run CLI with --no-bundle to override frontmatter
    output, _error = run_cli_isolated(["process", "--no-bundle"])

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

    # Mock BundleLoader
    mock_context = "# Coding Standards\nProject coding standards and guidelines.\n\n## Original Prompt\nCheck code quality and standards compliance."
    Ace::PromptPrep::Molecules::BundleLoader.stub(:call, mock_context) do
      # Run CLI with short -b flag
      output, _error = run_cli_isolated(["process", "-b"])

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

    Ace::PromptPrep::Molecules::BundleLoader.stub(:call, expanded_context) do
      # Process the prompt
      output, _error = run_cli_isolated(["process", "--bundle"])

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

    # Mock BundleLoader to return empty string (simulating failure)
    Ace::PromptPrep::Molecules::BundleLoader.stub(:call, "") do
      # Run CLI with bundle enabled
      output, _error = run_cli_isolated(["process", "--bundle"])

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
    output, _error = run_cli_isolated(["process", "--bundle"])

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
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:call, ->(**_) { { success: true, path: template_file } }) do
      # Run setup command
      output, _error = run_cli_isolated(["setup"])

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
    output, _error = run_cli_isolated(["version"])

    # Should output version with package name
    assert_match(/^ace-prompt-prep \d+\.\d+\.\d+/, output.strip)
  end

  def test_process_with_enhance_flag_integration
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Create a mock system prompt
    system_prompt_file = File.join(@tmpdir, "system-prompt.md")
    File.write(system_prompt_file, "You are a prompt enhancer.", encoding: "utf-8")

    # Skip if ace-llm not available
    begin
      require "ace/llm"
    rescue LoadError
      skip "ace-llm not available for integration testing"
    end

    enhanced_content = "Enhanced: Review this code for security issues with detailed analysis"

    # Mock the LLM call
    mock_query = ->(_model, _prompt, **_opts) { { text: enhanced_content } }

    Ace::LLM::QueryInterface.stub :query, mock_query do
      # Run CLI with --enhance and specify system prompt file
      output, _error = run_cli_isolated(["process", "--enhance", "--system-prompt", system_prompt_file])

      # Verify enhanced content output
      assert_match(/Enhanced:/, output)
      assert_match(/detailed analysis/, output)

      # Verify archive created with enhancement file
      assert File.directory?(@archive_dir)
      archive_files = Dir.glob(File.join(@archive_dir, "*.md"))
      assert archive_files.length >= 2 # Original + enhanced (_e001)

      # Check for enhanced archive file
      enhanced_files = archive_files.select { |f| f.include?("_e") }
      assert_equal 1, enhanced_files.length

      # Verify symlink points to enhanced version
      symlink_path = File.join(@prompt_dir, "_previous.md")
      assert File.symlink?(symlink_path)
      symlink_target = File.readlink(symlink_path)
      assert_match(/_e001\.md$/, symlink_target)
    end
  end

  def test_process_with_enhance_flag_and_model_option
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Create a mock system prompt
    system_prompt_file = File.join(@tmpdir, "system-prompt.md")
    File.write(system_prompt_file, "You are a prompt enhancer.", encoding: "utf-8")

    begin
      require "ace/llm"
    rescue LoadError
      skip "ace-llm not available for integration testing"
    end

    enhanced_content = "Enhanced prompt"
    model_used = nil

    # Mock LLM to capture model parameter
    mock_query = lambda { |model, _prompt, **_opts|
      model_used = model
      { text: enhanced_content }
    }

    Ace::LLM::QueryInterface.stub :query, mock_query do
      run_cli_isolated(["process", "--enhance", "--model", "claude", "--system-prompt", system_prompt_file])
      assert_equal "claude", model_used
    end
  end

  def test_process_with_short_enhance_flag
    # Create prompt file
    File.write(@prompt_file, @prompt_content, encoding: "utf-8")

    # Create a mock system prompt
    system_prompt_file = File.join(@tmpdir, "system-prompt.md")
    File.write(system_prompt_file, "You are a prompt enhancer.", encoding: "utf-8")

    begin
      require "ace/llm"
    rescue LoadError
      skip "ace-llm not available for integration testing"
    end

    enhanced_content = "Enhanced prompt"
    mock_query = ->(_model, _prompt, **_opts) { { text: enhanced_content } }

    Ace::LLM::QueryInterface.stub :query, mock_query do
      output, _error = run_cli_isolated(["process", "-e", "--system-prompt", system_prompt_file])
      assert_match(/Enhanced prompt/, output)
    end
  end

  # ============================================
  # Task-specific prompt tests
  # ============================================

  def test_process_with_task_flag_uses_task_prompts_directory
    # Create task directory structure
    task_dir = File.join(@tmpdir, ".ace-taskflow/v.0.9.0/tasks/117-feature-name")
    task_prompts_dir = File.join(task_dir, "prompts")
    task_archive_dir = File.join(task_prompts_dir, "archive")
    FileUtils.mkdir_p(task_prompts_dir)

    # Create task file (required for TaskManager to find the task)
    task_file = File.join(task_dir, "task.117.s.md")
    File.write(task_file, "# Task 117\n\nTask description", encoding: "utf-8")

    # Create prompt in task directory
    task_prompt_file = File.join(task_prompts_dir, "the-prompt.md")
    task_prompt_content = "Task-specific prompt content for feature 117"
    File.write(task_prompt_file, task_prompt_content, encoding: "utf-8")

    # Mock TaskPathResolver to return our test task directory
    mock_result = {
      path: task_dir,
      prompts_path: task_prompts_dir,
      found: true,
      error: nil
    }

    Ace::PromptPrep::Atoms::TaskPathResolver.stub :resolve, mock_result do
      output, _error = run_cli_isolated(["process", "--task", "117"])

      # Verify content output
      assert_match(/Task-specific prompt content/, output)

      # Verify archive created in task directory
      assert File.directory?(task_archive_dir), "Archive directory should be created in task prompts"
      archive_files = Dir.glob(File.join(task_archive_dir, "*.md"))
      assert_equal 1, archive_files.length, "One archive file should be created"

      # Verify symlink created in task directory
      symlink_path = File.join(task_prompts_dir, "_previous.md")
      assert File.symlink?(symlink_path), "_previous.md symlink should be created"
    end
  end

  def test_process_with_invalid_task_shows_error
    # Mock TaskPathResolver to return not found
    mock_result = {
      path: nil,
      prompts_path: nil,
      found: false,
      error: "Task not found: 999"
    }

    Ace::PromptPrep::Atoms::TaskPathResolver.stub :resolve, mock_result do
      _stdout, stderr = run_cli_isolated(["process", "--task", "999"])
      # CLI raises Ace::Core::CLI::Error, caught and written to stderr
      assert_match(/Task not found/i, stderr, "Should show error for invalid task")
    end
  end

  def test_setup_with_task_flag_creates_prompt_in_task_directory
    # Create task directory structure
    task_dir = File.join(@tmpdir, ".ace-taskflow/v.0.9.0/tasks/118-new-task")
    task_prompts_dir = File.join(task_dir, "prompts")
    FileUtils.mkdir_p(task_dir)

    # Mock TaskPathResolver
    mock_result = {
      path: task_dir,
      prompts_path: task_prompts_dir,
      found: true,
      error: nil
    }

    # Create a template
    template_content = "# Task Template\n\nDescribe your task here."
    template_file = File.join(@tmpdir, "template.md")
    File.write(template_file, template_content)

    Ace::PromptPrep::Atoms::TaskPathResolver.stub :resolve, mock_result do
      Ace::PromptPrep::Molecules::TemplateResolver.stub :call, ->(**_) { { success: true, path: template_file } } do
        output, _error = run_cli_isolated(["setup", "--task", "118"])

        # Verify prompt created in task directory
        task_prompt_file = File.join(task_prompts_dir, "the-prompt.md")
        assert File.exist?(task_prompt_file), "Prompt should be created in task prompts directory"

        content = File.read(task_prompt_file)
        assert_match(/Task Template/, content)

        # Verify output message
        assert_match(/Prompt initialized/, output)
      end
    end
  end

  def test_process_with_auto_detection_from_branch
    # Create task directory structure
    task_dir = File.join(@tmpdir, ".ace-taskflow/v.0.9.0/tasks/121-feature")
    task_prompts_dir = File.join(task_dir, "prompts")
    FileUtils.mkdir_p(task_prompts_dir)

    # Create prompt in task directory
    task_prompt_file = File.join(task_prompts_dir, "the-prompt.md")
    File.write(task_prompt_file, "Auto-detected task prompt", encoding: "utf-8")

    # Mock TaskPathResolver
    mock_result = {
      path: task_dir,
      prompts_path: task_prompts_dir,
      found: true,
      error: nil
    }

    # Enable task detection in config (merge with test's default config)
    config_with_detection = @default_config.merge(
      "task" => { "detection" => true }
    )

    tmpdir = @tmpdir
    Ace::PromptPrep.stub :config, config_with_detection do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, tmpdir do
        Ace::Git::Molecules::BranchReader.stub :current_branch, "121-feature-branch" do
          Ace::PromptPrep::Atoms::TaskPathResolver.stub :extract_from_branch, "121" do
            Ace::PromptPrep::Atoms::TaskPathResolver.stub :resolve, mock_result do
              output, _error = run_cli(["process"])

              # Verify auto-detected task prompt was used
              assert_match(/Auto-detected task prompt/, output)
            end
          end
        end
      end
    end
  end

  def test_process_with_auto_detection_when_branch_returns_nil
    # Create project prompt file as fallback
    File.write(@prompt_file, "Project-level prompt content", encoding: "utf-8")

    # Enable task detection in config (merge with test's default config)
    config_with_detection = @default_config.merge(
      "task" => { "detection" => true }
    )

    tmpdir = @tmpdir
    Ace::PromptPrep.stub :config, config_with_detection do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, tmpdir do
        # Simulate ace-git returning nil (not in git repo or error)
        Ace::Git::Molecules::BranchReader.stub :current_branch, nil do
          output, _error = run_cli(["process"])

          # Should fall back to project-level prompt
          assert_match(/Project-level prompt content/, output)

          # Verify archive created in project directory
          assert File.directory?(@archive_dir)
        end
      end
    end
  end

  def test_process_with_auto_detection_ignores_task_path_outside_project_root
    # Create project prompt file as fallback
    File.write(@prompt_file, "Project-level prompt content", encoding: "utf-8")

    mock_result = {
      path: "/tmp/external-task",
      prompts_path: "/tmp/external-task/prompts",
      found: true,
      error: nil
    }

    config_with_detection = @default_config.merge(
      "task" => { "detection" => true }
    )

    tmpdir = @tmpdir
    Ace::PromptPrep.stub :config, config_with_detection do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, tmpdir do
        Ace::Git::Molecules::BranchReader.stub :current_branch, "121-feature-branch" do
          Ace::PromptPrep::Atoms::TaskPathResolver.stub :extract_from_branch, "121" do
            Ace::PromptPrep::Atoms::TaskPathResolver.stub :resolve, mock_result do
              output, error = run_cli(["process"])

              # Should fall back to project-level prompt when resolved task is outside root
              assert_match(/Project-level prompt content/, output)
              assert_match(/outside project root/, error)
            end
          end
        end
      end
    end
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
      Dry::CLI.new(Ace::PromptPrep::CLI).call(arguments: args)
    rescue Ace::Core::CLI::Error => e
      $stderr.print e.message
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    [output.string, error.string]
  end

  def run_cli_for_exit_code(args)
    # Run CLI and return exit code
    # Success returns nil, failure raises Ace::Core::CLI::Error
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    begin
      Dry::CLI.new(Ace::PromptPrep::CLI).call(arguments: args)
      nil
    rescue Ace::Core::CLI::Error => e
      e.exit_code
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
end
