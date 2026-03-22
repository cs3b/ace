# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Organisms::StatusCollectorTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    create_provider_manifest("pi", ".pi/skills")
    create_skill_source_registration("ace-demo", "ace-demo/handbook/skills")
    create_skill_source_registration("ace-task", "ace-task/handbook/skills")
    create_skill("as-sync", source: "ace-demo")
    create_skill("as-outdated", source: "ace-task")
    create_skill("as-missing", source: "ace-task")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_collect_groups_canonical_skills_by_source
    snapshot = collector.collect(provider: "pi")

    assert_equal 3, snapshot.fetch("canonical").fetch("total")
    assert_equal [
      { "source" => "ace-demo", "count" => 1 },
      { "source" => "ace-task", "count" => 2 }
    ], snapshot.fetch("canonical").fetch("by_source")
  end

  def test_collect_reports_sync_metrics_for_directory
    install_skill("pi", "as-sync")
    install_skill("pi", "as-outdated", content: <<~MD)
      ---
      name: as-outdated
      source: ace-task
      ---

      outdated
    MD
    install_extra_skill("pi", "as-extra")

    snapshot = collector.collect(provider: "pi")
    provider = snapshot.fetch("providers").first

    assert_equal "directory", provider.fetch("path_type")
    assert_equal ".pi/skills", provider.fetch("relative_output_dir")
    assert_equal 3, provider.fetch("expected")
    assert_equal 3, provider.fetch("installed")
    assert_equal 1, provider.fetch("in_sync")
    assert_equal 1, provider.fetch("outdated")
    assert_equal 1, provider.fetch("missing")
    assert_equal 1, provider.fetch("extra")
  end

  def test_collect_reports_symlink_type_and_compares_through_target
    install_skill("shared", "as-sync")
    install_skill("shared", "as-outdated", content: <<~MD)
      ---
      name: as-outdated
      source: ace-task
      ---

      outdated
    MD

    FileUtils.mkdir_p(File.join(@tmpdir, ".pi"))
    FileUtils.ln_s("../.shared/skills", File.join(@tmpdir, ".pi", "skills"))

    snapshot = collector.collect(provider: "pi")
    provider = snapshot.fetch("providers").first

    assert_equal "symlink", provider.fetch("path_type")
    assert_equal 2, provider.fetch("installed")
    assert_equal 1, provider.fetch("in_sync")
    assert_equal 1, provider.fetch("outdated")
    assert_equal 1, provider.fetch("missing")
    assert_equal 0, provider.fetch("extra")
  end

  def test_to_table_includes_canonical_summary_and_provider_metrics
    install_skill("pi", "as-sync")

    output = collector.to_table(collector.collect(provider: "pi"))

    assert_includes output, "CANONICAL SKILLS"
    assert_includes output, "SOURCE"
    assert_includes output, "EXPECTED"
    assert_includes output, "IN_SYNC"
    assert_includes output, "ace-task"
    assert_includes output, "pi"
  end

  private

  def collector
    @collector ||= Ace::Handbook::Organisms::StatusCollector.new(
      project_root: @tmpdir,
      config: {}
    )
  end

  def create_provider_manifest(provider, output_dir)
    dir = File.join(@tmpdir, "ace-handbook-integration-#{provider}", ".ace-defaults", "handbook", "providers")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{provider}.yml"), <<~YML)
      provider: #{provider}
      output_dir: #{output_dir}
    YML
  end

  def create_skill_source_registration(name, relative_path)
    dir = File.join(@tmpdir, ".ace", "nav", "protocols", "skill-sources")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{name}.yml"), <<~YML)
      name: #{name}
      type: directory
      path: #{relative_path}
      priority: 10
    YML
  end

  def create_skill(name, source:, body: "Load and run `ace-bundle wfi://test` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.\n")
    skill_dir = File.join(@tmpdir, source, "handbook", "skills", name)
    FileUtils.mkdir_p(skill_dir)
    File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
      ---
      name: #{name}
      description: Test skill
      source: #{source}
      skill:
        kind: workflow
      ---

      #{body}
    MD
  end

  def install_skill(provider_or_dir, skill_name, content: nil)
    output_dir = provider_or_dir == "shared" ? File.join(@tmpdir, ".shared", "skills") : File.join(@tmpdir, ".#{provider_or_dir}", "skills")
    FileUtils.mkdir_p(File.join(output_dir, skill_name))

    skill = Ace::Handbook::Organisms::SkillInventory.new(project_root: @tmpdir).all.find { |entry| entry.name == skill_name }
    rendered = content || Ace::Handbook::Molecules::SkillProjection.render(
      Ace::Handbook::Molecules::SkillProjection.projected_frontmatter(skill.frontmatter, provider: "pi"),
      skill.body
    )

    File.write(File.join(output_dir, skill_name, "SKILL.md"), rendered)
  end

  def install_extra_skill(provider, skill_name)
    output_dir = File.join(@tmpdir, ".#{provider}", "skills", skill_name)
    FileUtils.mkdir_p(output_dir)
    File.write(File.join(output_dir, "SKILL.md"), <<~MD)
      ---
      name: #{skill_name}
      source: custom
      ---

      extra
    MD
  end
end
