# frozen_string_literal: true

require "open3"
require "rbconfig"

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
          class SafeCapture
            # @param cmd [Array<String>] Command arguments
            # @param timeout [Integer] Timeout in seconds
            # @param stdin_data [String, nil] Data to write to stdin
            # @param chdir [String, nil] Working directory
            # @param env [Hash, nil] Environment variables (merged with current env)
            # @param provider_name [String] Provider name for error messages
            # @param isolate_process_group [Boolean] Spawn subprocess in isolated process group
            # @param cleanup_group_on_exit [Boolean] Clean up descendants on success
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
              supervised = isolate_process_group && cleanup_group_on_exit && RUBY_PLATFORM.include?("linux")
              full_cmd = supervisor_command(full_cmd) if supervised
              ready_reader, ready_writer = IO.pipe if supervised
              opts[ready_writer.fileno] = ready_writer if supervised
              spawn_env = env&.dup || {}
              spawn_env["ACE_SAFE_CAPTURE_READY_FD"] = ready_writer.fileno.to_s if supervised
              args = spawn_env.empty? ? full_cmd : [spawn_env, *full_cmd]

              Open3.popen3(*args, **opts) do |stdin, stdout, stderr, wait_thr|
                ready_writer&.close
                ready_reader&.read(1)
                ready_reader&.close

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
                  terminate_subprocess_tree(
                    pid: pid, pgid: pgid, provider_name: provider_name, supervised: supervised
                  )
                  unless wait_thr.join(5)
                    terminate_group_or_pid("KILL", pid, pgid)
                    wait_thr.join(5)
                  end

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
                if isolate_process_group && cleanup_group_on_exit && !supervised
                  terminate_descendants_after_success(pid: pid, pgid: pgid, provider_name: provider_name)
                end

                [out_reader.value, err_reader.value, status]
              end
            ensure
              ready_reader&.close unless ready_reader&.closed?
              ready_writer&.close unless ready_writer&.closed?
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
