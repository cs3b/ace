# frozen_string_literal: true

require "open3"

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
          # Uses Open3.popen3 + Process.kill so the child process is terminated
          # directly — no thread interruption, no IOError.
          class SafeCapture
            # @param cmd [Array<String>] Command arguments
            # @param timeout [Integer] Timeout in seconds
            # @param stdin_data [String, nil] Data to write to stdin
            # @param chdir [String, nil] Working directory
            # @param env [Hash, nil] Environment variables (merged with current env)
            # @param provider_name [String] Provider name for error messages
            # @param isolate_process_group [Boolean] Spawn subprocess in isolated process group
            # @param cleanup_group_on_exit [Boolean] Best-effort cleanup of descendants on success
            # @return [Array(String, String, Process::Status)] [stdout, stderr, status]
            # @raise [Ace::LLM::ProviderError] on timeout
            def self.call(cmd, timeout:, stdin_data: nil, chdir: nil, env: nil, provider_name: "CLI",
              command_prefix: nil,
              isolate_process_group: true, cleanup_group_on_exit: true)
              normalized_timeout = normalize_timeout(timeout)
              opts = {}
              opts[:chdir] = chdir if chdir
              opts[:pgroup] = true if isolate_process_group

              full_cmd = Array(command_prefix) + cmd
              args = env ? [env, *full_cmd] : full_cmd

              Open3.popen3(*args, **opts) do |stdin, stdout, stderr, wait_thr|
                pid = wait_thr.pid
                pgid = safe_getpgid(pid)
                debug_log(provider_name, "spawn pid=#{pid} pgid=#{pgid || "n/a"}")

                begin
                  stdin.write(stdin_data) if stdin_data
                rescue Errno::EPIPE
                  # Subprocess exited before consuming stdin — continue to capture stderr for the real error
                end
                stdin.close

                out_reader = Thread.new { safe_read_stream(stdout) }
                err_reader = Thread.new { safe_read_stream(stderr) }
                out_reader.report_on_exception = false
                err_reader.report_on_exception = false

                unless wait_thr.join(normalized_timeout)
                  # Timeout: kill subprocess group (and descendants), then clean up
                  terminate_subprocess_tree(pid: pid, pgid: pgid, provider_name: provider_name)
                  wait_thr.join(5)

                  stdout.close unless stdout.closed?
                  stderr.close unless stderr.closed?
                  out_reader.join(1)
                  err_reader.join(1)
                  out_reader.kill if out_reader.alive?
                  err_reader.kill if err_reader.alive?
                  raise Ace::LLM::ProviderError,
                    "#{provider_name} CLI execution timed out after #{normalized_timeout} seconds"
                end

                status = wait_thr.value
                if isolate_process_group && cleanup_group_on_exit
                  terminate_descendants_after_success(pid: pid, pgid: pgid, provider_name: provider_name)
                end

                [out_reader.value, err_reader.value, status]
              end
            end

            class << self
              private

              def safe_read_stream(io)
                io.read
              rescue IOError
                ""
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

              def terminate_subprocess_tree(pid:, pgid:, provider_name:)
                debug_log(provider_name, "timeout cleanup pid=#{pid} pgid=#{pgid || "n/a"}")
                # In container PID namespaces, process groups may be unreliable.
                # Use multiple signals with delays to ensure termination.
                terminate_with_retry(pid, pgid)
              end

              def terminate_descendants_after_success(pid:, pgid:, provider_name:)
                return unless pgid

                debug_log(provider_name, "post-exit cleanup pgid=#{pgid}")

                # In container PID namespaces, process group termination may miss
                # reparented processes. Use aggressive retry with fallback to PID kill.
                aggressive_group_termination(pgid)
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

              # Terminate a process group with retry logic for container environments.
              # In containers, kill(-pgid) may not reach all members due to namespace
              # isolation and rapid reparenting. Use multiple signals with delays.
              def terminate_with_retry(pid, pgid)
                # Try process group first
                if pgid
                  safe_kill_group(pgid, "TERM")
                  sleep(0.1)
                  safe_kill_group(pgid, "KILL")

                  # If group might still have stragglers, hunt descendants
                  hunt_and_kill_descendants(pid) if group_alive?(pgid)
                else
                  safe_kill_pid(pid, "TERM")
                  sleep(0.1)
                  safe_kill_pid(pid, "KILL")
                end
              end

              # Aggressive process group termination with multiple signals.
              def aggressive_group_termination(pgid)
                # First wave: TERM to the group
                safe_kill_group(pgid, "TERM")
                sleep(0.05)

                # Second wave: KILL if group still alive
                safe_kill_group(pgid, "KILL") if group_alive?(pgid)

                # Final verification: wait and KILL again if needed
                sleep(0.05)
                safe_kill_group(pgid, "KILL") if group_alive?(pgid)
              end

              def safe_kill_group(pgid, signal)
                Process.kill(signal, -pgid)
              rescue Errno::ESRCH, Errno::EPERM
                nil
              end

              def safe_kill_pid(pid, signal)
                Process.kill(signal, pid)
              rescue Errno::ESRCH, Errno::EPERM
                nil
              end

              # Hunt and kill descendant processes using /proc filesystem.
              # This is a best-effort fallback for container PID namespaces where
              # process group termination may miss reparented processes.
              def hunt_and_kill_descendants(root_pid)
                children = read_proc_children(root_pid)
                children.each { |child| safe_kill_pid(child, "TERM") }
                sleep(0.03)
                children.each { |child| safe_kill_pid(child, "KILL") }
              rescue Errno::ESRCH, Errno::EPERM, Errno::ENOENT, Errno::EACCES
                nil
              end

              # Read child PIDs from /proc/<pid>/task/<pid>/children.
              # Returns empty array on non-Linux systems or if the file is unavailable.
              def read_proc_children(pid)
                proc_children = "/proc/#{pid}/task/#{pid}/children"
                return [] unless File.exist?(proc_children)

                content = File.read(proc_children).strip
                content.split.map(&:to_i)
              rescue Errno::ENOENT, Errno::EACCES
                []
              end

              def safe_getpgid(pid)
                Process.getpgid(pid)
              rescue Errno::ESRCH
                nil
              end

              def group_alive?(pgid)
                Process.kill(0, -pgid)
                true
              rescue Errno::ESRCH
                false
              rescue Errno::EPERM
                true
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
