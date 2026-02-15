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
            # @return [Array(String, String, Process::Status)] [stdout, stderr, status]
            # @raise [Ace::LLM::ProviderError] on timeout
            def self.call(cmd, timeout:, stdin_data: nil, chdir: nil, env: nil, provider_name: "CLI")
              opts = {}
              opts[:chdir] = chdir if chdir

              args = env ? [env, *cmd] : cmd

              Open3.popen3(*args, **opts) do |stdin, stdout, stderr, wait_thr|
                if stdin_data
                  stdin.write(stdin_data)
                end
                stdin.close

                out_reader = Thread.new { stdout.read }
                err_reader = Thread.new { stderr.read }

                unless wait_thr.join(timeout)
                  # Timeout: kill the process, then clean up reader threads
                  begin
                    Process.kill("TERM", wait_thr.pid)
                  rescue Errno::ESRCH
                    # Process already exited
                  end
                  sleep(0.1)
                  begin
                    Process.kill("KILL", wait_thr.pid)
                  rescue Errno::ESRCH
                    # Process already exited
                  end
                  wait_thr.join(5)
                  out_reader.kill
                  err_reader.kill
                  raise Ace::LLM::ProviderError,
                    "#{provider_name} CLI execution timed out after #{timeout} seconds"
                end

                [out_reader.value, err_reader.value, wait_thr.value]
              end
            end
          end
        end
      end
    end
  end
end
