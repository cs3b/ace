# frozen_string_literal: true

require "pathname"
require "time"

module Ace
  module Lab
    module Molecules
      # Deployment-owned operation and authorization facts. The caller may
      # name a reference but cannot define its scope or executor binding.
      class ServicePolicy
        NAME = /\A[a-z][a-z0-9-]{0,63}\z/
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/

        def initialize(document)
          @operations = document.fetch("operations", {})
          @authorizations = document.fetch("authorizations", {})
          unless @operations.is_a?(Hash) && @authorizations.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, "trusted service policy must contain mappings"
          end
        end

        def operation!(name, project:, service_id:)
          raise ArgumentError, "invalid operation name" unless name.to_s.match?(NAME)
          operation = @operations[name]
          raise SecurityError, "operation is not configured" unless operation.is_a?(Hash)
          unless operation["project"] == project && operation["service_id"] == service_id
            raise SecurityError, "operation does not authorize the selected service in this project"
          end
          transport = operation.fetch("transport", "local")
          unless %w[local unix].include?(transport)
            raise Ace::Lab::InvalidConfigurationError, "configured service transport is invalid"
          end
          if transport == "local"
            argv = operation["argv"]
            unless argv.is_a?(Array) && !argv.empty? && argv.all? { |v| v.is_a?(String) && !v.empty? } &&
                argv.first.start_with?("/") && File.file?(argv.first) && File.executable?(argv.first)
              raise Ace::Lab::InvalidConfigurationError, "configured operation needs a fixed executable argv"
            end
          elsif !operation["socket_path"].is_a?(String) || !operation["socket_path"].start_with?("/")
            raise Ace::Lab::InvalidConfigurationError, "unix service needs an absolute socket path"
          end
          uid = operation["executor_uid"]
          raise Ace::Lab::InvalidConfigurationError, "configured executor UID is invalid" unless uid.is_a?(Integer) && uid >= 0
          if transport == "local"
            # Every path component is validated (symlinks resolved, writable
            # ancestors rejected) and the validated resolved file replaces
            # the configured argv entry, so execution cannot be redirected
            # between validation and dispatch.
            resolved = trusted_executable!(operation["argv"].first, uid)
            operation = operation.merge("argv" => [resolved] + operation["argv"][1..])
          end
          expires_at = parse_time(operation["lease_expires_at"])
          raise SecurityError, "executor lease has expired" if expires_at <= Time.now.utc
          if operation["host_maintenance"] == true
            # Maintenance executes a fixed updater outside the replaced
            # deployment; a socket-only operation has no executable to place
            # and cannot prove the maintenance boundary.
            unless transport == "local"
              raise Ace::Lab::InvalidConfigurationError,
                "host maintenance requires a local executable transport"
            end
            deployment = resolved_path(operation["deployment_root"].to_s)
            sink = resolved_path(operation["evidence_sink"].to_s)
            executable = operation.dig("argv", 0).to_s
            unless deployment.start_with?("/") && sink.start_with?("/") && executable.start_with?("/") &&
                !inside?(executable, deployment) && !inside?(sink, deployment)
              raise Ace::Lab::InvalidConfigurationError,
                "host maintenance needs executable and evidence sink outside the replaced deployment"
            end
          end
          operation
        end

        def authorize!(reference, binding)
          raise ArgumentError, "invalid authorization reference" unless reference.to_s.match?(ID)
          decision = @authorizations[reference]
          raise SecurityError, "authorization reference is unresolved" unless decision.is_a?(Hash)
          required = %w[operation project_id assignment_id attempt_id input_digest target candidate_head caller_uid]
          unless required.all? { |key| decision[key] == binding[key] }
            raise SecurityError, "authorization does not match the exact service request"
          end
          raise SecurityError, "authorization has expired" if parse_time(decision["expires_at"]) <= Time.now.utc
          decision
        end

        private

        # Validate the executable and every directory component on its
        # resolved path: each must be owned by root or the executor and not
        # group/other-writable, so no ancestor or symlink component can
        # redirect the fixed argv. Returns the resolved file path.
        def trusted_executable!(path, uid)
          resolved = resolved_path(path.to_s)
          unless resolved.start_with?("/") && File.file?(resolved) && File.executable?(resolved)
            raise Ace::Lab::InvalidConfigurationError, "configured executable is unavailable"
          end
          Pathname.new(resolved).descend do |component|
            stat = File.stat(component)
            unless [0, uid].include?(stat.uid) && (stat.mode & 0o022).zero?
              raise Ace::Lab::InvalidConfigurationError,
                "configured executable path has a writable or foreign-owned component: #{component}"
            end
          end
          resolved
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          raise Ace::Lab::InvalidConfigurationError, "configured executable is unavailable"
        end

        def inside?(path, root)
          expanded = File.expand_path(path)
          base = File.expand_path(root)
          expanded == base || expanded.start_with?(base + File::SEPARATOR)
        end

        # Resolve a configured path through symlinks so placement checks see
        # the real location. Paths may not exist yet (an evidence sink is
        # created on first use), so the deepest ancestor — counting symlink
        # components themselves via lstat — is resolved instead of failing;
        # a dangling symlink resolves through its own target chain rather
        # than hiding behind its parent.
        def resolved_path(path)
          expanded = File.expand_path(path)
          candidate = expanded
          candidate = File.dirname(candidate) until candidate == "/" || lstat?(candidate)
          resolved = begin
            File.realpath(candidate)
          rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
            dangling_target(candidate) || candidate
          end
          return resolved unless resolved == candidate && lstat?(candidate) && File.symlink?(candidate)
          dangling_target(candidate) || resolved
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          expanded
        end

        # Follow a dangling symlink's own target chain; nil when the link
        # cannot be resolved to any concrete location.
        def dangling_target(link)
          target = File.readlink(link)
          target = File.expand_path(target, File.dirname(link)) unless Pathname.new(target).absolute?
          resolved_path(target)
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          nil
        end

        def lstat?(path)
          File.lstat(path)
          true
        rescue Errno::ENOENT
          false
        end

        def parse_time(value)
          Time.iso8601(value.to_s)
        rescue ArgumentError
          raise Ace::Lab::InvalidConfigurationError, "trusted policy has invalid expiry"
        end
      end
    end
  end
end
