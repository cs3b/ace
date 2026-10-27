# frozen_string_literal: true

require "open3"
require_relative "../test_helper"

# Installed-extension acceptance: the ace-wake extension lives at the
# repository-top-level ace-wake/ and is deployed from there by the host lane
# (the pi integration package no longer ships or projects extension assets).
# This target proves the deployable artifact — ace-wake/index.js, not the
# test source tree — wakes agents through the real Pi SDK runtime by running
# the JavaScript acceptance suite against it (no external timer or service).
class Ace::Handbook::Integration::PiSdkAcceptanceTest < Minitest::Test
  def test_extension_artifact_wakes_agents_through_real_pi_runtime
    skip "node is not installed" unless node_bin
    pi_root = pi_package_root
    skip "pi-coding-agent package not found (install the pi CLI)" unless pi_root
    skip "ace-wake source not found next to this package" unless File.file?(extension_entry)

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
      # The package carries no extension assets anymore: pi sync must not
      # project any extension into the throwaway project.
      refute result.key?(:relative_extensions_dir),
        "pi sync must not project extension assets (ace-wake/ is the single source)"
      refute File.exist?(File.join(project_root, ".pi", "extensions"))

      stdout, stderr, status = Open3.capture3(
        { "PI_PKG_ROOT" => pi_root, "EXT_PATH" => extension_entry },
        node_bin, "--test", acceptance_target
      )
      assert status.success?, "ace-wake acceptance failed:\n#{stdout}\n#{stderr}"
      assert_match(/^ℹ fail 0$/m, stdout)
    end
  end

  private

  def package_root
    File.expand_path("../..", __dir__)
  end

  def extension_entry
    File.expand_path("../../../ace-wake/index.js", __dir__)
  end

  def acceptance_target
    File.expand_path("../../../ace-wake/test/acceptance/pi-sdk-acceptance.test.mjs", __dir__)
  end

  def node_bin
    candidate = ENV.fetch("NODE_BIN", "node")
    paths = candidate.include?(File::SEPARATOR) ? [candidate] : ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, candidate) }
    paths.find { |path| File.file?(path) && File.executable?(path) }
  end

  def pi_package_root
    candidates = [ENV["PI_PKG_ROOT"]].compact
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
