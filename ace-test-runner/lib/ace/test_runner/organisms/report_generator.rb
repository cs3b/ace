# frozen_string_literal: true

module Ace
  module TestRunner
    module Organisms
      # Generates comprehensive test reports
      class ReportGenerator
        def initialize(configuration)
          @configuration = configuration
          @formatter = configuration.formatter_class.new(configuration.to_h)
        end

        def generate(result, files_tested)
          report = Models::TestReport.new(
            result: result,
            configuration: @configuration,
            timestamp: Time.now,
            files_tested: files_tested,
            metadata: generate_metadata
          )

          # Let formatter enhance the report if needed
          if @formatter.respond_to?(:enhance_report)
            @formatter.enhance_report(report)
          end

          report
        end

        def generate_summary(result)
          {
            total_tests: result.total_tests,
            passed: result.passed,
            failed: result.failed,
            errors: result.errors,
            skipped: result.skipped,
            pass_rate: result.pass_rate,
            duration: result.duration,
            success: result.success?
          }
        end

        def generate_failure_report(failures)
          return nil if failures.empty?

          {
            count: failures.size,
            by_type: group_failures_by_type(failures),
            by_file: group_failures_by_file(failures),
            details: failures.map(&:to_h)
          }
        end

        def generate_deprecation_report(deprecations)
          return nil if deprecations.empty?

          fixer = Molecules::DeprecationFixer.new
          fixes = deprecations.map do |deprecation|
            fixer.fix_deprecations_in_output(deprecation)
          end.flatten

          {
            count: deprecations.size,
            warnings: deprecations,
            suggested_fixes: fixes
          }
        end

        def generate_performance_report(result)
          {
            total_duration: result.duration,
            average_per_test: (result.total_tests > 0) ? result.duration / result.total_tests : 0,
            tests_per_second: (result.duration > 0) ? result.total_tests / result.duration : 0,
            assertions_per_second: (result.duration > 0) ? result.assertions / result.duration : 0
          }
        end

        def generate_recommendations(result)
          recommendations = []

          # Performance recommendations
          if result.duration > 60
            recommendations << {
              type: "performance",
              message: "Tests took over a minute. Consider using --parallel or optimizing slow tests."
            }
          end

          # Failure rate recommendations
          if result.pass_rate < 50
            recommendations << {
              type: "quality",
              message: "Less than 50% of tests passing. Focus on fixing critical failures first."
            }
          end

          # Skip recommendations
          if result.skipped > result.total_tests * 0.2
            recommendations << {
              type: "coverage",
              message: "Over 20% of tests are skipped. Review and enable skipped tests."
            }
          end

          # Deprecation recommendations
          if result.has_deprecations?
            recommendations << {
              type: "maintenance",
              message: "Deprecation warnings detected. Run with --fix-deprecations to auto-fix."
            }
          end

          recommendations
        end

        private

        def generate_metadata
          {
            generator: "ace-test-runner",
            version: VERSION,
            format: @configuration.format,
            timestamp: Time.now.iso8601,
            configuration_source: configuration_source
          }
        end

        def configuration_source
          if defined?(Ace::Core::Configuration)
            "ace-core cascade"
          elsif File.exist?(".ace/test.yml")
            "project configuration"
          else
            "defaults"
          end
        end

        def group_failures_by_type(failures)
          failures.group_by(&:type).transform_values(&:count)
        end

        def group_failures_by_file(failures)
          failures.group_by(&:file_path)
            .transform_values(&:count)
            .sort_by { |_, count| -count }
            .to_h
        end
      end
    end
  end
end
