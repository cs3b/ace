# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Organisms::ProviderSyncerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    create_provider_manifest("pi", ".pi/skills")
    create_provider_manifest("claude", ".claude/skills")
    create_provider_manifest("codex", ".codex/skills")
    create_skill_source_registration("ace-demo", "ace-demo/handbook/skills")
    create_skill("as-test-sync", <<~BODY)
      read and run `ace-bundle wfi://test/sync`
    BODY
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_sync_replaces_legacy_symlink_with_directory
    FileUtils.mkdir_p(File.join(@tmpdir, ".shared"))
    FileUtils.mkdir_p(File.join(@tmpdir, ".pi"))
    FileUtils.ln_s("../.shared/skills", File.join(@tmpdir, ".pi", "skills"))

    syncer.sync(provider: "pi")

    output_dir = File.join(@tmpdir, ".pi", "skills")
    refute File.symlink?(output_dir)
    assert File.directory?(output_dir)
    assert File.exist?(File.join(output_dir, "as-test-sync", "SKILL.md"))
  end

  def test_sync_applies_provider_frontmatter_overrides_and_removes_integration_block
    frontmatter = {
      "name" => "as-test-override",
      "description" => "Base description",
      "source" => "ace-demo",
      "skill" => {"kind" => "workflow"},
      "integration" => {
        "targets" => ["pi"],
        "providers" => {
          "pi" => {
            "frontmatter" => {
              "description" => "PI description"
            }
          }
        }
      }
    }

    create_skill("as-test-override", <<~BODY, frontmatter: frontmatter)
      read and run `ace-bundle wfi://test/override`
    BODY

    syncer.sync(provider: "pi")

    rendered = File.read(File.join(@tmpdir, ".pi", "skills", "as-test-override", "SKILL.md"))
    assert_includes rendered, "description: PI description"
    refute_includes rendered, "integration:"
  end

  def test_sync_prunes_stale_skill_directories
    stale_dir = File.join(@tmpdir, ".pi", "skills", "as-stale")
    FileUtils.mkdir_p(stale_dir)
    File.write(File.join(stale_dir, "SKILL.md"), "---\nname: as-stale\n---\n")

    result = syncer.sync(provider: "pi").first

    refute Dir.exist?(stale_dir)
    assert_equal 1, result[:removed_entries]
  end

  def test_sync_projects_provider_execution_overrides_for_git_commit
    frontmatter = {
      "name" => "as-git-commit",
      "description" => "Generate intelligent git commit message",
      "source" => "ace-demo",
      "skill" => {"kind" => "workflow"},
      "integration" => {
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          },
          "codex" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "gpt-5.3-codex-spark"
            }
          }
        }
      }
    }

    create_skill("as-git-commit", <<~BODY, frontmatter: frontmatter)
      read and run `ace-bundle wfi://git/commit`
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-git-commit", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-git-commit", "SKILL.md"))

    assert_includes claude_rendered, "context: fork"
    assert_includes claude_rendered, "model: haiku"
    assert_includes codex_rendered, "context: fork"
    assert_includes codex_rendered, "model: gpt-5.3-codex-spark"
    refute_includes claude_rendered, "integration:"
    refute_includes codex_rendered, "integration:"
  end

  def test_sync_preserves_conditional_sandbox_branch_in_skill_body
    create_skill("as-e2e-run", <<~BODY)
      If `$ARGUMENTS` contains `--sandbox`:
        read and run `ace-bundle wfi://e2e/execute`
      Otherwise:
        read and run `ace-bundle wfi://e2e/run`
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-e2e-run", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-e2e-run", "SKILL.md"))

    assert_includes claude_rendered, "If `$ARGUMENTS` contains `--sandbox`:"
    assert_includes claude_rendered, "read and run `ace-bundle wfi://e2e/execute`"
    assert_includes codex_rendered, "If `$ARGUMENTS` contains `--sandbox`:"
    assert_includes codex_rendered, "read and run `ace-bundle wfi://e2e/execute`"
  end

  private

  def syncer
    @syncer ||= Ace::Handbook::Organisms::ProviderSyncer.new(
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

  def create_skill(name, body, frontmatter: nil)
    skill_dir = File.join(@tmpdir, "ace-demo", "handbook", "skills", name)
    FileUtils.mkdir_p(skill_dir)
    data = frontmatter || {
      "name" => name,
      "description" => "Test skill",
      "source" => "ace-demo",
      "skill" => {"kind" => "workflow"}
    }
    File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
      ---
      #{YAML.dump(data).sub(/\A---\n/, "")}---

      #{body}
    MD
  end
end
