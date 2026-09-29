# frozen_string_literal: true

require "open3"
require "rbconfig"

require_relative "../models/capture_result"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          # Thread-safe command execution with process-level timeout.
          #
          # Replaces the unsafe Timeout.timeout { Open3.capture3(...) } pattern
          # which causes "stream closed in another thread (IOError)" when the
          # timeout fires while Open3's internal reader threads hold pipe handles.
          #
          # Uses Open3.popen3 and, on Linux, a dedicated child-subreaper supervisor
          # so the complete command tree is terminated and reaped without thread
          # interruption or closed-stream races.
          #
          # Returns a typed Models::CaptureResult instead of a bare tuple so
          # callers can distinguish completed runs from deadline expiry, transport
          # failure, and spawn failure, and carry that evidence into errors.
          class SafeCapture
            # @param cmd [Array<String>] Command arguments
            # @param timeout [Integer] Timeout in seconds
            # @param stdin_data [String, nil] Data to write to stdin
            # @param chdir [String, nil] Working directory
            # @param env [Hash, nil] Environment variables (merged with current env)
            # @param provider_name [String] Provider name for error messages
            # @param isolate_process_group [Boolean] Spawn subprocess in isolated process group
            # @param cleanup_group_on_exit [Boolean] Clean up descendants on success
            # @return [Models::CaptureResult] typed capture outcome with raw streams
            def self.call(cmd, timeout:, stdin_data: nil, chdir: nil, env: nil, provider_name: "CLI",
              command_prefix: nil,
              isolate_process_group: true, cleanup_group_on_exit: true)
              normalized_timeout = normalize_timeout(timeout)
              invocation_id = Models::CaptureResult.next_invocation_id
              started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

              spawn_result = begin
                spawn_subprocess(
                  cmd, chdir: chdir, env: env, command_prefix: command_prefix,
                  isolate_process_group: isolate_process_group,
                  cleanup_group_on_exit: cleanup_group_on_exit
                )
              rescue SystemCallError => e
                return spawn_failure_result(
                  e, provider_name: provider_name, invocation_id: invocation_id,
                  deadline_seconds: normalized_timeout, started_at: started_at
                )
              end

              begin
                run_capture(
                  spawn_result,
                  provider_name: provider_name,
                  stdin_data: stdin_data,
                  isolate_process_group: isolate_process_group,
                  cleanup_group_on_exit: cleanup_group_on_exit,
                  normalized_timeout: normalized_timeout,
                  invocation_id: invocation_id,
                  started_at: started_at
                )
              rescue SystemCallError => e
                # popen3 raises before the capture block runs when the command
                # cannot be spawned (e.g. binary not found).
                spawn_failure_result(
                  e, provider_name: provider_name, invocation_id: invocation_id,
                  deadline_seconds: normalized_timeout, started_at: started_at
                )
              ensure
                spawn_result.close_setup_handles
              end
            end

            class << self
              private

              SpawnSetup = Struct.new(:args, :opts, :supervised, :ready_reader, :ready_writer, :readiness,
                keyword_init: true) do
                def supervised?
                  supervised
                end

                # Read the supervisor's readiness message (small, bounded; the
                # supervisor closes the pipe after writing). "1" means the child
                # group spawned; "S<detail>" reports a child spawn failure.
                def activate_streams
                  ready_writer&.close
                  self.readiness = ready_reader&.read
                  ready_reader&.close
                end

                # StandardError describing a supervisor-reported child spawn
                # failure, or nil when the child group started normally.
                def child_spawn_failure
                  return nil if supervised != true || readiness.nil.

                  message = readiness.to_s
                  return nil unless message.start_with?("S")

                  StandardError.new("child process failed to start: #{message[1..].strip}")
                end

                def close_setup_handles
                  [ready_reader, ready_writer].each do |io|
                    next unless io

                    io.close unless io.closed?
                  end
                end
              end
              private_constant :SpawnSetup

              def spawn_failure_result(error, provider_name:, invocation_id:, deadline_seconds:, started_at:)
                Models::CaptureResult.new(
                  outcome: Models::CaptureResult::OUTCOME_SPAWN_FAILURE,
                  provider_name: provider_name,
                  invocation_id: invocation_id,
                  deadline_seconds: deadline_seconds,
                  elapsed_seconds: elapsed_since(started_at),
                  spawn_error: error
                )
              end

              def run_capture(spawn_result, provider_name:, stdin_data:, isolate_process_group:,
                cleanup_group_on_exit:, normalized_timeout:, invocation_id:, started_at:)
                Open3.popen3(*spawn_result.args, **spawn_result.opts) do |stdin, stdout, stderr, wait_thr|
                  spawn_result.activate_streams
                  if (spawn_failure = spawn_result.child_spawn_failure)
                    return Models::CaptureResult.new(
                      outcome: Models::CaptureResult::OUTCOME_SPAWN_FAILURE,
                      provider_name: provider_name,
                      invocation_id: invocation_id,
                      deadline_seconds: normalized_timeout,
                      elapsed_seconds: elapsed_since(started_at),
                      spawn_error: spawn_failure
                    )
                  end

                  pid = wait_thr.pid
                  pgid = safe_getpgid(pid)
                  debug_log(provider_name, "spawn pid=#{pid} pgid=#{pgid || "n/a"} invocation=#{invocation_id}")

                  begin
                    stdin.write(stdin_data) if stdin_data
                  rescue Errno::EPIPE
                    # Subprocess exited before consuming stdin — continue to capture stderr for the real error
                  end
                  stdin.close

                  partial_stdout = +""
                  partial_stderr = +""
                  out_reader = Thread.new { safe_read_stream(stdout, partial_stdout) }
                  err_reader = Thread.new { safe_read_stream(stderr, partial_stderr) }
                  out_reader.report_on_exception = false
                  err_reader.report_on_exception = false

                  unless wait_thr.join(normalized_timeout)
                    # Deadline exceeded: kill subprocess group (and descendants), retain partial streams
                    terminate_subprocess_tree(
                      pid: pid, pgid: pgid, provider_name: provider_name, supervised: spawn_result.supervised?
                    )
                    unless wait_thr.join(5)
                      terminate_group_or_pid("KILL", pid, pgid)
                      wait_thr.join(5)
                    end

                    return Models::CaptureResult.new(
                      outcome: Models::CaptureResult::OUTCOME_DEADLINE_EXCEEDED,
                      stdout: drain_reader(out_reader, stdout, partial_stdout),
                      stderr: drain_reader(err_reader, stderr, partial_stderr),
                      provider_name: provider_name,
                      invocation_id: invocation_id,
                      deadline_seconds: normalized_timeout,
                      elapsed_seconds: elapsed_since(started_at)
                    )
                  end

                  status = wait_thr.value
                  if isolate_process_group && cleanup_group_on_exit && !spawn_result.supervised?
                    terminate_descendants_after_success(pid: pid, pgid: pgid, provider_name: provider_name)
                  end

                  outcome = if status.exited?
                    Models::CaptureResult::OUTCOME_COMPLETED
                  else
                    # Terminated by a signal we did not send: the session ended
                    # abruptly rather than the CLI finishing on its own.
                    Models::CaptureResult::OUTCOME_TRANSPORT_FAILURE
                  end

                  return Models::CaptureResult.new(
                    outcome: outcome,
                    stdout: out_reader.value.to_s,
                    stderr: err_reader.value.to_s,
                    status: status,
                    provider_name: provider_name,
                    invocation_id: invocation_id,
                    deadline_seconds: normalized_timeout,
                    elapsed_seconds: elapsed_since(started_at)
                  )
                end
              end

              def spawn_subprocess(cmd, chdir:, env:, command_prefix:, isolate_process_group:,
                cleanup_group_on_exit:)
                opts = {}
                opts[:chdir] = chdir if chdir
                opts[:pgroup] = true if isolate_process_group

                full_cmd = Array(command_prefix) + cmd
                supervised = isolate_process_group && cleanup_group_on_exit && RUBY_PLATFORM.include?("linux")
                full_cmd = supervisor_command(full_cmd) if supervised
                ready_reader, ready_writer = IO.pipe if supervised
                opts[ready_writer.fileno] = ready_writer if supervised
                spawn_env = env&.dup || {}
                spawn_env["ACE_SAFE_CAPTURE_READY_FD"] = ready_writer.fileno.to_s if supervised
                args = spawn_env.empty? ? full_cmd : [spawn_env, *full_cmd]

                SpawnSetup.new(
                  args: args,
                  opts: opts,
                  supervised: supervised,
                  ready_reader: ready_reader,
                  ready_writer: ready_writer,
                  readiness: nil
                )
              end

              # Pull whatever partial output a reader thread captured without
              # ever blocking past a short bound: a descendant outside the
              # killed process group can keep the pipe open indefinitely. The
              # buffer is caller-owned, so bytes already read survive even when
              # the stream must be closed or the reader thread must be killed.
              def drain_reader(reader, io, buffer)
                if reader.join(2)
                  reader.value.to_s
                else
                  io.close unless io.closed?
                  reader.join(1)
                  reader.kill if reader.alive?
                  buffer.dup
                end
              end

              # Incrementally buffer stream output into a caller-owned buffer so
              # already-read bytes survive even when the stream must be closed
              # mid-read or the reader thread must be killed.
              def safe_read_stream(io, buffer)
                loop do
                  chunk = io.read_nonblock(65_536, exception: false)
                  if chunk.nil?
                    break # EOF
                  elsif chunk == :wait_readable
                    IO.select([io])
                    next
                  end
                  buffer << chunk
                end
                buffer
              rescue IOError, SystemCallError
                buffer
              end

              def normalize_timeout(value)
                return value if value.is_a?(Numeric) && value.finite?

                normalized = value.to_s.strip
                normalized_timeout = Float(normalized)
                raise ArgumentError, "timeout must be positive" unless normalized_timeout.positive?

                normalized_timeout
              rescue ArgumentError, TypeError
                raise ArgumentError, "timeout must be a positive numeric value, got #{value.inspect}"
              end

              def elapsed_since(started_at)
                Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
              end

              def supervisor_command(command)
                supervisor = File.expand_path("process_supervisor.rb", __dir__)
                [RbConfig.ruby, "-W0", supervisor, *command]
              end

              def terminate_subprocess_tree(pid:, pgid:, provider_name:, supervised: false)
                debug_log(provider_name, "timeout cleanup pid=#{pid} pgid=#{pgid || "n/a"}")
                terminate_group_or_pid("TERM", pid, pgid)
                terminate_group_or_pid("KILL", pid, pgid) unless supervised
              end

              def terminate_descendants_after_success(pid:, pgid:, provider_name:)
                return unless pgid

                debug_log(provider_name, "post-exit cleanup pgid=#{pgid}")
                safe_kill_group(pgid, "TERM")
                safe_kill_group(pgid, "KILL")
                reap_terminated_group(pgid)
              end

              def terminate_group_or_pid(signal, pid, pgid)
                if pgid
                  Process.kill(signal, -pgid)
                else
                  Process.kill(signal, pid)
                end
                true
              rescue Errno::ESRCH, Errno::EPERM
                nil
              end

              def safe_kill_group(pgid, signal)
                Process.kill(signal, -pgid)
              rescue Errno::ESRCH, Errno::EPERM
                nil
              end

              def safe_getpgid(pid)
                Process.getpgid(pid)
              rescue Errno::ESRCH
                nil
              end

              def reap_terminated_group(pgid)
                loop { Process.waitpid(-pgid) }
              rescue Errno::ECHILD
                nil
              end

              def debug_log(provider_name, message)
                return unless ENV["ACE_LLM_DEBUG_SUBPROCESS"] == "1"

                warn("[SafeCapture][#{provider_name}] #{message}")
              end
            end
          end
        end
      end
    end
  end
end
