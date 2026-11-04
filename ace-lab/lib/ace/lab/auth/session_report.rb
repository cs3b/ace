# frozen_string_literal: true

require_relative "session_peer"
require_relative "session_native_transport"
require_relative "../molecules/install_manifest_loader"
require "ace/runtime/molecules/protected_socket"
require "etc"

module Ace
  module Lab
    module Auth
      # Projects an authenticated session's report onto its root-bound terminal.
      # This is not a general Herdr API proxy and never grants resume commands.
      class SessionReport
        METHODS = %w[pane.report_agent pane.report_agent_session].freeze
        COMMON = %w[pane_id agent source seq agent_session_id agent_session_path].freeze

        def initialize(**options)
          @transport = SessionNativeTransport.new(**options)
        end

        def call(request, identity:)
          @transport.call(self.class.project(request, identity: identity), identity: identity)
        end

        def self.validate!(request)
          unless request.is_a?(Hash) && request.keys.sort == %w[id method params] &&
              METHODS.include?(request["method"]) && text?(request["id"], 512) && request["params"].is_a?(Hash)
            raise Error, "invalid session report envelope"
          end
          params = request.fetch("params")
          state = request["method"] == "pane.report_agent"
          allowed = COMMON + (state ? %w[state message] : %w[session_start_source])
          unless (params.keys - allowed).empty? && params["agent"] == "pi" && params["source"] == "herdr:pi" &&
              text?(params["pane_id"], 128) && params["seq"].is_a?(Integer) && params["seq"].between?(1, 9_007_199_254_740_991) &&
              (!state || %w[working blocked idle].include?(params["state"]))
            raise Error, "invalid session report fields"
          end
          %w[agent_session_id agent_session_path message session_start_source].each do |key|
            raise Error, "invalid session report text" if params.key?(key) && !text?(params[key], 4096)
          end
          true
        end

        def self.text?(value, limit)
          value.is_a?(String) && value.valid_encoding? && value.bytesize.between?(1, limit) && !value.match?(/[[:cntrl:]]/)
        end
        private_class_method :text?

        def self.project(request, identity:)
          validate!(request)
          unless identity.is_a?(SessionPeer::Identity) && identity.terminal_id.is_a?(String) &&
              SessionPeer::TERMINAL_ID.match?(identity.terminal_id)
            raise Error, "session has no authenticated terminal binding"
          end
          params = request.fetch("params").dup
          # A client may only report its bound terminal, even though the value
          # used downstream always comes from the authenticated unit.
          raise Error, "session report targets another terminal" unless params["pane_id"] == identity.terminal_id
          if (path = params["agent_session_path"])
            root = File.join(identity.runtime_dir, "pi", "sessions")
            unless path.start_with?(root + "/") && File.expand_path(path) == path
              raise Error, "session report path escapes private Pi sessions"
            end
          end
          params["pane_id"] = identity.terminal_id
          request.merge("params" => params)
        end
      end
    end
  end
end
