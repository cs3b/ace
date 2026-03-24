# frozen_string_literal: true

module Ace
  module TestRunner
    module Organisms
      # Executes test groups sequentially with visual separation and fail-fast support
      class SequentialGroupExecutor
        def initialize(test_executor:, result_parser:, formatter: nil)
          @test_executor = test_executor
          @result_parser = result_parser
          @formatter = formatter
        end

        def execute_groups(groups, options = {})
          fail_fast = options[:fail_fast] || options[:group_fail_fast]
          all_results = []
          all_files = []
          group_results = []

          groups.each do |group|
            group_name = group[:name]
            files = group[:files]
            next if files.empty?

            # Notify formatter of group start
            if @formatter&.respond_to?(:on_group_start)
              @formatter.on_group_start(group_name, files.size)
            end

            start_time = Time.now

            # Execute tests for this group
            result = @test_executor.execute_with_progress(files, options) do |event|
              yield(event) if block_given?
            end

            # Parse result
            parsed = if result[:commands] && result[:commands].is_a?(Array)
              # Multiple commands executed (per-file)
              aggregate_results(result[:stdout], @result_parser)
            else
              @result_parser.parse_output(result[:stdout])
            end

            duration = Time.now - start_time
            success = result[:success]

            # Store group result
            group_result = {
              name: group_name,
              success: success,
              duration: duration,
              parsed: parsed,
              files: files
            }
            group_results << group_result

            # Notify formatter of group completion
            if @formatter&.respond_to?(:on_group_complete)
              @formatter.on_group_complete(
                group_name,
                success,
                duration,
                parsed[:summary]
              )
            end

            # Collect all results and files
            all_results << result
            all_files.concat(files)

            # Stop if group failed and fail_fast is enabled
            if fail_fast && !success
              # Return early with aggregated results so far
              return build_aggregated_result(group_results, all_files, all_results, stopped: group_name)
            end
          end

          # All groups completed successfully (or fail_fast not enabled)
          build_aggregated_result(group_results, all_files, all_results)
        end

        private

        def aggregate_results(combined_output, parser)
          # Split output by test file executions
          individual_outputs = combined_output.split(/^Started with run options/)
          individual_outputs.shift if individual_outputs.first && individual_outputs.first.empty?

          aggregated = {
            summary: {
              runs: 0,
              assertions: 0,
              failures: 0,
              errors: 0,
              skips: 0,
              passed: 0
            },
            failures: [],
            duration: 0.0,
            deprecations: [],
            test_times: []
          }

          individual_outputs.each do |output|
            output = "Started with run options" + output
            parsed = parser.parse_output(output)

            aggregated[:summary][:runs] += parsed[:summary][:runs]
            aggregated[:summary][:assertions] += parsed[:summary][:assertions]
            aggregated[:summary][:failures] += parsed[:summary][:failures]
            aggregated[:summary][:errors] += parsed[:summary][:errors]
            aggregated[:summary][:skips] += parsed[:summary][:skips]
            aggregated[:summary][:passed] += parsed[:summary][:passed]

            aggregated[:failures].concat(parsed[:failures])
            aggregated[:deprecations].concat(parsed[:deprecations])
            aggregated[:duration] += parsed[:duration]
            aggregated[:test_times].concat(parsed[:test_times]) if parsed[:test_times]
          end

          aggregated[:test_times].sort_by! { |t| -t[:duration] } if aggregated[:test_times]
          aggregated
        end

        def build_aggregated_result(group_results, all_files, all_results, stopped: nil)
          # Aggregate all parsed results
          total_summary = {
            runs: 0,
            assertions: 0,
            failures: 0,
            errors: 0,
            skips: 0,
            passed: 0
          }
          all_failures = []
          all_deprecations = []
          total_duration = 0.0
          all_test_times = []

          group_results.each do |gr|
            parsed = gr[:parsed]
            total_summary[:runs] += parsed[:summary][:runs]
            total_summary[:assertions] += parsed[:summary][:assertions]
            total_summary[:failures] += parsed[:summary][:failures]
            total_summary[:errors] += parsed[:summary][:errors]
            total_summary[:skips] += parsed[:summary][:skips]
            total_summary[:passed] += parsed[:summary][:passed]

            all_failures.concat(parsed[:failures] || [])
            all_deprecations.concat(parsed[:deprecations] || [])
            total_duration += gr[:duration]
            all_test_times.concat(parsed[:test_times] || [])
          end

          # Sort test times
          all_test_times.sort_by! { |t| -t[:duration] } unless all_test_times.empty?

          # Combine stdout and stderr
          combined_stdout = all_results.map { |r| r[:stdout] }.join("\n")
          combined_stderr = all_results.map { |r| r[:stderr] }.join("\n")

          # Determine success
          success = total_summary[:failures] == 0 && total_summary[:errors] == 0

          {
            stdout: combined_stdout,
            stderr: combined_stderr,
            success: success,
            duration: total_duration,
            commands: all_results.map { |r| r[:command] || r[:commands] }.flatten.compact,
            parsed_result: {
              summary: total_summary,
              failures: all_failures,
              deprecations: all_deprecations,
              duration: total_duration,
              test_times: all_test_times
            },
            stopped_at_group: stopped
          }
        end
      end
    end
  end
end
