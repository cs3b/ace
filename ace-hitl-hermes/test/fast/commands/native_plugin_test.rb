# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class NativePluginTest < AceHermesTestCase
  def test_packaged_python_transport_runs_without_ruby_or_cli_on_path
    python, status = Open3.capture2("which", "python3")
    assert status.success?
    package = File.expand_path("../../..", __dir__)
    script = File.join(package, "test/fixtures/native_plugin_check.py")
    plugin = File.join(package, "plugin/native_transport.py")
    # Python itself is addressed absolutely; PATH has no Ruby, gem, or ACE CLI.
    out, err, status = Open3.capture3({"PATH" => "/nonexistent", "PYTHONDONTWRITEBYTECODE" => "1"},
      python.strip, script, plugin)
    assert status.success?, out + err
    assert_includes err, "Ran 9 tests"
    assert_includes err, "OK"
    refute_includes out + err, "123456"
    refute_includes out + err, "secret response"
  end

  def test_native_plugin_assets_are_in_gem_and_install_keeps_them
    require "ace/hitl/hermes/cli"
    require "rubygems/package"
    require "rubygems/user_interaction"
    package = File.expand_path("../../..", __dir__)
    spec = Dir.chdir(package) { Gem::Specification.load("ace-hitl-hermes.gemspec") }
    %w[plugin/__init__.py plugin/native_transport.py plugin/legacy_transition.py plugin/plugin.yaml].each do |path|
      assert_includes spec.files, path
    end
    Dir.mktmpdir do |tmp|
      artifact = File.join(tmp, "native.gem")
      Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
        Dir.chdir(package) { Gem::Package.build(spec, false, false, artifact) }
      end
      built = Gem::Package.new(artifact)
      dependency = built.spec.dependencies.find { |item| item.name == "ace-hitl" }
      refute dependency.match?("ace-hitl", "0.23.1")
      assert dependency.match?("ace-hitl", "0.23.2")
      extracted = File.join(tmp, "extracted")
      built.extract_files(extracted)
      %w[__init__.py native_transport.py legacy_transition.py].each do |asset|
        assert_equal File.binread(File.join(package, "plugin", asset)),
          File.binread(File.join(extracted, "plugin", asset))
      end
      installed = File.join(tmp, "plugin")
      Ace::Hitl::Hermes::CLI.start(["plugin", "install", "--path", installed], output: StringIO.new)
      assert_equal File.binread(File.join(package, "plugin/native_transport.py")),
        File.binread(File.join(installed, "native_transport.py"))
    end
  end

  def test_real_startup_order_and_single_owner_transition_without_ruby
    python, status = Open3.capture2("which", "python3")
    assert status.success?
    package = File.expand_path("../../..", __dir__)
    out, err, status = Open3.capture3({"PATH" => "/nonexistent", "PYTHONDONTWRITEBYTECODE" => "1"},
      python.strip, File.join(package, "test/fixtures/native_startup_transition_check.py"),
      File.join(package, "plugin"))
    assert status.success?, out + err
    assert_includes err, "Ran 9 tests"
    assert_includes err, "OK"
    refute_includes out + err, "private response"
  end
end
