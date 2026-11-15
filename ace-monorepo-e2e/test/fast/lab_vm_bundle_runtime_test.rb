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
end
