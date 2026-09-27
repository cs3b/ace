# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Organisms::PromptTemplateInventoryTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_groups_templates_by_provider_from_package_manifests
    create_package("pi", "loop")
    create_package("claude", "review")

    inventory = Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: @tmpdir, gem_roots: [])

    assert_equal %w[claude pi], inventory.all.keys.sort
    assert_equal 1, inventory.for_provider("pi").size
    template = inventory.for_provider("pi").first
    assert_equal "loop", template.name
    assert_equal "pi", template.provider
    assert_equal "ace-handbook-integration-pi", template.source
    assert_includes template.content, "Body of loop"
    assert_kind_of Ace::Handbook::Models::PromptTemplate, template
  end

  def test_ignores_packages_without_provider_manifest
    create_package("pi", "loop")
    orphan = File.join(@tmpdir, "ace-handbook-integration-orphan", "handbook", "prompts")
    FileUtils.mkdir_p(orphan)
    File.write(File.join(orphan, "stray.md"), "---\nsource: x\n---\nbody")

    inventory = Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: @tmpdir, gem_roots: [])

    assert_equal %w[pi], inventory.all.keys
  end

  def test_tolerates_templates_without_frontmatter
    create_package("pi", "loop")
    prompts_dir = File.join(@tmpdir, "ace-handbook-integration-pi", "handbook", "prompts")
    File.write(File.join(prompts_dir, "bare.md"), "no frontmatter here")

    inventory = Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: @tmpdir, gem_roots: [])

    names = inventory.for_provider("pi").map(&:name).sort
    assert_equal %w[bare loop], names
  end

  private

  def create_package(provider, template_name)
    manifest_dir = File.join(@tmpdir, "ace-handbook-integration-#{provider}", ".ace-defaults", "handbook", "providers")
    FileUtils.mkdir_p(manifest_dir)
    File.write(File.join(manifest_dir, "#{provider}.yml"), "provider: #{provider}\noutput_dir: .#{provider}/skills\n")

    prompts_dir = File.join(@tmpdir, "ace-handbook-integration-#{provider}", "handbook", "prompts")
    FileUtils.mkdir_p(prompts_dir)
    File.write(File.join(prompts_dir, "#{template_name}.md"), <<~MD)
      ---
      description: Test prompt #{template_name}
      source: ace-handbook-integration-#{provider}
      ---

      Body of #{template_name} for #{provider}.
    MD
  end
end
