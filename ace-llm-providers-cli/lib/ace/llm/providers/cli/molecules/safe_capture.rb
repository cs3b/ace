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
                          isolate_process_group: true, cleanup_group_on_exit: true)
              opts = {}
              opts[:chdir] = chdir if chdir
              opts[:pgroup] = true if isolate_process_group

              args = env ? [env, *cmd] : cmd

              Open3.popen3(*args, **opts) do |stdin, stdout, stderr, wait_thr|
                pid = wait_thr.pid
                pgid = safe_getpgid(pid)
                debug_log(provider_name, "spawn pid=#{pid} pgid=#{pgid || "n/a"}")

                if stdin_data
                  stdin.write(stdin_data)
                end
                stdin.close

                out_reader = Thread.new { stdout.read }
                err_reader = Thread.new { stderr.read }

                unless wait_thr.join(timeout)
                  # Timeout: kill subprocess group (and descendants), then clean up
                  terminate_subprocess_tree(pid: pid, pgid: pgid, provider_name: provider_name)
                  wait_thr.join(5)
                  out_reader.kill
                  err_reader.kill
                  raise Ace::LLM::ProviderError,
                    "#{provider_name} CLI execution timed out after #{timeout} seconds"
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

              def terminate_subprocess_tree(pid:, pgid:, provider_name:)
                debug_log(provider_name, "timeout cleanup pid=#{pid} pgid=#{pgid || "n/a"}")
                terminate_group_or_pid("TERM", pid, pgid)
                sleep(0.1)
                terminate_group_or_pid("KILL", pid, pgid)
              end

              def terminate_descendants_after_success(pid:, pgid:, provider_name:)
                return unless pgid
                return unless group_alive?(pgid)

                debug_log(provider_name, "post-exit cleanup pgid=#{pgid}")
                terminate_group_or_pid("TERM", pid, pgid)
                sleep(0.05)
                terminate_group_or_pid("KILL", pid, pgid) if group_alive?(pgid)
              end

              def terminate_group_or_pid(signal, pid, pgid)
                if pgid
                  Process.kill(signal, -pgid)
                else
                  Process.kill(signal, pid)
                end
              rescue Errno::ESRCH, Errno::EPERM
                nil
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

                $stderr.puts("[SafeCapture][#{provider_name}] #{message}")
              end
            end
          end
        end
      end
    end
  end
end
