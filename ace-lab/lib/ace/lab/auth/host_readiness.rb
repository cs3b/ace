# frozen_string_literal: true
require_relative "session_launch_peer"
require_relative "session_readiness"

module Ace::Lab::Auth
  # Host operator counterpart to the session-scoped native readiness query.
  # Scope is authorized before target discovery; all file access stays with
  # the existing authenticated target reader and installed owner evaluator.
  class HostReadiness
    def initialize(peer: SessionLaunchPeer.new, transport: SessionNativeTransport.new, readiness: nil)
      @peer, @transport = peer, transport
      @readiness = readiness || SessionReadiness.new(transport: transport)
    end

    def call(socket, request:)
      self.class.validate!(request)
      _, uid, = socket.getsockopt(Socket::SOL_SOCKET, SessionLaunchPeer::SO_PEERCRED).data.unpack("i!3")
      raise Refusal, "host readiness requires an operator" if SessionPeer::DYNAMIC_UIDS.cover?(uid)
      @peer.with_selection(socket, project: request.fetch("project"), role: request.fetch("role")) do |selection, handle|
        caller = SessionNativeTransport::HostCaller.new(pidfd: handle)
        id = "ace-lab:host-readiness"
        response = @transport.call({"id" => id, "method" => "agent.get",
          "params" => {"target" => request.fetch("terminal_id")}}, identity: caller)
        agent = response.dig("result", "agent")
        unless !response.key?("error") && agent.is_a?(Hash) &&
            agent["terminal_id"] == request.fetch("terminal_id") &&
            agent["isolated_session"] == {"project" => selection.project, "role" => selection.role}
          raise Error, "operator readiness target differs from granted scope"
        end
        @readiness.call(agent: agent, identity: caller, request_id: id)
      end
    end

    def self.validate!(request)
      unless request.is_a?(Hash) && request.keys.sort == %w[action project role terminal_id] &&
          request["action"] == "readiness" && %w[lab-overseer project-overseer].include?(request["role"]) &&
          request["project"].is_a?(String) && request["project"].match?(/\A[a-z][a-z0-9_-]{0,31}\z/) &&
          request["terminal_id"].is_a?(String) && SessionPeer::TERMINAL_ID.match?(request["terminal_id"])
        raise Error, "invalid operator readiness request"
      end
    end
  end
end
