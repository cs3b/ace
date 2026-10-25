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
              converge(base(gem, gem_home), gem, gem_home)
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
