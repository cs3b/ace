# frozen_string_literal: true

require "open3"
require_relative "../test_helper"

# Installed-extension acceptance: projects the package through the real
# ProviderSyncer into a throwaway project and runs the JavaScript acceptance
# suite against the projected .pi/extensions/ace-wake.mjs inside the real Pi
# SDK runtime (no external timer or service).
class Ace::Handbook::Integration::PiSdkAcceptanceTest < Minitest::Test
  def test_projected_extension_wakes_agents_through_real_pi_runtime
    skip "node is not installed" unless node_bin
    pi_root = pi_package_root
    skip "pi-coding-agent package not found (install the pi CLI)" unless pi_root

    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "project")
      FileUtils.mkdir_p(project_root)
      FileUtils.cp_r(package_root, File.join(project_root, "ace-handbook-integration-pi"))

      syncer = Ace::Handbook::Organisms::ProviderSyncer.new(
        project_root: project_root,
        prompt_inventory: Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: project_root, gem_roots: []),
        config: {}
      )
      result = syncer.sync(provider: "pi").first
      assert_equal 7, result.fetch(:projected_extensions)

      projected_entry = File.join(project_root, ".pi", "extensions", "ace-wake.mjs")
      assert File.file?(projected_entry), "sync must project the extension entrypoint"

      stdout, stderr, status = Open3.capture3(
        { "PI_PKG_ROOT" => pi_root, "EXT_PATH" => projected_entry },
        node_bin, "--test", File.join(package_root, "test", "js", "acceptance", "pi-sdk-acceptance.test.mjs")
      )
      assert status.success?, "installed-extension acceptance failed:\n#{stdout}\n#{stderr}"
      assert_match(/^ℹ fail 0$/m, stdout)
    end
  end

  private

  def package_root
    File.expand_path("../..", __dir__)
  end

  def node_bin
    candidate = ENV.fetch("NODE_BIN", "node")
    system("command", "-v", candidate, out: File::NULL) ? candidate : nil
  end

  def pi_package_root
    candidates = []
    npm_root = IO.popen(["npm", "root", "-g"], &:read).to_s.strip
    candidates << File.join(npm_root, "@earendil-works", "pi-coding-agent") unless npm_root.empty?

    which_pi = IO.popen(["which", "pi"], &:read).to_s.strip
    if !which_pi.empty? && File.symlink?(which_pi)
      resolved = (File.realpath(which_pi) rescue which_pi)
      if resolved.include?("pi-coding-agent")
        candidates << File.expand_path("../..", File.dirname(resolved))
      end
    end

    candidates.find { |dir| File.file?(File.join(dir, "package.json")) }
  end
end
