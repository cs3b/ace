# frozen_string_literal: true

require 'json'

module AceTools
  module TestReporter
    module Formatters
      class JsonFormatter
        def format_summary(data)
          JSON.pretty_generate({
            timestamp: Time.now.iso8601,
            total_time: data[:total_time],
            total_tests: data[:total_tests],
            total_assertions: data[:total_assertions],
            groups: data[:groups],
            summary: build_summary_stats(data[:groups])
          })
        end

        def format_failures(failures)
          JSON.pretty_generate({
            timestamp: Time.now.iso8601,
            failure_count: failures.size,
            failures: failures.map { |failure| format_single_failure(failure) }
          })
        end

        private

        def build_summary_stats(groups)
          {
            total_passed: groups.sum { |g| g[:passed] },
            total_failed: groups.sum { |g| g[:failed] },
            total_errors: groups.sum { |g| g[:errors] },
            total_skipped: groups.sum { |g| g[:skipped] }
          }
        end

        def format_single_failure(result)
          {
            name: result.name,
            class: result.class_name,
            file: result.source_location&.first,
            line: result.source_location&.last,
            time: result.time,
            error_class: result.failure&.class&.name,
            message: extract_message(result),
            backtrace: extract_backtrace(result)
          }
        end

        def extract_message(result)
          return nil unless result.failure

          msg = result.failure.message.to_s
          # Clean up the message for better readability
          msg.split("\n").first(5).join("\n")
        end

        def extract_backtrace(result)
          return [] unless result.failure

          backtrace = result.failure.backtrace || []
          # Filter out framework lines, keep app lines
          backtrace.reject { |line| line.include?('/minitest/') || line.include?('/ruby/') }
                   .first(10)
        end
      end
    end
  end
end