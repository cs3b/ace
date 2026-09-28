# frozen_string_literal: true

require "test_helper"

class Ace::Handbook::Organisms::ProviderSyncerTest < Minitest::Test
  FakeSkillSource = Struct.new(:source)
  FakeProviderRegistry = Struct.new(:provider_manifests) do
    def providers
      provider_manifests.keys.sort
    end

    def known?(provider)
      provider_manifests.key?(provider.to_s)
    end

    def output_dir(provider)
      provider_manifests.fetch(provider.to_s).fetch("output_dir")
    end

    def prompts_dir(provider)
      provider_manifests.fetch(provider.to_s)["prompts_dir"]
    end

    def extensions_dir(provider)
      provider_manifests.fetch(provider.to_s)["extensions_dir"]
    end

    def package_root(provider)
      File.join("/fake-packages", "ace-handbook-integration-#{provider}")
    end
  end

  def setup
    @tmpdir = Dir.mktmpdir
    create_handbook_provider_manifest("agents", ".agents/skills")
    create_provider_manifest("pi", ".pi/skills")
    create_provider_manifest("claude", ".claude/skills")
    create_provider_manifest("codex", ".codex/skills")
    create_provider_manifest("gemini", ".gemini/skills")
    create_provider_manifest("opencode", ".opencode/skills")
    create_skill_source_registration("ace-demo", "ace-demo/handbook/skills")
    create_skill("as-test-sync", <<~BODY)
      Load and run `ace-bundle wfi://test/sync` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
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

  def test_default_sync_projects_to_agents_only
    results = syncer.sync

    assert_equal ["agents"], results.map { |entry| entry[:provider] }
    assert File.exist?(File.join(@tmpdir, ".agents", "skills", "as-test-sync", "SKILL.md"))
    refute File.exist?(File.join(@tmpdir, ".codex", "skills", "as-test-sync", "SKILL.md"))
  end

  def test_default_agents_sync_includes_legacy_full_provider_targets
    frontmatter = {
      "name" => "as-git-commit",
      "description" => "Generate intelligent git commit message",
      "source" => "ace-demo",
      "skill" => {"kind" => "workflow", "execution" => {"workflow" => "wfi://git/commit"}},
      "integration" => {
        "targets" => %w[claude codex gemini opencode pi],
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          }
        }
      }
    }
    create_skill("as-git-commit", <<~BODY, frontmatter: frontmatter)
      Load and run `ace-bundle wfi://git/commit` in the current project.
      Follow the loaded workflow as the source of truth and execute it end-to-end.
    BODY

    result = agents_only_syncer.sync.first

    assert_equal "agents", result.fetch(:provider)
    assert_equal 2, result.fetch(:projected_skills)
    rendered = File.read(File.join(@tmpdir, ".agents", "skills", "as-git-commit", "SKILL.md"))
    assert_includes rendered, "ace-bundle wfi://git/commit"
    refute_includes rendered, "integration:"
    refute_includes rendered, "context: fork"
    refute_includes rendered, "model: haiku"
    refute File.exist?(File.join(@tmpdir, ".codex", "skills", "as-git-commit", "SKILL.md"))
  end

  def test_default_agents_sync_excludes_narrow_provider_targets
    frontmatter = {
      "name" => "as-codex-only",
      "description" => "Codex-only workflow",
      "source" => "ace-demo",
      "skill" => {"kind" => "workflow"},
      "integration" => {
        "targets" => ["codex"]
      }
    }
    create_skill("as-codex-only", <<~BODY, frontmatter: frontmatter)
      Load and run `ace-bundle wfi://codex-only` in the current project.
      Follow the loaded workflow as the source of truth and execute it end-to-end.
    BODY

    result = agents_only_syncer.sync.first

    assert_equal 1, result.fetch(:projected_skills)
    refute File.exist?(File.join(@tmpdir, ".agents", "skills", "as-codex-only", "SKILL.md"))
  end

  def test_explicit_provider_sync_projects_codex_even_when_default_is_agents
    configured = Ace::Handbook::Organisms::ProviderSyncer.new(
      project_root: @tmpdir,
      config: {"sync" => {"providers" => {"enabled" => ["agents"], "disabled" => []}}}
    )

    results = configured.sync(provider: "codex")

    assert_equal ["codex"], results.map { |entry| entry[:provider] }
    assert File.exist?(File.join(@tmpdir, ".codex", "skills", "as-test-sync", "SKILL.md"))
    refute File.exist?(File.join(@tmpdir, ".agents", "skills", "as-test-sync", "SKILL.md"))
  end

  def test_explicit_provider_sync_blocks_disabled_provider
    configured = Ace::Handbook::Organisms::ProviderSyncer.new(
      project_root: @tmpdir,
      config: {"sync" => {"providers" => {"enabled" => ["agents"], "disabled" => ["codex"]}}}
    )

    error = assert_raises(ArgumentError) { configured.sync(provider: "codex") }

    assert_includes error.message, "Provider 'codex' is disabled"
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
      Load and run `ace-bundle wfi://test/override` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
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

  def test_sync_projects_prompt_templates_into_prompts_dir
    create_provider_manifest("pi", ".pi/skills", prompts_dir: ".pi/prompts")
    create_prompt_template("pi", "loop", source: "ace-handbook-integration-pi")

    result = syncer.sync(provider: "pi").first

    projected = File.join(@tmpdir, ".pi", "prompts", "loop.md")
    assert_equal ".pi/prompts", result.fetch(:relative_prompts_dir)
    assert_equal 1, result.fetch(:projected_prompts)
    assert_equal 1, result.fetch(:updated_prompt_files)
    assert_equal 0, result.fetch(:removed_prompt_entries)
    assert_includes File.read(projected), "source: ace-handbook-integration-pi"

    second = syncer.sync(provider: "pi").first
    assert_equal 1, second.fetch(:projected_prompts)
    assert_equal 0, second.fetch(:updated_prompt_files)
    assert_equal 0, second.fetch(:removed_prompt_entries)
  end

  def test_sync_prunes_only_stale_ace_marked_prompt_templates
    create_provider_manifest("pi", ".pi/skills", prompts_dir: ".pi/prompts")
    create_prompt_template("pi", "loop", source: "ace-handbook-integration-pi")
    prompts_dir = File.join(@tmpdir, ".pi", "prompts")
    FileUtils.mkdir_p(prompts_dir)
    File.write(File.join(prompts_dir, "retired-loop.md"), "---\nsource: ace-handbook-integration-pi\n---\nold body")
    File.write(File.join(prompts_dir, "user-own.md"), "---\ndescription: mine\n---\nkeep me")

    result = syncer.sync(provider: "pi").first

    assert_equal 1, result.fetch(:removed_prompt_entries)
    refute File.exist?(File.join(prompts_dir, "retired-loop.md"))
    assert File.exist?(File.join(prompts_dir, "user-own.md"))
    assert File.exist?(File.join(prompts_dir, "loop.md"))
  end

  def test_sync_skips_prompt_projection_without_prompts_dir
    create_prompt_template("codex", "loop", source: "ace-handbook-integration-codex")

    result = syncer.sync(provider: "codex").first

    refute result.key?(:relative_prompts_dir)
    refute Dir.exist?(File.join(@tmpdir, ".codex", "prompts"))
  end

  def test_sync_projects_extension_assets_into_extensions_dir
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// wake entrypoint\nexport default () => {};\n")
    create_extension_asset("pi", "wake/helper.mjs", "export const tick = () => 1;\n")

    result = syncer.sync(provider: "pi").first

    assert_equal ".pi/extensions", result.fetch(:relative_extensions_dir)
    assert_equal 2, result.fetch(:projected_extensions)
    assert_equal 2, result.fetch(:updated_extension_files)
    assert_equal 0, result.fetch(:removed_extension_entries)
    assert_equal "// wake entrypoint\nexport default () => {};\n", File.read(File.join(@tmpdir, ".pi", "extensions", "ace-wake.mjs"))
    assert File.exist?(File.join(@tmpdir, ".pi", "extensions", "wake", "helper.mjs"))

    receipt = JSON.parse(File.read(File.join(@tmpdir, ".pi", "extensions", ".ace-handbook-projection.json")))
    assert_equal "ace-handbook-integration-pi", receipt.fetch("source")
    assert_equal ["ace-wake.mjs", "wake/helper.mjs"], receipt.fetch("files").sort

    second = syncer.sync(provider: "pi").first
    assert_equal 2, second.fetch(:projected_extensions)
    assert_equal 0, second.fetch(:updated_extension_files)
    assert_equal 0, second.fetch(:removed_extension_entries)
  end

  def test_sync_updates_changed_extension_assets
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "export const version = 1;\n")

    syncer.sync(provider: "pi")
    create_extension_asset("pi", "ace-wake.mjs", "export const version = 2;\n")

    result = syncer.sync(provider: "pi").first

    assert_equal 1, result.fetch(:updated_extension_files)
    assert_equal "export const version = 2;\n", File.read(File.join(@tmpdir, ".pi", "extensions", "ace-wake.mjs"))
  end

  def test_sync_prunes_only_receipt_recorded_extension_files
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")

    syncer.sync(provider: "pi")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    stale_dir = File.join(extensions_dir, "wake")
    FileUtils.mkdir_p(stale_dir)
    File.write(File.join(stale_dir, "retired.mjs"), "// retired\n")
    File.write(File.join(extensions_dir, "user-own.mjs"), "// user extension\n")
    receipt = JSON.parse(File.read(File.join(extensions_dir, ".ace-handbook-projection.json")))
    receipt["files"] << "wake/retired.mjs"
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), JSON.generate(receipt))

    result = syncer.sync(provider: "pi").first

    assert_equal 1, result.fetch(:removed_extension_entries)
    refute File.exist?(File.join(stale_dir, "retired.mjs"))
    refute Dir.exist?(stale_dir)
    assert File.exist?(File.join(extensions_dir, "user-own.mjs"))
    assert File.exist?(File.join(extensions_dir, "ace-wake.mjs"))
  end

  def test_sync_never_prunes_extensions_without_receipt
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    FileUtils.mkdir_p(extensions_dir)
    File.write(File.join(extensions_dir, "pre-existing.mjs"), "// unknown origin\n")

    result = syncer.sync(provider: "pi").first

    assert_equal 0, result.fetch(:removed_extension_entries)
    assert File.exist?(File.join(extensions_dir, "pre-existing.mjs"))
  end

  def test_sync_prunes_stale_file_even_when_sibling_directory_keeps_files
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")

    syncer.sync(provider: "pi")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    FileUtils.mkdir_p(File.join(extensions_dir, "wake"))
    File.write(File.join(extensions_dir, "wake", "retired.mjs"), "// retired\n")
    File.write(File.join(extensions_dir, "wake", "keeper.mjs"), "// kept\n")
    receipt = JSON.parse(File.read(File.join(extensions_dir, ".ace-handbook-projection.json")))
    receipt["files"] << "wake/retired.mjs"
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), JSON.generate(receipt))

    result = syncer.sync(provider: "pi").first

    assert_equal 1, result.fetch(:removed_extension_entries)
    refute File.exist?(File.join(extensions_dir, "wake", "retired.mjs"))
    assert File.exist?(File.join(extensions_dir, "wake", "keeper.mjs"))
    assert_equal 0, result.fetch(:updated_extension_files), "sync must complete after partial pruning"
    assert File.exist?(File.join(extensions_dir, "ace-wake.mjs"))
  end

  def test_sync_ignores_receipt_paths_outside_the_projection_directory
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")

    syncer.sync(provider: "pi")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    victim = File.join(@tmpdir, ".pi", "victim.txt")
    File.write(victim, "do not delete")
    receipt = JSON.parse(File.read(File.join(extensions_dir, ".ace-handbook-projection.json")))
    receipt["files"] += ["../victim.txt", "/etc/hostname", "sub/../../escape.txt"]
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), JSON.generate(receipt))

    result = syncer.sync(provider: "pi").first

    assert File.exist?(victim), "receipt traversal must never delete outside the projection dir"
    assert_equal 0, result.fetch(:removed_extension_entries), "traversal entries are never removed"
    assert File.exist?(File.join(extensions_dir, "ace-wake.mjs"))
  end

  def test_sync_never_writes_through_a_symlinked_receipt
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")

    syncer.sync(provider: "pi")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    outside = File.join(@tmpdir, "outside")
    FileUtils.mkdir_p(outside)
    victim = File.join(outside, "victim.txt")
    File.write(victim, "precious content")
    receipt_path = File.join(extensions_dir, ".ace-handbook-projection.json")
    FileUtils.rm_f(receipt_path)
    FileUtils.ln_s(victim, receipt_path)

    # An unreadable receipt claims nothing, so the projection refuses rather
    # than guessing ownership — and never writes through the symlink.
    error = assert_raises(StandardError) { syncer.sync(provider: "pi") }

    assert_includes error.message, "refusing to overwrite"
    assert_equal "precious content", File.read(victim), "the receipt write must truncate the symlink target"
    assert File.symlink?(receipt_path), "the refused sync must leave the receipt untouched"
  end

  def test_sync_refuses_conflicting_writes_when_the_receipt_is_corrupt
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake/index.js", "export const v = 1;\n")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    FileUtils.mkdir_p(File.join(extensions_dir, "ace-wake"))
    File.write(File.join(extensions_dir, "ace-wake", "index.js"), "\"user content\"")
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), "{ not json")

    error = assert_raises(StandardError) { syncer.sync(provider: "pi") }

    assert_includes error.message, "refusing to overwrite"
    assert_equal "\"user content\"", File.read(File.join(extensions_dir, "ace-wake", "index.js"))
  end

  def test_sync_ignores_receipts_from_a_foreign_source
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake/index.js", "export const v = 1;\n")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    FileUtils.mkdir_p(File.join(extensions_dir, "ace-wake"))
    File.write(File.join(extensions_dir, "ace-wake", "index.js"), "\"user content\"")
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), JSON.generate(
      "source" => "different-projector",
      "files" => ["ace-wake/index.js"]
    ))

    error = assert_raises(StandardError) { syncer.sync(provider: "pi") }

    assert_includes error.message, "refusing to overwrite"
    assert_equal "\"user content\"", File.read(File.join(extensions_dir, "ace-wake", "index.js")),
                 "a foreign receipt must not authorize overwrites"
  end

  def test_sync_rejects_receipt_paths_through_symlinked_components
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake.mjs", "// current\n")

    syncer.sync(provider: "pi")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    outside = File.join(@tmpdir, "outside")
    FileUtils.mkdir_p(outside)
    victim = File.join(outside, "victim.txt")
    File.write(victim, "do not delete")
    FileUtils.ln_s(outside, File.join(extensions_dir, "linked"))
    receipt = JSON.parse(File.read(File.join(extensions_dir, ".ace-handbook-projection.json")))
    receipt["files"] << "linked/victim.txt"
    File.write(File.join(extensions_dir, ".ace-handbook-projection.json"), JSON.generate(receipt))

    result = syncer.sync(provider: "pi").first

    assert File.exist?(victim), "symlinked receipt components must never delete outside the projection dir"
    assert_equal 0, result.fetch(:removed_extension_entries)
    assert File.exist?(File.join(extensions_dir, "ace-wake.mjs"))
  end

  def test_sync_refuses_to_overwrite_unowned_destination_files
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake/package.json", "{\"type\": \"module\"}\n")
    extensions_dir = File.join(@tmpdir, ".pi", "extensions")
    FileUtils.mkdir_p(File.join(extensions_dir, "ace-wake"))
    File.write(File.join(extensions_dir, "ace-wake", "package.json"), "{\"dependencies\": {\"user-pkg\": \"1.0.0\"}}\n")

    error = assert_raises(StandardError) { syncer.sync(provider: "pi") }

    assert_includes error.message, "refusing to overwrite"
    assert_includes error.message, "not claimed by a valid projection receipt"
    assert_equal "{\"dependencies\": {\"user-pkg\": \"1.0.0\"}}\n", File.read(File.join(extensions_dir, "ace-wake", "package.json"))
  end

  def test_sync_updates_owned_files_on_repeat_projections
    create_provider_manifest("pi", ".pi/skills", extensions_dir: ".pi/extensions")
    create_extension_asset("pi", "ace-wake/index.js", "export const v = 1;\n")

    syncer.sync(provider: "pi")
    create_extension_asset("pi", "ace-wake/index.js", "export const v = 2;\n")
    result = syncer.sync(provider: "pi").first

    assert_equal 1, result.fetch(:updated_extension_files), "receipt-owned files are updated freely"
    assert_equal "export const v = 2;\n", File.read(File.join(@tmpdir, ".pi", "extensions", "ace-wake", "index.js"))
  end

  def test_sync_skips_extension_projection_without_extensions_dir
    create_extension_asset("codex", "ace-wake.mjs", "// codex extension\n")

    result = syncer.sync(provider: "codex").first

    refute result.key?(:relative_extensions_dir)
    refute Dir.exist?(File.join(@tmpdir, ".codex", "extensions"))
  end

  def test_all_provider_projections_are_consistent_and_idempotent
    create_skill(
      "as-provider-contract",
      <<~BODY,
        Load and run `ace-bundle wfi://test/provider-contract` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
      BODY
      frontmatter: {
        "name" => "as-provider-contract",
        "description" => "Canonical provider contract",
        "source" => "ace-demo",
        "skill" => {"kind" => "workflow"},
        "integration" => {
          "providers" => {
            "agents" => {"frontmatter" => {"description" => "agents projection"}},
            "claude" => {"frontmatter" => {"description" => "claude projection"}},
            "codex" => {"frontmatter" => {"description" => "codex projection"}},
            "gemini" => {"frontmatter" => {"description" => "gemini projection"}},
            "opencode" => {"frontmatter" => {"description" => "opencode projection"}},
            "pi" => {"frontmatter" => {"description" => "pi projection"}}
          }
        }
      }
    )

    projection_providers.each do |provider|
      first = syncer.sync(provider: provider).fetch(0)
      assert_equal 2, first.fetch(:projected_skills), provider

      output_path = File.join(@tmpdir, ".#{provider}", "skills", "as-provider-contract", "SKILL.md")
      rendered = File.read(output_path)
      document = YAML.safe_load(rendered.split("---\n", 3).fetch(1))
      assert_equal "#{provider} projection", document.fetch("description"), provider
      refute_includes rendered, "integration:", provider

      stale_dir = File.join(@tmpdir, ".#{provider}", "skills", "as-stale-contract")
      FileUtils.mkdir_p(stale_dir)
      File.write(File.join(stale_dir, "SKILL.md"), "---\nname: as-stale-contract\n---\n")

      second = syncer.sync(provider: provider).fetch(0)
      assert_equal 0, second.fetch(:updated_files), provider
      assert_equal 1, second.fetch(:removed_entries), provider
      refute Dir.exist?(stale_dir), provider

      third = syncer.sync(provider: provider).fetch(0)
      assert_equal 0, third.fetch(:updated_files), provider
      assert_equal 0, third.fetch(:removed_entries), provider

      status = Ace::Handbook::Organisms::StatusCollector.new(
        project_root: @tmpdir,
        config: {}
      ).collect(provider: provider).fetch("providers").fetch(0)
      assert_equal first.fetch(:projected_skills), status.fetch("expected"), provider
      assert_equal status.fetch("expected"), status.fetch("installed"), provider
      assert_equal status.fetch("expected"), status.fetch("in_sync"), provider
      assert_equal 0, status.fetch("outdated"), provider
      assert_equal 0, status.fetch("missing"), provider
      assert_equal 0, status.fetch("extra"), provider
    end
  end

  def test_sync_projects_claude_overrides_and_preserves_canonical_git_commit_body
    frontmatter = {
      "name" => "as-git-commit",
      "description" => "Generate intelligent git commit message",
      "source" => "ace-demo",
      "argument-hint" => ["intention"],
      "skill" => {"kind" => "workflow", "execution" => {"workflow" => "wfi://git/commit"}},
      "integration" => {
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          }
        }
      }
    }

    create_skill("as-git-commit", <<~BODY, frontmatter: frontmatter)
      ## Arguments

      Use the skill `argument-hint` values as the explicit inputs for this skill.

      ## Variables

      - INTENTION
      - CHANGED_FILES

      ## Execution

      - You are working in the current project.
      - Run `ace-bundle wfi://git/commit` in the current project to load the workflow instructions.
      - Read the loaded workflow and execute it end-to-end in this project.
      - Follow the workflow as the source of truth.
      - If `INTENTION` is provided explicitly, use it. Otherwise derive it from recent changes.
      - If `CHANGED_FILES` are provided explicitly, use them. Otherwise derive them from changed files in this session.
      - Do the work described by the workflow instead of only summarizing it.
      - When the workflow requires edits, tests, or commits, perform them in this project.
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-git-commit", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-git-commit", "SKILL.md"))

    assert_includes claude_rendered, "context: fork"
    assert_includes claude_rendered, "model: haiku"
    assert_includes codex_rendered, "argument-hint:\n- intention"
    assert_includes codex_rendered, "## Variables"
    assert_includes codex_rendered, "- INTENTION"
    assert_includes codex_rendered, "- CHANGED_FILES"
    assert_includes codex_rendered, "## Execution"
    assert_includes codex_rendered, "Run `ace-bundle wfi://git/commit` in the current project to load the workflow instructions."
    refute_includes codex_rendered, "context: fork"
    refute_includes codex_rendered, "model: haiku"
    refute_includes claude_rendered, "integration:"
    refute_includes codex_rendered, "integration:"
  end

  def test_sync_projects_claude_overrides_and_preserves_canonical_release_body
    frontmatter = {
      "name" => "as-release",
      "description" => "Release modified ACE packages",
      "source" => "ace-demo",
      "argument-hint" => "package-name... bump-level",
      "skill" => {"kind" => "workflow", "execution" => {"workflow" => "wfi://release/local"}},
      "integration" => {
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          }
        }
      }
    }

    create_skill("as-release", <<~BODY, frontmatter: frontmatter)
      ## Arguments

      Use the skill `argument-hint` values as the explicit inputs for this skill.

      ## Variables

      None

      ## Execution

      - You are working in the current project.
      - Run `ace-bundle wfi://release/local` in the current project to load the workflow instructions.
      - Read the loaded workflow and execute it end-to-end in this project.
      - Follow the workflow as the source of truth.
      - Do the work described by the workflow instead of only summarizing it.
      - When the workflow requires edits, tests, or commits, perform them in this project.
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-release", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-release", "SKILL.md"))

    assert_includes claude_rendered, "context: fork"
    assert_includes claude_rendered, "model: haiku"
    assert_includes codex_rendered, "argument-hint: package-name... bump-level"
    assert_includes codex_rendered, "## Variables"
    assert_includes codex_rendered, "None"
    assert_includes codex_rendered, "## Execution"
    assert_includes codex_rendered, "Run `ace-bundle wfi://release/local` in the current project to load the workflow instructions."
    refute_includes claude_rendered, "integration:"
    refute_includes codex_rendered, "integration:"
  end

  def test_sync_projects_claude_overrides_and_preserves_canonical_github_pr_body
    frontmatter = {
      "name" => "as-github-pr-create",
      "description" => "Create GitHub pull request",
      "source" => "ace-demo",
      "argument-hint" => "pr-type",
      "skill" => {"kind" => "workflow", "execution" => {"workflow" => "wfi://github/pr/create"}},
      "integration" => {
        "providers" => {
          "claude" => {
            "frontmatter" => {
              "context" => "fork",
              "model" => "haiku"
            }
          }
        }
      }
    }

    create_skill("as-github-pr-create", <<~BODY, frontmatter: frontmatter)
      ## Arguments

      Use the skill `argument-hint` values as the explicit inputs for this skill.

      ## Variables

      None

      ## Execution

      - You are working in the current project.
      - Run `ace-bundle wfi://github/pr/create` in the current project to load the workflow instructions.
      - Read the loaded workflow and execute it end-to-end in this project.
      - Follow the workflow as the source of truth.
      - Do the work described by the workflow instead of only summarizing it.
      - When the workflow requires edits, tests, or commits, perform them in this project.
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-github-pr-create", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-github-pr-create", "SKILL.md"))

    assert_includes claude_rendered, "context: fork"
    assert_includes claude_rendered, "model: haiku"
    assert_includes claude_rendered, "## Execution"
    assert_includes claude_rendered, "Run `ace-bundle wfi://github/pr/create` in the current project to load the workflow instructions."
    refute_includes codex_rendered, "context: fork"
    refute_includes codex_rendered, "model: haiku"
    assert_includes codex_rendered, "## Execution"
    refute_includes codex_rendered, "integration:"
  end

  def test_sync_preserves_conditional_sandbox_branch_in_skill_body
    create_skill("as-e2e-run", <<~BODY)
      If `$ARGUMENTS` contains `--sandbox`:
        Load and run `ace-bundle wfi://e2e/execute` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
      Otherwise:
        Load and run `ace-bundle wfi://e2e/run` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
    BODY

    syncer.sync(provider: "claude")
    syncer.sync(provider: "codex")

    claude_rendered = File.read(File.join(@tmpdir, ".claude", "skills", "as-e2e-run", "SKILL.md"))
    codex_rendered = File.read(File.join(@tmpdir, ".codex", "skills", "as-e2e-run", "SKILL.md"))

    assert_includes claude_rendered, "If `$ARGUMENTS` contains `--sandbox`:"
    assert_includes claude_rendered, "Load and run `ace-bundle wfi://e2e/execute` in the current project"
    assert_includes codex_rendered, "If `$ARGUMENTS` contains `--sandbox`:"
    assert_includes codex_rendered, "Load and run `ace-bundle wfi://e2e/execute` in the current project"
  end

  def test_summarize_sources_handles_empty_inventory
    assert_equal({}, syncer.send(:summarize_sources, []))
  end

  def test_summarize_sources_normalizes_nil_and_blank_sources
    skills = [
      FakeSkillSource.new("ace-handbook"),
      FakeSkillSource.new(nil),
      FakeSkillSource.new("")
    ]

    assert_equal({"ace-handbook" => 1, "unknown" => 2}, syncer.send(:summarize_sources, skills))
  end

  private

  def syncer
    @syncer ||= Ace::Handbook::Organisms::ProviderSyncer.new(
      project_root: @tmpdir,
      prompt_inventory: hermetic_prompt_inventory,
      config: {}
    )
  end

  def hermetic_prompt_inventory
    Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: @tmpdir, gem_roots: [])
  end

  def agents_only_syncer
    Ace::Handbook::Organisms::ProviderSyncer.new(
      project_root: @tmpdir,
      registry: FakeProviderRegistry.new({
        "agents" => {"output_dir" => ".agents/skills"}
      }),
      config: {}
    )
  end

  def projection_providers
    %w[agents claude codex gemini opencode pi]
  end

  def create_provider_manifest(provider, output_dir, prompts_dir: nil, extensions_dir: nil)
    dir = File.join(@tmpdir, "ace-handbook-integration-#{provider}", ".ace-defaults", "handbook", "providers")
    FileUtils.mkdir_p(dir)
    manifest = "provider: #{provider}\noutput_dir: #{output_dir}\n"
    manifest += "prompts_dir: #{prompts_dir}\n" if prompts_dir
    manifest += "extensions_dir: #{extensions_dir}\n" if extensions_dir
    File.write(File.join(dir, "#{provider}.yml"), manifest)
  end

  def create_extension_asset(provider, relative_path, content)
    path = File.join(@tmpdir, "ace-handbook-integration-#{provider}", "handbook", "extensions", relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def create_prompt_template(provider, name, source:)
    dir = File.join(@tmpdir, "ace-handbook-integration-#{provider}", "handbook", "prompts")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{name}.md"), <<~MD)
      ---
      description: Test prompt #{name}
      argument-hint: "[focus]"
      source: #{source}
      ---

      Body of #{name} for #{provider}.
    MD
  end

  def create_handbook_provider_manifest(provider, output_dir)
    dir = File.join(@tmpdir, "ace-handbook", ".ace-defaults", "handbook", "providers")
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
