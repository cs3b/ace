# frozen_string_literal: true

require_relative "../errors"
require "open3"
require "fileutils"

module Ace
  module Lab
    module Molecules
      # Idempotently converges the install manifest's declared gem set
      # into the declared target runtime (GEM_HOME; gad.2 gap #1, owner
      # spec 8xg.t.sbz.7): a gem whose exact declared version is already
      # present is a no-op (`exists`), a missing gem is installed
      # (`installed`), a gem present at a different version is updated
      # (the declared version installed alongside — RubyGems keeps
      # versions side by side; verify judges the declared set). Probes
      # and installs run the `gem` executable with GEM_HOME/GEM_PATH
      # pinned to the target runtime through the SAME argv runner seam
      # the other prepare molecules use (POSIX `env`, never a shell
      # string, ADR-031) — so the lab runtime stays isolated from the
      # installer's own gems and the runner stays injectable for
      # dry-run and tests. The runtime directory itself is created only
      # with administrator privileges (the same seam
      # AccountProvisioner gates creation with) and a symlink or
      # non-directory at the declared path is refused (the
      # DirectoryProvisioner takeover posture). Every failure is a
      # classified per-gem item with an actionable message; command
      # failures surface only the exit status and the first stderr line.
      class GemsetProvisioner
        attr_reader :runner, :privileged, :dry_run

        def initialize(runner: nil, privileged: nil, dry_run: false)
          @runner = runner || method(:run_argv)
          @privileged = privileged || -> { Process.euid.zero? }
          @dry_run = dry_run
        end

        # @param runtime [Hash] normalized manifest gemset section
        #   ({"gem_home" => path, "gems" => [{"name" =>, "version" =>}]})
        # @return [Array<Hash>] one report per declared gem:
        #   {name:, version:, gem_home:, status:, message:}
        def call(runtime:)
          gems = runtime["gems"]
          return [] if gems.empty?

          gem_home = runtime["gem_home"]
          runtime_failure = ensure_runtime(gem_home)
          gems.map do |gem|
            if runtime_failure
              base(gem, gem_home).merge("status" => "failed", "message" => runtime_failure)
            else
              report = converge(base(gem, gem_home), gem, gem_home)
              if %w[exists installed updated].include?(report["status"])
                converge_post_presence(report, gem, gem_home)
              else
                report
              end
            end
          end
        end

        # Public READ-ONLY probe (L8.5): the local versions of `name`
        # inside the target runtime — the exact probe convergence runs,
        # exposed so the readiness verifier reuses the same logic
        # instead of reimplementing it (the two can never drift).
        # @param name [String] gem name
        # @param gem_home [String] target runtime (GEM_HOME)
        # @return [Array(Symbol, Object)] [:ok, versions],
        #   [:unknown, message] (no `gem` executable — offline posture)
        #   or [:failed, message]
        def runtime_versions(name:, gem_home:)
          result = @runner.call(runtime_argv(gem_home,
            ["gem", "list", name, "--exact", "--local"]))
          return [:unknown, "gem not found in PATH; install RubyGems and rerun ace-lab prepare"] if result["status"] == "enoent"
          return [:failed, command_failure("gem list", result)] unless result["status"] == "ok"

          versions = parse_versions(result["out"], name)
          if versions.nil?
            return [:failed, "could not determine installed versions of gem '#{name}' from " \
              "'gem list' output; rerun ace-lab prepare"]
          end

          [:ok, versions]
        end

        # Public READ-ONLY probes (verify, task 8xs.t.pu0.0): the same
        # primitives convergence runs, exposed so readiness reuses the
        # identical logic instead of reimplementing it.
        #
        # Unsatisfied runtime dependencies of the declared gem — the
        # concrete missing-dependency list readiness reports.
        # @return [Array<String>] classified reasons (empty = closed)
        def closure_failures(name:, version:, gem_home:)
          queue = [[name, version]]
          seen = {}
          reasons = []
          until queue.empty?
            current_name, current_version = queue.shift
            next if seen[[current_name, current_version]]

            seen[[current_name, current_version]] = true
            deps = runtime_dependencies(name: current_name, version: current_version, gem_home: gem_home)
            return [deps] if deps.is_a?(String)

            deps.each do |dep|
              kind, versions_or_message = runtime_versions(name: dep["name"], gem_home: gem_home)
              return [versions_or_message] if kind != :ok

              satisfying = satisfying_versions(dep, versions_or_message)
              if satisfying.empty?
                reasons << "dependency '#{dep["name"]} (#{dep["requirement"]})' required by gem " \
                  "'#{current_name}' is not satisfied in runtime '#{gem_home}'"
              else
                queue << [dep["name"], satisfying.max_by { |v| Gem::Version.new(v) }]
              end
            end
          end
          reasons
        end

        # Installed versions of `name` NEWER than the declared one —
        # the versions that would win activation and take over the CLI.
        # @return [Array(String, Object)] [:ok, versions] or the probe's
        #   [:unknown/:failed, message]
        def newer_versions(name:, declared_version:, gem_home:)
          kind, versions_or_message = runtime_versions(name: name, gem_home: gem_home)
          return [kind, versions_or_message] if kind != :ok

          declared = Gem::Version.new(declared_version)
          [:ok, versions_or_message.select { |version| Gem::Version.new(version) > declared }]
        end

        private

        def base(gem, gem_home)
          {"name" => gem["name"], "version" => gem["version"], "gem_home" => gem_home}
        end

        # One runtime failure fails every declared gem as a dependency
        # (the keys-need-accounts posture): convergence is never
        # attempted against a runtime that did not prepare.
        def ensure_runtime(gem_home)
          stat = lstat(gem_home)
          return "gem runtime '#{gem_home}' is a symbolic link; refusing" if stat&.symlink?
          return "gem runtime '#{gem_home}' exists but is not a directory; refusing" if stat && !stat.directory?
          return nil if stat

          unless @privileged.call
            return "creating gem runtime '#{gem_home}' requires administrator privileges; " \
              "rerun ace-lab prepare with sudo or create the directory manually"
          end
          return nil if @dry_run # prediction: creation would succeed

          FileUtils.mkdir_p(gem_home)
          nil
        rescue Errno::EPERM, Errno::EACCES
          "insufficient permissions while preparing gem runtime '#{gem_home}'; " \
            "rerun ace-lab prepare with sudo or adjust ownership manually"
        rescue SystemCallError => e
          "gem runtime '#{gem_home}' could not be created (#{e.class.name}); rerun ace-lab prepare"
        end

        def converge(base, gem, gem_home)
          kind, versions_or_message = runtime_versions(name: gem["name"], gem_home: gem_home)
          # Prepare's fail-closed posture: an unprobeable runtime (no
          # `gem` executable — the :unknown probe kind) fails the item in
          # wet AND dry runs, exactly as the wet run would fail; verify
          # maps the same probe kind to its offline `unknown` posture.
          return base.merge("status" => "failed", "message" => versions_or_message) if kind != :ok

          versions = versions_or_message
          return base.merge("status" => "exists", "message" => nil) if versions.include?(gem["version"])

          status = versions.empty? ? "install" : "update"
          return base.merge("status" => "would_#{status}", "message" => nil) if @dry_run

          failure = install(gem, gem_home)
          return base.merge("status" => "failed", "message" => failure) if failure

          if status == "install"
            base.merge("status" => "installed", "message" => nil)
          else
            base.merge("status" => "updated", "message" => nil)
          end
        end

        # Post-presence convergence (task 8xs.t.pu0.0): the declared
        # version being present is necessary but not sufficient.
        #   1. NEWER versions of the declared gem sitting beside the
        #      declared one would win RubyGems activation and take over
        #      the runtime's CLI — the manifest is the single owner of
        #      the declared set, so convergence removes them from the
        #      target runtime.
        #   2. The dependency closure must actually resolve in the
        #      runtime: a gem whose version already figures in
        #      `gem list` can still miss a transitive runtime
        #      dependency (the manually-repaired `json` class of gap);
        #      missing dependencies are converged by installing them
        #      at the parent's requirement, and an unsatisfiable
        #      dependency is a classified failure — never readiness.
        # A dry run predicts both without writing (would_uninstall /
        # would_install) and stops recursion at the prediction.
        def converge_post_presence(report, gem, gem_home)
          removal = converge_newer_versions(gem, gem_home)
          return report.merge("status" => "failed", "message" => removal) if removal.is_a?(String)
          report["removed_newer_versions"] = removal

          closure = converge_closure(gem, gem_home)
          return report.merge("status" => "failed", "message" => closure) if closure.is_a?(String)
          report["closure"] = closure
          report
        end

        # @return [Array<Hash>, String] per-version removal reports or a
        #   classified failure message
        def converge_newer_versions(gem, gem_home)
          kind, versions_or_message = runtime_versions(name: gem["name"], gem_home: gem_home)
          return versions_or_message if kind != :ok

          declared = Gem::Version.new(gem["version"])
          newer = versions_or_message.select { |version| Gem::Version.new(version) > declared }
          return [] if newer.empty?

          return newer.map { |version| {"version" => version, "status" => "would_uninstall"} } if @dry_run

          newer.map do |version|
            result = @runner.call(runtime_argv(gem_home,
              ["gem", "uninstall", gem["name"], "--version", version, "-x", "--force"]))
            if result["status"] != "ok"
              break command_failure("gem uninstall #{gem["name"]} #{version}", result)
            end
            {"version" => version, "status" => "uninstalled"}
          end
        end

        # Breadth-first walk of the gem's RUNTIME dependency closure in
        # the target runtime. `gem dependency` output is plain text (no
        # marshaled objects), development dependencies are ignored.
        # @return [Array<Hash>, String] per-dependency convergence
        #   actions or a classified failure message
        def converge_closure(gem, gem_home)
          queue = [[gem["name"], gem["version"]]]
          seen = {}
          actions = []
          until queue.empty?
            name, version = queue.shift
            next if seen[[name, version]]

            seen[[name, version]] = true
            deps = runtime_dependencies(name: name, version: version, gem_home: gem_home)
            return deps if deps.is_a?(String)

            deps.each do |dep|
              kind, versions_or_message = runtime_versions(name: dep["name"], gem_home: gem_home)
              return versions_or_message if kind != :ok

              satisfying = satisfying_versions(dep, versions_or_message)
              if satisfying.empty?
                if @dry_run
                  actions << {"name" => dep["name"], "requirement" => dep["requirement"],
                              "status" => "would_install"}
                  next # recursion stops at the prediction
                end

                failure = install_dependency(dep, gem_home)
                return failure if failure

                kind, versions_or_message = runtime_versions(name: dep["name"], gem_home: gem_home)
                return versions_or_message if kind != :ok
                satisfying = satisfying_versions(dep, versions_or_message)
                if satisfying.empty?
                  return "dependency '#{dep["name"]} (#{dep["requirement"]})' required by gem " \
                    "'#{name}' is not satisfiable in runtime '#{gem_home}' after install; " \
                    "check the gem source or the manifest declaration"
                end
                actions << {"name" => dep["name"], "requirement" => dep["requirement"],
                            "status" => "installed"}
              end

              chosen = satisfying.max_by { |v| Gem::Version.new(v) }
              queue << [dep["name"], chosen]
            end
          end
          actions
        end

        # Installs a missing dependency at the parent requirement: the
        # requirement string the runtime's own resolver would accept
        # (`gem install name -v "~> 2.7"`).
        # @return [String, nil] classified failure, nil on success
        def install_dependency(dep, gem_home)
          result = @runner.call(runtime_argv(gem_home,
            ["gem", "install", dep["name"], "--version", dep["requirement"], "--no-document"]))
          return nil if result["status"] == "ok"

          command_failure("gem install #{dep["name"]}", result)
        end

        # The runtime (non-development) dependencies of an installed
        # gem, from `gem dependency <name> --version <v>` plain-text
        # output: "dep (~> 2.0, runtime)" lines under the gem header.
        # @return [Array<Hash{"name","requirement"}>, String] or a
        #   classified failure message
        def runtime_dependencies(name:, version:, gem_home:)
          result = @runner.call(runtime_argv(gem_home,
            ["gem", "dependency", name, "--version", version]))
          if result["status"] == "enoent"
            return "gem not found in PATH; install RubyGems and rerun ace-lab prepare"
          end
          return "gem dependency failed (#{exit_detail(result["status"])}); rerun ace-lab prepare" \
            unless result["status"] == "ok"

          result["out"].lines.filter_map do |line|
            match = line.match(/\A\s+([A-Za-z0-9._-]+) \(([^)]*)\)\s*\z/)
            next if match.nil?

            parts = match[2].split(",").map(&:strip)
            type = %w[runtime development].include?(parts.last) ? parts.pop : "runtime"
            next if type == "development"

            requirement = parts.join(", ")
            requirement = ">= 0" if requirement.empty?
            {"name" => match[1], "requirement" => requirement}
          end
        end

        def satisfying_versions(dep, versions)
          requirement = dep["requirement"].split(",").map(&:strip)
          versions.select do |version|
            Gem::Dependency.new(dep["name"], *requirement).match?(dep["name"], version)
          end
        end

        # Installs the EXACT declared version into the runtime. Sources
        # are the gem command's own defaults — fetching from the
        # configured gem source is provisioning network access, the same
        # envelope as cloning a declared repository remote.
        # @return [String, nil] the classified failure, nil on success
        def install(gem, gem_home)
          result = @runner.call(runtime_argv(gem_home,
            ["gem", "install", gem["name"], "--version", gem["version"], "--no-document"]))
          return nil if result["status"] == "ok"

          command_failure("gem install", result)
        end

        # Environment variables that would drag the INVOKING process's
        # bundler context into the gem subprocess: RUBYOPT carries
        # `-rbundler/setup` under `bundle exec ace-lab` (the documented
        # invocation), RubyGems auto-requires ENV["BUNDLER_SETUP"]
        # (rubygems.rb), and the BUNDLE_*/BUNDLER_* vars re-bind bundler
        # when it loads — any of which overrides the pinned paths with
        # the invoking bundle's load paths. The lab runtime must stay
        # isolated from the installer's gems, its bundle included.
        BUNDLER_ENV_KEYS = %w[RUBYOPT RUBYLIB BUNDLER_SETUP BUNDLE_BIN_PATH
          BUNDLE_GEMFILE BUNDLER_VERSION BUNDLE_BUNDLER_VERSION].freeze

        private_constant :BUNDLER_ENV_KEYS

        # GEM_HOME/GEM_PATH are pinned through the POSIX `env` command so
        # the argv-array runner seam stays unchanged and the subprocess
        # sees ONLY the target runtime.
        def runtime_argv(gem_home, argv)
          ["env"] +
            BUNDLER_ENV_KEYS.flat_map { |key| ["-u", key] } +
            ["GEM_HOME=#{gem_home}", "GEM_PATH=#{gem_home}"] + argv
        end

        # `gem list <name> --exact --local` prints one `name (v1, v2)`
        # line when the name is present in the runtime and nothing when
        # it is absent. A present-but-unparseable line is a failed probe
        # (nil, fail closed), never a guessed empty list.
        def parse_versions(out, name)
          line = out.lines.find { |candidate| candidate.start_with?("#{name} ") }
          return [] if line.nil?

          match = line.chomp.match(/\A#{Regexp.escape(name)} \((.*)\)\z/)
          return nil if match.nil?

          match[1].split(",").map(&:strip)
        end

        # Classified one-line command failure: status plus the first
        # stderr line only — never command output bodies.
        def command_failure(command, result)
          case result["status"]
          when "enoent"
            return "#{command} failed: gem not found in PATH; install RubyGems and rerun ace-lab prepare"
          when "exec_failed"
            return "#{command} failed: could not be executed (#{result["err"]}); rerun ace-lab prepare"
          end

          message = "#{command} failed (#{exit_detail(result["status"])})"
          line = result["err"].to_s.lines.map(&:strip).reject(&:empty?).first
          message = "#{message}: #{line}" if line
          "#{message}; rerun ace-lab prepare (with sudo when the runtime is not writable)"
        end

        def exit_detail(status)
          status.is_a?(Integer) ? "exit #{status}" : status.to_s
        end

        def lstat(path)
          File.lstat(path)
        rescue Errno::ENOENT, Errno::ENOTDIR
          nil
        end

        def run_argv(argv)
          out, err, status = Open3.capture3(*argv)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal #{status.termsig}"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
        end
      end
    end
  end
end
