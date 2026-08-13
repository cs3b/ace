# frozen_string_literal: true

require "etc"
require "fileutils"
require "open3"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Wraps subprocesses in a lightweight bubblewrap sandbox on Linux.
        class BwrapSandboxBackend
          BUNDLER_ENV_PREFIXES = %w[BUNDLE BUNDLER].freeze
          STRIPPED_ENV_KEYS = %w[RUBYOPT RUBYLIB].freeze
          PROVIDER_HOME_MOUNTS = [
            [".claude", ".claude"],
            [".codex", ".codex"],
            [".gemini", ".gemini"],
            [".pi", ".pi"],
            [".local/share/opencode", ".local/share/opencode"]
          ].freeze
          DEFAULT_SYSTEM_MOUNTS = %w[/usr /bin /sbin /lib /lib64 /etc /opt /var/lib/flatpak/exports].freeze

          attr_reader :sandbox_root

          def self.supported?
            Gem.win_platform? == false && RUBY_PLATFORM.include?("linux")
          end

          def self.available?(bwrap_path: "bwrap")
            return false unless supported?

            system("which", bwrap_path, out: File::NULL, err: File::NULL)
          end

          def initialize(sandbox_root:, source_root: nil, bwrap_path: "bwrap", outer_env: nil)
            @sandbox_root = File.expand_path(sandbox_root)
            @source_root = source_root ? File.expand_path(source_root) : infer_source_root
            @bwrap_path = bwrap_path
            @outer_env = sanitized_outer_env(outer_env)
          end

          def ensure_available!
            return unless self.class.supported?
            return if self.class.available?(bwrap_path: @bwrap_path)

            raise "bubblewrap is required for Linux E2E sandboxing but '#{@bwrap_path}' is not available"
          end

          def prepared_env(base_env = {})
            env = stringify_keys(base_env)
            STRIPPED_ENV_KEYS.each { |key| env.delete(key) }
            env["PROJECT_ROOT_PATH"] = @sandbox_root
            env["ACE_E2E_SOURCE_ROOT"] ||= @source_root if @source_root
            env["HOME"] = sandbox_home
            env["TMPDIR"] = sandbox_tmp
            env["XDG_RUNTIME_DIR"] = sandbox_runtime_dir
            env["TMUX_TMPDIR"] ||= sandbox_runtime_dir
            env["BUNDLE_GEMFILE"] ||= File.join(@sandbox_root, ".ace-local", "e2e-runtime", "Gemfile")
            env["ACE_CONFIG_PATH"] ||= File.join(@sandbox_root, ".ace")
            env["BUNDLE_APP_CONFIG"] ||= bundler_app_config
            env["BUNDLE_USER_HOME"] ||= bundler_home
            env["BUNDLE_USER_CACHE"] ||= bundler_cache
            env["BUNDLE_USER_CONFIG"] ||= bundler_user_config
            env["PATH"] ||= ENV["PATH"].to_s
            env
          end

          def wrap_command(cmd, chdir:, env: {})
            command_prefix(chdir: chdir, env: env) + Array(cmd)
          end

          def command_prefix(chdir:, env: {})
            ensure_available!
            merged_env = prepared_env(env)
            ensure_runtime_dirs(merged_env)

            args = [
              @bwrap_path,
              "--clearenv",
              "--die-with-parent",
              "--new-session",
              "--proc", "/proc",
              "--dev-bind", "/dev", "/dev",
              "--tmpfs", "/tmp",
              "--tmpfs", home_root,
              "--dir", merged_env.fetch("HOME"),
              "--bind", merged_env.fetch("HOME"), merged_env.fetch("HOME")
            ]

            host_mounts(merged_env.fetch("PATH")).each do |mount|
              append_bind(args, mount, mount, read_only: true)
            end
            append_bind(args, @source_root, @source_root, read_only: true) if @source_root
            append_bind(args, @sandbox_root, @sandbox_root, read_only: false)
            append_bind(args, support_root, support_root, read_only: false)
            ruby_root = merged_env["ACE_E2E_SANDBOX_RUBY_ROOT"].to_s
            append_bind(args, ruby_root, ruby_root, read_only: true) if !ruby_root.empty? && File.exist?(ruby_root)
            bind_provider_homes(args, merged_env.fetch("HOME"))

            setenvs = {
              "HOME" => merged_env.fetch("HOME"),
              "TMPDIR" => merged_env.fetch("TMPDIR"),
              "XDG_RUNTIME_DIR" => merged_env.fetch("XDG_RUNTIME_DIR"),
              "TMUX_TMPDIR" => merged_env.fetch("TMUX_TMPDIR"),
              "PATH" => merged_env.fetch("PATH"),
              "PROJECT_ROOT_PATH" => merged_env.fetch("PROJECT_ROOT_PATH")
            }
            setenvs["ACE_E2E_SOURCE_ROOT"] = merged_env["ACE_E2E_SOURCE_ROOT"] if merged_env["ACE_E2E_SOURCE_ROOT"]
            setenvs["ACE_E2E_SANDBOX_RUBY_ROOT"] = ruby_root unless ruby_root.empty?
            setenvs["ACE_TMUX_SESSION"] = merged_env["ACE_TMUX_SESSION"] if merged_env["ACE_TMUX_SESSION"]

            merged_env.each do |key, value|
              next if setenvs.key?(key)
              next if value.nil?

              setenvs[key] = value.to_s
            end

            setenvs.each do |key, value|
              args.concat(["--setenv", key, value])
            end

            args.concat(["--chdir", File.expand_path(chdir), "--"])
            args
          end

          def capture3(cmd, chdir:, env: {}, stdin_data: nil)
            if self.class.supported?
              Open3.capture3(
                @outer_env,
                *wrap_command(cmd, chdir: chdir, env: env),
                chdir: "/",
                stdin_data: stdin_data
              )
            else
              full_env = prepared_env(env)
              Open3.capture3(
                @outer_env.merge(full_env),
                *Array(cmd),
                chdir: chdir,
                stdin_data: stdin_data
              )
            end
          end

          def exec(cmd, chdir:, env: {})
            if self.class.supported?
              Kernel.exec(@outer_env, *wrap_command(cmd, chdir: chdir, env: env))
            else
              full_env = prepared_env(env)
              Kernel.exec(@outer_env.merge(full_env), *Array(cmd), chdir: chdir)
            end
          end

          private

          def sandbox_home
            File.join(support_root, "home")
          end

          def sandbox_tmp
            File.join(support_root, "tmp")
          end

          def sandbox_runtime_dir
            File.join(support_root, "runtime")
          end

          def bundler_root
            File.join(support_root, "bundler")
          end

          def bundler_home
            File.join(bundler_root, "home")
          end

          def bundler_cache
            File.join(bundler_root, "cache")
          end

          def bundler_user_config
            File.join(bundler_root, "config")
          end

          def bundler_app_config
            File.join(bundler_root, "app-config")
          end

          def home_root
            File.dirname(actual_home)
          end

          def actual_home
            File.expand_path(ENV.fetch("HOME"))
          end

          def infer_source_root
            env_root = ENV["ACE_E2E_SOURCE_ROOT"].to_s.strip
            return File.expand_path(env_root) unless env_root.empty?

            File.expand_path(Dir.pwd)
          end

          def support_root
            "#{@sandbox_root}.support"
          end

          def host_mounts(path_value)
            mounts = DEFAULT_SYSTEM_MOUNTS.select { |path| File.exist?(path) }
            path_value.to_s.split(File::PATH_SEPARATOR).each do |entry|
              next if entry.to_s.strip.empty?

              expanded = File.expand_path(entry)
              next unless File.exist?(expanded)

              mounts << expanded
              mounts << mise_install_root(expanded) if expanded.include?("/.local/share/mise/installs/")
            end

            mounts.compact.uniq.sort
          end

          def mise_install_root(path)
            match = path.match(%r{\A(.*/\.local/share/mise/installs/[^/]+/[^/]+)})
            match && match[1]
          end

          def ensure_runtime_dirs(env)
            [
              @sandbox_root,
              support_root,
              env.fetch("HOME"),
              env.fetch("TMPDIR"),
              env.fetch("XDG_RUNTIME_DIR"),
              env.fetch("BUNDLE_APP_CONFIG"),
              env.fetch("BUNDLE_USER_HOME"),
              env.fetch("BUNDLE_USER_CACHE")
            ].each { |path| FileUtils.mkdir_p(path) }
            FileUtils.chmod(0o700, env.fetch("XDG_RUNTIME_DIR")) if File.exist?(env.fetch("XDG_RUNTIME_DIR"))
          end

          def bind_provider_homes(args, sandbox_home_dir)
            PROVIDER_HOME_MOUNTS.each do |source_suffix, target_suffix|
              source = File.join(actual_home, source_suffix)
              next unless File.exist?(source)

              target = File.join(sandbox_home_dir, target_suffix)
              FileUtils.mkdir_p(File.dirname(target))
              FileUtils.mkdir_p(target) if File.directory?(source)
              append_bind(args, source, target, read_only: false)
            end
          end

          def append_bind(args, source, target, read_only:)
            source = File.expand_path(source)
            target = File.expand_path(target)
            FileUtils.mkdir_p(File.dirname(target))
            FileUtils.mkdir_p(target) if File.directory?(source)
            args.concat([read_only ? "--ro-bind" : "--bind", source, target])
          end

          def stringify_keys(hash)
            hash.each_with_object({}) { |(key, value), acc| acc[key.to_s] = value }
          end

          def sanitized_process_env(base_env)
            stringify_keys(base_env).each_with_object({}) do |(key, value), env|
              next if strip_env_key?(key)

              env[key] = value
            end
          end

          def sanitized_outer_env(outer_env)
            path = stringify_keys(outer_env || {"PATH" => ENV["PATH"].to_s})["PATH"]
            {"PATH" => path.to_s.empty? ? ENV["PATH"].to_s : path.to_s}
          end

          def strip_env_key?(key)
            STRIPPED_ENV_KEYS.include?(key) || BUNDLER_ENV_PREFIXES.any? { |prefix| key.start_with?(prefix) }
          end
        end
      end
    end
  end
end
