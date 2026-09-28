# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "open3"
require "rubygems/installer"
require "rubygems/package"
require "tmpdir"
require "timeout"

# Installed-consumer probe (task 8wj.t.ocz): builds the current gem artifacts,
# installs them into an isolated consumer environment (fresh GEM_HOME, unrelated
# cwd, sanitized HOME), and proves wfi://overseer resolves from packaged content
# only. A registration-removal fixture proves the probe detects masking.
class InstalledWorkflowResolutionTest < AceOverseerTestCase
  PROBE_TIMEOUT_SECONDS = 120

  # ace-overseer is installed with --ignore-dependencies (see
  # InstalledConsumerEnvironment::SUPPORT_CLOSURE for the split).

  def test_clean_consumer_resolves_overseer_workflow_from_installed_package
    consumer = build_consumer

    nav_out, nav_err, nav_status = probe(consumer, "ace-nav", "resolve", "wfi://overseer")
    assert_predicate nav_status, :success?, <<~MESSAGE
      ace-nav resolve wfi://overseer must succeed for an installed consumer.
      stdout: #{nav_out}
      stderr: #{nav_err}
    MESSAGE
    resolved_path = nav_out.strip
    assert_equal "overseer.wf.md", File.basename(resolved_path),
      "resolved workflow must be the packaged overseer.wf.md"
    assert consumer.installed_ace_overseer_path?(resolved_path),
      "resolved path must come from the installed ace-overseer gem, not the source checkout: #{resolved_path}"

    bundle_out, bundle_err, bundle_status = probe(consumer, "ace-bundle", "wfi://overseer")
    assert_predicate bundle_status, :success?, <<~MESSAGE
      ace-bundle wfi://overseer must succeed for an installed consumer.
      stdout: #{bundle_out}
      stderr: #{bundle_err}
    MESSAGE
    payload = extract_bundle_payload(bundle_out)
    assert_includes payload, "handbook/workflow-instructions/overseer.wf.md",
      "bundle payload must identify the packaged workflow file"
    assert consumer.installed_ace_overseer_path?(payload_path_from_bundle(payload)),
      "bundle payload must be served from the installed gem, not the source checkout"
    assert_includes payload, "prune_safety_non_negotiable_executed_check",
      "installed workflow must carry the prune-safety lifecycle contract"
    assert_includes payload, "status_truth_non_negotiable_executed_check",
      "installed workflow must carry the status-truth lifecycle contract"
  end

  def test_consumer_without_package_registration_fails_both_probes_despite_retained_workflow
    consumer = build_consumer
    consumer.remove_ace_overseer_registration!

    nav_out, nav_err, nav_status = probe(consumer, "ace-nav", "resolve", "wfi://overseer")
    refute_predicate nav_status, :success?,
      "removing the packaged wfi registration must break resolution (workflow file alone is not enough)"
    assert_match(/Resource not found/, "#{nav_out}#{nav_err}")

    bundle_out, bundle_err, bundle_status = probe(consumer, "ace-bundle", "wfi://overseer")
    refute_predicate bundle_status, :success?,
      "removing the packaged wfi registration must break bundling even though the workflow file remains"
    assert_match(/Failed to resolve protocol|Resource not found/, "#{bundle_out}#{bundle_err}")
  end

  private

  def build_consumer
    InstalledConsumerEnvironment.build
  end

  def probe(consumer, executable, *arguments)
    bin_path = File.join(consumer.gem_home, "bin", executable)
    Timeout.timeout(PROBE_TIMEOUT_SECONDS) do
      # unsetenv_others keeps the consumer airtight: inherited parent variables
      # (RUBYOPT, BUNDLE_GEMFILE, ...) would pull bundler/host gems into the
      # probe and mask packaging gaps.
      Open3.capture3(consumer.command_env, bin_path, *arguments,
        chdir: consumer.probe_cwd, unsetenv_others: true)
    end
  end

  # ace-bundle auto-routes output: short bundles print to stdout, long ones are
  # written to a cache file with a "Bundle saved ... output file:" pointer.
  def extract_bundle_payload(output)
    if output.include?("Bundle saved") && output.include?("output file:")
      File.read(output.lines.last.strip)
    else
      output
    end
  end

  def payload_path_from_bundle(payload)
    file_line = payload.lines.find { |line| line.start_with?("FILE|") }
    file_line ? file_line.sub("FILE|", "").strip : ""
  end
end

