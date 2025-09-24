# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module TestRunner
    module Suite
      class ProcessMonitor
        attr_reader :processes, :max_parallel

        def initialize(max_parallel = 10)
          @max_parallel = max_parallel
          @processes = {}
          @queue = []
          @completed = []
        end

        def start_package(package, test_options, &callback)
          # Queue the package if we're at max capacity
          if @processes.size >= @max_parallel
            @queue << { package: package, options: test_options, callback: callback }
            callback.call(package, { status: :waiting }, nil) if callback
            return
          end

          # Build command
          cmd = build_command(package, test_options)

          # Start the process
          start_time = Time.now
          stdin, stdout, stderr, thread = Open3.popen3(cmd, chdir: package["path"])

          @processes[package["name"]] = {
            package: package,
            thread: thread,
            stdout: stdout,
            stderr: stderr,
            stdin: stdin,
            start_time: start_time,
            callback: callback,
            output: +"",
            test_count: 0,
            tests_run: 0,
            dots: +""
          }

          # Initial callback
          callback.call(package, { status: :running, start_time: start_time }, nil) if callback
        end

        def check_processes
          @processes.each do |name, process_info|
            package = process_info[:package]
            thread = process_info[:thread]
            callback = process_info[:callback]

            # Read available output
            begin
              if IO.select([process_info[:stdout]], nil, nil, 0)
                chunk = process_info[:stdout].read_nonblock(4096)
                process_info[:output] << chunk

                # Parse progress from output
                parse_progress(process_info, chunk)

                # Update display with progress
                if callback
                  elapsed = Time.now - process_info[:start_time]
                  callback.call(package, {
                    status: :running,
                    progress: process_info[:tests_run],
                    total: process_info[:test_count],
                    dots: process_info[:dots],
                    elapsed: elapsed
                  }, chunk)
                end
              end
            rescue IO::WaitReadable, EOFError
              # No data available or stream closed
            end

            # Check if process completed
            unless thread.alive?
              elapsed = Time.now - process_info[:start_time]
              exit_status = thread.value.exitstatus

              # Get final output
              remaining_output = process_info[:stdout].read rescue ""
              process_info[:output] << remaining_output

              # Try to get accurate results from summary.json first
              results = nil
              summary_file = File.join(package["path"], "test-reports", "latest", "summary.json")
              if File.exist?(summary_file)
                begin
                  json_data = JSON.parse(File.read(summary_file))
                  results = {
                    tests: json_data["total"] || 0,
                    assertions: json_data["assertions"] || 0,
                    failures: json_data["failed"] || 0,
                    errors: json_data["errors"] || 0,
                    duration: json_data["duration"] || elapsed,
                    success: json_data["success"] || false
                  }

                  # Also try to get assertions from report.json if not in summary
                  if results[:assertions] == 0
                    report_file = File.join(package["path"], "test-reports", "latest", "report.json")
                    if File.exist?(report_file)
                      report_data = JSON.parse(File.read(report_file))
                      results[:assertions] = report_data.dig("result", "assertions") || 0
                    end
                  end
                rescue JSON::ParserError
                  # Fall back to parsing output
                end
              end

              # Fall back to parsing output if no JSON data
              results ||= parse_results(process_info[:output])

              # Close streams
              process_info[:stdout].close rescue nil
              process_info[:stderr].close rescue nil
              process_info[:stdin].close rescue nil

              # Final callback
              if callback
                # Use results[:success] from summary.json if available, otherwise check exit code
                # This ensures the package status matches what ace-test actually reported
                success_status = results[:success] != nil ? results[:success] : (exit_status == 0)

                callback.call(package, {
                  status: :completed,
                  completed: true,
                  success: success_status,
                  exit_code: exit_status,
                  elapsed: elapsed,
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

          cmd_parts.join(" ")
        end

        def parse_progress(process_info, chunk)
          # Count dots, F, E, S in the output for progress
          dots = chunk.scan(/[\.FES]/).join
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
            dots = output.scan(/[\.FES]/).join
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