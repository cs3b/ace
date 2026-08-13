# frozen_string_literal: true

require "fileutils"
require "open3"
require "digest"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Builds a sandbox-local Ruby/Bundler runtime for E2E execution.
        class SandboxRuntimeBuilder
          DEFAULT_RUBY_VERSION = RUBY_VERSION
          DEFAULT_SHARED_RUNTIME_CACHE_ROOT = ".ace-local/test-e2e/runtime-cache"
          SHARED_RUNTIME_ENV_KEY = "ACE_E2E_SHARED_RUNTIME_ROOT"
          RUNTIME_CACHE_LAYOUT_VERSION = 1
          RESERVED_ENV_KEYS = %w[
            PROJECT_ROOT_PATH
            ACE_E2E_SOURCE_ROOT
            ACE_CONFIG_PATH
            BUNDLE_GEMFILE
            BUNDLE_APP_CONFIG
            BUNDLE_USER_HOME
            BUNDLE_USER_CACHE
            BUNDLE_USER_CONFIG
            BUNDLE_PATH
            BUNDLE_BIN
            BUNDLE_DISABLE_SHARED_GEMS
            BUNDLER_VERSION
            GEM_HOME
            GEM_PATH
            RUBYOPT
            RUBYLIB
          ].freeze

          def initialize(source_root:, ruby_version: nil, command_runner: nil)
            @source_root = File.expand_path(source_root)
            @ruby_version = (ruby_version || DEFAULT_RUBY_VERSION).to_s.strip
            @command_runner = command_runner || method(:capture3)
          end

          def prepare(sandbox_root:, env: {}, tool_names: nil)
            sandbox_root = File.expand_path(sandbox_root)
            local_runtime_root = File.join(sandbox_root, ".ace-local", "e2e-runtime")
            runtime_root = resolve_runtime_root(local_runtime_root, env)
            FileUtils.mkdir_p(runtime_root) unless shared_runtime_root?(env)

            runtime_env = build_runtime_env(
              sandbox_root,
              runtime_root,
              env,
              mutable_runtime_root: local_runtime_root
            )
            ensure_runtime_dirs(runtime_env)
            if shared_runtime_root?(env)
              ensure_shared_runtime!(runtime_root, tool_names)
            else
              prepare_runtime_root!(runtime_root, runtime_env, tool_names)
            end

            {
              runtime_root: runtime_root,
              env: runtime_env
            }
          end

          def prepare_shared_runtime(cache_root: nil, tool_names: nil)
            runtime_root = shared_runtime_root(cache_root: cache_root)
            runtime_env = build_shared_runtime_env(runtime_root)
            ensure_runtime_dirs(runtime_env)
            prepare_runtime_root!(runtime_root, runtime_env, tool_names)
            runtime_root
          end

          private

          def capture3(env, *cmd, chdir:)
            Open3.capture3(env, *cmd, chdir: chdir, unsetenv_others: true)
          end

          def build_runtime_env(sandbox_root, runtime_root, env, mutable_runtime_root: runtime_root)
            merged = stringify_keys(env).reject { |key, _value| RESERVED_ENV_KEYS.include?(key) }
            bundler_root = File.join(mutable_runtime_root, "bundler")
            gem_root = File.join(runtime_root, "gems")
            bin_root = File.join(runtime_root, "bin")
            path = merged["PATH"].to_s
            path = ENV["PATH"].to_s if path.empty?

            merged.merge(
              "PROJECT_ROOT_PATH" => sandbox_root,
              "ACE_E2E_SOURCE_ROOT" => @source_root,
              "ACE_CONFIG_PATH" => File.join(sandbox_root, ".ace"),
              "ACE_E2E_SANDBOX_RUNTIME_ROOT" => runtime_root,
              "ACE_E2E_SANDBOX_RUBY_VERSION" => @ruby_version,
              "ACE_E2E_SANDBOX_RUBY_ROOT" => (@ruby_version.empty? ? "" : resolve_ruby_install_path!),
              "BUNDLE_GEMFILE" => File.join(runtime_root, "Gemfile"),
              "BUNDLE_APP_CONFIG" => File.join(bundler_root, "app-config"),
              "BUNDLE_USER_HOME" => File.join(bundler_root, "home"),
              "BUNDLE_USER_CACHE" => File.join(bundler_root, "cache"),
              "BUNDLE_USER_CONFIG" => File.join(bundler_root, "config"),
              "BUNDLE_PATH" => gem_root,
              "BUNDLE_DISABLE_SHARED_GEMS" => "true",
              "BUNDLE_WITHOUT" => "",
              "GEM_HOME" => gem_root,
              "GEM_PATH" => gem_root,
              "PATH" => [bin_root, path].reject(&:empty?).join(File::PATH_SEPARATOR)
            )
          end

          def build_shared_runtime_env(runtime_root)
            build_runtime_env(@source_root, runtime_root, {}, mutable_runtime_root: runtime_root)
          end

          def ensure_runtime_dirs(env)
            [
              env.fetch("ACE_CONFIG_PATH"),
              env.fetch("BUNDLE_APP_CONFIG"),
              env.fetch("BUNDLE_USER_HOME"),
              env.fetch("BUNDLE_USER_CACHE"),
              File.dirname(env.fetch("BUNDLE_USER_CONFIG")),
              env.fetch("BUNDLE_PATH"),
              env.fetch("GEM_HOME"),
              File.join(env.fetch("ACE_E2E_SANDBOX_RUNTIME_ROOT"), "bin")
            ].each do |path|
              FileUtils.mkdir_p(path)
            end
          end

          def write_runtime_gemfile(runtime_root)
            source_gemfile = File.join(@source_root, "Gemfile")
            content = File.read(source_gemfile)
            rewritten = content.gsub(/(path:\s*["'])([^"']+)(["'])/) do
              prefix = Regexp.last_match(1)
              relative_path = Regexp.last_match(2)
              suffix = Regexp.last_match(3)
              absolute_path = File.expand_path(relative_path, @source_root)
              "#{prefix}#{absolute_path}#{suffix}"
            end
            File.write(File.join(runtime_root, "Gemfile"), rewritten)
          end

          def write_command_shims(runtime_root, tool_names)
            bin_root = File.join(runtime_root, "bin")
            requested = normalize_tool_names(tool_names)
            executable_map = discover_executable_map
            names = executable_map.keys | requested

            names.each do |tool_name|
              source_exec = executable_map[tool_name]
              next unless source_exec

              shim_path = File.join(bin_root, tool_name)
              shim_body = if @ruby_version.empty?
                <<~SH
                  #!/usr/bin/env bash
                  set -euo pipefail
                  exec ruby -rbundler/setup "#{source_exec}" "$@"
                SH
              else
                ruby_exec = ruby_executable_path
                <<~SH
                  #!/usr/bin/env bash
                  set -euo pipefail
                  exec "#{ruby_exec}" -rbundler/setup "#{source_exec}" "$@"
                SH
              end
              File.write(shim_path, shim_body)
              FileUtils.chmod(0o755, shim_path)
            end
          end

          def discover_executable_map
            @discover_executable_map ||= begin
              paths = Dir.glob(File.join(@source_root, "bin", "ace-*")).sort
              Dir.glob(File.join(@source_root, "ace-*", "exe", "ace-*")).sort.each do |path|
                basename = File.basename(path)
                next if paths.any? { |candidate| File.basename(candidate) == basename }

                paths << path
              end

              paths.each_with_object({}) do |path, map|
                map[File.basename(path)] = path
              end
            end
          end

          def normalize_tool_names(tool_names)
            Array(tool_names)
              .flat_map { |entry| entry.to_s.split(",") }
              .map(&:strip)
              .reject(&:empty?)
              .uniq
          end

          def resolve_runtime_root(local_runtime_root, env)
            shared_root = shared_runtime_root_from_env(env)
            return shared_root if shared_root

            local_runtime_root
          end

          def shared_runtime_root?(env)
            !shared_runtime_root_from_env(env).nil?
          end

          def shared_runtime_root_from_env(env)
            merged = stringify_keys(ENV.to_h).merge(stringify_keys(env))
            raw = merged[SHARED_RUNTIME_ENV_KEY].to_s.strip
            return nil if raw.empty?

            File.expand_path(raw)
          end

          def shared_runtime_root(cache_root: nil)
            base = if cache_root
              File.expand_path(cache_root)
            else
              File.join(@source_root, DEFAULT_SHARED_RUNTIME_CACHE_ROOT)
            end

            File.join(base, runtime_cache_key)
          end

          def runtime_cache_key
            @runtime_cache_key ||= begin
              digest = Digest::SHA256.new
              digest.update("layout:#{RUNTIME_CACHE_LAYOUT_VERSION}\n")
              digest.update("ruby:#{@ruby_version}\n")
              digest.update(File.read(File.join(@source_root, "Gemfile")))
              lockfile_path = File.join(@source_root, "Gemfile.lock")
              digest.update(File.read(lockfile_path)) if File.file?(lockfile_path)
              digest.hexdigest[0, 16]
            end
          end

          def ensure_shared_runtime!(runtime_root, tool_names)
            runtime_env = build_shared_runtime_env(runtime_root)
            ensure_runtime_dirs(runtime_env)
            prepare_runtime_root!(runtime_root, runtime_env, tool_names)
          end

          def prepare_runtime_root!(runtime_root, env, tool_names)
            with_runtime_lock(runtime_root) do
              marker_path = File.join(runtime_root, ".bootstrapped")
              return if File.exist?(marker_path)

              FileUtils.mkdir_p(runtime_root)
              write_runtime_gemfile(runtime_root)
              write_command_shims(runtime_root, tool_names)
              install_runtime!(runtime_root, env)
            end
          end

          def with_runtime_lock(runtime_root)
            lock_path = "#{runtime_root}.lock"
            FileUtils.mkdir_p(File.dirname(lock_path))
            File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lock_file|
              lock_file.flock(File::LOCK_EX)
              yield
            end
          end

          def install_runtime!(runtime_root, env)
            marker_path = File.join(runtime_root, ".bootstrapped")
            return if File.exist?(marker_path)

            ensure_ruby_available!
            ensure_no_global_ace_gems!

            stdout, stderr, status = @command_runner.call(
              install_env(env),
              *runtime_command(%w[bundle install]),
              chdir: runtime_root
            )
            return File.write(marker_path, "ok\n") if status.success?

            raise [
              "Sandbox bundle install failed for Ruby #{@ruby_version}",
              stdout.to_s.strip,
              stderr.to_s.strip
            ].reject(&:empty?).join("\n")
          end

          def ensure_ruby_available!
            resolve_ruby_install_path!
          rescue RuntimeError => e
            raise e

          end

          def resolve_ruby_install_path!
            return @ruby_install_path if defined?(@ruby_install_path) && @ruby_install_path

            stdout, stderr, status = @command_runner.call(
              minimal_host_env,
              "mise", "where", "ruby@#{@ruby_version}",
              chdir: @source_root
            )
            if status.success?
              @ruby_install_path = stdout.to_s.strip
              return @ruby_install_path unless @ruby_install_path.empty?
            end

            raise [
              "Dedicated sandbox Ruby #{ruby_label} is not available.",
              "Install it with: mise install ruby@#{@ruby_version}",
              stderr.to_s.strip
            ].reject(&:empty?).join("\n")
          end

          def ensure_no_global_ace_gems!
            script = <<~RUBY
              names = Gem::Specification.map(&:name).grep(/^ace-/)
              puts names.join("\\n") unless names.empty?
              exit(names.empty? ? 0 : 42)
            RUBY

            stdout, stderr, status = @command_runner.call(
              minimal_host_env,
              *runtime_command(["ruby", "-e", script]),
              chdir: @source_root
            )
            return if status.success?

            raise [
              "Dedicated sandbox Ruby #{ruby_label} already exposes ace-* gems globally.",
              stdout.to_s.strip,
              stderr.to_s.strip
            ].reject(&:empty?).join("\n")
          end

          def runtime_command(cmd)
            return cmd if @ruby_version.empty?
            ruby = ruby_executable_path
            command = Array(cmd)
            executable = command.shift

            case executable
            when "ruby"
              [ruby] + command
            when "bundle", "gem"
              [ruby, "-S", executable] + command
            else
              [ruby, "-S", executable] + command
            end
          end

          def ruby_executable_path
            File.join(resolve_ruby_install_path!, "bin", "ruby")
          end

          def minimal_host_env
            {"HOME" => ENV["HOME"].to_s, "PATH" => ENV["PATH"].to_s}
          end

          def install_env(env)
            minimal_host_env.merge(env).merge("PATH" => env.fetch("PATH"))
          end

          def ruby_label
            @ruby_version.empty? ? "(default ruby)" : @ruby_version
          end

          def stringify_keys(hash)
            hash.each_with_object({}) do |(key, value), acc|
              acc[key.to_s] = value
            end
          end
        end
      end
    end
  end
end
