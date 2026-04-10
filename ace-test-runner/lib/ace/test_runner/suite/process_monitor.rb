# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

module Ace
  module TestRunner
    module Suite
      class ProcessMonitor
        attr_reader :processes, :max_parallel

        def initialize(max_parallel = 10, package_timeout: nil, termination_grace_period: 1.0, clock: nil)
          @max_parallel = max_parallel
          @package_timeout = package_timeout
          @termination_grace_period = termination_grace_period
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

          # Build command
          cmd = build_command(package, test_options)

          # Start the process
          # Strip assignment context vars to prevent tests from resolving to wrong assignments
          env = ENV.to_h.merge({
            "ACE_ASSIGN_ID" => nil,
            "ACE_ASSIGN_FORK_ROOT" => nil
          })
          start_time = now
          stdin, stdout, stderr, thread = Open3.popen3(env, *cmd, chdir: package["path"], pgroup: true)

          @processes[package["name"]] = {
            package: package,
            thread: thread,
            stdout: stdout,
            stderr: stderr,
            stdin: stdin,
            start_time: start_time,
            callback: callback,
            output: +"",
            stderr_output: +"",
            report_root: test_options["report_dir"],
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
              results = build_results(process_info, elapsed)
              close_streams(process_info)

              # Final callback
              if callback
                # Use results[:success] from summary.json if available, otherwise check exit code
                # This ensures the package status matches what ace-test actually reported
                success_status = (!results[:success].nil?) ? results[:success] : (exit_status == 0)

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

            close_streams(process_info)
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
          cmd_parts = ["ace-test"]

          # Add format (use progress if compact is specified since ace-test doesn't have compact format)
          format = options["format"] || "progress"
          format = "progress" if format == "compact"  # Handle legacy compact format
          cmd_parts << "--format" << format

          # Add other options
          cmd_parts << "--no-save" unless options["save_reports"]
          cmd_parts << "--fail-fast" if options["fail_fast"]
          cmd_parts << "--no-color" unless options.fetch("color", true)
          if options["report_dir"]
            short_name = package["name"].to_s.sub(/\Aace-/, "")
            pkg_report_dir = File.join(options["report_dir"], short_name)
            cmd_parts << "--report-dir" << pkg_report_dir
          end

          cmd_parts
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

        def build_results(process_info, elapsed)
          return timeout_results(process_info, elapsed) if process_info[:timeout_triggered]
          return interrupted_results(elapsed) if process_info[:terminated_by] == :interrupt
          results = load_summary_results(process_info, elapsed)
          return results if results

          parse_results(process_info[:output])
        end

        def timeout_results(process_info, elapsed)
          {
            tests: 0,
            assertions: 0,
            failures: 0,
            errors: 1,
            duration: elapsed,
            success: false,
            error: "Timed out after #{process_info[:timeout]} seconds"
          }
        end

        def interrupted_results(elapsed)
          {
            tests: 0,
            assertions: 0,
            failures: 0,
            errors: 1,
            duration: elapsed,
            success: false,
            error: "Interrupted before completion"
          }
        end

        def load_summary_results(process_info, elapsed)
          package = process_info[:package]
          reports_dir = Atoms::ReportPathResolver.report_directory(
            package["path"],
            report_root: process_info[:report_root],
            package_name: package["name"]
          )
          summary_file = reports_dir ? File.join(reports_dir, "summary.json") : nil
          return nil unless summary_file && File.exist?(summary_file)

          json_data = JSON.parse(File.read(summary_file))
          results = {
            tests: json_data["total"] || 0,
            assertions: json_data["assertions"] || 0,
            failures: json_data["failed"] || 0,
            errors: json_data["errors"] || 0,
            duration: json_data["duration"] || elapsed,
            success: json_data["success"] || false
          }

          if results[:assertions] == 0
            report_file = File.join(reports_dir, "report.json")
            if File.exist?(report_file)
              report_data = JSON.parse(File.read(report_file))
              results[:assertions] = report_data.dig("result", "assertions") || 0
            end
          end

          results
        rescue JSON::ParserError
          nil
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

        def parse_results(output)
          # Look for summary line in output
          if output =~ /(\d+) tests?, (\d+) assertions?, (\d+) failures?, (\d+) errors? \(([\d.]+)s\)/
            {
              tests: $1.to_i,
              assertions: $2.to_i,
              failures: $3.to_i,
              errors: $4.to_i,
              duration: $5.to_f,
              success: $3.to_i == 0 && $4.to_i == 0
            }
          else
            # Fallback to counting dots/F/E/S
            dots = output.scan(/[.FES]/).join
            {
              tests: dots.length,
              failures: dots.count("F"),
              errors: dots.count("E"),
              skipped: dots.count("S"),
              success: !dots.include?("F") && !dots.include?("E")
            }
          end
        end
      end
    end
  end
end
