# frozen_string_literal: true

require "socket"
require_relative "issuer_request"

module Ace
  module Lab
    module Auth
      # One systemd invocation owns all connections. Forked handlers isolate
      # namespace operations; they are children of this service, not separate
      # issuers. Any lost handler stops admission and triggers ExecStopPost.
      class IssuerServer
        MAX_CONNECTIONS = 64
        MAX_SUPERVISIONS = 64

        def initialize(handler: IssuerRequest.new, max_connections: MAX_CONNECTIONS, max_supervisions: MAX_SUPERVISIONS)
          @handler = handler
          unless [max_connections, max_supervisions].all? { |limit| limit.is_a?(Integer) && limit.positive? }
            raise ArgumentError, "issuer capacity must be positive"
          end
          @max_connections, @max_supervisions = max_connections, max_supervisions
        end

        def run(listener, invocation:)
          unless invocation.is_a?(String) && invocation.match?(/\A[0-9a-f]{32}\z/) && invocation != "0" * 32
            raise ArgumentError, "invalid issuer invocation"
          end
          children = {}
          socket = nil
          loop do
            children.keys.each do |pid|
              result = Process.waitpid2(pid, Process::WNOHANG)
              next unless result
              children.delete(pid).fetch(:notice).close
              raise Error, "issuer handler failed; lease recovery is required" unless result.last.success?
            end
            # This is host process supervision, not an agent/model wake loop.
            pending = children.values.select { |child| child[:phase] == :connection }
            ready = IO.select([listener, *pending.map { |child| child[:notice] }], nil, nil, 0.1)
            next unless ready
            pending.each do |child|
              next unless ready.first.include?(child[:notice])
              notice = child[:notice].read_nonblock(1, exception: false)
              if notice == "S"
                child[:phase] = :supervision
                child[:notice].write("A")
              end
              child[:phase] = :exiting if notice.nil?
            end
            next unless ready.first.include?(listener)
            socket, = listener.accept
            connections = children.values.count { |child| child[:phase] != :supervision }
            if connections >= @max_connections
              socket.close
              next
            end
            # Pending connections reserve potential request capacity. Long
            # lease supervision never consumes exec/status/revoke capacity.
            allow_request = children.size < @max_supervisions
            notice_reader, notice_writer = UNIXSocket.pair
            pid = fork do
              listener.close
              notice_reader.close
              children.each_value { |child| child.fetch(:notice).close }
              supervising = lambda do
                notice_writer.write("S")
                unless IO.select([notice_writer], nil, nil, 5) && notice_writer.read(1) == "A"
                  raise Error, "issuer did not acknowledge supervision"
                end
                notice_writer.close
              end
              outcome = @handler.call(socket, invocation: invocation, allow_request: allow_request, supervising: supervising)
              exit!(outcome == :cleanup_failed ? 1 : 0)
            rescue StandardError
              exit! 1
            end
            notice_writer.close
            children[pid] = {notice: notice_reader, phase: :connection}
            socket.close
          end
        ensure
          socket&.close unless socket&.closed?
          # systemd KillMode=control-group contains all descendants before
          # ExecStopPost. Direct callers must also leave no handler behind.
          children&.each_key do |pid|
            Process.kill("TERM", pid)
          rescue Errno::ESRCH
            nil
          end
          children&.each_value { |child| child.fetch(:notice).close }
          children&.each_key do |pid|
            Process.waitpid(pid)
          rescue Errno::ECHILD
            nil
          end
        end
      end
    end
  end
end
