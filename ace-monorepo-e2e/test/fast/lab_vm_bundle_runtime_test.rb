# frozen_string_literal: true

require_relative "../test_helper"
require "json"
require "yaml"
require "open3"
require_relative "../../../ace-lab/lib/ace/lab/molecules/gemset_provisioner"

class LabVmBundleRuntimeTest < AceMonorepoE2eTestCase
  def test_generated_fixture_manifest_is_accepted_by_bundle_installer
    Dir.mktmpdir("fixture-bundle-") do |dir|
      script = File.read(File.expand_path("../../lab-vm/provision-runtime.sh", __dir__))
      generator = script.split('python3 - "$input/release-manifest.json" > /etc/lab/ace-lab/install.yml <<\'PY\'', 2).last.split("\nPY", 2).first
      manifest = File.join(dir, "release.json")
      order = File.join(dir, "order.json")
      File.write(manifest, JSON.generate("gems" => [{"name" => "fixture-gem", "version" => "1.0.0"}]))
      File.write(order, JSON.generate(["fixture-gem"]))
      output, error, status = Open3.capture3("python3", "-", manifest,
        stdin_data: generator.sub("/var/lib/ace-e2e/install-gems.json", order))
      assert status.success?, error
      runtime = YAML.safe_load(output).fetch("gemset")
      runtime["gem_home"] = runtime.fetch("gem_home").sub("/opt/ace", dir)
      runtime["bin_dir"] = File.join(dir, "bin")
      calls = []
      installer = Ace::Lab::Molecules::GemsetProvisioner.new(
        privileged: -> { true }, runner: ->(argv) { calls << argv; {"status" => "ok"} })
      results = installer.call(runtime: runtime)
      assert_equal ["installed"], results.map { |item| item.fetch("status") }
      assert_equal 1, calls.length
      assert_equal ["bundle", "install"], calls.first.last(2)
      assert File.file?(File.join(dir, "runtime/bundle/Gemfile"))
    end
  end
  def test_runtime_probe_checks_the_locked_bundle_not_unselected_installed_versions
    Dir.mktmpdir("fixture-lock-") do |dir|
      File.write(File.join(dir, "fixture.gemspec"), <<~SPEC)
        Gem::Specification.new do |s|
          s.name = "fixture-gem"
          s.version = "1.0.0"
          s.summary = "fixture"
          s.authors = ["test"]
          s.files = []
          s.add_dependency "fileutils", "= #{Gem::Specification.load(Dir.glob(File.join(Gem.default_specifications_dir, "fileutils-*.gemspec")).first).version}"
        end
      SPEC
      gemfile = File.join(dir, "Gemfile")
      File.write(gemfile, "gem 'fixture-gem', path: #{dir.dump}\n")
      manifest = File.join(dir, "manifest.json")
      File.write(manifest, JSON.generate("gems" => [{"name" => "fixture-gem", "version" => "1.0.0"}]))
      script = File.read(File.expand_path("../../lab-vm/provision-runtime.sh", __dir__))
      probe = script.split("<<'RUBY'", 2).last.split("\nRUBY", 2).first
      extra_home = File.join(dir, "extra-gems")
      FileUtils.mkdir_p(File.join(extra_home, "specifications"))
      FileUtils.mkdir_p(File.join(extra_home, "gems/fixture-gem-0.9.0"))
      File.write(File.join(extra_home, "specifications/fixture-gem-0.9.0.gemspec"),
        "Gem::Specification.new { |s| s.name='fixture-gem'; s.version='0.9.0'; s.summary='old'; s.authors=['test'] }\n")
      env = {"GEM_PATH" => ([extra_home] + Gem.path).join(File::PATH_SEPARATOR), "BUNDLE_GEMFILE" => gemfile, "RUBYOPT" => nil, "BUNDLE_BIN_PATH" => nil, "RUBYLIB" => nil, "BUNDLER_SETUP" => nil}
      visible, _, visible_status = Open3.capture3(env.merge("BUNDLE_GEMFILE" => nil, "RUBYLIB" => nil, "BUNDLER_SETUP" => nil), Gem.ruby, "-e", "puts Gem::Specification.find_all_by_name('fixture-gem').map(&:version)", chdir: dir)
      assert visible_status.success?
      assert_includes visible, "0.9.0"
      output, error, status = Open3.capture3(env, Gem.ruby, "-rbundler", "-e", "Bundler.definition.resolve; Bundler.definition.lock", chdir: dir)
      assert status.success?, error
      output, error, status = Open3.capture3(env, Gem.ruby, "-rjson", "-rbundler/setup", "-", manifest, stdin_data: probe, chdir: dir)
      assert status.success?, error
      assert_includes output, "verified exact locked gemset: 1 entries"
      File.write(manifest, JSON.generate("gems" => [{"name" => "fixture-gem", "version" => "2.0.0"}]))
      _, error, status = Open3.capture3(env, Gem.ruby, "-rjson", "-rbundler/setup", "-", manifest, stdin_data: probe, chdir: dir)
      refute status.success?
      assert_includes error, "differs from the pinned manifest"
    end
  end

end
