# frozen_string_literal: true

require "json"
require "ace/herdr/molecules/bounded_process"
require "shellwords"
require "tempfile"
require "securerandom"
require "fileutils"
require "ace/support/cli/toolchain"

module Ace
  module Overseer
    module Molecules
      # A project's own Gemfile/lock and binstub select its ACE version.
      # Never load child project gems into the lab coordinator's process.
      class ProjectBundle
        # A new Herdr shell inherits the server environment, which may differ
        # from this CLI's environment. Clear known Bundler selectors even
        # when the requesting process did not have them set.
        BUNDLE_SELECTORS = %w[
          BUNDLE_ALLOW_OFFLINE_INSTALL BUNDLE_APP_CONFIG BUNDLE_AUTO_INSTALL
          BUNDLE_BIN BUNDLE_BIN_PATH BUNDLE_CACHE_ALL BUNDLE_CACHE_ALL_PLATFORMS
          BUNDLE_CACHE_PATH BUNDLE_CLEAN BUNDLE_CONSOLE BUNDLE_DEPLOYMENT
          BUNDLE_DISABLE_CHECKSUM_VALIDATION BUNDLE_DISABLE_EXEC_LOAD
          BUNDLE_DISABLE_LOCAL_BRANCH_CHECK BUNDLE_DISABLE_LOCAL_REVISION_CHECK
          BUNDLE_DISABLE_SHARED_GEMS BUNDLE_DISABLE_VERSION_CHECK
          BUNDLE_FORCE_RUBY_PLATFORM BUNDLE_FORGET_CLI_OPTIONS BUNDLE_FROZEN
          BUNDLE_GEMFILE BUNDLE_GEM__BUNDLE BUNDLE_GEM__CHANGELOG BUNDLE_GEM__CI
          BUNDLE_GEM__COC BUNDLE_GEM__GITHUB_USERNAME BUNDLE_GEM__LINTER
          BUNDLE_GEM__MIT BUNDLE_GEM__RUBOCOP BUNDLE_GEM__TEST
          BUNDLE_GIT__ALLOW_INSECURE BUNDLE_GLOBAL_GEM_CACHE BUNDLE_IGNORE_CONFIG
          BUNDLE_IGNORE_MESSAGES BUNDLE_INIT_GEMS_RB BUNDLE_INLINE BUNDLE_JOBS
          BUNDLE_LOCKFILE_CHECKSUMS BUNDLE_NO_INSTALL BUNDLE_NO_PRUNE BUNDLE_ONLY
          BUNDLE_PATH BUNDLE_PATH__SYSTEM BUNDLE_PLUGINS BUNDLE_PREFER_PATCH
          BUNDLE_REDIRECT BUNDLE_RETRY BUNDLE_SHEBANG BUNDLE_SILENCE_DEPRECATIONS
          BUNDLE_SILENCE_ROOT_WARNING BUNDLE_SIMULATE_VERSION BUNDLE_SSL_CA_CERT
          BUNDLE_SSL_CLIENT_CERT BUNDLE_SSL_VERIFY_MODE BUNDLE_SYSTEM_BINDIR
          BUNDLE_TIMEOUT BUNDLE_TRUST___POLICY BUNDLE_UPDATE_REQUIRES_ALL_FLAG
          BUNDLE_USER_HOME BUNDLE_USER_CONFIG BUNDLE_USER_CACHE BUNDLE_USER_PLUGIN
          BUNDLE_VERBOSE BUNDLE_VERSION BUNDLE_WITH BUNDLE_WITHOUT
          BUNDLER_SETUP BUNDLER_VERSION
        ].freeze
        RUBY_SELECTORS = %w[RUBYOPT RUBYLIB GEM_HOME GEM_PATH ACE_TOOLCHAIN].freeze

        def self.environment(root, env: ENV)
          if Ace::Support::Cli::Toolchain.installed?
            # Reuse the installed closure; the project checkout is domain data.
            # Do not let a project binstub or Gemfile select source dependencies.
            return Ace::Support::Cli::Toolchain.child_environment.merge(
              "HERDR_PANE" => nil, "HERDR_TAB" => nil,
              "HERDR_PANE_ID" => nil, "HERDR_TAB_ID" => nil
            )
          end
          known = BUNDLE_SELECTORS + RUBY_SELECTORS
          names = env.keys.grep(/\ABUNDLER?_/) + known +
            (known + %w[PATH]).map { |key| "BUNDLER_ORIG_#{key}" } +
            %w[HERDR_PANE HERDR_TAB HERDR_PANE_ID HERDR_TAB_ID]
          names.to_h { |name| [name, nil] }.merge(
            "BUNDLE_GEMFILE" => File.file?(File.join(root, "Gemfile")) ? File.join(root, "Gemfile") : nil,
            "PATH" => [File.join(root, "bin"), env.fetch("PATH", "/usr/bin:/bin")].join(File::PATH_SEPARATOR)
          )
        end

        def self.shell_setup(root, env: ENV)
          values = environment(root, env: env).reject { |name, _| %w[HERDR_PANE HERDR_TAB HERDR_PANE_ID HERDR_TAB_ID].include?(name) }
          if Ace::Support::Cli::Toolchain.installed?
            # A server-created shell may contain selectors absent from this
            # caller. Clear the same known selectors before applying the
            # installed closure; never inherit server-side Bundler injection.
            names = BUNDLE_SELECTORS + BUNDLE_SELECTORS.map { |key| "BUNDLER_ORIG_#{key}" }
            values = names.to_h { |name| [name, nil] }.merge(values)
          end

          cleared, assigned = values.partition { |_, value| value.nil? }
          # Guard every operation: e.g. a readonly inherited selector must
          # refuse setup rather than print readiness after a failed unset.
          commands = cleared.map { |name, _| "unset #{Shellwords.escape(name)}" } +
            assigned.map { |name, value| "export #{name}=#{Shellwords.escape(value)}" }
          commands.join(" &&\n")
        end

        # pane_run types through a terminal: Linux canonical input truncates
        # a line after 4095 bytes. Keep the environment in a private shared
        # project file, not /tmp (Herdr can use a different PrivateTmp).
        # The caller must observe the marker before launching the harness.
        def self.with_shell_setup(root, env: ENV)
          directory = root
          %w[.ace-local overseer runtime-start].each do |part|
            directory = File.join(directory, part)
            raise Ace::Overseer::Error, "runtime setup directory is a symlink: #{directory}" if File.symlink?(directory)

            Dir.mkdir(directory, 0o700) unless File.exist?(directory)
            raise Ace::Overseer::Error, "runtime setup path is not a directory: #{directory}" unless File.directory?(directory)
          end
          info = File.stat(directory)
          unless info.uid == Process.uid && (info.mode & 0o077).zero?
            raise Ace::Overseer::Error, "runtime setup directory must be private and owned by the current user: #{directory}"
          end
          marker = "ACE_OVERSEER_ENV_READY_#{SecureRandom.hex(16)}"
          Tempfile.create(["environment-", ".sh"], directory) do |file|
            setup = shell_setup(root, env: env).strip.sub(/;\z/, "")
            file.write("#{setup} && printf '%s\\n' #{Shellwords.escape(marker)}\n")
            file.flush
            file.fsync
            # The tab is created in root. An explicit ./ prevents dot from
            # searching PATH; a relative path also keeps terminal input short.
            relative = "./.ace-local/overseer/runtime-start/#{File.basename(file.path)}"
            yield ". #{Shellwords.escape(relative)}", marker
          end
        rescue SystemCallError => e
          raise Ace::Overseer::Error, "runtime setup file could not be prepared: #{e.message}"
        end

        def initialize(timeout_s: 240)
          @timeout_s = timeout_s
        end

        def call(root:, workspace:, env: ENV)
          installed = Ace::Support::Cli::Toolchain.installed?
          unless installed
            %w[Gemfile Gemfile.lock].each do |name|
              unless File.file?(File.join(root, name))
                raise Ace::Overseer::Error, "project bundle missing #{name}; prepare this project's own bundle first"
              end
            end
          end
          binary = installed ? Ace::Support::Cli::Toolchain.executable("ace-overseer") : File.join(root, "bin", "ace-overseer")
          command = File.executable?(binary) ? [binary] : ["bundle", "exec", "ace-overseer"]
          command += ["start", "--scope", "project", "--format", "json"]
          child_env = self.class.environment(root, env: env).merge("HERDR_WORKSPACE_ID" => workspace)
          result = Ace::Herdr::Molecules::BoundedProcess.call(command,
            environment: ENV.to_h.merge(child_env).compact, chdir: root,
            timeout_s: @timeout_s, output_limit: 1_048_576)
          raise Ace::Overseer::Error, "project start output exceeded its limit" if result.oversized
          out, err, status = result.stdout, result.stderr, result.status
          report = JSON.parse(out)
          # Startup can fail before it establishes project scope. Keep that
          # concrete failure without admitting an unscoped report as ready.
          if report.is_a?(Hash) && report["status"] == "blocked" &&
              report.key?("scope") && report["scope"].nil? &&
              report["message"].is_a?(String) && !report["message"].strip.empty?
            raise Ace::Overseer::Error, report["message"]
          end
          unless report.is_a?(Hash) && report["scope"] == "project" && report["status"].is_a?(String)
            raise Ace::Overseer::Error, "project start returned no project-scope report"
          end
          if !status.success? && %w[started reused ready].include?(report["status"])
            raise Ace::Overseer::Error, "project start exited #{status.exitstatus} despite a ready report"
          end
          report
        rescue Timeout::Error
          raise Ace::Overseer::Error, "project start timed out after #{@timeout_s}s; inspect the existing session before retrying"
        rescue Ace::Herdr::Molecules::BoundedProcess::PostLaunchError => e
          raise Ace::Overseer::Error, "project start outcome is uncertain: #{e.message}"
        rescue JSON::ParserError
          raise Ace::Overseer::Error, "project bundle start returned invalid JSON#{": " + err.strip[0, 300] unless err.to_s.empty?}"
        rescue SystemCallError => e
          raise Ace::Overseer::Error, "project bundle could not start: #{e.message}"
        end
      end
    end
  end
end
