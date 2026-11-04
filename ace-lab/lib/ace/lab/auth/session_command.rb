# frozen_string_literal: true

require "rbconfig"
require "ace/herdr/molecules/installed_pi_extensions"
require "ace/herdr/molecules/bounded_process"
require_relative "session_configuration"

module Ace
  module Lab
    module Auth
      # Converts the protected deployment selection into a fixed Pi command.
      # No argv, environment, executable or extension comes from a request.
      class SessionCommand
        def initialize(verify: nil,
          extensions: -> { Ace::Herdr::Molecules::InstalledPiExtensions.arguments(
            env: {"ACE_TOOLCHAIN" => "installed", "ACE_LAB_SESSION" => "1"}) },
          runner: Ace::Herdr::Molecules::BoundedProcess.method(:call))
          @verify, @extensions, @runner = verify || method(:verify_path!), extensions, runner
        end

        def build(selection:, id:, terminal_id: nil, cwd: nil)
          unless selection.is_a?(SessionConfiguration::Selection) && id.is_a?(String) && id.match?(/\A[0-9a-f]{16}\z/)
            raise ArgumentError, "configured session selection required"
          end
          runtime = selection.runtime
          if terminal_id && !runtime["herdr"].is_a?(Hash)
            raise Error, "configured native reporting endpoint is unavailable"
          end
          @verify.call(runtime.fetch("node"), directory: false, executable: true)
          @verify.call(runtime.fetch("pi"), directory: false)
          @verify.call(runtime.fetch("credentials"), directory: false, secret: true)
          @verify.call(selection.gem_home, directory: true)
          path = [File.dirname(RbConfig.ruby), File.join(selection.gem_home, "bin"), *runtime.fetch("path")].uniq
          path.each { |directory| @verify.call(directory, directory: true) }
          environment = {"PATH" => path.join(":"), "GEM_HOME" => selection.gem_home, "GEM_PATH" => selection.gem_home,
            "HOME" => "/run/ace-auth-#{id}/home", "PI_CODING_AGENT_DIR" => "/run/ace-auth-#{id}/pi",
            "LANG" => "C.UTF-8"}
          instructions = resolve_instructions(selection.instructions, selection.gem_home, environment)
          @verify.call(instructions, directory: false)
          SessionUnit.new(role: selection.role, id: id, directory: selection.execution_directory(cwd),
            project_root: selection.path, environment: environment, terminal_id: terminal_id,
            command: [runtime.fetch("node"), runtime.fetch("pi"), "--provider", runtime.fetch("provider"),
              "--model", runtime.fetch("model"), "--append-system-prompt", instructions, *@extensions.call])
        rescue KeyError, Ace::Runtime::Error, Ace::Herdr::Error, SystemCallError, Timeout::Error,
          Ace::Herdr::Molecules::BoundedProcess::PostLaunchError
          raise Error, "configured installed Pi runtime is unavailable"
        end

        private

        def verify_path!(path, directory: false, executable: false, secret: false)
          Ace::Runtime::Molecules::ProtectedSocket.root_path!(path, directory: directory)
          stat = File.lstat(path)
          unless (directory || stat.file?) && (!executable || File.executable?(path)) &&
              (!secret || (stat.mode & 0o7777) == 0o600)
            raise Error, "configured session path has an unsuitable type or mode"
          end
        end

        def resolve_instructions(source, gem_home, environment)
          return source unless source.include?("://")
          executable = File.join(gem_home, "bin", "ace-nav")
          @verify.call(executable, directory: false)
          @verify.call(RbConfig.ruby, directory: false)
          result = @runner.call([RbConfig.ruby, executable, "resolve", source], timeout_s: 10, output_limit: 4096,
            environment: environment.merge("HOME" => "/var/empty", "ACE_TOOLCHAIN" => "installed"),
            chdir: "/", cleanup_group: true)
          path = result.stdout.to_s.strip
          unless result.status.success? && !result.oversized && path.start_with?("/") &&
              !path.match?(/[[:cntrl:]]/) && File.expand_path(path) == path
            raise Error, "configured standing instructions did not resolve"
          end
          path
        end
      end
    end
  end
end
