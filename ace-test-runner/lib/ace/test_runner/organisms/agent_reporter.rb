# frozen_string_literal: true

module Ace
  module TestRunner
    module Organisms
      # Specialized reporter for AI agent consumption (recreating lost functionality)
      # This was originally a 242-line component that provided AI-friendly output
      class AgentReporter
        def initialize(options = {})
          @verbose = options[:verbose] || false
          @format = options[:format] || "structured"
          @include_raw = options[:include_raw] || false
        end

        def generate_agent_report(result, report)
          {
            execution_summary: generate_execution_summary(result),
            actionable_items: generate_actionable_items(result),
            context_for_ai: generate_ai_context(result, report),
            suggested_actions: generate_suggested_actions(result),
            structured_failures: generate_structured_failures(result),
            code_quality_insights: generate_quality_insights(result),
            fix_commands: generate_fix_commands(result)
          }
        end

        def format_for_agent(result)
          lines = []

          # Status indicator
          lines << "TEST_EXECUTION_STATUS: #{result.success? ? "SUCCESS" : "FAILURE"}"
          lines << "TEST_METRICS: passed=#{result.passed} failed=#{result.failed} errors=#{result.errors} skipped=#{result.skipped}"

          # Actionable failures
          if result.has_failures?
            lines << "\nACTIONABLE_FAILURES:"
            result.failures_detail.each_with_index do |failure, idx|
              lines << "  FAILURE_#{idx + 1}:"
              lines << "    TYPE: #{failure.type}"
              lines << "    TEST: #{failure.full_test_name}"
              lines << "    FILE: #{failure.file_path}"
              lines << "    LINE: #{failure.line_number}"
              lines << "    FIX_SUGGESTION: #{failure.fix_suggestion || "Review test logic"}"
            end
          end

          # Deprecations that need fixing
          if result.has_deprecations?
            lines << "\nDEPRECATIONS_TO_FIX:"
            result.deprecations.each_with_index do |dep, idx|
              lines << "  DEPRECATION_#{idx + 1}: #{dep}"
            end
          end

          # Next steps
          lines << "\nNEXT_STEPS:"
          generate_next_steps(result).each do |step|
            lines << "  - #{step}"
          end

          lines.join("\n")
        end

        def generate_fix_script(result)
          return nil unless result.has_failures? || result.has_deprecations?

          script_lines = ["#!/usr/bin/env ruby", "# Auto-generated fix script", ""]

          # Add deprecation fixes
          if result.has_deprecations?
            script_lines << "# Fix deprecations"
            script_lines << "puts 'Fixing deprecations...'"
            script_lines << "system('ace-test --fix-deprecations')"
            script_lines << ""
          end

          # Add failure fixes based on patterns
          if result.has_failures?
            script_lines << "# Suggested fixes for failures"
            result.failures_detail.each do |failure|
              if failure.fix_suggestion
                script_lines << "# #{failure.full_test_name}"
                script_lines << "# Suggestion: #{failure.fix_suggestion}"
                script_lines << "# TODO: Implement fix for #{failure.location}"
                script_lines << ""
              end
            end
          end

          script_lines.join("\n")
        end

        private

        def generate_execution_summary(result)
          {
            status: result.success? ? "all_passing" : "failures_detected",
            test_count: result.total_tests,
            pass_rate_percent: result.pass_rate,
            duration_seconds: result.duration,
            critical_failures: count_critical_failures(result),
            needs_immediate_attention: result.failed > 0 || result.errors > 0
          }
        end

        def generate_actionable_items(result)
          items = []

          # High priority: errors
          if result.errors > 0
            items << {
              priority: "high",
              type: "fix_errors",
              count: result.errors,
              action: "Fix runtime errors preventing test execution"
            }
          end

          # Medium priority: failures
          if result.failed > 0
            items << {
              priority: "medium",
              type: "fix_failures",
              count: result.failed,
              action: "Fix assertion failures in test logic"
            }
          end

          # Low priority: deprecations
          if result.has_deprecations?
            items << {
              priority: "low",
              type: "fix_deprecations",
              count: result.deprecations.size,
              action: "Update deprecated code patterns"
            }
          end

          # Info: skipped tests
          if result.skipped > 0
            items << {
              priority: "info",
              type: "review_skips",
              count: result.skipped,
              action: "Review and enable skipped tests"
            }
          end

          items
        end

        def generate_ai_context(result, report)
          {
            project_state: determine_project_state(result),
            test_coverage: estimate_coverage(result),
            code_stability: calculate_stability_score(result),
            recommended_focus: recommend_focus_area(result),
            environment: report.environment,
            test_patterns: analyze_test_patterns(result)
          }
        end

        def generate_suggested_actions(result)
          actions = []

          if result.errors > 0
            actions << "Run failing tests individually to isolate errors"
            actions << "Check for missing dependencies or setup issues"
          end

          if result.failed > 5
            actions << "Focus on fixing the most common failure pattern first"
            actions << "Consider running tests with --fail-fast to speed up debugging"
          end

          if result.pass_rate < 80
            actions << "Review recent changes that may have broken tests"
            actions << "Run git bisect to find the commit that introduced failures"
          end

          if result.has_deprecations?
            actions << "Run 'ace-test --fix-deprecations' to auto-fix deprecation warnings"
          end

          if result.duration > 60
            actions << "Consider parallel test execution to reduce runtime"
            actions << "Profile slow tests and optimize or mark as slow"
          end

          actions
        end

        def generate_structured_failures(result)
          return {} unless result.has_failures?

          analyzer = Molecules::FailureAnalyzer.new
          common_issues = analyzer.find_common_issues(result.failures_detail)

          {
            total_failures: result.failures_detail.size,
            failure_types: result.failures_detail.group_by(&:type).transform_values(&:count),
            common_patterns: common_issues,
            affected_files: result.failures_detail.map(&:file_path).uniq.compact,
            suggested_fix_order: prioritize_fixes(result.failures_detail)
          }
        end

        def generate_quality_insights(result)
          {
            assertion_density: result.assertions.to_f / result.total_tests,
            failure_clustering: analyze_failure_clustering(result),
            test_performance: categorize_test_performance(result),
            maintainability_score: calculate_maintainability_score(result)
          }
        end

        def generate_fix_commands(result)
          commands = []

          # Commands based on failure types
          if result.has_failures?
            commands << "# Run only failing tests"
            failing_files = result.failures_detail.map(&:file_path).uniq.compact
            failing_files.each do |file|
              commands << "ace-test --filter '#{File.basename(file)}'"
            end
          end

          # Deprecation fix command
          if result.has_deprecations?
            commands << "# Fix deprecations"
            commands << "ace-test --fix-deprecations"
          end

          # Debug commands
          if result.errors > 0
            commands << "# Debug with verbose output"
            commands << "ace-test --verbose --fail-fast"
          end

          commands
        end

        def generate_next_steps(result)
          steps = []

          if result.success?
            steps << "All tests passing - consider adding more test coverage"
            steps << "Review code for potential optimizations"
          elsif result.errors > 0
            steps << "Fix critical errors preventing test execution"
            steps << "Check test environment and dependencies"
          elsif result.failed > 0
            steps << "Fix failing assertions in order of priority"
            steps << "Run focused tests on problem areas"
          end

          if result.has_deprecations?
            steps << "Update deprecated code patterns"
          end

          steps
        end

        def count_critical_failures(result)
          result.failures_detail.count { |f| f.type == :error }
        end

        def determine_project_state(result)
          if result.success?
            "stable"
          elsif result.pass_rate >= 90
            "mostly_stable"
          elsif result.pass_rate >= 70
            "unstable"
          else
            "broken"
          end
        end

        def estimate_coverage(result)
          # Rough estimation based on assertion density
          assertion_density = (result.total_tests > 0) ? result.assertions.to_f / result.total_tests : 0

          if assertion_density > 10
            "high"
          elsif assertion_density > 5
            "medium"
          else
            "low"
          end
        end

        def calculate_stability_score(result)
          # Score from 0-100 based on various factors
          score = 100

          # Deduct for failures
          score -= (result.failed * 5)
          score -= (result.errors * 10)
          score -= (result.skipped * 1)

          # Bonus for high assertion count
          score += [result.assertions / 10, 10].min

          [score, 0].max
        end

        def recommend_focus_area(result)
          if result.errors > 0
            "critical_errors"
          elsif result.failed > result.total_tests * 0.3
            "widespread_failures"
          elsif result.has_deprecations?
            "technical_debt"
          elsif result.skipped > result.total_tests * 0.2
            "test_coverage"
          else
            "optimization"
          end
        end

        def analyze_test_patterns(result)
          {
            uses_assertions: result.assertions > 0,
            has_skipped_tests: result.skipped > 0,
            has_error_tests: result.errors > 0,
            average_assertions_per_test: (result.total_tests > 0) ? result.assertions.to_f / result.total_tests : 0
          }
        end

        def analyze_failure_clustering(result)
          return "none" unless result.has_failures?

          files = result.failures_detail.map(&:file_path).compact
          unique_files = files.uniq.size
          total_failures = files.size

          if unique_files == 1
            "single_file"
          elsif unique_files < total_failures * 0.3
            "clustered"
          else
            "distributed"
          end
        end

        def categorize_test_performance(result)
          if result.duration < 1
            "fast"
          elsif result.duration < 10
            "acceptable"
          elsif result.duration < 60
            "slow"
          else
            "very_slow"
          end
        end

        def calculate_maintainability_score(result)
          score = 100

          # Factors that reduce maintainability
          score -= result.deprecations.size * 2
          score -= result.skipped * 1
          score -= [result.duration / 10, 20].min  # Slow tests are harder to maintain

          [score, 0].max
        end

        def prioritize_fixes(failures)
          # Sort by priority: errors first, then by file to fix related issues together
          failures.sort_by do |failure|
            [
              (failure.type == :error) ? 0 : 1,
              failure.file_path || "",
              failure.line_number || 0
            ]
          end.map(&:full_test_name)
        end
      end
    end
  end
end
