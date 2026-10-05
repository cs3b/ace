# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

module Ace
  module TestRunner
    module Suite
      class ProcessMonitor
        attr_reader :processes, :max_parallel

        def initialize(max_parallel = 10, package_timeout: nil, termination_grace_period: 1.0, clock: nil,
          environment_policy: Models::EnvironmentPolicy.new)
          @max_parallel = max_parallel
          @package_timeout = package_timeout
          @termination_grace_period = termination_grace_period
          @environment_policy = environment_policy
          @clock = clock || -> { Time.now }
          @processes = {}
          @queue = []
          @completed = []
        end

        def start_package(package, test_options, &callback)
          # Queue the package if we're at max capacity
          if @processes.size >= @max_parallel
            @queue << {package: package, options: test_options, callback: callback}
            callback.call(package, {status: :waiting}, nil) if callback
            return
          end

          package["entry_id"] ||= SecureRandom.uuid
          evidence = Molecules::ExecutionEvidence.new(package_path: package["path"],
            package: package["name"], entry_id: package["entry_id"])

          # Build command
          cmd = build_command(package, test_options)

          # Launch each package from its own hermetic fixture environment so
          # parallel workers never share (or leak) ambient Lab/ACE/user state.
          # Suite-level fixture configuration propagates to the package worker
          # through the runner-internal channel; the worker merges it under its
          # own runner configuration and the channel never reaches test children.
          fixture_environment = Molecules::FixtureEnvironment.new(
            policy: @environment_policy,
            parent_env: ENV.to_h
          ).build
          fixture_environment.env[Models::EnvironmentPolicy::SUITE_CHANNEL_KEY] =
            @environment_policy.channel_payload

          fixture_environment.env[Molecules::ExecutionEvidence::CHANNEL] = evidence.channel

          start_time = now
          stdin, stdout, stderr, thread = Open3.popen3(
            fixture_environment.env, *cmd, chdir: package["path"], pgroup: true, unsetenv_others: true
          )

          @processes[package["entry_id"]] = {
            evidence: evidence,
            save_reports: test_options.fetch("save_reports", true),
            package: package,
            thread: thread,
            stdout: stdout,
            stderr: stderr,
            stdin: stdin,
            start_time: start_time,
            callback: callback,
            fixture_environment: fixture_environment,
            output: +"",
            stderr_output: +"",
            test_count: 0,
            tests_run: 0,
            dots: +"",
            timeout: @package_timeout,
            pid: thread.pid,
            pgid: thread.pid,
            terminating: false,
            timeout_triggered: false,
            terminated_by: nil,
            terminate_at: nil
          }

          # Initial callback
          callback.call(package, {status: :running, start_time: start_time}, nil) if callback
        end

        def check_processes
          @processes.each do |name, process_info|
            package = process_info[:package]
            thread = process_info[:thread]
            callback = process_info[:callback]

            stdout_chunk = drain_stream(process_info[:stdout], process_info[:output])
            stderr_chunk = drain_stream(process_info[:stderr], process_info[:stderr_output])

            parse_progress(process_info, stdout_chunk) if stdout_chunk && !stdout_chunk.empty?

            if callback && ((stdout_chunk && !stdout_chunk.empty?) || (stderr_chunk && !stderr_chunk.empty?))
              elapsed = now - process_info[:start_time]
              callback.call(package, {
                status: :running,
                progress: process_info[:tests_run],
                total: process_info[:test_count],
                dots: process_info[:dots],
                elapsed: elapsed
              }, stdout_chunk)
            end

            enforce_timeout(process_info)

            # Check if process completed
            unless thread.alive?
              elapsed = now - process_info[:start_time]
              exit_status = thread.value.exitstatus

              collect_remaining_output(process_info)
              results = build_results(process_info, elapsed, exit_status)
              close_streams(process_info)
              process_info[:fixture_environment]&.cleanup

              # Final callback
              if callback
                # Completion evidence and child outcome must both permit success.
                success_status = results[:success] == true

                callback.call(package, {
                  status: :completed,
                  completed: true,
                  success: success_status,
                  exit_code: exit_status,
                  elapsed: elapsed,
                  timed_out: process_info[:timeout_triggered],
                  interrupted: process_info[:terminated_by] == :interrupt,
                  results: results
                }, process_info[:output])
              end

              # Remove from active processes
              @completed << name
            end
          end

          # Remove completed processes
          @completed.each { |name| @processes.delete(name) }
          @completed.clear

          # Start queued processes if we have capacity
          while @processes.size < @max_parallel && !@queue.empty?
            queued = @queue.shift
            start_package(queued[:package], queued[:options], &queued[:callback])
          end
        end

        def running?
          !@processes.empty? || !@queue.empty?
        end

        def stop_all(reason: :interrupt)
          @queue.clear

          @processes.each_value do |process_info|
            terminate_process_group(process_info, signal: "TERM", reason: reason)
          end

          deadline = now + @termination_grace_period
          while @processes.values.any? { |info| info[:thread].alive? } && now < deadline
            sleep 0.05
          end

          @processes.each_value do |process_info|
            next unless process_info[:thread].alive?

            terminate_process_group(process_info, signal: "KILL", reason: reason)
          end

          @processes.each_value do |process_info|
            begin
              Timeout.timeout(0.5) { process_info[:thread].value if process_info[:thread].alive? }
            rescue Timeout::Error, StandardError
              nil
            end
          end

          # Capture trustworthy partial counts and interruption outcome before cleanup.
          check_processes
          @processes.each_value do |process_info|
            close_streams(process_info)
            process_info[:fixture_environment]&.cleanup
          end
          @processes.clear
          @completed.clear
        end

        def wait_all
          while running?
            check_processes
            sleep 0.1
          end
        end

        private

        def build_command(package, options)
          # Run the child with this suite's own Ruby binary and a bundler
          # bootstrap: the hermetic fixture env blocks RUBYOPT/BUNDLE_/GEM_ and
          # redirects HOME/XDG, so a PATH-resolved interpreter can fail through
          # manager shims and children have no dependency surface beyond the
          # Ruby install's default gem dir. -rbundler/setup makes bundler
          # discover the checkout Gemfile by walking up from the package cwd,
          # giving every child the same source-of-truth dependency set without
          # ambient env or globally installed gems.
          cmd_parts = [RbConfig.ruby, "-rbundler/setup", ace_test_executable]

          # Suite package execution intentionally bypasses grouped mode so each
          # package runs its full target scope as one batch under suite orchestration.
          cmd_parts << "--run-in-single-batch"

          # Add format (use progress if compact is specified since ace-test doesn't have compact format)
          format = options["format"] || "progress"
          format = "progress" if format == "compact"  # Handle legacy compact format
          cmd_parts << "--format" << format

          # Add other options
          cmd_parts << "--no-save-reports" unless options.fetch("save_reports", true)
          cmd_parts << "--fail-fast" if options["fail_fast"]
          cmd_parts << "--no-color" unless options.fetch("color", true)
          if options["report_dir"]
            short_name = package["name"].to_s.sub(/\Aace-/, "")
            pkg_report_dir = File.join(options["report_dir"], short_name)
            cmd_parts << "--report-dir" << pkg_report_dir
          end

          target = options["target"]
          cmd_parts << target if target && !target.to_s.empty?

          cmd_parts
        end

        def ace_test_executable
          File.expand_path("../../../../exe/ace-test", __dir__)
        end

        def now
          @clock.call
        end

        def enforce_timeout(process_info)
          timeout = process_info[:timeout]
          return unless timeout

          elapsed = now - process_info[:start_time]

          if !process_info[:timeout_triggered] && elapsed > timeout
            process_info[:timeout_triggered] = true
            process_info[:terminate_at] = now + @termination_grace_period
            terminate_process_group(process_info, signal: "TERM", reason: :timeout)
          elsif process_info[:timeout_triggered] && process_info[:thread].alive? && process_info[:terminate_at] && now >= process_info[:terminate_at]
            terminate_process_group(process_info, signal: "KILL", reason: :timeout)
            process_info[:terminate_at] = nil
          end
        end

        def terminate_process_group(process_info, signal:, reason:)
          process_info[:terminated_by] = reason
          process_info[:terminating] = true
          Process.kill(signal, -process_info[:pgid])
        rescue Errno::ESRCH, Errno::EPERM
          nil
        end

        def drain_stream(io, buffer)
          return nil unless io && !io.closed?

          chunk = +""
          loop do
            ready = IO.select([io], nil, nil, 0)
            break unless ready

            chunk << io.read_nonblock(4096)
          end

          buffer << chunk unless chunk.empty?
          chunk
        rescue IO::WaitReadable, EOFError
          buffer << chunk unless chunk.empty?
          chunk
        rescue IOError
          nil
        end

        def collect_remaining_output(process_info)
          process_info[:output] << safe_read(process_info[:stdout])
          process_info[:stderr_output] << safe_read(process_info[:stderr])
        end

        def safe_read(io)
          return "" unless io && !io.closed?

          io.read
        rescue StandardError
          ""
        end

        def close_streams(process_info)
          %i[stdout stderr stdin].each do |stream|
            begin
              process_info[stream]&.close
            rescue StandardError
              nil
            end
          end
        end

        def build_results(process_info, elapsed, exit_status)
          snapshot = begin
            process_info[:evidence].read(pid: process_info[:pid], save_reports: process_info[:save_reports])
          rescue Ace::TestRunner::Error => e
            {total: 0, passed: 0, failed: 0, errors: 1, skipped: 0, assertions: 0,
             duration: elapsed, success: false, error: e.message}
          end
          results = snapshot.merge(tests: snapshot[:total], failures: snapshot[:failed],
            execution_id: process_info[:evidence].identity, completion_path: process_info[:evidence].path)
          reason = if process_info[:timeout_triggered]
            "Timed out after #{process_info[:timeout]} seconds"
          elsif process_info[:terminated_by] == :interrupt
            "Interrupted before completion"
          elsif exit_status != 0
            failure_message_for(process_info, exit_status)
          end
          if reason
            results[:success] = false
            results[:error] = reason
          end
          results.freeze
        end

        def failure_message_for(process_info, exit_status)
          stderr = process_info[:stderr_output].to_s.strip
          stderr.empty? ? "ace-test exited with status #{exit_status.inspect}" : stderr
        end

        def parse_progress(process_info, chunk)
          # Count dots, F, E, S in the output for progress
          dots = chunk.scan(/[.FES]/).join
          process_info[:dots] << dots
          process_info[:tests_run] += dots.length

          # Try to extract total test count from output
          if process_info[:test_count] == 0 && chunk =~ /Running (\d+)(?:\/\d+)? test files/
            process_info[:test_count] = $1.to_i * 10  # Estimate tests per file
          elsif chunk =~ /(\d+) tests?,/
            process_info[:test_count] = $1.to_i
          end
        end
      end
    end
  end
end
