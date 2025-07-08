# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module CodeQuality
      # Molecule for orchestrating moderate-level autofix operations
      class AutofixOrchestrator
        attr_reader :dry_run

        def initialize(dry_run: false)
          @dry_run = dry_run
        end

        def apply_fixes(linting_results)
          fix_summary = {
            total_fixed: 0,
            total_failed: 0,
            fixes_applied: [],
            failures: []
          }

          # Process Ruby fixes
          if linting_results.dig(:ruby, :linters, :standardrb, :fixed)
            process_ruby_fixes(linting_results[:ruby], fix_summary)
          end

          # Process Markdown fixes
          if linting_results.dig(:markdown, :linters, :styleguide, :findings)
            process_markdown_fixes(linting_results[:markdown], fix_summary)
          end

          fix_summary
        end

        def validate_fixes(before_results, after_results)
          validation = {
            success: true,
            new_issues: [],
            resolved_issues: [],
            persistent_issues: []
          }

          # Compare before and after results
          compare_results(before_results, after_results, validation)
          
          validation
        end

        private

        def process_ruby_fixes(ruby_results, summary)
          standardrb = ruby_results.dig(:linters, :standardrb)
          return unless standardrb

          if standardrb[:fixed] && standardrb[:success]
            fixed_count = standardrb[:findings].count { |f| f[:correctable] }
            summary[:total_fixed] += fixed_count
            summary[:fixes_applied] << {
              type: "ruby_standardrb",
              count: fixed_count,
              message: "Applied StandardRB formatting fixes"
            }
          elsif standardrb[:fixed] && !standardrb[:success]
            summary[:total_failed] += 1
            summary[:failures] << {
              type: "ruby_standardrb",
              error: "Some StandardRB fixes could not be applied"
            }
          end
        end

        def process_markdown_fixes(markdown_results, summary)
          styleguide = markdown_results.dig(:linters, :styleguide)
          return unless styleguide

          fixed_count = styleguide[:findings].count { |f| f[:fixed] }
          
          if fixed_count > 0
            summary[:total_fixed] += fixed_count
            summary[:fixes_applied] << {
              type: "markdown_formatting",
              count: fixed_count,
              message: "Applied Kramdown formatting to markdown files"
            }
          end
        end

        def compare_results(before, after, validation)
          # Extract all issues from before and after
          before_issues = extract_all_issues(before)
          after_issues = extract_all_issues(after)

          # Find resolved issues
          before_issues.each do |issue|
            unless find_matching_issue(issue, after_issues)
              validation[:resolved_issues] << issue
            end
          end

          # Find new issues
          after_issues.each do |issue|
            unless find_matching_issue(issue, before_issues)
              validation[:new_issues] << issue
              validation[:success] = false
            end
          end

          # Find persistent issues
          after_issues.each do |issue|
            if find_matching_issue(issue, before_issues)
              validation[:persistent_issues] << issue
            end
          end
        end

        def extract_all_issues(results)
          issues = []

          # Ruby issues
          results.dig(:ruby, :linters)&.each do |linter, data|
            next unless data[:findings]
            
            data[:findings].each do |finding|
              issues << {
                type: "ruby_#{linter}",
                file: finding[:file],
                line: finding[:line],
                message: finding[:message] || finding.to_s
              }
            end
          end

          # Markdown issues
          results.dig(:markdown, :linters)&.each do |linter, data|
            if data[:findings]
              data[:findings].each do |finding|
                issues << {
                  type: "markdown_#{linter}",
                  file: finding[:file],
                  message: finding[:message] || finding.to_s
                }
              end
            elsif data[:errors]
              data[:errors].each do |error|
                issues << {
                  type: "markdown_#{linter}",
                  message: error
                }
              end
            end
          end

          issues
        end

        def find_matching_issue(issue, issue_list)
          issue_list.find do |other|
            issue[:type] == other[:type] &&
            issue[:file] == other[:file] &&
            issue[:line] == other[:line] &&
            issue[:message] == other[:message]
          end
        end
      end
    end
  end
end