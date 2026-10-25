# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  # gad.2 gap #1 (owner spec 8xg.t.sbz.7): the gem-set provisioner
  # converges the manifest's declared gem set into the declared target
  # runtime (GEM_HOME) — exact version present = no-op, missing =
  # installed, different version present = updated. Command paths run
  # through the injectable argv runner (fakes here); the real `gem`
  # executable is exercised offline for the read-only probe paths via a
  # locally built gem (network installs are provisioning, not tests).
  class GemsetProvisionerTest < Minitest::Test
    # Records every argv and replays canned results in call order.
    class FakeRunner
      attr_reader :calls

      def initialize(results = [])
        @results = results
        @calls = []
      end

      def call(argv)
        @calls << argv
        @results.shift || {"status" => "ok", "out" => "", "err" => ""}
      end
    end

    def runtime(dir, gems = [{"name" => "ace-lab", "version" => "0.13.0"}])
      {"gem_home" => File.join(dir, "gems"), "gems" => gems}
    end

    # An ALREADY-CONVERGED runtime on disk: the scenarios below judge
    # gem items against a runtime that exists, so the directory must
    # exist before the provisioner runs.
    def converged_runtime(dir, gems = [{"name" => "ace-lab", "version" => "0.13.0"}])
      section = runtime(dir, gems)
      FileUtils.mkdir_p(section["gem_home"])
      section
    end

    # The exact env-pinned argv prefix every gem subprocess must run
    # under: bundler context stripped, GEM_HOME/GEM_PATH pinned.
    def runtime_env(gem_home)
      strip = %w[RUBYOPT RUBYLIB BUNDLER_SETUP BUNDLE_BIN_PATH BUNDLE_GEMFILE BUNDLER_VERSION BUNDLE_BUNDLER_VERSION]
      ["env", *strip.flat_map { |key| ["-u", key] }, "GEM_HOME=#{gem_home}", "GEM_PATH=#{gem_home}"]
    end

    def listing(name, versions)
      {"status" => "ok", "out" => versions.empty? ? "" : "#{name} (#{versions.join(", ")})\n", "err" => ""}
    end

    # --- no-op and convergence paths (fake runner) ---------------------

    def test_no_declared_gems_is_a_no_op_that_never_touches_the_runner
      runner = FakeRunner.new
      report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
        .call(runtime: {"gem_home" => "/tmp/unused", "gems" => []})

      assert_empty report
      assert_empty runner.calls
    end

    def test_exact_version_present_is_a_no_op
      runner = FakeRunner.new([listing("ace-lab", %w[0.13.0])])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "exists", gem["status"]
        assert_nil gem["message"]
        assert_equal File.join(dir, "gems"), gem["gem_home"]
        # the probe ran inside the pinned runtime; nothing was installed
        assert_equal [runtime_env(File.join(dir, "gems")) +
          ["gem", "list", "ace-lab", "--exact", "--local"]], runner.calls
      end
    end

    def test_missing_gem_is_installed_into_the_pinned_runtime
      runner = FakeRunner.new([listing("ace-lab", []), {"status" => "ok", "out" => "", "err" => ""}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "installed", report.first["status"]
        assert_equal runtime_env(File.join(dir, "gems")) +
          ["gem", "install", "ace-lab", "--version", "0.13.0", "--no-document"],
          runner.calls.last
      end
    end

    def test_different_version_present_installs_the_declared_version
      runner = FakeRunner.new([listing("ace-lab", %w[0.12.0]),
        {"status" => "ok", "out" => "", "err" => ""}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "updated", report.first["status"]
        assert_equal 2, runner.calls.size
      end
    end

    def test_install_failure_is_classified_with_the_first_stderr_line
      runner = FakeRunner.new([listing("ace-lab", []),
        {"status" => 2, "out" => "", "err" => "ERROR:  Could not find a valid gem\nline two\n"}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "failed", gem["status"]
        assert_match(/gem install failed \(exit 2\): ERROR:  Could not find a valid gem/,
          gem["message"])
        refute_match(/line two/, gem["message"])
        assert_match(/rerun ace-lab prepare/, gem["message"])
      end
    end

    def test_probe_command_failure_fails_the_item_without_installing
      runner = FakeRunner.new([{"status" => 1, "out" => "", "err" => "ERROR: bad probe"}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "failed", report.first["status"]
        assert_match(/gem list failed \(exit 1\): ERROR: bad probe/, report.first["message"])
        assert_equal 1, runner.calls.size
      end
    end

    def test_missing_gem_executable_fails_the_item_wet_and_dry
      [false, true].each do |dry_run|
        runner = FakeRunner.new([{"status" => "enoent", "out" => "", "err" => ""}])
        Dir.mktmpdir do |dir|
          report = Ace::Lab::Molecules::GemsetProvisioner.new(
            runner: runner, dry_run: dry_run
          ).call(runtime: converged_runtime(dir))

          assert_equal "failed", report.first["status"],
            "wet=#{!dry_run}: prepare is fail-closed when the runtime cannot be probed"
          assert_match(/gem not found in PATH/, report.first["message"])
        end
      end
    end

    def test_unparseable_probe_output_fails_closed
      runner = FakeRunner.new([{"status" => "ok", "out" => "ace-lab ???garbage\n", "err" => ""}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "failed", report.first["status"]
        assert_match(/could not determine installed versions/, report.first["message"])
      end
    end

    # --- runtime preparation -------------------------------------------

    def test_missing_runtime_requires_privileges_when_not_privileged
      runner = FakeRunner.new
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { false }
        ).call(runtime: runtime(dir))

        gem = report.first
        assert_equal "failed", gem["status"]
        assert_match(/creating gem runtime '#{File.join(dir, "gems")}' requires administrator privileges/,
          gem["message"])
        assert_match(/with sudo/, gem["message"])
        # nothing probed, nothing created
        assert_empty runner.calls
        refute File.exist?(File.join(dir, "gems"))
      end
    end

    def test_missing_runtime_is_created_when_privileged
      runner = FakeRunner.new([listing("ace-lab", %w[0.13.0])])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { true }
        ).call(runtime: runtime(dir))

        assert_equal "exists", report.first["status"], report.inspect
        assert File.directory?(File.join(dir, "gems"))
      end
    end

    def test_runtime_creation_permission_failure_is_classified
      runner = FakeRunner.new
      Dir.mktmpdir do |dir|
        FileUtils.stub :mkdir_p, ->(*) { raise Errno::EACCES } do
          report = Ace::Lab::Molecules::GemsetProvisioner.new(
            runner: runner, privileged: -> { true }
          ).call(runtime: runtime(dir))

          assert_equal "failed", report.first["status"]
          assert_match(/insufficient permissions while preparing gem runtime/, report.first["message"])
        end
      end
    end

    def test_symlinked_runtime_is_refused_wet_and_dry
      [false, true].each do |dry_run|
        Dir.mktmpdir do |dir|
          target = File.join(dir, "elsewhere")
          FileUtils.mkdir_p(target)
          File.symlink(target, File.join(dir, "gems"))
          runner = FakeRunner.new
          report = Ace::Lab::Molecules::GemsetProvisioner.new(
            runner: runner, dry_run: dry_run
          ).call(runtime: runtime(dir))

          assert_equal "failed", report.first["status"]
          assert_match(/is a symbolic link; refusing/, report.first["message"])
          assert_empty runner.calls
        end
      end
    end

    def test_non_directory_runtime_is_refused
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "gems"), "occupied")
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: FakeRunner.new)
          .call(runtime: runtime(dir))

        assert_equal "failed", report.first["status"]
        assert_match(/exists but is not a directory; refusing/, report.first["message"])
      end
    end

    def test_runtime_failure_fails_every_declared_gem_as_a_dependency
      runner = FakeRunner.new
      Dir.mktmpdir do |dir|
        gems = [{"name" => "ace-lab", "version" => "0.13.0"},
          {"name" => "ace-review", "version" => "0.54.0"}]
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { false }
        ).call(runtime: runtime(dir, gems))

        assert_equal %w[failed failed], report.map { |item| item["status"] }
        assert_match(/requires administrator privileges/, report.first["message"])
      end
    end

    # --- dry-run prediction ---------------------------------------------

    def test_dry_run_predicts_would_install_and_would_update_without_mutation
      runner = FakeRunner.new([listing("ace-lab", %w[0.12.0]),
        listing("ace-review", []),
        listing("ace-hermes", %w[0.13.0])])
      gems = [{"name" => "ace-lab", "version" => "0.13.0"},
        {"name" => "ace-review", "version" => "0.54.0"},
        {"name" => "ace-hermes", "version" => "0.13.0"}]
      Dir.mktmpdir do |dir|
        runtime_dir = File.join(dir, "gems")
        FileUtils.mkdir_p(runtime_dir)
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { true }, dry_run: true
        ).call(runtime: {"gem_home" => runtime_dir, "gems" => gems})

        assert_equal %w[would_update would_install exists], report.map { |item| item["status"] }
        # prediction parity: the probe ran, the install never did
        assert_equal 3, runner.calls.size
        assert runner.calls.all? { |argv| argv.include?("list") }
      end
    end

    def test_dry_run_with_missing_runtime_and_privileges_creates_nothing_but_predicts_install
      runner = FakeRunner.new([listing("ace-lab", [])])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { true }, dry_run: true
        ).call(runtime: runtime(dir))

        assert_equal "would_install", report.first["status"]
        refute File.exist?(File.join(dir, "gems"))
      end
    end

    # --- offline real-gem integration (probe + no-op parity) ------------

    # build_and_install_gem (shared helper) builds a real gem and
    # installs it --local into a real GEM_HOME, so the probe parses REAL
    # rubygems output (no network).

    def test_real_runtime_reports_exists_for_the_installed_version
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-probe", "0.13.0")
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new

        kind, versions = provisioner.runtime_versions(name: "ace-lab-probe", gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal %w[0.13.0], versions

        runtime = {"gem_home" => gem_home, "gems" => [{"name" => "ace-lab-probe", "version" => "0.13.0"}]}
        report = provisioner.call(runtime: runtime)
        assert_equal "exists", report.first["status"]
      end
    end

    def test_real_runtime_dry_run_predicts_update_for_a_different_declared_version
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-probe", "0.12.0")
        runtime = {"gem_home" => gem_home, "gems" => [{"name" => "ace-lab-probe", "version" => "0.13.0"}]}
        report = Ace::Lab::Molecules::GemsetProvisioner.new(dry_run: true).call(runtime: runtime)

        assert_equal "would_update", report.first["status"]
        # nothing was installed: still only the 0.12.0 spec
        _kind, versions = Ace::Lab::Molecules::GemsetProvisioner.new
          .runtime_versions(name: "ace-lab-probe", gem_home: gem_home)
        assert_equal %w[0.12.0], versions
      end
    end

    def test_real_runtime_reports_absent_gem_probe_as_empty
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-probe", "0.13.0")
        kind, versions = Ace::Lab::Molecules::GemsetProvisioner.new
          .runtime_versions(name: "not-declared-anywhere", gem_home: gem_home)

        assert_equal :ok, kind
        assert_empty versions
      end
    end
  end
end
