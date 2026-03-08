# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class AgentCompressorTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_agent")
    @previous_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@previous_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_returns_agent_output_with_concept_inventory_when_validation_passes
    source = File.join(@tmp, "policy.md")
    File.write(source, "# Policy\n\nTeams must not remove controls.\n")
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["spike prompt", "", successful_status]
      else
        [
          "H|ContextPack/3|agent\nFILE|policy.md\nRULE|Teams must not remove controls.\n",
          "",
          successful_status
        ]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "H|ContextPack/3|agent"
    assert_includes output, "FILE|policy.md"
    assert_includes output, "RULE|Teams must not remove controls."
    assert_includes output, "LIST|validated_concepts|"
    assert_includes output, "LIST|deferred_concepts|"
    refute_includes output, "REFUSAL|"
    refute_includes output, "FALLBACK|"
  end

  def test_returns_exact_fallback_markers_when_agent_output_fails_validation
    source = File.join(@tmp, "policy.md")
    File.write(source, "# Policy\n\nTeams must not remove controls.\n")
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["spike prompt", "", successful_status]
      else
        ["H|ContextPack/3|agent\nFILE|policy.md\nSUMMARY|lost the rule\n", "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "H|ContextPack/3|exact"
    assert_includes output, "FILE|policy.md"
    assert_includes output, "FIDELITY|source=policy.md|status=fail|check=agent_validation"
    assert_includes output, "FALLBACK|source=policy.md|from=agent|to=exact|reason=validation_failed|check=agent_validation"
    refute_includes output, "REFUSAL|"
  end

  def test_returns_provider_unavailable_exact_fallback_when_ace_llm_fails
    source = File.join(@tmp, "policy.md")
    File.write(source, "# Policy\n\nTeams must not remove controls.\n")
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["spike prompt", "", successful_status]
      else
        ["", "provider timeout", failed_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "H|ContextPack/3|exact"
    assert_includes output, "FILE|policy.md"
    assert_includes output, "FIDELITY|source=policy.md|status=fail|check=provider_unavailable"
    assert_includes output, "FALLBACK|source=policy.md|from=agent|to=exact|reason=provider_unavailable|check=provider_unavailable"
    refute_includes output, "REFUSAL|"
  end

  def test_rule_heavy_source_can_succeed_when_required_records_are_preserved
    source = File.join(@tmp, "decisions.md")
    File.write(source, <<~MD)
      # Decisions

      All workflows must be self-contained.
      Commands must include exact error evidence.
    MD
    baseline = Ace::Compressor::Organisms::ExactCompressor.new([source], mode_label: "agent").call
    required_lines = baseline.lines.map(&:strip).select do |line|
      line.start_with?("RULE|", "CONSTRAINT|", "U|", "CMD|", "EXAMPLE|", "TABLE|")
    end
    agent_output = ["H|ContextPack/3|agent", "FILE|decisions.md", *required_lines].join("\n")
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["minify prompt", "", successful_status]
      else
        [agent_output, "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "H|ContextPack/3|agent"
    assert_includes output, "FILE|decisions.md"
    required_lines.each { |line| assert_includes output, line }
    refute_includes output, "REFUSAL|"
    refute_includes output, "FALLBACK|"
  end

  def test_rejects_output_when_required_example_or_command_records_are_missing
    source = File.join(@tmp, "example.md")
    File.write(source, <<~MD)
      # How It Works

      ## Example: ace-git-commit
      ```bash
      ace-git-commit -i "fix auth bug"
      ```
    MD
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["minify prompt", "", successful_status]
      else
        ["H|ContextPack/3|agent\nFILE|example.md\nSUMMARY|compressed\n", "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "details=missing_required_records="
    assert_includes output, "FALLBACK|source=example.md|from=agent|to=exact|reason=validation_failed|check=agent_validation"
    refute_includes output, "REFUSAL|"
  end

  def test_rejects_output_when_numeric_tokens_are_missing
    source = File.join(@tmp, "stats.md")
    File.write(source, <<~MD)
      # Script

      ```ruby
      retry_count = 42
      ```
    MD
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["minify prompt", "", successful_status]
      else
        ["H|ContextPack/3|agent\nFILE|stats.md\nCODE|ruby|retry_count = many\n", "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "details=missing_numeric_tokens="
    assert_includes output, "FALLBACK|source=stats.md|from=agent|to=exact|reason=validation_failed|check=agent_validation"
    refute_includes output, "REFUSAL|"
  end

  def test_rejects_summary_only_output
    source = File.join(@tmp, "narrative.md")
    File.write(source, "# Narrative\n\nThis document describes the background context for the feature.\n")
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["minify prompt", "", successful_status]
      else
        ["H|ContextPack/3|agent\nFILE|narrative.md\nSUMMARY|Short summary only.\n", "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_match(/details=(summary_only_output|missing_semantic_payload|not_smaller_than_exact)/, output)
    assert_includes output, "FALLBACK|source=narrative.md|from=agent|to=exact|reason=validation_failed|check=agent_validation"
    refute_includes output, "REFUSAL|"
  end

  def test_rejects_output_when_not_smaller_than_exact_baseline
    source = File.join(@tmp, "short.md")
    File.write(source, "# Short\n\ntiny\n")
    long_fact = "FACT|" + ("x" * 300)
    shell_runner = lambda do |command|
      if command.first == "ace-bundle"
        ["minify prompt", "", successful_status]
      else
        ["H|ContextPack/3|agent\nFILE|short.md\n#{long_fact}\n", "", successful_status]
      end
    end

    output = Ace::Compressor::Organisms::AgentCompressor.new([source], shell_runner: shell_runner).call

    assert_includes output, "details=not_smaller_than_exact"
    assert_includes output, "FALLBACK|source=short.md|from=agent|to=exact|reason=validation_failed|check=agent_validation"
    refute_includes output, "REFUSAL|"
  end

  private

  def successful_status
    Object.new.tap do |status|
      status.define_singleton_method(:success?) { true }
    end
  end

  def failed_status
    Object.new.tap do |status|
      status.define_singleton_method(:success?) { false }
    end
  end
end
