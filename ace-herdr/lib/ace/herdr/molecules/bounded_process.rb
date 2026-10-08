# frozen_string_literal: true

require "fiddle"
require "timeout"
require "fcntl"

module Ace
  module Herdr
    module Molecules
      # Runs a child process in its own process group with a real deadline.
      # Pipes drain with bounded memory and a stalled child is killed at the
      # execution deadline. Cleanup adds at most one second of owned reaping;
      # unconfirmed cleanup transfers eventual reaping and reports uncertainty.
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

        CLEANUP_TIMEOUT = 1.0
        DARWIN_GROUP_PID_LIMIT = 4096

        # No detached waiter may reap this leader before its owned group is
        # signalled: the unreaped child pins its PID even after normal exit.
        class OwnedChild
          attr_reader :pid

          def initialize(pid = nil)
            @pid, @status, @owned = pid, nil, !pid.nil?
            @group_signalled = false
          end

          def start!(command, options)
            raise PostLaunchError, "original child handle cannot be replaced" if started?
            @pid = Process.spawn(*command, **options)
            @owned = true
          end

          def group_signalled? = @group_signalled

          def group_signalled!
            raise PostLaunchError, "original child ownership is unavailable" unless alive?
            @group_signalled = true
          end

          def started?
            !@pid.nil?
          end

          def alive?
            @owned && @status.nil?
          end

          def join(timeout)
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
            loop do
              unless @status
                result = Process.waitpid2(@pid, Process::WNOHANG)
                @status = result.last if result
              end
              return self if @status
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              return nil unless remaining.positive?
              sleep [remaining, 0.002].min
            end
          rescue Errno::ECHILD
            @owned = false
            raise PostLaunchError, "original child ownership is unavailable"
          end

          def exited?
            BoundedProcess.nonreaping_exit?(@pid)
          rescue Errno::ECHILD
            @owned = false
            raise PostLaunchError, "original child ownership is unavailable"
          end

          def release_to_reaper!
            raise PostLaunchError, "original child ownership is unavailable" unless alive?
            Process.detach(@pid)
            @owned = false
          rescue Errno::ECHILD
            @owned = false
            raise PostLaunchError, "original child ownership is unavailable"
          end

          def value
            raise PostLaunchError, "owned child has not been reaped" unless @status
            @status
          end
        end

        module_function

        # @param argv [Array<String>] child argv (no shell)
        # @param stdin_data [String] payload written to the child's stdin
        # @param timeout_s [Numeric] wall-clock deadline for the whole run
        # @param output_limit [Integer] stdout retained byte cap
        # @param stderr_limit [Integer] stderr retained byte cap (defaults to stdout cap)
        # @param cleanup_group [Boolean] signal owned group after observed leader exit, before reaping
        # @return [Result] stdout/stderr are capped; oversized reports truncation
        # @raise [Timeout::Error] when the child outlives the deadline (killed)
        # @raise [SystemCallError] spawn failures only (child never launched)
        # @raise [PostLaunchError] SystemCallError while the child was live
        def call(argv, stdin_data: "", timeout_s:, output_limit: 65_536, environment: nil, chdir: nil, descriptor_mapping: {}, stderr_limit: output_limit, cleanup_group: false)
          if environment && (!environment.is_a?(Hash) || !environment.all? { |key, value| key.is_a?(String) && value.is_a?(String) })
            raise ArgumentError, "bounded process environment must be explicit strings"
          end
          if chdir && (!chdir.is_a?(String) || !chdir.start_with?("/"))
            raise ArgumentError, "bounded process working directory must be absolute"
          end
          unless descriptor_mapping.is_a?(Hash) && descriptor_mapping.size <= 16 &&
              descriptor_mapping.all? { |descriptor, handle|
                descriptor.is_a?(Integer) && descriptor.between?(3, 63) &&
                  handle.is_a?(File) && !handle.closed? && handle.stat.file? &&
                  (handle.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE) == Fcntl::O_RDONLY
              }
            raise ArgumentError, "bounded process descriptors must be explicit read-only regular files"
          end
          unless [output_limit, stderr_limit].all? { |limit| limit.is_a?(Integer) && limit.positive? } &&
              [true, false].include?(cleanup_group)
            raise ArgumentError, "bounded process limits and cleanup mode are invalid"
          end
          selected_descriptors = descriptor_mapping.dup.freeze
          command = environment ? [environment, *argv] : argv
          options = {pgroup: true, close_others: true}.merge(selected_descriptors)
          options[:chdir] = chdir if chdir
          options[:unsetenv_others] = true if environment
          handles = []
          waiter = nil
          begin
            child_stdin, stdin = IO.pipe
            handles.concat([child_stdin, stdin])
            stdout, child_stdout = IO.pipe
            handles.concat([stdout, child_stdout])
            stderr, child_stderr = IO.pipe
            handles.concat([stderr, child_stderr])
            handles.each(&:binmode)
            waiter = OwnedChild.new
            begin
              waiter.start!(command, options.merge(in: child_stdin, out: child_stdout, err: child_stderr))
              close_error = close_handles([child_stdin, child_stdout, child_stderr])
              raise close_error if close_error
              run_loop(stdin, stdout, stderr, waiter, stdin_data: stdin_data,
                timeout_s: timeout_s, output_limit: output_limit, stderr_limit: stderr_limit,
                cleanup_group: cleanup_group)
            rescue SystemCallError, IOError => error
              raise unless waiter.started?
              raise PostLaunchError, error.message
            ensure
              close_error = close_handles(handles)
              # Closing one pipe cannot prevent original-child cleanup.
              cleanup_child!(waiter) if waiter.started?
              raise PostLaunchError.new(close_error.message), cause: close_error if close_error && waiter.started?
            end
          ensure
            close_handles(handles)
          end
        end

        def close_handles(handles)
          first_error = nil
          handles.each do |io|
            begin
              io.close unless io.closed?
            rescue SystemCallError, IOError => error
              first_error ||= error
            end
          end
          first_error
        end

        def run_loop(stdin, stdout, stderr, waiter, stdin_data:, timeout_s:, output_limit:, stderr_limit:, cleanup_group:)
          payload = stdin_data.to_s
          sent = 0
          stdin_closed = payload.empty?
          stdin.close if stdin_closed
          buffers = {stdout => +"", stderr => +""}
          streams = [stdout, stderr]
          oversized = false
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_s
          group_cleaned = false

          loop do
            if streams.empty? && stdin_closed
              if cleanup_group && !group_cleaned && waiter.exited?
                kill_group(waiter)
                group_cleaned = true
              end
              break if (!cleanup_group || group_cleaned) && waiter.join(0)
            end
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            if remaining <= 0
              kill_group(waiter)
              raise Timeout::Error, "process did not finish within #{timeout_s}s"
            end

            ready = IO.select(streams, stdin_closed ? [] : [stdin], nil, [remaining, 0.02].min)
            next unless ready

            ready.first.each do |io|
              begin
                chunk = io.read_nonblock(4096, exception: false)
              rescue Errno::EINTR
                # No bytes were returned. Keep the original child/pipe and
                # return to the same absolute-deadline loop before reading again.
                next
              end
              if chunk.nil?
                io.close
                streams.delete(io)
              elsif chunk != :wait_readable
                buffer = buffers.fetch(io)
                limit = io.equal?(stderr) ? stderr_limit : output_limit
                available = limit - buffer.bytesize
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

        def cleanup_child!(waiter)
          return unless waiter.alive?
          signal_error = nil
          begin
            kill_group(waiter)
          rescue SystemCallError => error
            signal_error = error
          end
          unless waiter.join(CLEANUP_TIMEOUT)
            # Transfer only this still-exclusively-owned child to an eventual
            # reaper. No signal or positive result can use it after transfer.
            waiter.release_to_reaper!
            raise PostLaunchError, "owned child cleanup could not be confirmed within deadline"
          end
          raise PostLaunchError.new(signal_error.message), cause: signal_error if signal_error
        end

        # POSIX waitid observes only this original child's termination and
        # leaves it waitable. No stream/timeout/PID liveness inference is used.
        # Constants: Linux v6.12 include/uapi/linux/wait.h; XNU bsd/sys/wait.h.
        def nonreaping_exit?(pid)
          nowait = if RUBY_PLATFORM.include?("linux")
            0x01000000
          elsif RUBY_PLATFORM.include?("darwin")
            0x00000020
          else
            raise PostLaunchError, "nonreaping child observation is unsupported"
          end
          buffer = Fiddle::Pointer.malloc(512, Fiddle::RUBY_FREE)
          buffer[0, 512] = "\0" * 512
          function = Fiddle::Function.new(Fiddle.dlopen(nil)["waitid"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          result = function.call(1, pid, buffer, 4 | 1 | nowait)
          raise SystemCallError.new("waitid", Fiddle.last_error) unless result.zero?
          buffer[0, Fiddle::SIZEOF_INT].unpack1("i!") == Signal.list.fetch("CHLD")
        rescue Fiddle::DLError => error
          raise PostLaunchError, error.message
        end

        def kill_group(waiter)
          return unless waiter.alive?
          return if waiter.is_a?(OwnedChild) && waiter.group_signalled?
          Process.kill("KILL", -waiter.pid)
          waiter.group_signalled! if waiter.is_a?(OwnedChild)
        rescue Errno::ESRCH
          nil
        rescue Errno::EPERM
          # XNU killpg1 excludes SZOMB members and can return EPERM for
          # the owned zombie alone. Genuine permission failures still fail:
          # prove the complete group contains only our unreaped child.
          raise unless darwin_singleton_exited_group?(waiter)
        end

        def darwin_singleton_exited_group?(waiter)
          return false unless darwin_platform? && waiter.is_a?(OwnedChild) &&
            waiter.alive? && waiter.exited?
          return false unless darwin_group_pids(waiter.pid) == [waiter.pid]
          waiter.alive? && waiter.exited? && waiter.alive?
        rescue SystemCallError, IOError, Fiddle::DLError, PostLaunchError
          false
        end

        def darwin_platform? = RUBY_PLATFORM.include?("darwin")

        # libproc enumerates allproc AND zombproc under the kernel process
        # list lock. A full buffer is potentially truncated, never proof.
        # This observes only the owned group, not children escaping it.
        def darwin_group_pids(pid)
          library = Fiddle.dlopen("/usr/lib/libproc.dylib")
          function = Fiddle::Function.new(library["proc_listpids"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          capacity = DARWIN_GROUP_PID_LIMIT * Fiddle::SIZEOF_INT
          buffer = Fiddle::Pointer.malloc(capacity, Fiddle::RUBY_FREE)
          buffer[0, capacity] = "\0" * capacity
          # PROC_PGRP_ONLY=2, from XNU bsd/sys/proc_info.h.
          size = function.call(2, pid, buffer, capacity)
          return nil unless size.positive? && size < capacity && (size % Fiddle::SIZEOF_INT).zero?
          pids = buffer[0, size].unpack("i!*")
          return nil unless pids.all?(&:positive?) && pids.uniq == pids
          pids
        end
      end
    end
  end
end
