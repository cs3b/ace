# frozen_string_literal: true

require_relative "../test_helper"

# Task 8xs.t.pu0.0 contract: the ace-wake extension ships from the
# publishable `ace-wake` asset package. This package declares the
# projection (extensions_dir + extensions_package) and depends on the
# gem; it must NOT carry a second editable JavaScript copy.
class Ace::Handbook::Integration::PiExtensionAssetsTest < Minitest::Test
  def setup
    @package_root = File.expand_path("../..", __dir__)
  end

  def test_provider_manifest_declares_gem_backed_extension_projection
    manifest = provider_manifest

    assert_equal ".pi/extensions", manifest["extensions_dir"],
      "the pi manifest must project extensions into .pi/extensions"
    assert_equal "ace-wake", manifest["extensions_package"],
      "the pi manifest must source extensions from the ace-wake asset package"
  end

  def test_extension_does_not_ship_in_the_gem
    gem_files = gemspec_file_list

    assert gem_files.grep(%r{handbook/extensions}).empty?,
      "the gem must not carry the extension; the ace-wake gem is the single source"
    assert gem_files.grep(%r{test/js/}).empty?, "test assets must not ship in the gem"
  end

  def test_gemspec_declares_the_ace_wake_dependency
    spec = Gem::Specification.load(File.join(@package_root, "ace-handbook-integration-pi.gemspec"))

    dependency = spec.dependencies.find { |dep| dep.name == "ace-wake" }
    refute_nil dependency, "the gemspec must depend on the ace-wake asset package"
    assert_match(/\A~> 0\./, dependency.requirement.to_s,
      "the ace-wake constraint must track the published release line")
  end

  def test_gem_backed_extension_source_resolves
    registry = Ace::Handbook::Atoms::ProviderRegistry.new(project_root: repo_root)

    source_root = registry.extensions_source_root("pi")
    refute_nil source_root
    assert File.file?(File.join(source_root, "handbook", "extensions", "ace-wake", "index.js")),
      "the resolved ace-wake package must carry the extension entrypoint"
  end

  def test_sync_projects_extension_assets_from_the_ace_wake_package
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "project")
      FileUtils.mkdir_p(project_root)
      # The project under test carries only the pi package plus the
      # ace-wake asset package — the standard monorepo layout.
      FileUtils.cp_r(@package_root, File.join(project_root, "ace-handbook-integration-pi"))
      FileUtils.cp_r(File.join(repo_root, "ace-wake"), File.join(project_root, "ace-wake"))

      registry = Ace::Handbook::Atoms::ProviderRegistry.new(project_root: project_root)
      syncer = Ace::Handbook::Organisms::ProviderSyncer.new(
        project_root: project_root,
        prompt_inventory: Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: project_root, gem_roots: []),
        config: {}
      )

      result = syncer.sync(provider: "pi").first

      assert_equal ".pi/extensions", result.fetch(:relative_extensions_dir)
      assert File.file?(File.join(project_root, ".pi", "extensions", "ace-wake", "index.js")),
        "the ace-wake entrypoint must project from the asset package"
      assert File.file?(File.join(project_root, ".pi", "extensions", "ace-wake", "wake", "wake-registry.js"))
      receipt = JSON.parse(File.read(File.join(project_root, ".pi", "extensions", ".ace-handbook-projection.json")))
      assert_includes receipt.fetch("files"), "ace-wake/index.js"

      # Second sync is idempotent: the same projection stays standing.
      second = syncer.sync(provider: "pi").first
      assert_equal result.fetch(:projected_extensions), second.fetch(:projected_extensions)
      assert File.file?(File.join(project_root, ".pi", "extensions", "ace-wake", "index.js"))
    end
  end

  private

  def repo_root
    File.expand_path("..", @package_root)
  end

  def provider_manifest
    path = File.join(@package_root, ".ace-defaults", "handbook", "providers", "pi.yml")
    YAML.safe_load_file(path, permitted_classes: [Date, Time], aliases: true)
  end

  def gemspec_file_list
    spec = Gem::Specification.load(File.join(@package_root, "ace-handbook-integration-pi.gemspec"))
    Dir.chdir(@package_root) do
      spec.files
    end
  end
end
