# frozen_string_literal: true

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
          validate_executable!(operation["argv"].first, uid) if transport == "local"
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
            executable = resolved_path(operation.dig("argv", 0).to_s)
            unless deployment.start_with?("/") && sink.start_with?("/") && executable.start_with?("/") &&
                !inside?(executable, deployment) && !inside?(sink, deployment)
              raise Ace::Lab::InvalidConfigurationError,
                "host maintenance needs executable and evidence sink outside the replaced deployment"
            end
            validate_executable!(executable, uid)
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

        def validate_executable!(path, uid)
          file = File.stat(path)
          parent = File.stat(File.dirname(File.realpath(path)))
          unless [0, uid].include?(file.uid) && [0, uid].include?(parent.uid) &&
              (file.mode & 0o022).zero? && (parent.mode & 0o022).zero?
            raise Ace::Lab::InvalidConfigurationError,
              "configured executable or containing directory is writable by another identity"
          end
        rescue Errno::ENOENT, Errno::EACCES
          raise Ace::Lab::InvalidConfigurationError, "configured executable is unavailable"
        end

        def inside?(path, root)
          expanded = File.expand_path(path)
          base = File.expand_path(root)
          expanded == base || expanded.start_with?(base + File::SEPARATOR)
        end

        # Resolve a configured path through symlinks so placement checks see
        # the real location. Paths may not exist yet (an evidence sink is
        # created on first use), so the deepest existing ancestor is
        # resolved instead of failing.
        def resolved_path(path)
          expanded = File.expand_path(path)
          candidate = expanded
          candidate = File.dirname(candidate) until candidate == "/" || File.exist?(candidate)
          File.realpath(candidate)
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          expanded
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
