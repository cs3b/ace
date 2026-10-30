# frozen_string_literal: true

require "test_helper"
require "ace/handbook/atoms/provider_registry"

# PR #398 F4: a packaged extension source (`extensions_package`) must
# follow the toolchain mode. In auto mode a monorepo checkout projects
# the working-tree sibling package; in installed mode
# (ACE_TOOLCHAIN=installed) the checkout directory is project data,
# never the runtime source — the package must come from the installed
# gem.
class Ace::Handbook::Atoms::ProviderRegistryTest < Minitest::Test
  def setup
    @project_root = Dir.mktmpdir("provider-registry")
    provider_dir = File.join(@project_root, "ace-handbook", ".ace-defaults", "handbook", "providers")
    FileUtils.mkdir_p(provider_dir)
    File.write(File.join(provider_dir, "wake.yml"), <<~YAML)
      provider: wake
      output_dir: .wake
      extensions_package: ace-wake
    YAML
    # the checkout-side sibling package carries extensions
    @checkout_pkg = File.join(@project_root, "ace-wake")
    FileUtils.mkdir_p(File.join(@checkout_pkg, "handbook", "extensions"))
    File.write(File.join(@checkout_pkg, "handbook", "extensions", "checkout.txt"), "checkout")

    # an installed gem also carries extensions (different content)
    @gem_root = Dir.mktmpdir("installed-wake-gem")
    @gem_dir = File.join(@gem_root, "gems", "ace-wake-1.0")
    FileUtils.mkdir_p([@gem_dir, File.join(@gem_root, "specifications")])
    FileUtils.mkdir_p(File.join(@gem_dir, "handbook", "extensions"))
    File.write(File.join(@gem_dir, "handbook", "extensions", "gem.txt"), "gem")
    @spec = Gem::Specification.new { |item| item.name = "ace-wake"; item.version = "1.0" }
    @spec.loaded_from = File.join(@gem_root, "specifications", "ace-wake-1.0.gemspec")
    File.write(@spec.loaded_from, @spec.to_ruby)

    @old_toolchain = ENV["ACE_TOOLCHAIN"]
  end

  def teardown
    ENV["ACE_TOOLCHAIN"] = @old_toolchain
    FileUtils.remove_entry(@project_root) if @project_root
    FileUtils.remove_entry(@gem_root) if @gem_root
  end

  def registry
    Ace::Handbook::Atoms::ProviderRegistry.new(project_root: @project_root)
  end

  def with_installed_spec
    each_spec = proc { |&block| block.call(@spec) }
    Gem::Specification.stub(:each, each_spec) do
      Gem::Specification.stub(:find_all, proc { |&block| block ? [@spec].each(&block) : [@spec] }) do
        yield
      end
    end
  end

  def test_auto_mode_prefers_the_local_checkout_package
    ENV["ACE_TOOLCHAIN"] = "auto"

    assert_equal @checkout_pkg, registry.extensions_source_root("wake")
  end

  # PR #398 F4 (8xtgv6a6): an unresolvable extensions_package must raise,
  # never fall back to "no extensions" — the syncer would otherwise prune
  # every receipt-owned extension file from the target directory.
  def test_auto_mode_without_a_resolvable_package_raises
    ENV["ACE_TOOLCHAIN"] = "auto"
    FileUtils.rm_rf(@checkout_pkg)

    Gem::Specification.stub(:find_by_name, ->(_name) { raise Gem::LoadError, "ace-wake is not installed" }) do
      error = assert_raises(Ace::Handbook::Atoms::ProviderRegistry::UnresolvableExtensionsPackageError) { registry.extensions_source_root("wake") }
      assert_match(/extensions_package 'ace-wake' cannot be resolved/, error.message)
    end
  end

  def test_installed_mode_uses_the_installed_gem_not_the_checkout_directory
    ENV["ACE_TOOLCHAIN"] = "installed"
    with_installed_spec do
      assert_equal @gem_dir, registry.extensions_source_root("wake"),
        "packaged extensions must come from the installed gem when ACE_TOOLCHAIN=installed"
    end
  end

  def test_installed_mode_without_the_installed_gem_resolves_to_the_manifest_package
    ENV["ACE_TOOLCHAIN"] = "installed"
    empty_specs = proc { |_block| }
    Gem::Specification.stub(:each, empty_specs) do
      Gem::Specification.stub(:find_all, proc { |&block| block ? [].each(&block) : [] }) do
        # no installed ace-wake gem: falls back to the manifest's own
        # package root (the gem the manifest itself was loaded from),
        # never the checkout's sibling directory
        assert_equal registry.package_root("wake"), registry.extensions_source_root("wake")
      end
    end
  end
end
