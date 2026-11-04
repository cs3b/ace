# frozen_string_literal: true
require_relative "session_configuration"
require_relative "session_native_transport"

module Ace
  module Lab
    module Auth
      # Authorize the original isolated caller before invoking the host's
      # native start. Native still owns name reservation and process adoption.
      class SessionDelegate
        METHOD = "agent.start_isolated"
        def initialize(configuration: SessionConfiguration.new, transport: SessionNativeTransport.new)
          @configuration, @transport = configuration, transport
        end

        def self.validate!(request)
          params = request.is_a?(Hash) && request["params"]
          unless request.is_a?(Hash) && request.keys.sort == %w[id method params] && request["method"] == METHOD &&
              request["id"].is_a?(String) && request["id"].bytesize.between?(1, 512) &&
              !request["id"].match?(/[[:cntrl:]]/) && params.is_a?(Hash) &&
              params.keys.sort == %w[name project role workspace_id] &&
              params["name"].is_a?(String) && params["name"].match?(/\A[a-z][a-z0-9_-]{0,31}\z/) &&
              %w[project workspace_id].all? { |key| params[key].is_a?(String) && params[key].match?(/\A[a-zA-Z0-9_.:-]{1,128}\z/) } &&
              SessionUnit::ROLES.include?(params["role"])
            raise Error, "invalid isolated delegation request"
          end
          true
        end

        def call(request, identity:)
          self.class.validate!(request)
          params = request.fetch("params")
          selection = @configuration.resolve(project: params.fetch("project"), role: params.fetch("role"), session: identity)
          # Construct a new closed request from authorized selectors. No
          # runtime, terminal binding or host-principal override is forwarded.
          message = {"id" => request.fetch("id"), "method" => METHOD, "params" => {
            "name" => params.fetch("name"), "workspace_id" => params.fetch("workspace_id"),
            "project" => selection.project, "role" => selection.role}}
          @transport.call(message, identity: identity, timeout: 60)
        end
      end
    end
  end
end
