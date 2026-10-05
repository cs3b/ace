# frozen_string_literal: true

require "securerandom"
require "json"
require "fileutils"

module Ace
  module TestRunner
    module Molecules
      # The completion file is published last, after the optional report is complete.
      # A suite reads this exact file once; latest is only a navigation convenience.
      class ExecutionEvidence
        CHANNEL = "ACE_TEST_EXECUTION"
        COUNTS = %w[total passed failed errors skipped assertions].freeze
        attr_reader :identity, :path, :package, :entry_id, :package_path

        def initialize(package_path:, package: nil, entry_id: nil, identity: SecureRandom.uuid, path: nil)
          @identity = identity
          @package_path = File.realpath(package_path)
          @package = package || File.basename(@package_path)
          @entry_id = entry_id || identity
          @path = path || File.join(@package_path, ".ace-local/test/completions", "#{identity}.json")
        end

        def self.for_invocation(package_path)
          channel = ENV[CHANNEL]
          return new(package_path: package_path) unless channel

          data = JSON.parse(channel, symbolize_names: true)
          raise Error, "Execution package path mismatch" unless File.realpath(package_path) == data[:package_path]

          new(**data)
        end

        def channel
          JSON.generate(identity: identity, path: path, package: package, entry_id: entry_id, package_path: package_path)
        end

        def publish(result, files:, report_dir: nil)
          data = {
            execution_id: identity, entry_id: entry_id, package: package, package_path: package_path,
            pid: Process.pid, completed: true, selected_files: files, report_dir: report_dir,
            total: result.total_tests, passed: result.passed, failed: result.failed, errors: result.errors,
            skipped: result.skipped, assertions: result.assertions, duration: result.duration,
            success: result.success?, error: result.execution_error
          }
          FileUtils.mkdir_p(File.dirname(path))
          temporary = "#{path}.#{SecureRandom.uuid}.tmp"
          File.write(temporary, JSON.generate(data))
          # Exclusive publication: a completed invocation may never be replaced.
          File.link(temporary, path)
          data
        ensure
          FileUtils.rm_f(temporary) if temporary
        end

        def read(pid:, save_reports:)
          data = JSON.parse(File.read(path))
          valid = data.is_a?(Hash) && data["completed"] == true &&
            data["execution_id"] == identity && data["entry_id"] == entry_id &&
            data["package"] == package && data["package_path"] == package_path && data["pid"] == pid &&
            data["selected_files"].is_a?(Array) && data["selected_files"].all? { |file| file.is_a?(String) } &&
            COUNTS.all? { |key| data[key].is_a?(Integer) && data[key] >= 0 } &&
            [true, false].include?(data["success"]) && data["duration"].is_a?(Numeric) &&
            data["duration"].finite? && data["duration"] >= 0 &&
            data["total"] == data.values_at("passed", "failed", "errors", "skipped").sum &&
            (!data["success"] || data["failed"] + data["errors"] == 0) &&
            (!data["selected_files"].empty? || data["total"] == 0)
          raise Error, "Invalid or mismatched execution completion evidence" unless valid

          if save_reports
            validate_report!(data)
          elsif data["report_dir"]
            raise Error, "Unexpected saved report in no-save execution"
          end
          data.transform_keys(&:to_sym)
        rescue SystemCallError, JSON::ParserError, TypeError => e
          raise Error, "Unverifiable execution completion evidence: #{e.message}"
        end

        private

        def validate_report!(data)
          directory = data["report_dir"]
          raise Error, "Missing concrete execution report directory" unless directory.is_a?(String) &&
            File.absolute_path(directory) == directory && File.basename(directory) == identity && !File.symlink?(directory)

          summary = JSON.parse(File.read(File.join(directory, "summary.json")))
          report = JSON.parse(File.read(File.join(directory, "report.json")))
          raise Error, "Mismatched execution summary/report" unless summary.is_a?(Hash) && report.is_a?(Hash) &&
            summary["execution_id"] == identity && report.dig("metadata", "execution_id") == identity &&
            report["report_path"] == directory && report["files_tested"] == data["selected_files"] &&
            report.dig("result", "total_tests") == data["total"] &&
            COUNTS.all? { |key| summary[key] == data[key] } && summary["success"] == data["success"] &&
            summary["duration"] == data["duration"] &&
            %w[passed failed errors skipped assertions duration success].all? { |key| report.dig("result", key) == data[key] }
        end
      end
    end
  end
end
