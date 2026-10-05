# frozen_string_literal: true

require "etc"
require "json"
require "socket"

module Ace
  module Assign
    module Molecules
      # Resolves the trusted execution-boundary identity for attempt
      # transitions.
      #
      # Actor identity is derived from the execution boundary, never granted
      # by command flags or receipt claims. Two adapters ship:
      # - `local` — the interactive operator is the coordinator; identity
      #   comes from the kernel process account (equal real/effective UID).
      # - `service` — a trusted service executor supplies a structured
      #   identity through a configured environment variable; the executor
      #   owns OS/process enforcement.
      #
      # Unknown adapter, missing actor, or malformed identity fails closed:
      # unknown identity is an error, never permission.
      class ExecutionIdentityResolver
        ROLES = %w[coordinator service worker].freeze
        TRUSTED_ROLES = %w[coordinator service].freeze

        # Resolved boundary identity.
        Identity = Struct.new(:actor, :role, :runtime, :adapter, :process_pid, :runtime_binding, keyword_init: true)

        # @param adapter [String, nil] "local" or "service" (default from config)
        # @param service_env [String, nil] Env var carrying the service identity (default from config)
        def initialize(adapter: nil, service_env: nil, runtime_resolver: Ace::Runtime, env: ENV, caller_pid: Process.ppid)
          section = Ace::Assign.config["attempt"] || {}
          @adapter = adapter || section["identity_adapter"] || "local"
          @service_env = service_env || section["service_identity_env"] || "ACE_ASSIGN_SERVICE_IDENTITY"
          @runtime_resolver = runtime_resolver
          @env = env
          @caller_pid = caller_pid
        end

        # @return [Identity] Trusted boundary identity
        # @raise [AttemptErrors::UnauthorizedIdentity] when identity cannot be established
        def resolve
          case @adapter
          when "local" then from_local_boundary
          when "service" then from_service_env
          else
            raise AttemptErrors::UnauthorizedIdentity, "Unknown identity adapter '#{@adapter}'"
          end
        end

        # @param identity [Identity] Identity to inspect
        # @return [Boolean] True when the role may accept privileged transitions
        def trusted?(identity)
          TRUSTED_ROLES.include?(identity.role)
        end

        private

        def from_local_boundary
          uid, euid = Process.uid, Process.euid
          unless uid == euid
            raise AttemptErrors::UnauthorizedIdentity, "Local execution requires equal real and effective UIDs"
          end

          account = local_account(euid)
          verify_local_credentials!(uid, euid)
          binding = native_process_binding
          verify_local_credentials!(uid, euid)
          Identity.new(
            actor: account.name,
            role: "coordinator",
            runtime: "local:#{Socket.gethostname}",
            adapter: "local",
            process_pid: binding&.dig("process_identity", "pid"),
            runtime_binding: binding
          )
        end

        def local_account(euid)
          account = Etc.getpwuid(euid)
          unless account && account.uid == euid && account.name.is_a?(String) && !account.name.strip.empty?
            raise AttemptErrors::UnauthorizedIdentity, "No valid kernel process account for effective UID #{euid}"
          end
          account
        rescue ArgumentError, SystemCallError
          raise AttemptErrors::UnauthorizedIdentity, "Cannot resolve kernel process account for effective UID #{euid}"
        end

        def verify_local_credentials!(uid, euid)
          unless Process.uid == uid && Process.euid == euid
            raise AttemptErrors::UnauthorizedIdentity, "Local execution credentials changed during identity resolution"
          end
        end

        def from_service_env
          raw = ENV[@service_env].to_s.strip
          if raw.empty?
            raise AttemptErrors::UnauthorizedIdentity,
              "Service identity env #{@service_env} is empty; the trusted executor must supply it"
          end

          data = begin
            JSON.parse(raw)
          rescue JSON::ParserError
            raise AttemptErrors::UnauthorizedIdentity, "Service identity env #{@service_env} is not valid JSON"
          end

          actor = data["actor"].to_s.strip
          role = data["role"].to_s.strip
          runtime = data["runtime"].to_s.strip
          if actor.empty? || runtime.empty? || !ROLES.include?(role)
            raise AttemptErrors::UnauthorizedIdentity,
              "Service identity must supply actor, runtime, and a role in #{ROLES.join('/')}"
          end

          pid = data["process_pid"]
          if pid && (!pid.is_a?(Integer) || !pid.positive?)
            raise AttemptErrors::UnauthorizedIdentity, "Service process_pid must be a positive integer"
          end
          Identity.new(actor: actor, role: role, runtime: runtime, adapter: "service", process_pid: pid)
        end

        def native_process_binding
          adapter = Ace::Runtime::Molecules::RuntimeSelector.new(
            config: Ace::Runtime.config, registry: @runtime_resolver, env: @env).resolve
          context = adapter.context
          return nil unless context[:in_runtime] && context[:pane]

          adapter.process_binding(pane: context[:pane], caller_pid: @caller_pid)
        rescue Ace::Runtime::Error
          nil
        end
      end
    end
  end
end
