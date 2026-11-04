# frozen_string_literal: true
require_relative "session_peer"
require_relative "../molecules/install_manifest_loader"
require "ace/runtime/molecules/protected_socket"
require "etc"

module Ace
  module Lab
    module Auth
      # Internal transport for authorized operations only. Its callers own
      # the closed operation schemas; this is never exposed as a raw proxy.
      class SessionNativeTransport
        HostCaller = Data.define(:pidfd)
        SO_PEERCRED = 17
        def initialize(loader: -> { Molecules::InstallManifestLoader.load }, account: Etc.method(:getpwnam),
          manager: ->(unit) { Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: SessionPeer::SLICE, service_unit: unit) })
          @loader, @account, @manager = loader, account, manager
        end

        def call(message, identity:, timeout: 5)
          endpoint = @loader.call.fetch("session_runtime").fetch("herdr")
          account = @account.call(endpoint.fetch("account"))
          raise Error, "native control account must be a non-session host account" if account.uid.zero? || SessionPeer::DYNAMIC_UIDS.cover?(account.uid)
          path = endpoint.fetch("socket")
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(path, owner: account.uid)
          before = wire.socket_identity(path)
          deadline = wire.deadline(timeout)
          wire.connect(path, deadline: deadline) do |socket|
            _, uid, gid = socket.getsockopt(Socket::SOL_SOCKET, SO_PEERCRED).data.unpack("i!3")
            unless uid == account.uid && gid == account.gid && wire.socket_identity(path) == before
              raise Error, "native control endpoint identity changed"
            end
            live!(identity)
            wire.write(socket, message, deadline: deadline)
            response = wire.read(wire::Ingress.new(socket), deadline: deadline)
            live!(identity)
            unless response.is_a?(Hash) && response["id"] == message["id"] &&
                ((response.key?("result") && !response.key?("error")) || (response.key?("error") && !response.key?("result")))
              raise Error, "native control acknowledgement differs"
            end
            response
          end
        rescue KeyError, ArgumentError, SystemCallError, IOError, SecurityError, Ace::Runtime::Error
          raise Error, "authenticated session control is unavailable"
        end

        private

        def live!(identity)
          if identity.is_a?(HostCaller)
            handle = identity.pidfd
            unless handle.is_a?(IO) && !handle.closed? && !IO.select([handle], nil, nil, 0)
              raise Error, "calling host operator is no longer live"
            end
            return true
          end
          handles = [identity.pidfd, identity.main_pidfd]
          unless handles.all? { |handle| handle.is_a?(IO) && !handle.closed? } && !IO.select(handles, nil, nil, 0) &&
              @manager.call(identity.unit).unit_for_pidfd(handle: identity.main_pidfd) ==
                {"unit" => identity.unit, "invocation_id" => identity.invocation_id}
            raise Error, "calling session invocation is no longer live"
          end
        end
      end
    end
  end
end
