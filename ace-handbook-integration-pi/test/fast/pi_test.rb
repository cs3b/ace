# frozen_string_literal: true

require_relative "../test_helper"

class Ace::Handbook::Integration::PiTest < Minitest::Test
  def test_loads_with_ace_handbook_runtime
    assert defined?(Ace::Handbook)
    assert_kind_of String, Ace::Handbook::Integration::Pi::VERSION
  end

  def test_provider_manifest_declares_skill_and_prompt_projections
    manifest_path = File.expand_path("../../.ace-defaults/handbook/providers/pi.yml", __dir__)
    manifest = YAML.safe_load_file(manifest_path, permitted_classes: [Date, Time], aliases: true)

    assert_equal "pi", manifest.fetch("provider")
    assert_equal ".pi/skills", manifest.fetch("output_dir")
    assert_equal ".pi/prompts", manifest.fetch("prompts_dir")
  end

  def test_canonical_continue_work_prompt_template_is_complete
    template_path = File.expand_path("../../handbook/prompts/continue-work.md", __dir__)
    content = File.read(template_path)
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n?(.*)\z/m)

    refute_nil match, "continue-work.md must carry frontmatter"
    frontmatter = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true)

    assert_equal "ace-handbook-integration-pi", frontmatter.fetch("source")
    assert frontmatter["description"].to_s.length > 10, "description is shown in pi command completion"
    assert_equal "[report-ref]", frontmatter.fetch("argument-hint")

    body = match[2]
    # The resume prompt reads real state: _overseer tasks, assignments, and
    # current project truth (8xg.t.sbz.6.2 acceptance).
    assert_includes body, "ace-task --in _overseer list"
    assert_includes body, ".ace-local/assign/"
    assert_includes body, "ace-git-worktree list"
    assert_includes body, "git status --short"
    # It continues the commissioned process through the existing gates.
    assert_includes body, "ace-overseer process-reports"
    assert_includes body, "ace-overseer work-on"
    assert_includes body, "ace-overseer handoff"
    # Contract rules: single execution, delivery repetition != work
    # repetition, no self-seeking of new work.
    assert_includes body, "one overseer execution"
    assert_includes body, "Delivery repetition is not work repetition"
    assert_includes body, "No self-seeking"
    assert_includes body, "ace-task update"
    assert_includes body, "Stop this cycle"
  end

  def test_continue_work_template_projects_through_handbook_sync
    Dir.mktmpdir do |tmpdir|
      integration_root = File.expand_path("../..", __dir__)
      manifest_dir = File.join(tmpdir, "ace-handbook-integration-pi")
      FileUtils.mkdir_p(File.dirname(manifest_dir))
      FileUtils.cp_r(integration_root, manifest_dir)

      inventory = Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: tmpdir, gem_roots: [])
      templates = inventory.for_provider("pi")
      template = templates.find { |candidate| candidate.name == "continue-work" }

      refute_nil template, "continue-work template must be discovered for the pi provider"
      assert File.exist?(template.source_path)
    end
  end
end
