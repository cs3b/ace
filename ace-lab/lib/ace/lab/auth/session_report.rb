# frozen_string_literal: true

require_relative "session_peer"
require_relative "../molecules/install_manifest_loader"
require "ace/runtime/molecules/protected_socket"
require "etc"

module Ace
  module Lab
    module Auth
      # Projects an authenticated session's report onto its root-bound terminal.
      # This is not a general Herdr API proxy and never grants resume commands.
      class SessionReport
        SO_PEERCRED = 17 # Linux socket peer credentials.
        METHODS = %w[pane.report_agent pane.report_agent_session].freeze
        COMMON = %w[pane_id agent source seq agent_session_id agent_session_path].freeze

        def initialize(loader: -> { Molecules::InstallManifestLoader.load }, account: Etc.method(:getpwnam),
          manager: ->(unit) { Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: SessionPeer::SLICE, service_unit: unit) })
          @loader, @account, @manager = loader, account, manager
        end

        def call(request, identity:)
          message = self.class.project(request, identity: identity)
          endpoint = @loader.call.fetch("session_runtime").fetch("herdr")
          account = @account.call(endpoint.fetch("account"))
          raise Error, "native report account must be a non-session host account" if account.uid.zero? || SessionPeer::DYNAMIC_UIDS.cover?(account.uid)
          path = endpoint.fetch("socket")
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(path, owner: account.uid)
          before = wire.socket_identity(path)
          wire.connect(path) do |socket|
            _, uid, gid = socket.getsockopt(Socket::SOL_SOCKET, SO_PEERCRED).data.unpack("i!3")
            unless uid == account.uid && gid == account.gid && wire.socket_identity(path) == before
              raise Error, "native report endpoint identity changed"
            end
            live!(identity)
            wire.write(socket, message, deadline: wire.deadline)
            response = wire.read(wire::Ingress.new(socket), deadline: wire.deadline)
            live!(identity)
            unless response.is_a?(Hash) && response["id"] == message["id"] &&
                ((response.key?("result") && !response.key?("error")) || (response.key?("error") && !response.key?("result")))
              raise Error, "native report acknowledgement differs"
            end
            response
          end
        rescue KeyError, ArgumentError, SystemCallError, IOError, SecurityError, Ace::Runtime::Error
          raise Error, "authenticated session reporting is unavailable"
        end

        private

        def live!(identity)
          handles = [identity.pidfd, identity.main_pidfd]
          unless handles.all? { |handle| handle.is_a?(IO) && !handle.closed? } && !IO.select(handles, nil, nil, 0) &&
              @manager.call(identity.unit).unit_for_pidfd(handle: identity.main_pidfd) ==
                {"unit" => identity.unit, "invocation_id" => identity.invocation_id}
            raise Error, "reporting session invocation is no longer live"
          end
        end

        public

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
