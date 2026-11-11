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
      {"gem_home" => File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")), "gems" => gems}
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








    # --- default gems: REAL `gem list` format (PR #398 F1) ---------------

    # Real RubyGems output marks a default gem's bundled version as
    # `default: V` inside the version list (`abbrev (default: 0.1.2)`,
    # `json (2.9.4, default: 2.9.1)`): the marked V is the default
    # gem's own version, other parts are additionally installed
    # versions — the normalized list must carry plain versions, never
    # the literal `default: 2.9.1` string (which crashes
    # Gem::Version.new in newer-version and closure checks).
    def raw_listing(name, version_parts)
      {"status" => "ok", "out" => "#{name} (#{version_parts.join(", ")})\n", "err" => ""}
    end

    def test_default_gem_marker_normalizes_to_the_default_version
      runner = FakeRunner.new([raw_listing("abbrev", ["default: 0.1.2"])])
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        kind, versions = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .runtime_versions(name: "abbrev", gem_home: gem_home)

        assert_equal :ok, kind
        assert_equal %w[0.1.2], versions
        assert_equal Gem::Version.new("0.1.2"), Gem::Version.new(versions.first)
      end
    end

    # 8xtiatf5: a candidate that Gem::Version itself rejects (e.g. a
    # platform-suffixed string) fails the probe CLOSED — it must never
    # reach a later Gem::Version.new caller as a "version".
    def test_platform_suffixed_version_fails_the_probe_closed
      runner = FakeRunner.new([raw_listing("some-gem", ["1.0-x86_64-linux"])])
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        kind, outcome = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .runtime_versions(name: "some-gem", gem_home: gem_home)

        assert_equal :failed, kind
        assert_match(/could not determine installed versions/, outcome)
      end
    end

    def test_mixed_default_and_installed_versions_list_both_plain_versions
      runner = FakeRunner.new([raw_listing("json", ["2.9.4", "default: 2.9.1"])] * 2)
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)

        kind, versions = provisioner.runtime_versions(name: "json", gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal %w[2.9.4 2.9.1], versions
        versions.each { |version| Gem::Version.new(version) }

        # the newer-version check consumes the normalized list
        kind, newer = provisioner.newer_versions(name: "json", declared_version: "2.9.1",
          gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal %w[2.9.4], newer

        # the dependency closure judge consumes it too
        dep = {"name" => "json", "requirement" => "~> 2.9"}
        assert_equal %w[2.9.4 2.9.1],
          provisioner.send(:satisfying_versions, dep, versions)
      end
    end

    def test_installed_prerelease_satisfying_a_dependency_is_usable
      provisioner = Ace::Lab::Molecules::GemsetProvisioner.new
      dependency = {"name" => "ace-herdr", "requirement" => "~> 0.9"}
      versions = %w[0.8.9 0.9.0.pre.utm1 0.9.1.pre.utm1 1.0.0.pre.utm1 1.1.0.pre.utm1 1.0.0]
      assert_equal ["0.9.1.pre.utm1"], provisioner.send(:satisfying_versions, dependency, versions)
    end


    # Offline real-gem probe of an actual DEFAULT gem shipping with the
    # running Ruby (json is one): the normalized versions must all be
    # plain, parseable version strings — exactly the convergence the
    # reviewer reproduced with a real isolated GEM_HOME.
    def test_real_runtime_probe_of_a_default_gem_yields_parseable_versions
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new

        kind, versions = provisioner.runtime_versions(name: "json", gem_home: gem_home)
        assert_equal :ok, kind
        refute_includes versions.to_s, "default:",
          "the default-gem marker must never leak into the version list"
        versions.each do |version|
          assert_equal Gem::Version.new(version).to_s, version,
            "real 'gem list' output for default gem json must normalize to plain versions"
        end

        kind, = provisioner.newer_versions(name: "json", declared_version: "0.0.1", gem_home: gem_home)
        assert_equal :ok, kind, "version comparisons over real default-gem output must not crash"
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
        assert_match(/creating gem runtime '#{File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))}' requires administrator privileges/,
          gem["message"])
        assert_match(/with sudo/, gem["message"])
        # nothing probed, nothing created
        assert_empty runner.calls
        refute File.exist?(File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")))
      end
    end

    def test_missing_runtime_is_created_when_privileged
      runner = FakeRunner.new([listing("ace-lab", %w[0.13.0])])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(
          runner: runner, privileged: -> { true }
        ).call(runtime: runtime(dir))

        assert_equal "installed", report.first["status"], report.inspect
        assert File.directory?(File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")))
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
          FileUtils.mkdir_p(File.join(dir, "gems", RUBY_ENGINE))
          File.symlink(target, File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")))
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
        FileUtils.mkdir_p(File.join(dir, "gems", RUBY_ENGINE))
        File.write(File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")), "occupied")
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



    # --- offline real-gem integration (probe + no-op parity) ------------

    # build_and_install_gem (shared helper) builds a real gem and
    # installs it --local into a real GEM_HOME, so the probe parses REAL
    # rubygems output (no network).





    def test_real_runtime_reports_absent_gem_probe_as_empty
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-probe", "0.13.0")
        kind, versions = Ace::Lab::Molecules::GemsetProvisioner.new
          .runtime_versions(name: "not-declared-anywhere", gem_home: gem_home)

        assert_equal :ok, kind
        assert_empty versions
      end
    end

    # --- post-presence convergence (8xs.t.pu0.0) -----------------------

    def dependency_listing(name, version, deps)
      body = deps.map { |dep, requirement| "  #{dep} (#{requirement}, runtime)\n" }.join
      {"status" => "ok", "out" => "#{name} (#{version})\n#{body}", "err" => ""}
    end








    def test_read_only_probes_report_closure_gaps_and_newer_versions
      runner = FakeRunner.new([
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", []),                                # json missing
        listing("ace-lab", %w[0.14.0 0.13.0])               # newer probe
      ])
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)

        kind, reasons = provisioner.closure_failures(name: "ace-lab", version: "0.13.0", gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal 1, reasons.size
        assert_match(/dependency 'json \(~> 2\.7\)'.*not satisfied/, reasons.first)

        kind, newer = provisioner.newer_versions(name: "ace-lab", declared_version: "0.13.0", gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal %w[0.14.0], newer
      end
    end

    # 8xth38c4: closure_failures returns the SAME status-tuple shape
    # newer_versions returns — probe failures surface as
    # [:unknown/:failed, message], never a bare message list.
    def test_closure_failures_reports_probe_failures_as_status_tuples
      runner = FakeRunner.new([
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        {"status" => "enoent", "out" => "", "err" => ""} # json probe: no gem executable
      ])
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
        FileUtils.mkdir_p(gem_home)
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)

        kind, message = provisioner.closure_failures(name: "ace-lab", version: "0.13.0", gem_home: gem_home)
        assert_equal :unknown, kind
        assert_match(/gem not found in PATH/, message)
      end
    end
    def test_one_bundle_install_for_the_entire_runtime_without_dependency_probes
      Dir.mktmpdir do |dir|
        runner = FakeRunner.new
        section = converged_runtime(dir, [
          {"name" => "ace-lab", "version" => "0.15.1"},
          {"name" => "ace-overseer", "version" => "0.29.0"}])
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner).call(runtime: section)
        assert_equal %w[installed installed], report.map { |r| r["status"] }
        assert_equal 1, runner.calls.size
        assert_equal ["bundle", "install"], runner.calls.first.last(2)

        gemfile = File.read(File.join(dir, "gems", "Gemfile"))
        assert_includes gemfile, 'gem "ace-lab", "0.15.1"'
        assert_includes gemfile, 'gem "ace-overseer", "0.29.0"'
      end
    end

    def test_bundle_failure_is_reported_without_retry_or_diagnostics
      Dir.mktmpdir do |dir|
        runner = FakeRunner.new([{"status" => 17, "err" => "resolution failed", "out" => ""}])
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner).call(runtime: converged_runtime(dir))
        assert_equal "failed", report.first["status"]
        assert_includes report.first["message"], "exit 17"
        assert_equal 1, runner.calls.size
      end
    end

    def test_dry_run_does_not_resolve_or_write_a_bundle
      Dir.mktmpdir do |dir|
        runner = FakeRunner.new
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner, dry_run: true,
          privileged: -> { true }).call(runtime: runtime(dir))
        assert_equal "would_install", report.first["status"]
        assert_empty runner.calls
        refute File.exist?(File.join(dir, "gems", RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version")))
      end
    end
    def test_real_bundle_binstub_runs_without_shell_setup_and_reuses_lock
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-runtime-probe", "1.0.0", files: {
          "exe/ace-lab-runtime-probe" => "#!/usr/bin/env ruby\nputs Gem.loaded_specs.fetch('ace-lab-runtime-probe').version\n"
        })
        section = {"gem_home" => gem_home, "bin_dir" => File.join(dir, "commands"), "gems" => [{"name" => "ace-lab-runtime-probe", "version" => "1.0.0"}]}
        with_local_gem_source(gem_home) do
          provisioner = Ace::Lab::Molecules::GemsetProvisioner.new
          report = provisioner.call(runtime: section)
          assert_equal "installed", report.first["status"], report.inspect
          root = File.dirname(File.dirname(gem_home))
          lock = File.binread(File.join(root, "Gemfile.lock"))
          clean = ENV.keys.grep(/\A(?:BUNDLE|GEM_|RUBY)/).to_h { |key| [key, nil] }
          clean["PATH"] = "#{section.fetch('bin_dir')}:/usr/bin:/bin"
          out, err, status = Open3.capture3(clean, "ace-lab-runtime-probe", chdir: dir)
          assert status.success?, err
          assert_equal "1.0.0\n", out
          assert_equal "installed", provisioner.call(runtime: section).first["status"]
          assert_equal lock, File.binread(File.join(root, "Gemfile.lock"))
          assert_equal [:ok, nil], provisioner.bundle_status(name: "ace-lab-runtime-probe", version: "1.0.0", gem_home: gem_home)
          failed = provisioner.call(runtime: section.merge("gems" => [{"name" => "ace-lab-runtime-probe", "version" => "99.0.0"}]))
          assert_equal "failed", failed.first["status"]
          assert_equal lock, File.binread(File.join(root, "Gemfile.lock"))
          out, err, status = Open3.capture3(clean, "ace-lab-runtime-probe", chdir: dir)
          assert status.success?, err
          assert_equal "1.0.0\n", out
        end
      end
    end
  end
end
