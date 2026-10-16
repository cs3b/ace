# frozen_string_literal: true

require "socket"
require "ace/runtime/molecules/process_identity"
require "ace/herdr/molecules/bounded_observation"

module Ace
  module Assign
    module Authority
      # Ordinary UNIX peer attribution. This is not a protected launch observer:
      # it confers no Yama, capability, cgroup or descendant-closure guarantee.
      class OrdinaryPeer
        def initialize(identity: nil)
          @identity = identity
        end

        def capture(socket, deadline: default_deadline)
          identity = identity_observer(deadline)
          uid, gid = socket.getpeereid
          pid = if RUBY_PLATFORM.include?("darwin")
            socket.getsockopt(0, 2).int # SOL_LOCAL / LOCAL_PEERPID
          elsif Socket.const_defined?(:SO_PEERCRED)
            observed_pid, observed_uid, observed_gid = socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_PEERCRED).data.unpack("i!3")
            unavailable! unless [observed_uid, observed_gid] == [uid, gid]
            observed_pid
          end
          value = identity.capture(pid)
          unavailable! unless value && value["uid"] == uid && socket.getpeereid == [uid, gid] && identity.capture(pid) == value
          value.merge("gid" => gid).freeze
        rescue SystemCallError, IOError, SocketError, NotImplementedError
          unavailable!
        end

        def live!(peer, deadline: default_deadline)
          unavailable! unless peer.is_a?(Hash) && identity_observer(deadline).capture(peer["pid"]) == peer.slice("pid", "uid", "started_at", "host")
          peer
        end

        private

        def default_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5

        def identity_observer(deadline)
          @identity || Ace::Runtime::Molecules::ProcessIdentity.new(
            executor: Ace::Herdr::Molecules::BoundedObservation.new(deadline: deadline))
        end

        def unavailable!
          raise AttemptErrors::UnauthorizedIdentity, "ordinary kernel peer is unavailable or changed"
        end
      end
    end
  end
end
