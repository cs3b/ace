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
        # presence probe, newer-version probe, closure probe — all
        # read-only, nothing installed (8xs.t.pu0.0 post-presence)
        env = runtime_env(File.join(dir, "gems"))
        assert_equal [env + ["gem", "list", "ace-lab", "--exact", "--local"],
                      env + ["gem", "list", "ace-lab", "--exact", "--local"],
                      env + ["gem", "dependency", "ace-lab", "--version", "0.13.0"]],
                     runner.calls
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
          runner.calls[1]
        # post-presence probes: newer-version list + closure dependency
        assert_equal ["gem", "list", "ace-lab", "--exact", "--local"], runner.calls[2][17..]
        assert_equal ["gem", "dependency", "ace-lab", "--version", "0.13.0"], runner.calls[3][17..]
      end
    end

    def test_different_version_present_installs_the_declared_version
      runner = FakeRunner.new([listing("ace-lab", %w[0.12.0]),
        {"status" => "ok", "out" => "", "err" => ""}])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "updated", report.first["status"]
        # list, install, then post-presence list + dependency probes
        assert_equal 4, runner.calls.size
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
        gem_home = File.join(dir, "gems")
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
        gem_home = File.join(dir, "gems")
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
        gem_home = File.join(dir, "gems")
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

    def test_declared_version_present_only_as_the_default_gem_satisfies_existence
      runner = FakeRunner.new([
        raw_listing("abbrev", ["default: 0.1.2"]),   # presence probe
        raw_listing("abbrev", ["default: 0.1.2"]),   # newer probe
        dependency_listing("abbrev", "0.1.2", {})
      ])
      Dir.mktmpdir do |dir|
        runtime = converged_runtime(dir, [{"name" => "abbrev", "version" => "0.1.2"}])
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: runtime)

        assert_equal "exists", report.first["status"], report.inspect
        assert_empty report.first["removed_newer_versions"]
      end
    end

    # Offline real-gem probe of an actual DEFAULT gem shipping with the
    # running Ruby (json is one): the normalized versions must all be
    # plain, parseable version strings — exactly the convergence the
    # reviewer reproduced with a real isolated GEM_HOME.
    def test_real_runtime_probe_of_a_default_gem_yields_parseable_versions
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
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
        # prediction parity: the probes ran, the install never did; the
        # already-present gem additionally gets the post-presence
        # newer/closure probes (8xs.t.pu0.0)
        assert_equal 5, runner.calls.size
        assert runner.calls[0, 4].all? { |argv| argv.include?("list") }
        assert runner.calls[4].include?("dependency")
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
        gem_home = build_and_install_gem(dir, "ace-lab-probe", "0.13.0", files: {"lib/probe.rb" => "# public fixture\n"})
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new

        kind, versions = provisioner.runtime_versions(name: "ace-lab-probe", gem_home: gem_home)
        assert_equal :ok, kind
        assert_equal %w[0.13.0], versions

        runtime = {"gem_home" => gem_home, "gems" => [{"name" => "ace-lab-probe", "version" => "0.13.0"}]}
        installed_spec = Gem::Specification.load(File.join(gem_home, "specifications", "ace-lab-probe-0.13.0.gemspec"))
        assert_empty installed_spec.files, "fixture must exercise RubyGems stripped installed payload metadata"
        payload = File.join(gem_home, "gems", "ace-lab-probe-0.13.0", "lib", "probe.rb")
        File.chmod(0o640, payload)
        unknown = File.join(gem_home, "private-credential")
        File.write(unknown, "not package-owned")
        File.chmod(0o600, unknown)
        predicted = Ace::Lab::Molecules::GemsetProvisioner.new(dry_run: true).call(runtime: runtime)
        assert_equal "exists", predicted.first["status"], predicted.first["message"]
        assert_equal 0o640, File.stat(payload).mode & 0o777
        report = provisioner.call(runtime: runtime)
        assert_equal "exists", report.first["status"], report.first["message"]
        assert_equal 0o644, File.stat(payload).mode & 0o777
        assert_equal 0o600, File.stat(unknown).mode & 0o777
        assert_equal predicted.first["permissions"].map { |r| r["path"] }, report.first["permissions"].map { |r| r["path"] }
        assert_empty provisioner.call(runtime: runtime).first["permissions"]
      end
    end

    def test_missing_or_wrong_cached_archive_refuses_permission_changes
      Dir.mktmpdir do |dir|
        gem_home = build_and_install_gem(dir, "ace-lab-cache-probe", "1.0.0",
          files: {"lib/probe.rb" => "# public fixture\n"})
        cache = File.join(gem_home, "cache", "ace-lab-cache-probe-1.0.0.gem")
        payload = File.join(gem_home, "gems", "ace-lab-cache-probe-1.0.0", "lib", "probe.rb")
        File.chmod(0o640, payload)
        File.unlink(cache)
        [true, false].each do |dry_run|
          error = assert_raises(Ace::Lab::Molecules::GemPayloadPermissions::Error) do
            Ace::Lab::Molecules::GemPayloadPermissions.new(gem_home: gem_home, dry_run: dry_run, privileged: false)
              .call(name: "ace-lab-cache-probe", version: "1.0.0")
          end
          assert_match(/cache missing/, error.message)
          assert_equal 0o640, File.stat(payload).mode & 0o777
        end
        Dir.mktmpdir do |other|
          other_home = build_and_install_gem(other, "ace-lab-other-probe", "1.0.0")
          FileUtils.cp(File.join(other_home, "cache", "ace-lab-other-probe-1.0.0.gem"), cache)
          error = assert_raises(Ace::Lab::Molecules::GemPayloadPermissions::Error) do
            Ace::Lab::Molecules::GemPayloadPermissions.new(gem_home: gem_home, dry_run: false, privileged: false)
              .call(name: "ace-lab-cache-probe", version: "1.0.0")
          end
          assert_match(/identity mismatch/, error.message)
          assert_equal 0o640, File.stat(payload).mode & 0o777
        end
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

    # --- post-presence convergence (8xs.t.pu0.0) -----------------------

    def dependency_listing(name, version, deps)
      body = deps.map { |dep, requirement| "  #{dep} (#{requirement}, runtime)\n" }.join
      {"status" => "ok", "out" => "#{name} (#{version})\n#{body}", "err" => ""}
    end

    def test_real_dry_run_validates_installed_parent_while_predicting_missing_dependency
      Dir.mktmpdir do |dir|
        dependency = "ace-lab-absent-permission-probe"
        gem_home = build_and_install_gem(dir, "ace-lab-parent-probe", "1.0.0",
          dependencies: {dependency => "= 1.0.0"}, ignore_dependencies: true)
        spec = File.join(gem_home, "specifications", "ace-lab-parent-probe-1.0.0.gemspec")
        File.chmod(0o640, spec)
        runtime = {"gem_home" => gem_home, "gems" => [{"name" => "ace-lab-parent-probe", "version" => "1.0.0"}]}
        report = Ace::Lab::Molecules::GemsetProvisioner.new(dry_run: true).call(runtime: runtime).first
        assert_equal "exists", report["status"], report["message"]
        assert_equal [{"name" => dependency, "requirement" => "= 1.0.0", "status" => "would_install"}], report["closure"]
        assert report["permissions"].any? { |item| item["path"] == File.realpath(spec) && item["status"] == "would_normalize" }
        assert_equal 0o640, File.stat(spec).mode & 0o777
        refute File.exist?(File.join(gem_home, "specifications", "#{dependency}-1.0.0.gemspec"))
        assert_raises(Ace::Lab::Molecules::GemPayloadPermissions::Error) do
          Ace::Lab::Molecules::GemPayloadPermissions.new(gem_home: gem_home, dry_run: false, privileged: false)
            .call(name: "ace-lab-parent-probe", version: "1.0.0")
        end
      end
    end

    def test_missing_transitive_dependency_is_installed_even_when_gem_listed
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.13.0]),                     # presence probe
        listing("ace-lab", %w[0.13.0]),                     # newer probe
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", []),                                # dep probe: missing
        {"status" => "ok", "out" => "", "err" => ""},       # gem install json
        listing("json", %w[2.7.2]),                         # dep probe: satisfied
        dependency_listing("json", "2.7.2", {})             # dep's own closure
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "exists", gem["status"]
        assert_equal [{"name" => "json", "requirement" => "~> 2.7", "status" => "installed"}],
          gem["closure"]
        assert_equal ["gem", "install", "json", "--version", "~> 2.7", "--no-document"],
          runner.calls[4][17..]
      end
    end

    def test_unsatisfiable_dependency_is_a_classified_failure_never_readiness
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.13.0]),
        listing("ace-lab", %w[0.13.0]),
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", []),                                # missing
        {"status" => "ok", "out" => "", "err" => ""},       # install claims ok…
        listing("json", [])                                 # …but the dep never appeared
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "failed", gem["status"]
        assert_match(/dependency 'json \(~> 2\.7\)'.*not satisfiable/, gem["message"])
      end
    end

    def test_failed_dependency_install_is_a_classified_failure
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.13.0]),
        listing("ace-lab", %w[0.13.0]),
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", []),                                # missing
        {"status" => 2, "out" => "", "err" => "ERROR:  Could not find a valid gem 'json'\n"}
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "failed", gem["status"]
        assert_match(/gem install json failed.*'json'/, gem["message"])
      end
    end

    def test_newer_version_beside_the_declared_one_is_uninstalled
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.14.0 0.13.0]),              # presence probe
        listing("ace-lab", %w[0.14.0 0.13.0]),              # newer probe
        {"status" => "ok", "out" => "", "err" => ""},       # gem uninstall 0.14.0
        dependency_listing("ace-lab", "0.13.0", {})         # closure
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "exists", gem["status"]
        assert_equal [{"version" => "0.14.0", "status" => "uninstalled"}], gem["removed_newer_versions"]
        assert_equal ["gem", "uninstall", "ace-lab", "--version", "0.14.0", "-x", "--force"],
          runner.calls[2][17..]
      end
    end

    def test_dry_run_predicts_uninstall_and_dependency_install_without_mutation
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.14.0 0.13.0]),              # presence probe
        listing("ace-lab", %w[0.14.0 0.13.0]),              # newer probe
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", [])                                 # dep probe: missing
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner, dry_run: true)
          .call(runtime: converged_runtime(dir))

        gem = report.first
        assert_equal "exists", gem["status"]
        assert_equal [{"version" => "0.14.0", "status" => "would_uninstall"}], gem["removed_newer_versions"]
        assert_equal [{"name" => "json", "requirement" => "~> 2.7", "status" => "would_install"}],
          gem["closure"]
        assert runner.calls.none? { |argv| argv.include?("uninstall") || argv.include?("install") }
      end
    end

    def test_development_dependencies_do_not_converge
      runner = FakeRunner.new([
        listing("ace-lab", %w[0.13.0]),
        listing("ace-lab", %w[0.13.0]),
        {"status" => "ok", "out" => "ace-lab (0.13.0)\n  rake (>= 0, development)\n", "err" => ""}
      ])
      Dir.mktmpdir do |dir|
        report = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)
          .call(runtime: converged_runtime(dir))

        assert_equal "exists", report.first["status"]
        assert_empty report.first["closure"]
        assert_equal 3, runner.calls.size
      end
    end

    def test_read_only_probes_report_closure_gaps_and_newer_versions
      runner = FakeRunner.new([
        dependency_listing("ace-lab", "0.13.0", {"json" => "~> 2.7"}),
        listing("json", []),                                # json missing
        listing("ace-lab", %w[0.14.0 0.13.0])               # newer probe
      ])
      Dir.mktmpdir do |dir|
        gem_home = File.join(dir, "gems")
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
        gem_home = File.join(dir, "gems")
        FileUtils.mkdir_p(gem_home)
        provisioner = Ace::Lab::Molecules::GemsetProvisioner.new(runner: runner)

        kind, message = provisioner.closure_failures(name: "ace-lab", version: "0.13.0", gem_home: gem_home)
        assert_equal :unknown, kind
        assert_match(/gem not found in PATH/, message)
      end
    end
  end
end
