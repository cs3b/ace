# frozen_string_literal: true

require "open3"
require "ace/wake"
require_relative "../test_helper"

# Installed-extension acceptance: the ace-wake extension ships from the
# ace-wake asset package (handbook/extensions/ace-wake) and projects into
# .pi/extensions through the pi manifest (extensions_dir +
# extensions_package). This target proves the deployable artifact — the
# published ace-wake extension entrypoint, not the test source tree —
# wakes agents through the real Pi SDK runtime by running the JavaScript
# acceptance suite against it (no external timer or service).
class Ace::Handbook::Integration::PiSdkAcceptanceTest < Minitest::Test
  def test_extension_artifact_wakes_agents_through_real_pi_runtime
    skip "node is not installed" unless node_bin
    pi_root = pi_package_root
    skip "pi-coding-agent package not found (install the pi CLI)" unless pi_root
    assert File.file?(extension_entry),
      "the published ace-wake entrypoint is missing at #{extension_entry}"

    Dir.mktmpdir do |tmpdir|
      project_root = File.join(tmpdir, "project")
      FileUtils.mkdir_p(project_root)
      FileUtils.cp_r(package_root, File.join(project_root, "ace-handbook-integration-pi"))
      # The manifest's extensions_package (ace-wake) must be present as a
      # sibling package — the standard monorepo layout the projection
      # resolves first.
      FileUtils.cp_r(ace_wake_package_root, File.join(project_root, "ace-wake"))

      syncer = Ace::Handbook::Organisms::ProviderSyncer.new(
        project_root: project_root,
        prompt_inventory: Ace::Handbook::Organisms::PromptTemplateInventory.new(project_root: project_root, gem_roots: []),
        config: {}
      )
      result = syncer.sync(provider: "pi").first
      # Current packaging truth: the pi manifest declares extensions_dir
      # .pi/extensions + extensions_package ace-wake, so pi sync projects
      # the published extension assets into the throwaway project.
      assert_equal ".pi/extensions", result.fetch(:relative_extensions_dir)
      assert File.file?(File.join(project_root, ".pi", "extensions", "ace-wake", "index.js")),
        "pi sync must project the ace-wake entrypoint into .pi/extensions"

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
    File.join(Ace::Wake.extension_root, "index.js")
  end

  def ace_wake_package_root
    # extension_root is <pkg>/handbook/extensions/ace-wake — three levels
    # up is the package root (two levels reach only <pkg>/handbook).
    File.expand_path("../../..", Ace::Wake.extension_root)
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
