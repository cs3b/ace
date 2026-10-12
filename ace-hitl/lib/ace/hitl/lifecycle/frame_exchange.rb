# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The deadline-bounded frame exchange of a lifecycle client (spec
      # 8wq.t.34i, shared by the Unix and the TLS 1.3/TCP transports):
      # one newline-delimited request frame out, one bounded response
      # frame back, size and deadline rules identical on both transports.
      # The includer supplies `@deadline_seconds` and implements
      # `#request(op, params, deadline:)`.
      module FrameExchange
        private

        def await!(socket, direction, deadline)
          remaining = deadline && deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise TransportError, "HITL boundary deadline exceeded" if remaining && remaining <= 0
          readable, writable = direction == :read ? [[socket], nil] : [nil, [socket]]
          raise TransportError, "HITL boundary deadline exceeded" unless IO.select(readable, writable, nil, remaining)
        end

        def write_frame!(socket, frame, deadline)
          offset = 0
          while offset < frame.bytesize
            await!(socket, :write, deadline)
            written = socket.write_nonblock(frame.byteslice(offset..), exception: false)
            next if written == :wait_writable
            raise TransportError, "HITL boundary closed before request" unless written.is_a?(Integer) && written.positive?
            offset += written
          end
        end

        def read_line(socket, deadline)
          data = +""
          loop do
            remaining = deadline && deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise TransportError, "HITL boundary deadline exceeded" if remaining && remaining <= 0
            ready = IO.select([socket], nil, nil, remaining)
            raise TransportError, "HITL boundary deadline exceeded" unless ready

            chunk = socket.read_nonblock(4096, exception: false)
            raise TransportError, "HITL boundary closed before responding" if chunk.nil?
            # A spurious not-ready result goes back to select; only the
            # deadline ends the wait (review 8x32r9b4).
            next if chunk == :wait_readable

            data << chunk
            if data.bytesize > Protocol::MAX_FRAME_BYTES
              raise TransportError, "HITL boundary response is too large"
            end
            return data if data.include?("\n")
          end
        end

        # A consume without a timeout waits indefinitely at the client
        # boundary too; every bounded call gets a deadline slightly
        # beyond its own wait so the server result wins the race.
        def request_deadline(op, params, selected)
          if !selected.nil? && (!selected.is_a?(Numeric) || !selected.finite?)
            raise TransportError, "HITL boundary deadline is invalid"
          end
          local = deadline_for(op, params)
          [selected, local].compact.min
        end

        def deadline_for(op, params)
          if op == "consume" && Integer(params["timeout"]) <= 0
            nil
          else
            Process.clock_gettime(Process::CLOCK_MONOTONIC) + @deadline_seconds + Integer(params["timeout"])
          end
        rescue ArgumentError, TypeError
          Process.clock_gettime(Process::CLOCK_MONOTONIC) + @deadline_seconds
        end
      end
    end
  end
end
