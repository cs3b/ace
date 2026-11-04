# frozen_string_literal: true

require_relative "session_configuration"
require "etc"
require "fcntl"

module Ace
  module Lab
    module Auth
      # The host operator is authorized by kernel socket credentials; an
      # isolated caller must satisfy the stricter system-session contract.
      # Neither identity nor executable selection is accepted from JSON.
      class SessionLaunchPeer
        SO_PEERCRED = 17 # Linux; Ruby does not expose this constant on macOS.
        def initialize(configuration: SessionConfiguration.new, sessions: SessionPeer.new,
          account: Etc.method(:getpwuid))
          @configuration, @sessions, @account = configuration, sessions, account
        end

        def with_selection(socket, project:, role:)
          handle = IO.for_fd(socket.getsockopt(Socket::SOL_SOCKET, SessionPeer::SO_PEERPIDFD).int, autoclose: true)
          handle.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          raise Error, "launch caller has exited" if IO.select([handle], nil, nil, 0)
          _pid, uid, gid = socket.getsockopt(Socket::SOL_SOCKET, SO_PEERCRED).data.unpack("i!3")
          if SessionPeer::DYNAMIC_UIDS.cover?(uid)
            session = @sessions.authenticate(socket)
            selection = @configuration.resolve(project: project, role: role, session: session)
          else
            account = @account.call(uid)
            unless account.uid == uid && account.gid == gid
              raise Error, "host launch account differs from socket credentials"
            end
            selection = @configuration.resolve(project: project, role: role, principal: account.name)
          end
          raise Error, "launch caller has exited" if IO.select([handle], nil, nil, 0)
          yield selection, handle
        ensure
          session&.close
          handle&.close unless handle&.closed?
        end
      end
    end
  end
end
