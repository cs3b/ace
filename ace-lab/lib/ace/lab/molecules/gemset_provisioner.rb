# frozen_string_literal: true

require_relative "../errors"
require "open3"
require "fileutils"
require "yaml"
require "rbconfig"

module Ace
  module Lab
    module Molecules
      # Install the declared runtime as one Bundler bundle. Dependency
      # resolution belongs to Bundler; read-only probes below are used only
      # by explicit diagnostics.
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
          if runtime_failure
            return gems.map { |gem| base(gem, gem_home).merge("status" => "failed", "message" => runtime_failure) }
          end
          if dry_run
            return gems.map { |gem| base(gem, gem_home).merge("status" => "would_install", "message" => nil) }
          end

          scope = File.join(RUBY_ENGINE, RbConfig::CONFIG.fetch("ruby_version"))
          unless gem_home.end_with?("/#{scope}")
            raise Ace::Lab::InvalidConfigurationError,
              "gemset gem_home must end in /#{scope} for the Bundler runtime"
          end
          bundle_root = File.dirname(File.dirname(gem_home))
          gemfile = File.join(bundle_root, "Gemfile")
          raise Ace::Lab::InvalidConfigurationError, "runtime Gemfile must not be a symlink" if File.symlink?(gemfile)
          content = "source #{Gem.sources.first.to_s.dump}\n" + gems.map do |gem|
            "gem #{gem.fetch('name').dump}, #{gem.fetch('version').dump}\n"
          end.join
          settings_dir = File.join(bundle_root, ".bundle")
          settings_path = File.join(settings_dir, "config")
          if File.symlink?(settings_dir) || File.symlink?(settings_path) || File.symlink?("#{gemfile}.lock")
            raise Ace::Lab::InvalidConfigurationError, "runtime bundle configuration must not be a symlink"
          end
          previous = [gemfile, "#{gemfile}.lock", settings_path].to_h do |path|
            [path, File.file?(path) ? [File.binread(path), File.stat(path).mode & 0o777] : nil]
          end
          begin
            File.write(gemfile, content) unless File.file?(gemfile) && File.read(gemfile) == content
            FileUtils.mkdir_p(settings_dir)
            File.write(settings_path, YAML.dump(
              "BUNDLE_PATH" => bundle_root, "BUNDLE_BIN" => File.join(gem_home, "bin"),
              "BUNDLE_SHEBANG" => Gem.ruby))
            result = @runner.call(runtime_argv(gem_home,
              ["BUNDLE_GEMFILE=#{gemfile}", "BUNDLE_USER_CONFIG=#{File::NULL}", "bundle", "install"]))
            failure = command_failure("bundle install", result) unless result["status"] == "ok"
            install_entrypoints(gem_home, runtime["bin_dir"]) unless failure
          rescue StandardError, Interrupt
            restore_bundle(previous)
            raise
          end
          restore_bundle(previous) if failure
          gems.map do |gem|
            base(gem, gem_home).merge("status" => failure ? "failed" : "installed", "message" => failure)
          end
        end

        # A configured bundle controls activation even when another version
        # is installed beside it. Bundler owns checking its locked closure.
        def bundle_status(name:, version:, gem_home:)
          gemfile = File.join(File.dirname(File.dirname(gem_home)), "Gemfile")
          return nil unless File.file?(gemfile)
          lock = "#{gemfile}.lock"
          return [:failed, "runtime bundle lock is missing; rerun ace-lab install"] unless File.file?(lock)
          require "bundler"
          specs = Bundler::LockfileParser.new(File.read(lock)).specs
          unless specs.any? { |spec| spec.name == name && spec.version.to_s == version }
            return [:failed, "runtime bundle does not lock #{name} at #{version}; rerun ace-lab install"]
          end
          result = @runner.call(runtime_argv(gem_home,
            ["BUNDLE_GEMFILE=#{gemfile}", "BUNDLE_USER_CONFIG=#{File::NULL}", "BUNDLE_FROZEN=true", "bundle", "check", "--dry-run"]))
          result["status"] == "ok" ? [:ok, nil] : [:failed, command_failure("bundle check", result)]
        rescue Bundler::BundlerError, SystemCallError => error
          [:failed, "runtime bundle is unavailable (#{error.class}); rerun ace-lab install"]
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
        # @return [Array(Symbol, Object)] [:ok, reasons] (empty reasons
        #   = closed) or the failing probe's [:unknown/:failed,
        #   message] — the same shape newer_versions returns.
        def closure_failures(name:, version:, gem_home:)
          queue = [[name, version]]
          seen = {}
          reasons = []
          until queue.empty?
            current_name, current_version = queue.shift
            next if seen[[current_name, current_version]]

            seen[[current_name, current_version]] = true
            deps = runtime_dependencies(name: current_name, version: current_version, gem_home: gem_home)
            return [:failed, deps] if deps.is_a?(String)

            deps.each do |dep|
              kind, versions_or_message = runtime_versions(name: dep["name"], gem_home: gem_home)
              return [kind, versions_or_message] if kind != :ok

              satisfying = satisfying_versions(dep, versions_or_message)
              if satisfying.empty?
                reasons << "dependency '#{dep["name"]} (#{dep["requirement"]})' required by gem " \
                  "'#{current_name}' is not satisfied in runtime '#{gem_home}'"
              else
                queue << [dep["name"], satisfying.max_by { |v| Gem::Version.new(v) }]
              end
            end
          end
          [:ok, reasons]
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

        def restore_bundle(previous)
          previous.each do |path, saved|
            if saved
              File.binwrite(path, saved.first)
              File.chmod(saved.last, path)
            else
              File.unlink(path) if File.file?(path)
            end
          end
        end

        def install_entrypoints(gem_home, directory)
          return unless directory
          FileUtils.mkdir_p(directory)
          Dir.glob(File.join(gem_home, "bin", "ace-*")).each do |source|
            target = File.join(directory, File.basename(source))
            if File.symlink?(target)
              next if File.expand_path(File.readlink(target), directory) == source
              raise Ace::Lab::InvalidConfigurationError, "executable already belongs to another runtime: #{target}"
            end
            raise Ace::Lab::InvalidConfigurationError, "executable already exists: #{target}" if File.exist?(target)
            File.symlink(source, target)
          end
        end

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
          constraint = Gem::Requirement.new(*requirement)
          versions.select do |version|
            # RubyGems can activate an explicitly installed prerelease even
            # when the depending gem uses a normal version requirement.
            # Dependency#match? filters prereleases intended for discovery;
            # closure checks must describe what this installed runtime can use.
            constraint.satisfied_by?(Gem::Version.new(version))
          end
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
            (BUNDLER_ENV_KEYS + ENV.keys.grep(/\ABUNDLER?_/)).uniq.flat_map { |key| ["-u", key] } +
            ["GEM_HOME=#{gem_home}", "GEM_PATH=#{gem_home}"] + argv
        end

        # `gem list <name> --exact --local` prints one `name (v1, v2)`
        # line when the name is present in the runtime and nothing when
        # it is absent. A DEFAULT gem's bundled version appears as a
        # `default: V` part (`abbrev (default: 0.1.2)`,
        # `json (2.9.4, default: 2.9.1)`): the marked V is the default
        # gem's own version, every other part is an additionally
        # installed version — both are present in the runtime, so the
        # normalized list carries the marked version in place of the
        # marker. Every candidate is validated by Gem::Version itself —
        # platform-suffixed or otherwise malformed strings fail the
        # probe (nil, fail closed) instead of crashing a later
        # Gem::Version.new caller; never a guessed empty list.
        def parse_versions(out, name)
          line = out.lines.find { |candidate| candidate.start_with?("#{name} ") }
          return [] if line.nil?

          match = line.chomp.match(/\A#{Regexp.escape(name)} \((.*)\)\z/)
          return nil if match.nil?

          versions = match[1].split(",").map(&:strip).map do |part|
            default = part.match(/\Adefault: (\S+)\z/)
            default ? default[1] : part
          end
          begin
            versions.each { |version| Gem::Version.new(version) }
          rescue ArgumentError
            return nil
          end

          versions
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
