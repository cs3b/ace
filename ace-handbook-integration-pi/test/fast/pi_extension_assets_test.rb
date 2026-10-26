# frozen_string_literal: true

require_relative "../test_helper"

class Ace::Handbook::Integration::PiExtensionAssetsTest < Minitest::Test
  def setup
    @package_root = File.expand_path("../..", __dir__)
    # The ace-wake extension moved out of this package: its canonical source
    # is the repository-top-level ace-wake/ directory, deployed by the host
    # lane. These tests pin that boundary.
    @extension_root = File.join(@package_root, "..", "ace-wake")
  end

  def test_provider_manifest_declares_no_extension_projection
    manifest = provider_manifest

    refute manifest.key?("extensions_dir"),
      "the pi manifest must not declare an extensions_dir: the extension no longer ships in this package"
  end

  def test_extension_does_not_ship_in_the_gem
    gem_files = gemspec_file_list

    assert gem_files.grep(%r{handbook/extensions}).empty?,
      "the gem must not carry the extension; ace-wake/ is the single source"
    assert gem_files.grep(%r{test/js/}).empty?, "test assets must not ship in the gem"
  end

  def test_extension_source_lives_at_the_repository_top_level
    assert File.directory?(File.expand_path(@extension_root)),
      "ace-wake/ must exist at the repository top level"
    assert File.file?(File.join(@extension_root, "index.js"))
    assert File.file?(File.join(@extension_root, "README.md")), "provenance must be documented"
    %w[types.js wake-dispatcher.js wake-registry.js loop-subscription.js
      watch-subscription.js wake-command-parser.js eyes.js eyes-runtime.js].each do |module_file|
      assert File.file?(File.join(@extension_root, "wake", module_file)), "missing wake module: #{module_file}"
    end
  end

  def test_extension_entrypoint_is_a_discoverable_subdirectory_index
    # Pi's extension discovery accepts direct .ts/.js files and subdirectories
    # containing an index.js/index.ts; a .mjs entrypoint would never load
    # unless explicitly passed.
    assert File.file?(File.join(@extension_root, "index.js"))
    refute File.file?(File.join(@extension_root, "index.mjs"))
    entry = File.read(File.join(@extension_root, "index.js"))

    imports = entry.scan(/import\s+[^"']*["']([^"']+)["']/).flatten
    offenders = imports.reject { |name| name.start_with?(".", "node:") }
    assert_empty offenders, "the extension must rely only on relative modules and node builtins"
  end

  def test_sync_projects_no_extension_assets_for_pi
    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "project")
      FileUtils.mkdir_p(project_root)
      FileUtils.cp_r(@package_root, File.join(project_root, "ace-handbook-integration-pi"))

      registry = Ace::Handbook::Atoms::ProviderRegistry.new(project_root: project_root)
      syncer = Ace::Handbook::Organisms::ProviderSyncer.new(
        project_root: project_root,
        prompt_inventory: Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: project_root, gem_roots: []),
        config: {}
      )

      result = syncer.sync(provider: "pi").first

      refute result.key?(:relative_extensions_dir),
        "pi sync must not project extension assets anymore"
      refute File.exist?(File.join(project_root, ".pi", "extensions")),
        "no .pi/extensions directory may appear from a package without extension assets"
    end
  end

  def test_javascript_suite_passes_on_the_installed_node_runtime
    skip "node is not installed" unless node_bin

    output = +`#{node_bin} --test #{File.join(@extension_root, "test", "*.test.mjs")} 2>&1`
    assert_equal 0, $?.exitstatus, "node test suite failed:\n#{output}"
    assert_match(/^ℹ pass \d+/m, output, "node test summary missing:\n#{output}")
    assert_match(/^ℹ fail 0$/m, output, "node test failures:\n#{output}")
  end

  private

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

  def node_bin
    @node_bin ||= begin
      candidate = ENV.fetch("NODE_BIN", "node")
      found = system("command -v #{candidate} >/dev/null 2>&1")
      found ? candidate : nil
    end
  end
end
