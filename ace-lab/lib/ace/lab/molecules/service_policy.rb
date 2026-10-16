# frozen_string_literal: true

require_relative "../errors"
require_relative "../atoms/service_input"
require "ace/assign/errors"
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

        def initialize(document, proposal_resolver = nil)
          @document = document
          @operations = document.fetch("operations", {})
          @authorizations = document.fetch("authorizations", {})
          @proposal_resolver = proposal_resolver
          unless @operations.is_a?(Hash) && @authorizations.is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, "trusted service policy must contain mappings"
          end
        end

        # The trusted installation document as loaded. Decisions are mutable;
        # all other configuration remains bound for the receiver lifetime.
        attr_reader :document

        def self.configuration_digest(document)
          Atoms::ServiceInput.digest(document.except("authorizations"))
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
            deployment_root = operation["deployment_root"].to_s
            sink_path = operation["evidence_sink"].to_s
            unless deployment_root.start_with?("/") && sink_path.start_with?("/")
              raise Ace::Lab::InvalidConfigurationError,
                "host maintenance needs absolute deployment and evidence sink paths"
            end
            deployment = resolved_path(deployment_root)
            sink = resolved_path(sink_path)
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
          if reference.start_with?("proposal-")
            raise SecurityError, "canonical proposal authority is unavailable" unless @proposal_resolver
            begin
              return @proposal_resolver.call(reference, binding)
            rescue Ace::Assign::Error
              raise SecurityError, "canonical proposal does not authorize this exact effect"
            end
          end
          decision = @authorizations[reference]
          raise SecurityError, "authorization reference is unresolved" unless decision.is_a?(Hash)
          required = %w[operation project_id assignment_id attempt_id input_digest target candidate_head caller_uid]
          unless required.all? { |key| decision[key] == binding[key] }
            raise SecurityError, "authorization does not match the exact service request"
          end
          raise SecurityError, "authorization has expired" if parse_time(decision["expires_at"]) <= Time.now.utc
          decision
        end

        # ---- ordinary fixed merge admission policy (spec 8x3.t.xz9.4) ------
        #
        # The installed ordinary section is the separately configured
        # ordinary receiver mapping and admission policy. It supplies
        # identity and placement only: the caller selects no endpoint,
        # credential or receiver. An absent project section or a disabled
        # admission flag is rollback: new admission is unavailable while
        # canonical records and read-only status stay preserved.
        ORDINARY_SECTION_KEYS = %w[projects].freeze
        ORDINARY_PROJECT_KEYS = %w[receiver_id socket_path receiver_uid principal admission].freeze
        ORDINARY_AUTHORIZATION_KEYS = %w[operation project_id assignment_id attempt_id queue_entry
          input_digest forge pr_url head_repository head_ref candidate_head base_repository
          base_ref expected_base_head expires_at].freeze
        # expires_at bounds the decision itself; it is never exact-matched
        # against the request binding, which carries no expiry.
        ORDINARY_BINDING_KEYS = ORDINARY_AUTHORIZATION_KEYS - %w[expires_at].freeze

        def ordinary_receiver!(project)
          section = @document["ordinary"]
          return nil unless section.is_a?(Hash)
          validate_ordinary_section!(section)
          entry = section.fetch("projects")[project.to_s]
          return nil unless entry.is_a?(Hash)
          entry
        end

        # The ordinary admission decision: exact-match on every closed
        # binding key, like authorize!, but over the ordinary request
        # identity (forge/PR/repository/ref) instead of execution selectors.
        def authorize_ordinary!(reference, binding)
          raise ArgumentError, "invalid authorization reference" unless reference.to_s.match?(ID)
          decision = @authorizations[reference]
          raise SecurityError, "authorization reference is unresolved" unless decision.is_a?(Hash)
          unless ORDINARY_AUTHORIZATION_KEYS.all? { |key| decision.key?(key) }
            raise SecurityError, "authorization reference is not an ordinary merge decision"
          end
          unless ORDINARY_BINDING_KEYS.all? { |key| decision[key] == binding[key] }
            raise SecurityError, "authorization does not match the exact ordinary merge request"
          end
          raise SecurityError, "authorization has expired" if parse_time(decision["expires_at"]) <= Time.now.utc
          decision
        end

        def validate_ordinary_section!(section)
          unless (section.keys - ORDINARY_SECTION_KEYS).empty? && section["projects"].is_a?(Hash)
            raise Ace::Lab::InvalidConfigurationError, "ordinary section must map projects"
          end
          section.fetch("projects").each do |project, entry|
            unless project.is_a?(String) && project.match?(ID) && entry.is_a?(Hash) &&
                (entry.keys - ORDINARY_PROJECT_KEYS).empty?
              raise Ace::Lab::InvalidConfigurationError, "ordinary project section is invalid"
            end
            unless entry["receiver_id"].is_a?(String) && entry["receiver_id"].match?(ID) &&
                entry["socket_path"].is_a?(String) && entry["socket_path"].start_with?("/") &&
                entry["receiver_uid"].is_a?(Integer) && entry["receiver_uid"] >= 0 &&
                entry["principal"].is_a?(String) && !entry["principal"].empty?
              raise Ace::Lab::InvalidConfigurationError, "ordinary receiver mapping is incomplete"
            end
            admission = entry.fetch("admission", "enabled")
            unless %w[enabled disabled].include?(admission)
              raise Ace::Lab::InvalidConfigurationError, "ordinary admission flag is invalid"
            end
          end
          true
        end

        # Inspection never renews effect permission or selects effect argv.
        def inspection!(name, project:, service_id:, executor_uid:)
          raise ArgumentError, "invalid inspection operation" unless name.is_a?(String) && name.match?(NAME)
          operation = @operations[name]
          unless operation.is_a?(Hash) && operation["project"] == project && operation["service_id"] == service_id &&
              operation["executor_uid"].is_a?(Integer) && operation["executor_uid"] == executor_uid &&
              operation.fetch("transport", "local") == "local"
            raise SecurityError, "inspection does not match the selected original executor"
          end
          # This source-composed inspector uses the fixed original root SDK;
          # configured handler argv cannot select or replace that owner.
          if name == "prune-preserved-workspace"
            return {"executor_uid" => executor_uid, "operation" => name}
          end
          argv = operation["no_effect_argv"]
          unless argv.is_a?(Array) && argv.length.between?(1, 16) &&
              argv.all? { |value| value.is_a?(String) && value.bytesize.between?(1, 1024) && !value.include?("\0") } &&
              argv.first.start_with?("/")
            raise Ace::Lab::InvalidConfigurationError, "operation has no fixed no-effect inspector"
          end
          executable = trusted_executable!(argv.first, executor_uid)
          {"executor_uid" => executor_uid, "argv" => [executable] + argv.drop(1)}
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
        MAX_SYMLINK_DEPTH = 16

        def resolved_path(path, depth = 0)
          raise Ace::Lab::InvalidConfigurationError, "trusted policy path has a symlink cycle" if depth > MAX_SYMLINK_DEPTH
          expanded = File.expand_path(path)
          candidate = expanded
          candidate = File.dirname(candidate) until candidate == "/" || lstat?(candidate)
          resolved = begin
            File.realpath(candidate)
          rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
            dangling_target(candidate, depth) || candidate
          end
          return resolved unless resolved == candidate && lstat?(candidate) && File.symlink?(candidate)
          dangling_target(candidate, depth) || resolved
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          expanded
        end

        # Follow a dangling symlink's own target chain; nil when the link
        # cannot be resolved to any concrete location.
        def dangling_target(link, depth = 0)
          raise Ace::Lab::InvalidConfigurationError, "trusted policy path has a symlink cycle" if depth > MAX_SYMLINK_DEPTH
          target = File.readlink(link)
          target = File.expand_path(target, File.dirname(link)) unless Pathname.new(target).absolute?
          resolved_path(target, depth + 1)
        rescue Errno::ENOENT, Errno::EACCES
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
