# frozen_string_literal: true

require "open3"
require "timeout"

module Ace
  module Herdr
    module Molecules
      # Runs a child process in its own process group with a real deadline.
      # Pipes drain with bounded memory and a stalled child is killed at the
      # deadline, so the caller never blocks in cleanup past the timeout the
      # way an Open3.capture3 + Timeout.timeout combination can.
      module BoundedProcess
        # Immutable outcome of one bounded child run.
        Result = Struct.new(:stdout, :stderr, :status, :oversized)

        # A SystemCallError raised while the child was already running (pipe
        # I/O after launch). Distinct from spawn failures: the child exists,
        # so the caller cannot classify the run as pre-launch.
        class PostLaunchError < StandardError
          def initialize(message)
            super("post-launch process failure: #{message}")
          end
        end

        module_function

        # @param argv [Array<String>] child argv (no shell)
        # @param stdin_data [String] payload written to the child's stdin
        # @param timeout_s [Numeric] wall-clock deadline for the whole run
        # @param output_limit [Integer] per-stream retained byte cap
        # @return [Result] stdout/stderr are capped; oversized reports truncation
        # @raise [Timeout::Error] when the child outlives the deadline (killed)
        # @raise [SystemCallError] spawn failures only (child never launched)
        # @raise [PostLaunchError] SystemCallError while the child was live
        def call(argv, stdin_data: "", timeout_s:, output_limit: 65_536)
          Open3.popen3(*argv, pgroup: true) do |stdin, stdout, stderr, waiter|
            begin
              run_loop(stdin, stdout, stderr, waiter,
                stdin_data: stdin_data, timeout_s: timeout_s, output_limit: output_limit)
            rescue SystemCallError => e
              # The child was already spawned: an I/O failure now cannot be
              # rewound into a pre-launch classification.
              raise PostLaunchError, e.message
            end
          end
        end

        def run_loop(stdin, stdout, stderr, waiter, stdin_data:, timeout_s:, output_limit:)
          payload = stdin_data.to_s
          sent = 0
          stdin_closed = payload.empty?
          stdin.close if stdin_closed
          buffers = {stdout => +"", stderr => +""}
          streams = [stdout, stderr]
          oversized = false
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_s
            buffers = {stdout => +"", stderr => +""}
            streams = [stdout, stderr]
            oversized = false
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_s

            until streams.empty? && stdin_closed && waiter.join(0)
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              if remaining <= 0
                kill_group(waiter)
                raise Timeout::Error, "process did not finish within #{timeout_s}s"
              end

              ready = IO.select(streams, stdin_closed ? [] : [stdin], nil, [remaining, 0.02].min)
              next unless ready

              ready.first.each do |io|
                chunk = io.read_nonblock(4096, exception: false)
                if chunk.nil?
                  io.close
                  streams.delete(io)
                elsif chunk != :wait_readable
                  buffer = buffers.fetch(io)
                  available = output_limit - buffer.bytesize
                  oversized = true if chunk.bytesize > available
                  buffer << chunk.byteslice(0, available) if available.positive?
                end
              end

              next if stdin_closed || !ready[1].to_a.include?(stdin)

              begin
                # Nonblocking with partial writes: a child that stops reading
                # must never trap us inside one large stdin.write; the loop
                # re-checks the deadline between write attempts.
                written = stdin.write_nonblock(payload.byteslice(sent, payload.bytesize - sent),
                  exception: false)
                sent += written if written != :wait_writable
              rescue Errno::EPIPE, IOError
                sent = payload.bytesize
              end
              if sent >= payload.bytesize
                stdin.close
                stdin_closed = true
              end
            end

          Result.new(buffers.fetch(stdout), buffers.fetch(stderr), waiter.value, oversized)
        end

        def kill_group(waiter)
          Process.kill("KILL", -waiter.pid)
        rescue Errno::ESRCH
          nil
        end
      end
    end
  end
end
