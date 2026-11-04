# frozen_string_literal: true
require_relative "session_configuration"
require_relative "session_native_transport"

module Ace
  module Lab
    module Auth
      # Narrow supervisory API. Native owns terminal identity and process
      # admission; the issuer owns the original caller's project authority.
      class SessionControl
        METHODS = %w[agent.list agent.get agent.prompt].freeze
        PUBLIC_FIELDS = %w[terminal_id name agent agent_status workspace_id tab_id pane_id
          launch_pending interactive_ready state_change_seq completion_seq revision isolated_session].freeze

        def initialize(configuration: SessionConfiguration.new, transport: SessionNativeTransport.new)
          @configuration, @transport = configuration, transport
        end

        def call(request, identity:)
          self.class.validate!(request)
          id, method, params = request.values_at("id", "method", "params")
          if method == "agent.list"
            result = native(id, method, {}, identity).fetch("result")
            agents = result.fetch("agents").select { |agent| authorized?(agent, identity) }
            return {"id" => id, "result" => {"type" => "agent_list", "agents" => agents.map { |agent| project(agent) }}}
          end
          agent = native(id, "agent.get", {"target" => params.fetch("target")}, identity).dig("result", "agent")
          raise Error, "session target is unavailable" unless authorized?(agent, identity)
          if method == "agent.get"
            return {"id" => id, "result" => {"type" => "agent_info", "agent" => project(agent)}}
          end
          unless %w[lab-overseer project-overseer].include?(identity.role) && agent["terminal_id"] != identity.terminal_id
            raise Error, "session cannot prompt this target"
          end
          terminal = agent.fetch("terminal_id")
          process = native(id, "pane.process_info", {"pane_id" => terminal}, identity).dig("result", "process_info")
          origin = process.is_a?(Hash) && process["guarded_prompt_origin"]
          unless process.is_a?(Hash) && process["guarded_prompt"] == true && origin.is_a?(Hash) &&
              origin["terminal_id"] == terminal && SessionPeer::DYNAMIC_UIDS.cover?(origin.dig("child", "uid"))
            raise Error, "isolated target has no live guarded runtime"
          end
          # Native rechecks this exact incarnation immediately before writing;
          # a restart between lookup and submission cannot receive the prompt.
          reply = native(id, method, {"target" => terminal, "text" => params.fetch("text"), "expected_origin" => origin}, identity)
          result = reply.fetch("result")
          {"id" => id, "result" => {"type" => "agent_prompted", "agent" => project(result.fetch("agent")),
            "submission" => result["submission"]}.compact}
        rescue KeyError, TypeError, NoMethodError
          raise Error, "session control response is incomplete"
        end

        private

        def native(id, method, params, identity)
          response = @transport.call({"id" => id, "method" => method, "params" => params}, identity: identity)
          raise Error, "session target operation failed" if response.key?("error")
          response
        end

        def project(agent)
          agent.select { |key, _| PUBLIC_FIELDS.include?(key) }
        end

        def authorized?(agent, identity)
          return false unless agent.is_a?(Hash) && agent["terminal_id"].is_a?(String) &&
            SessionPeer::TERMINAL_ID.match?(agent["terminal_id"]) && agent["isolated_session"].is_a?(Hash)
          return true if agent["terminal_id"] == identity.terminal_id
          selection = agent.fetch("isolated_session")
          @configuration.resolve(project: selection.fetch("project"), role: selection.fetch("role"), session: identity)
          true
        rescue Error, KeyError
          false
        end

        def self.validate!(request)
          unless request.is_a?(Hash) && request.keys.sort == %w[id method params] && METHODS.include?(request["method"]) &&
              request["id"].is_a?(String) && request["id"].bytesize.between?(1, 512) && !request["id"].match?(/[[:cntrl:]]/) &&
              request["params"].is_a?(Hash)
            raise Error, "invalid session control envelope"
          end
          params = request.fetch("params")
          fields = case request["method"]
          when "agent.list" then []
          when "agent.get" then %w[target]
          else %w[target text]
          end
          raise Error, "invalid session control fields" unless params.keys.sort == fields
          if params.key?("target") && !(params["target"].is_a?(String) && params["target"].match?(/\A[a-zA-Z0-9_.:-]{1,128}\z/))
            raise Error, "invalid session target"
          end
          if params.key?("text") && !(params["text"].is_a?(String) && params["text"].valid_encoding? &&
              params["text"].bytesize.between?(1, 12_000) && !params["text"].strip.empty?)
            raise Error, "invalid session prompt"
          end
        end
      end
    end
  end
end
