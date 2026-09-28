# frozen_string_literal: true

require_relative "../test_helper"

class Ace::Handbook::Integration::PiExtensionAssetsTest < Minitest::Test
  def setup
    @package_root = File.expand_path("../..", __dir__)
  end

  def test_provider_manifest_declares_extension_projection
    manifest = provider_manifest

    assert_equal ".pi/extensions", manifest.fetch("extensions_dir")
  end

  def test_extension_entrypoint_and_modules_ship_in_the_gem
    gem_files = gemspec_file_list

    assert_includes gem_files, "handbook/extensions/ace-wake.js"
    assert_includes gem_files, "handbook/extensions/package.json"
    assert_includes gem_files, "handbook/extensions/wake/types.js"
    assert_includes gem_files, "handbook/extensions/wake/wake-dispatcher.js"
    assert_includes gem_files, "handbook/extensions/wake/wake-registry.js"
    assert_includes gem_files, "handbook/extensions/wake/loop-subscription.js"
    assert_includes gem_files, "handbook/extensions/wake/watch-subscription.js"
    assert_includes gem_files, "handbook/extensions/wake/wake-command-parser.js"
    assert gem_files.grep(%r{^test/js/}).empty?, "test assets must not ship in the gem"
  end

  def test_extension_entrypoint_uses_the_auto_discoverable_js_extension
    # Pi's extension discovery only accepts .ts and .js entrypoints; a .mjs
    # entrypoint would never load unless explicitly passed.
    assert File.file?(File.join(@package_root, "handbook", "extensions", "ace-wake.js"))
    refute File.file?(File.join(@package_root, "handbook", "extensions", "ace-wake.mjs"))
    entry = File.read(File.join(@package_root, "handbook", "extensions", "ace-wake.js"))

    imports = entry.scan(/import\s+[^"']*["']([^"']+)["']/).flatten
    offenders = imports.reject { |name| name.start_with?(".", "node:") }
    assert_empty offenders, "the extension must rely only on relative modules and node builtins"
  end

  def test_extension_projects_through_handbook_sync_into_pi_extensions
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

      assert_equal ".pi/extensions", result.fetch(:relative_extensions_dir)
      assert_equal projected_relative_paths.size, result.fetch(:projected_extensions)
      assert_equal 0, result.fetch(:removed_extension_entries)

      projected_relative_paths.each do |relative_path|
        projected = File.join(project_root, ".pi", "extensions", relative_path)
        assert File.file?(projected), "projected extension asset missing: #{relative_path}"
        assert FileUtils.compare_file(projected, File.join(@package_root, "handbook", "extensions", relative_path))
      end

      receipt_path = File.join(project_root, ".pi", "extensions", ".ace-handbook-projection.json")
      receipt = JSON.parse(File.read(receipt_path))
      assert_equal "ace-handbook-integration-pi", receipt.fetch("source")
      assert_equal projected_relative_paths.sort, receipt.fetch("files").sort

      second = syncer.sync(provider: "pi").first
      assert_equal 0, second.fetch(:updated_extension_files), "projection must be idempotent"
    end
  end

  def test_javascript_suite_passes_on_the_installed_node_runtime
    skip "node is not installed" unless node_bin

    output = +`#{node_bin} --test #{File.join(@package_root, "test", "js", "*.test.mjs")} 2>&1`
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

  def projected_relative_paths
    source_root = File.join(@package_root, "handbook", "extensions")
    Dir.glob(File.join(source_root, "**", "*"))
       .select { |path| File.file?(path) }
       .map { |path| Pathname.new(path).relative_path_from(Pathname.new(source_root)).to_s }
  end

  def node_bin
    @node_bin ||= begin
      candidate = ENV.fetch("NODE_BIN", "node")
      found = system("command -v #{candidate} >/dev/null 2>&1")
      found ? candidate : nil
    end
  end
end
