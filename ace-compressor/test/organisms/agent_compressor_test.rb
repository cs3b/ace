# frozen_string_literal: true

require "json"
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

  def test_rewrite_payloads_returns_replacements_for_summary_fact_and_list_records
    rewriter = build_rewriter(agent_output: JSON.generate(
      "records" => [
        {"id" => "r1", "payload" => "shared cli workflows for humans and agents"},
        {"id" => "r2", "payload" => "trimmed supporting fact"},
        {"id" => "r3", "items" => %w[ace_support_core_foundation ace_bundle_protocol_loading ace_docs_frontmatter_docs]}
      ]
    ))

    rewrites = rewriter.send(:rewrite_payloads, [
      {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Agents and developers collaborate through shared command-line workflows."},
      {id: "r2", type: "FACT", file: "vision.md", section: "overview", payload: "This supporting fact is verbose."},
      {id: "r3", type: "LIST", file: "vision.md", section: "tools", name: "tools", items: %w[ace_support_core_configuration_management_foundation ace_bundle_project_context_loading ace_docs_documentation_management]}
    ])

    assert_equal "shared cli workflows for humans and agents", rewrites["r1"][:payload]
    assert_equal "trimmed supporting fact", rewrites["r2"][:payload]
    assert_equal %w[ace_support_core_base ace_bundle_protocol_loading ace_docs_frontmatter_docs], rewrites["r3"][:items]
  end

  def test_rewrite_payloads_accepts_json_code_fences
    rewriter = build_rewriter(agent_output: <<~JSON)
      ```json
      {"records":[{"id":"r1","payload":"compressed"}]}
      ```
    JSON

    rewrites = rewriter.send(:rewrite_payloads, [
      {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Long narrative text"}
    ])

    assert_equal "compressed", rewrites["r1"][:payload]
  end

  def test_rewrite_payloads_returns_empty_hash_for_invalid_json
    rewriter = build_rewriter(agent_output: "not json")

    rewrites = rewriter.send(:rewrite_payloads, [
      {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Long narrative text"}
    ])

    assert_equal({}, rewrites)
  end

  def test_list_rewrite_requires_same_item_count
    rewriter = build_rewriter(agent_output: JSON.generate(
      "records" => [
        {"id" => "r1", "items" => ["one_short_item"]}
      ]
    ))

    rewrites = rewriter.send(:rewrite_payloads, [
      {id: "r1", type: "LIST", file: "architecture.md", section: "tools", name: "tools", items: %w[first_item second_item]}
    ])

    assert_equal({}, rewrites)
  end

  def test_list_rewrite_applies_deterministic_token_compaction
    rewriter = build_rewriter(agent_output: JSON.generate(
      "records" => [
        {"id" => "r1", "items" => ["configuration_management_foundation", "documentation_management_with_frontmatter_tracking"]}
      ]
    ))

    rewrites = rewriter.send(:rewrite_payloads, [
      {id: "r1", type: "LIST", file: "architecture.md", section: "tools", name: "tools", items: %w[configuration_management_foundation documentation_management_with_frontmatter_tracking]}
    ])

    assert_equal %w[config_mgmt_base docs_mgmt_frontmatter_track], rewrites["r1"][:items]
  end

  def test_uses_template_uri_from_config_for_ace_bundle
    bundle_commands = []
    shell_override = lambda do |command|
      bundle_commands << command if command.first == "ace-bundle"
      if command.first == "ace-bundle"
        ["payload rewriter template", "", successful_status]
      else
        [JSON.generate("records" => [{"id" => "r1", "payload" => "compact"}]), "", successful_status]
      end
    end
    rewriter = build_rewriter(agent_output: "", shell_override: shell_override)

    with_compressor_config(
      "agent_model" => "glite",
      "agent_template_uri" => "tmpl://agent/custom-minify"
    ) do
      rewriter.send(:rewrite_payloads, [
        {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Long narrative text"}
      ])
    end

    assert_equal ["ace-bundle", "tmpl://agent/custom-minify"], bundle_commands.first
  end

  def test_uses_agent_model_from_config_for_ace_llm
    llm_commands = []
    shell_override = lambda do |command|
      llm_commands << command if command.first == "ace-llm"
      if command.first == "ace-bundle"
        ["payload rewriter template", "", successful_status]
      else
        [JSON.generate("records" => [{"id" => "r1", "payload" => "compact"}]), "", successful_status]
      end
    end
    rewriter = build_rewriter(agent_output: "", shell_override: shell_override)

    with_compressor_config(
      "agent_model" => "glite",
      "agent_template_uri" => "tmpl://agent/minify-single-source"
    ) do
      rewriter.send(:rewrite_payloads, [
        {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Long narrative text"}
      ])
    end

    assert_equal "ace-llm", llm_commands.first[0]
    assert_equal "glite", llm_commands.first[1]
    assert_includes llm_commands.first[2], "<records_json>"
  end

  def test_uses_deprecated_agent_provider_when_agent_model_is_unset
    llm_commands = []
    shell_override = lambda do |command|
      llm_commands << command if command.first == "ace-llm"
      if command.first == "ace-bundle"
        ["payload rewriter template", "", successful_status]
      else
        [JSON.generate("records" => [{"id" => "r1", "payload" => "compact"}]), "", successful_status]
      end
    end
    rewriter = build_rewriter(agent_output: "", shell_override: shell_override)

    with_compressor_config(
      "agent_provider" => "legacy-provider",
      "agent_template_uri" => "tmpl://agent/minify-single-source"
    ) do
      rewriter.send(:rewrite_payloads, [
        {id: "r1", type: "SUMMARY", file: "vision.md", section: "overview", payload: "Long narrative text"}
      ])
    end

    assert_equal "legacy-provider", llm_commands.first[1]
  end

  def test_compress_sources_keeps_structure_and_protected_records_exact
    source = File.join(@tmp, "architecture.md")
    File.write(source, <<~MD)
      # Architecture

      ## Overview
      Agents and developers collaborate through shared command-line workflows.

      ## Components
      - ace-support-core configuration management foundation
      - ace-bundle project context loading with protocol support
      - ace-docs documentation management with frontmatter tracking
      - ace-review preset-based code review with llm-powered analysis
      - ace-search unified file and content search with auto-detected matching

      ## Rules
      Commands must remain deterministic.
    MD

    output = build_rewriter(agent_output: JSON.generate(
      "records" => [
        {"id" => "r1", "payload" => "shared cli workflows for humans and agents"},
        {"id" => "r2", "items" => %w[ace_support_core_foundation ace_bundle_protocol_loading ace_docs_frontmatter_tracking ace_review_llm_analysis ace_search_pattern_matching]}
      ]
    )).compress_sources([source])

    assert_includes output, "H|ContextPack/3|agent"
    assert_includes output, "FILE|architecture.md"
    assert_includes output, "SUMMARY|shared cli workflows for humans and agents"
    assert_includes output, "LIST|components|[ace_support_core_base,ace_bundle_protocol_loading,ace_docs_frontmatter_track,ace_review_llm_analysis,ace_search_pattern_match]"
    assert_includes output, "RULE|Commands must remain deterministic."
  end

  def test_compress_sources_never_emits_prompt_leakage_markers
    source = File.join(@tmp, "vision.md")
    File.write(source, <<~MD)
      # Vision

      ## Overview
      Agents and developers collaborate through shared command-line workflows.
    MD

    output = build_rewriter(agent_output: JSON.generate(
      "records" => [
        {"id" => "r1", "payload" => "shared cli workflows for humans and agents"}
      ]
    )).compress_sources([source])

    refute_includes output, "SEC|contract"
    refute_includes output, "SEC|input"
    refute_includes output, "Output contract:"
    refute_includes output, "/tmp/ace-compressor-agent-input"
  end

  private

  def build_rewriter(agent_output:, shell_override: nil)
    shell_runner = shell_override || lambda do |command|
      if command.first == "ace-bundle"
        ["payload rewriter template", "", successful_status]
      else
        [agent_output, "", successful_status]
      end
    end

    Ace::Compressor::Organisms::AgentCompressor.new([], shell_runner: shell_runner)
  end

  def with_compressor_config(values)
    original = Ace::Compressor.instance_variable_get(:@config)
    Ace::Compressor.instance_variable_set(:@config, values)
    yield
  ensure
    Ace::Compressor.instance_variable_set(:@config, original)
  end

  def successful_status
    Object.new.tap do |status|
      status.define_singleton_method(:success?) { true }
    end
  end
end
