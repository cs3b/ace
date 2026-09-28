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
      #   comes from the OS login boundary.
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
        Identity = Struct.new(:actor, :role, :runtime, :adapter, keyword_init: true)

        # @param adapter [String, nil] "local" or "service" (default from config)
        # @param service_env [String, nil] Env var carrying the service identity (default from config)
        def initialize(adapter: nil, service_env: nil)
          section = Ace::Assign.config["attempt"] || {}
          @adapter = adapter || section["identity_adapter"] || "local"
          @service_env = service_env || section["service_identity_env"] || "ACE_ASSIGN_SERVICE_IDENTITY"
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
          actor = Etc.getlogin || ENV["USER"] || ENV["LOGNAME"]
          if actor.nil? || actor.strip.empty?
            raise AttemptErrors::UnauthorizedIdentity, "No OS login identity available at the execution boundary"
          end

          Identity.new(
            actor: actor.strip,
            role: "coordinator",
            runtime: "local:#{Socket.gethostname}",
            adapter: "local"
          )
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

          Identity.new(actor: actor, role: role, runtime: runtime, adapter: "service")
        end
      end
    end
  end
end
