# frozen_string_literal: true
require_relative "session_peer"
require_relative "session_evidence_file"
require_relative "session_eyes_evaluator"
require_relative "session_native_transport"
require_relative "session_configuration"

module Ace
  module Lab
    module Auth
      # Called only after SessionControl authorizes the original caller's
      # access to this native agent. Target identity is independently attested.
      class SessionReadiness
        def initialize(peer: SessionPeer.new, reader: SessionEvidenceFile.new, evaluator: SessionEyesEvaluator.new,
          transport: SessionNativeTransport.new, loader: -> { Molecules::InstallManifestLoader.load })
          @peer, @reader, @evaluator, @transport, @loader = peer, reader, evaluator, transport, loader
        end

        def call(agent:, identity:, request_id:)
          selection = agent.fetch("isolated_session")
          unless %w[lab-overseer project-overseer].include?(selection.fetch("role"))
            raise Error, "eyes readiness requires an overseer session"
          end
          terminal = agent.fetch("terminal_id")
          origin = origin_for(terminal, identity, request_id)
          target = @peer.authenticate_process(origin.fetch("child"))
          project = SessionConfiguration.scope(@loader.call, project: selection.fetch("project"), role: selection.fetch("role"))
          unless project && target.terminal_id == terminal && target.role == selection.fetch("role") &&
              target.project_root == project.fetch("path")
            raise Error, "target session does not match native project or role"
          end
          @peer.live!(target)
          session = agent["agent_session"]
          result = {"ready" => false, "terminal_id" => terminal, "invocation_id" => target.invocation_id,
            "root" => target.project_root, "role" => target.role}
          return result unless session.is_a?(Hash) && session["agent"] == "pi" && session["kind"] == "path"
          file = @reader.open(session.fetch("value"), identity: target)
          @peer.live!(target)
          context = {"pane" => agent.fetch("pane_id"), "terminal_id" => terminal, "root" => target.project_root,
            "session_path" => session.fetch("value"), "role" => target.role,
            "process" => origin.fetch("child").slice("pid", "uid", "started_at")}
          ready = @evaluator.call(context, file: file)
          @peer.live!(target)
          after = native("agent.get", {"target" => terminal}, identity, request_id).dig("result", "agent")
          keys = %w[terminal_id isolated_session agent_session]
          unless after.is_a?(Hash) && after.slice(*keys) == agent.slice(*keys) &&
              origin_for(terminal, identity, request_id) == origin
            raise Error, "native session changed during readiness evaluation"
          end
          @peer.live!(target)
          result.merge("ready" => ready)
        rescue KeyError, TypeError, NoMethodError
          raise Error, "session readiness evidence is incomplete"
        ensure
          file&.close
          target&.close
        end

        private

        def native(method, params, identity, id)
          response = @transport.call({"id" => id, "method" => method, "params" => params}, identity: identity)
          raise Error, "native readiness observation failed" if response.key?("error")
          response
        end

        def origin_for(terminal, identity, id)
          info = native("pane.process_info", {"pane_id" => terminal}, identity, id).dig("result", "process_info")
          origin = info.is_a?(Hash) && info["guarded_prompt_origin"]
          unless info.is_a?(Hash) && info["guarded_prompt"] == true && origin.is_a?(Hash) && origin["terminal_id"] == terminal
            raise Error, "target has no live guarded process"
          end
          origin
        end
      end
    end
  end
end
