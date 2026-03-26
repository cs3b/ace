# frozen_string_literal: true

require "test_helper"
require "ace/lint/cli"
require "stringio"
require "tmpdir"
require "fileutils"

class LintCommandTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir("ace_lint_command_test")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp_dir)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir && Dir.exist?(@tmp_dir)
  end

  def test_auto_fix_dry_run_does_not_modify_file
    path = "dry_run.md"
    original = "# Title\n\nLine\u2014with dash and \u201Csmart quote\u201D.\n"
    File.write(path, original)

    result = run_cli(["--auto-fix", "--dry-run", path])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stdout], "Would attempt to fix:"
    assert_includes result[:stdout], "issue(s) detected"
    assert_equal original, File.read(path)
  end

  def test_fix_alias_matches_auto_fix_dry_run_output
    path = "alias.md"
    File.write(path, "# Title\n\nLine\u2014with dash.\n")

    fix_result = run_cli(["--fix", "--dry-run", path])
    auto_fix_result = run_cli(["--auto-fix", "--dry-run", path])

    assert_equal 0, fix_result[:exit_code], fix_result[:stderr]
    assert_equal 0, auto_fix_result[:exit_code], auto_fix_result[:stderr]
    assert_equal fix_result[:stdout], auto_fix_result[:stdout]
  end

  def test_auto_fix_with_agent_dry_run_prints_prompt
    path = "agent.md"
    File.write(path, "# Title\n\nLine\u2014with dash.\n")

    result = run_cli(["--auto-fix-with-agent", "--dry-run", path])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stdout], "Agent prompt (dry-run):"
    assert_includes result[:stdout], "The following lint issues remain"
    assert_includes result[:stdout], "## File: #{path}"
  end

  def test_auto_fix_with_agent_dry_run_uses_safe_fence_for_fenced_content
    path = "fenced.md"
    File.write(path, "```ruby\nputs \"Hi\"\n```\n\nLine\u2014with dash.\n")

    result = run_cli(["--auto-fix-with-agent", "--dry-run", path])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stdout], "````text"
  end

  def test_auto_fix_with_agent_non_dry_run_applies_returned_file_blocks
    path = "agent_fix.yml"
    File.write(path, "key: [1,2\n")

    response = <<~TEXT
      #{Ace::Lint::CLI::Commands::Lint::AGENT_FIX_FILE_BLOCK_START}#{path}>>
      key: [1, 2]
      #{Ace::Lint::CLI::Commands::Lint::AGENT_FIX_FILE_BLOCK_END}
    TEXT

    with_stubbed_agent_query(response) do
      result = run_cli(["--auto-fix-with-agent", "--model", "openai:gpt-4.1", path])

      assert_equal 0, result[:exit_code], result[:stderr]
      assert_includes result[:stderr], "--auto-fix-with-agent sends full file contents"
      assert_equal "key: [1, 2]\n", File.read(path)
    end
  end

  def test_auto_fix_with_agent_non_dry_run_fails_when_no_edit_blocks_returned
    path = "agent_noop.yml"
    original = "key: [1,2\n"
    File.write(path, original)

    with_stubbed_agent_query("No changes required.") do
      result = run_cli(["--auto-fix-with-agent", "--model", "openai:gpt-4.1", path])

      assert_equal 2, result[:exit_code]
      assert_includes result[:stderr], "Agent returned no editable file blocks"
      assert_equal original, File.read(path)
    end
  end

  def test_auto_fix_with_format_warns_and_ignores_format
    path = "format.md"
    File.write(path, "# Title\n\nLine\u2014with dash.\n")

    result = run_cli(["--auto-fix", "--dry-run", "--format", path])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stderr], "--format is ignored"
  end

  def test_auto_fix_exits_one_when_violations_remain
    path = "invalid.yml"
    File.write(path, "key: [1,2\n")

    result = run_cli(["--auto-fix", path])

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], "violation(s) remain after auto-fix"
  end

  def test_auto_fix_exits_zero_when_no_violations_found
    path = "valid.md"
    File.write(path, "# Title\n\nValid content.\n")

    result = run_cli(["--auto-fix", path])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stdout], "All files passed"
  end

  def test_auto_fix_exits_zero_when_only_warnings_remain
    path = "warnings_only.md"
    File.write(path, "Broken reference [ref][missing]\n")

    result = run_cli(["--auto-fix", path])

    assert_equal 0, result[:exit_code], result[:stderr]
  end

  private

  def with_stubbed_agent_query(response_text)
    require "ace/llm"

    Ace::LLM::QueryInterface.stub(:query, lambda { |_provider_model, _prompt, **_options|
      {text: response_text}
    }) do
      yield
    end
  end

  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    exit_code = 0

    begin
      Ace::Lint::CLI.start(args)
    rescue Ace::Support::Cli::Error => e
      warn e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    {stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code}
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
