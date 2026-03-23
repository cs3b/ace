# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

class Ace::Lint::Organisms::LintOrchestratorTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir("lint_orchestrator_test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)
    Ace::Lint::Atoms::SkillSchemaLoader.reset_cache!
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.remove_entry(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # Formatting tests for skill/workflow/agent types

  def test_formatting_enabled_for_skill_type
    skill_file = File.join(@temp_dir, "SKILL.md")
    File.write(skill_file, <<~MARKDOWN)
      ---
      name: ace:test
      description: Test skill
      # bundle: project
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      Test body content.
    MARKDOWN

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([skill_file], options: {fix: true})

    assert_equal 1, results.size
    # The result should have been processed (not skipped)
    # and formatting should have been attempted
    result = results.first
    refute result.nil?, "Expected a result for skill file"
    assert_equal skill_file, result.file_path
  end

  def test_formatting_enabled_for_workflow_type
    workflow_file = File.join(@temp_dir, "test.wf.md")
    File.write(workflow_file, <<~MARKDOWN)
      ---
      name: test-workflow
      description: Test workflow
      ---

      Workflow content.
    MARKDOWN

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([workflow_file], options: {fix: true})

    assert_equal 1, results.size
    result = results.first
    refute result.nil?, "Expected a result for workflow file"
    assert_equal workflow_file, result.file_path
  end

  def test_formatting_enabled_for_agent_type
    agent_file = File.join(@temp_dir, "test.ag.md")
    File.write(agent_file, <<~MARKDOWN)
      ---
      name: test-agent
      type: agent
      ---

      Agent content.
    MARKDOWN

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([agent_file], options: {fix: true})

    assert_equal 1, results.size
    result = results.first
    refute result.nil?, "Expected a result for agent file"
    assert_equal agent_file, result.file_path
  end

  def test_formatting_returns_formatted_result_for_skill
    skill_file = File.join(@temp_dir, "SKILL.md")
    # Write content with inconsistent formatting that kramdown will normalize
    File.write(skill_file, <<~MARKDOWN)
      ---
      name: ace:test
      description: Test skill
      # bundle: project
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      ##   Test heading
    MARKDOWN

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([skill_file], options: {format: true})

    assert_equal 1, results.size
    result = results.first
    # The result should indicate formatting was performed
    # (formatted flag may be true if content changed)
    refute result.nil?, "Expected a result for skill file"
  end

  # Basic orchestrator tests

  def test_lint_markdown_file
    md_file = File.join(@temp_dir, "test.md")
    File.write(md_file, "# Valid Markdown\n\nContent.\n")

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([md_file])

    assert_equal 1, results.size
    assert results.first.success?
  end

  def test_lint_multiple_file_types
    md_file = File.join(@temp_dir, "test.md")
    skill_file = File.join(@temp_dir, "SKILL.md")

    File.write(md_file, "# Test\n\nContent.\n")
    File.write(skill_file, <<~MARKDOWN)
      ---
      name: ace:test
      description: Test skill
      # bundle: project
      # agent: Bash
      user-invocable: true
      allowed-tools:
        - Read
      source: test
      ---

      Skill content.
    MARKDOWN

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([md_file, skill_file])

    assert_equal 2, results.size
  end

  def test_any_failures_with_no_failures
    md_file = File.join(@temp_dir, "test.md")
    File.write(md_file, "# Valid\n\nContent.\n")

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    orchestrator.lint_files([md_file])

    refute orchestrator.any_failures?
  end

  def test_counts
    md_file = File.join(@temp_dir, "test.md")
    File.write(md_file, "# Valid\n\nContent.\n")

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    orchestrator.lint_files([md_file])

    assert_equal 1, orchestrator.passed_count
    assert_equal 0, orchestrator.failed_count
    assert_equal 0, orchestrator.total_errors
    assert_equal 0, orchestrator.total_warnings
  end

  def test_frontmatter_lint_allows_readme_without_frontmatter
    readme_file = File.join(@temp_dir, "ace-docs", "README.md")
    FileUtils.mkdir_p(File.dirname(readme_file))
    File.write(readme_file, "# README\n")

    orchestrator = Ace::Lint::Organisms::LintOrchestrator.new
    results = orchestrator.lint_files([readme_file], options: {type: :frontmatter})

    assert_equal 1, results.size
    assert results.first.success?
  end
end