# Builds and installs the probe closure into a disposable consumer environment.
# One instance per test keeps mutation (registration removal) order-independent.
class InstalledConsumerEnvironment
  # Gems the probe executables (ace-nav, ace-bundle) need fully installed with
  # dependency checking. ace-overseer is installed separately with
  # --ignore-dependencies: the probe only reads its packaged payload (workflow +
  # nav registration) and never activates its deeper runtime closure
  # (ace-assign, ace-task, ace-llm, ...), which would pull external gems and
  # break hermeticity.
  SUPPORT_CLOSURE = %w[
    ace-support-config
    ace-support-fs
    ace-support-cli
    ace-support-core
    ace-git
    ace-git-github
    ace-compressor
    ace-support-nav
    ace-bundle
  ].freeze

  GEM_NAME = "ace-overseer"

  @instances = []
  @mutex = Mutex.new

  class << self
    def build
      environment = new
      environment.build
      register(environment)
      environment
    end

    def register(instance)
      @mutex.synchronize { @instances << instance }
    end

    def cleanup_all
      @mutex.synchronize do
        @instances.each(&:teardown)
        @instances.clear
      end
    end
  end

  attr_reader :gem_home, :probe_cwd

  def build
    # Canonicalize so probe output paths and locally derived paths compare
    # equal (macOS reports /var/... as /private/var/...).
    @root = File.realpath(Dir.mktmpdir("ace-overseer-installed-consumer"))
    @gem_home = File.join(@root, "gems")
    @home = File.join(@root, "home")
    @probe_cwd = File.join(@root, "cwd")
    FileUtils.mkdir_p([@gem_home, @home, @probe_cwd])
    install_closure
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def installed_ace_overseer_path?(path)
    normalized = File.expand_path(path)
    normalized.start_with?("#{ace_overseer_gem_dir}#{File::SEPARATOR}")
  end

  def ace_overseer_gem_dir
    spec_dir = Dir.glob(File.join(gem_home, "specifications", "#{GEM_NAME}-*.gemspec")).first
    raise "installed ace-overseer gemspec not found in #{gem_home}" unless spec_dir

    spec = Gem::Specification.load(spec_dir)
    spec.gem_dir
  end

  def remove_ace_overseer_registration!
    registration = File.join(
      ace_overseer_gem_dir, ".ace-defaults", "nav", "protocols", "wfi-sources", "#{GEM_NAME}.yml"
    )
    raise "packaged registration missing: #{registration}" unless File.file?(registration)

    FileUtils.rm(registration)
  end

  def command_env
    {
      "HOME" => @home,
      "GEM_HOME" => gem_home,
      "GEM_PATH" => gem_home,
      "GEM_SPEC_CACHE" => File.join(@root, "gem-spec-cache"),
      "TMPDIR" => File.join(@root, "tmp"),
      "PATH" => "#{File.join(gem_home, 'bin')}:#{File.dirname(RbConfig.ruby)}:/usr/bin:/bin"
    }
  end

  private

  def install_closure
    SUPPORT_CLOSURE.each { |gem_name| install_artifact(build_gem_artifact(gem_name)) }
    install_artifact(build_gem_artifact(GEM_NAME), ignore_dependencies: true)

    bin = File.join(gem_home, "bin", "ace-nav")
    raise "ace-nav binstub missing after install" unless File.file?(bin)
  end

  # Installs via the RubyGems API instead of the `gem` CLI: the CLI loads the
  # host's rubygems plugins (the mise reshim hook shells out to `mise`, absent
  # from the sanitized environment).
  def install_artifact(artifact_path, ignore_dependencies: false)
    Gem::Installer.at(
      artifact_path,
      install_dir: gem_home,
      document: [],
      ignore_dependencies: ignore_dependencies
    ).install
  end

  def build_gem_artifact(gem_name)
    package_root = File.expand_path("../../../..", __dir__)
    gem_root = File.join(package_root, gem_name)
    spec = Dir.chdir(gem_root) { Gem::Specification.load("#{gem_name}.gemspec") }
    raise "could not load gemspec for #{gem_name}" unless spec

    artifact = Dir.chdir(gem_root) { Gem::Package.build(spec, true) }
    staging = File.join(@root, "artifacts")
    FileUtils.mkdir_p(staging)
    staged_path = File.join(staging, artifact)
    FileUtils.mv(File.join(gem_root, artifact), staged_path)
    staged_path
  end
end

Minitest.after_run { InstalledConsumerEnvironment.cleanup_all }
