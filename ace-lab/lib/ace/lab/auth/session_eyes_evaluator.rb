# frozen_string_literal: true
require "json"
require "rbconfig"
require "ace/runtime/molecules/protected_socket"
require "ace/herdr/molecules/bounded_process"
require_relative "../molecules/install_manifest_loader"
require_relative "error"

module Ace
  module Lab
    module Auth
      # The evidence interpreter belongs to ace-overseer. Invoke its fixed
      # installed helper without loading that package into the issuer.
      class SessionEyesEvaluator
        def initialize(loader: -> { Molecules::InstallManifestLoader.load },
          verify: Ace::Runtime::Molecules::ProtectedSocket.method(:root_path!),
          runner: Ace::Herdr::Molecules::BoundedProcess.method(:call), ruby: RbConfig.ruby)
          @loader, @verify, @runner, @ruby = loader, verify, runner, ruby
        end

        def call(context, file:)
          document = @loader.call
          gem_home = document.fetch("gemset").fetch("gem_home")
          @verify.call(gem_home, directory: true)
          roots = Dir.glob(File.join(gem_home, "gems", "ace-overseer-*"))
          raise Error, "installed readiness evaluator is missing or ambiguous" unless roots.size == 1
          helper = File.join(roots.first, "libexec", "eyes-ready")
          @verify.call(helper, directory: false)
          @verify.call(@ruby, directory: false)
          runtime = document.fetch("session_runtime")
          paths = [File.dirname(@ruby), File.join(gem_home, "bin"), *runtime.fetch("path")].uniq
          paths.each { |path| @verify.call(path, directory: true) }
          environment = {"GEM_HOME" => gem_home, "GEM_PATH" => gem_home,
            "PATH" => paths.join(":"), "HOME" => "/var/empty", "LANG" => "C.UTF-8",
            "ACE_TOOLCHAIN" => "installed", "HERDR_SOCKET_PATH" => runtime.fetch("herdr").fetch("socket")}
          result = @runner.call([@ruby, helper], stdin_data: JSON.generate(context),
            timeout_s: 10, output_limit: 1024, stderr_limit: 1024, environment: environment,
            chdir: "/", descriptor_mapping: {3 => file}, cleanup_group: true)
          unless result.status.success? && !result.oversized
            raise Error, "installed readiness evaluator failed"
          end
          value = JSON.parse(result.stdout, create_additions: false, allow_duplicate_key: false, max_nesting: 2)
          unless value.is_a?(Hash) && value.keys == ["ready"] && [true, false].include?(value["ready"])
            raise Error, "installed readiness evaluator returned invalid evidence"
          end
          value.fetch("ready")
        rescue KeyError, JSON::ParserError, SystemCallError, IOError, SecurityError, Timeout::Error,
          Ace::Runtime::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError
          raise Error, "installed readiness evaluator is unavailable"
        end
      end
    end
  end
end
