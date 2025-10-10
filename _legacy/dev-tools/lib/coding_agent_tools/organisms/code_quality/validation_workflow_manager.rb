# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Organism for managing validation workflows in Phase 2
      class ValidationWorkflowManager
        attr_reader :config

        def initialize(config:)
          @config = config
        end

        def orchestrate_validation(linting_results, autofix_applied: false)
          workflow = {
            validations_run: [],
            validations_passed: [],
            validations_failed: [],
            recommendations: []
          }

          # Run cross-validation checks
          run_cross_validations(linting_results, workflow)

          # Check for autofix regressions
          check_autofix_regressions(linting_results, workflow) if autofix_applied

          # Generate recommendations
          generate_recommendations(linting_results, workflow)

          workflow
        end

        private

        def run_cross_validations(results, workflow)
          # Check for conflicting fixes
          if has_conflicting_fixes?(results)
            workflow[:validations_failed] << {
              type: "conflicting_fixes",
              message: "Detected conflicting autofix rules between linters"
            }
          else
            workflow[:validations_passed] << {
              type: "conflicting_fixes",
              message: "No conflicting fixes detected"
            }
          end

          # Validate file integrity
          validate_file_integrity(results, workflow)

          # Check linter consistency
          check_linter_consistency(results, workflow)
        end

        def has_conflicting_fixes?(results)
          # Check if multiple linters want to modify the same lines
          modified_locations = {}

          %i[ruby markdown].each do |lang|
            next unless results[lang]

            results[lang][:linters].each do |_linter, data|
              next unless data[:findings]

              data[:findings].each do |finding|
                next unless finding[:correctable] || finding[:fixed]

                key = "#{finding[:file]}:#{finding[:line]}"
                modified_locations[key] ||= []
                modified_locations[key] << finding
              end
            end
          end

          # Check for conflicts
          modified_locations.any? { |_key, findings| findings.size > 1 }
        end

        def validate_file_integrity(results, workflow)
          integrity_issues = []

          # Check for files that might have been corrupted
          all_files = extract_all_files(results)

          all_files.each do |file|
            next unless File.exist?(file)

            # Basic integrity checks
            if File.size(file) == 0
              integrity_issues << "#{file} is empty"
            elsif !File.readable?(file)
              integrity_issues << "#{file} is not readable"
            end
          end

          if integrity_issues.empty?
            workflow[:validations_passed] << {
              type: "file_integrity",
              message: "All files passed integrity checks"
            }
          else
            workflow[:validations_failed] << {
              type: "file_integrity",
              message: "File integrity issues detected",
              details: integrity_issues
            }
          end
        end

        def check_linter_consistency(results, workflow)
          inconsistencies = []

          # Check if linters are reporting contradictory issues
          file_issues = {}

          %i[ruby markdown].each do |lang|
            next unless results[lang]

            results[lang][:linters].each do |linter, data|
              next unless data[:findings]

              data[:findings].each do |finding|
                file_issues[finding[:file]] ||= []
                file_issues[finding[:file]] << {
                  linter: linter,
                  issue: finding
                }
              end
            end
          end

          # Look for contradictions
          file_issues.each do |file, issues|
            inconsistencies << file if has_contradictory_issues?(issues)
          end

          if inconsistencies.empty?
            workflow[:validations_passed] << {
              type: "linter_consistency",
              message: "Linters are consistent"
            }
          else
            workflow[:validations_failed] << {
              type: "linter_consistency",
              message: "Inconsistent linter results",
              files: inconsistencies
            }
          end
        end

        def has_contradictory_issues?(issues)
          # Simple heuristic: check if different linters report opposite fixes
          return false if issues.size < 2

          # Group by line number
          by_line = issues.group_by { |i| i[:issue][:line] }

          by_line.any? do |_line, line_issues|
            line_issues.size > 1 &&
              line_issues.map { |i| i[:issue][:message] }.uniq.size > 1
          end
        end

        def check_autofix_regressions(results, workflow)
          # Check if autofix introduced new issues
          new_issues_count = count_total_issues(results)

          if new_issues_count > 0
            workflow[:validations_failed] << {
              type: "autofix_regression",
              message: "Autofix may have introduced new issues",
              count: new_issues_count
            }
          else
            workflow[:validations_passed] << {
              type: "autofix_regression",
              message: "No regressions detected from autofix"
            }
          end
        end

        def generate_recommendations(results, workflow)
          total_issues = count_total_issues(results)

          if total_issues > 100
            workflow[:recommendations] << {
              priority: "high",
              message: "Consider fixing issues incrementally due to high count"
            }
          end

          if has_security_issues?(results)
            workflow[:recommendations] << {
              priority: "critical",
              message: "Security issues detected - fix these first"
            }
          end

          return unless has_broken_links?(results)

          workflow[:recommendations] << {
            priority: "medium",
            message: "Broken links detected - may impact documentation quality"
          }
        end

        def extract_all_files(results)
          files = Set.new

          %i[ruby markdown].each do |lang|
            next unless results[lang]

            results[lang][:linters].each do |_linter, data|
              next unless data[:findings]

              data[:findings].each do |finding|
                files << finding[:file] if finding[:file]
              end
            end
          end

          files.to_a
        end

        def count_total_issues(results)
          count = 0

          %i[ruby markdown].each do |lang|
            count += results.dig(lang, :total_issues) || 0
          end

          count
        end

        def has_security_issues?(results)
          results.dig(:ruby, :linters, :security, :findings)&.any?
        end

        def has_broken_links?(results)
          results.dig(:markdown, :linters, :link_validation, :findings)&.any?
        end
      end
    end
  end
end
