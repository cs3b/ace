# frozen_string_literal: true

require_relative "../../atoms/code_quality/configuration_loader"
require_relative "../../atoms/code_quality/path_resolver"
require_relative "language_runner_factory"
require_relative "../../molecules/code_quality/autofix_orchestrator"
require_relative "../../molecules/code_quality/error_file_generator"
require_relative "../../molecules/code_quality/diff_review_analyzer"

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Main organism for orchestrating the 3-phase code quality system
      class MultiPhaseQualityManager
        attr_reader :config, :path_resolver, :dry_run

        def initialize(config_path: nil, dry_run: false)
          @config_loader = Atoms::CodeQuality::ConfigurationLoader.new(
            config_path: config_path
          )
          @config = @config_loader.load
          @path_resolver = Atoms::CodeQuality::PathResolver.new
          @dry_run = dry_run
        end

        def validate_configuration
          result = @config_loader.validate
          result[:valid]
        end

        def run(target: "all", paths: ["."], autofix: false, review_diff: false, show_details: false)
          puts "🔍 Starting Code Quality Validation"

          # Phase 1: Detection & Validation
          phase1_results = run_phase1(target, paths, autofix, show_details)

          # Write detailed results to file if issues found
          write_detailed_report(phase1_results, target) if phase1_results[:ruby] || phase1_results[:markdown]

          return phase1_results unless autofix

          # Phase 2: Moderate Autofix & Error Distribution
          phase2_results = run_phase2(phase1_results, target, paths, review_diff)

          # Prepare for Phase 3 (Agent Integration Foundation)
          phase3_results = prepare_phase3(phase2_results)

          # Combine all results
          combine_results(phase1_results, phase2_results, phase3_results)
        end

        private

        def run_phase1(target, paths, autofix, _show_details)
          puts "\n📋 Phase 1: Detection & Validation"

          results = {
            phase: 1,
            timestamp: Time.now,
            ruby: nil,
            markdown: nil,
            success: true
          }

          # Take snapshot before any changes
          diff_analyzer = Molecules::CodeQuality::DiffReviewAnalyzer.new
          before_snapshot = diff_analyzer.create_snapshot if autofix

          # Run Ruby linters
          if ["ruby", "all"].include?(target)
            ruby_runner = LanguageRunnerFactory.create_runner(
              "ruby",
              config: @config,
              path_resolver: @path_resolver
            )
            results[:ruby] = if autofix
              ruby_runner.autofix(paths: paths)
            else
              ruby_runner.validate(paths: paths)
            end
            results[:success] &&= results[:ruby][:success]
          end

          # Run Markdown linters
          if ["markdown", "all"].include?(target)
            markdown_runner = LanguageRunnerFactory.create_runner(
              "markdown",
              config: @config,
              path_resolver: @path_resolver
            )
            results[:markdown] = if autofix
              markdown_runner.autofix(paths: paths)
            else
              markdown_runner.validate(paths: paths)
            end
            results[:success] &&= results[:markdown][:success]
          end

          results[:before_snapshot] = before_snapshot if before_snapshot
          display_phase1_summary(results)

          # Don't show detailed results in console anymore
          # Detailed results are written to file instead

          results
        end

        def run_phase2(phase1_results, target, paths, review_diff)
          puts "\n🔧 Phase 2: Moderate Autofix & Error Distribution" unless @dry_run

          results = {
            phase: 2,
            timestamp: Time.now,
            autofix_summary: nil,
            error_distribution: nil,
            diff_review: nil
          }

          # Apply autofixes
          autofix_orchestrator = Molecules::CodeQuality::AutofixOrchestrator.new(
            dry_run: @dry_run
          )
          results[:autofix_summary] = autofix_orchestrator.apply_fixes(phase1_results)

          # Re-validate after fixes
          if results[:autofix_summary][:total_fixed] > 0
            puts "  ↻ Re-validating after fixes..." unless @dry_run
            revalidation = run_phase1(target, paths, false, false)
            results[:revalidation] = autofix_orchestrator.validate_fixes(
              phase1_results,
              revalidation
            )
          end

          # Generate error distribution files
          if @config.dig("error_distribution", "enabled")
            error_generator = Molecules::CodeQuality::ErrorFileGenerator.new(
              output_dir: @path_resolver.project_root,
              max_files: @config.dig("error_distribution", "max_files") || 4
            )

            # Clean up old error files first
            error_generator.cleanup

            # Generate new error files from latest results
            latest_results = results[:revalidation] ? revalidation : phase1_results
            results[:error_distribution] = error_generator.generate(latest_results)
          end

          # Generate diff review if requested
          if review_diff && phase1_results[:before_snapshot]
            diff_analyzer = Molecules::CodeQuality::DiffReviewAnalyzer.new
            after_snapshot = diff_analyzer.create_snapshot

            analysis = diff_analyzer.analyze_changes(
              before_snapshot: phase1_results[:before_snapshot],
              after_snapshot: after_snapshot
            )

            results[:diff_review] = {
              analysis: analysis,
              review: diff_analyzer.format_review(analysis)
            }

            # Write review to file
            review_path = File.join(@path_resolver.project_root, ".lint-diff-review.md")
            File.write(review_path, results[:diff_review][:review])
            puts "  📝 Diff review written to: #{review_path}" unless @dry_run
          end

          display_phase2_summary(results) unless @dry_run
          results
        end

        def prepare_phase3(phase2_results)
          puts "\n🤖 Phase 3: Agent Integration Foundation" unless @dry_run

          results = {
            phase: 3,
            timestamp: Time.now,
            agent_ready: false,
            error_files: []
          }

          # Check if error files were generated
          if phase2_results.dig(:error_distribution, :files_generated)
            results[:error_files] = phase2_results[:error_distribution][:files_generated]
            results[:agent_ready] = results[:error_files].any?
          end

          # Prepare agent coordination metadata
          if results[:agent_ready]
            results[:agent_metadata] = {
              total_errors: phase2_results.dig(:error_distribution, :total_errors),
              error_files: results[:error_files].size,
              workflow_instruction: "dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md",
              parallel_agents: @config.dig("error_distribution", "max_files") || 4
            }
          end

          display_phase3_summary(results) unless @dry_run
          results
        end

        def combine_results(phase1, phase2, phase3)
          {
            success: phase1[:success] &&
              (!phase2 || phase2.dig(:revalidation, :success) != false),
            phases: {
              phase1: phase1,
              phase2: phase2,
              phase3: phase3
            },
            summary: build_final_summary(phase1, phase2, phase3)
          }
        end

        def build_final_summary(phase1, phase2, phase3)
          summary = {
            total_issues_found: 0,
            total_issues_fixed: 0,
            total_issues_remaining: 0,
            files_modified: 0,
            error_files_generated: 0,
            agent_ready: false
          }

          # Count issues from phase 1
          summary[:total_issues_found] += phase1.dig(:ruby, :total_issues) || 0
          summary[:total_issues_found] += phase1.dig(:markdown, :total_issues) || 0

          # Count fixes from phase 2
          if phase2
            summary[:total_issues_fixed] = phase2.dig(:autofix_summary, :total_fixed) || 0
            summary[:files_modified] = phase2.dig(:diff_review, :analysis, :summary, :files_modified) || 0
            summary[:error_files_generated] = phase2.dig(:error_distribution, :files_generated)&.size || 0
          end

          # Calculate remaining issues
          summary[:total_issues_remaining] = summary[:total_issues_found] - summary[:total_issues_fixed]

          # Agent readiness from phase 3
          summary[:agent_ready] = phase3&.dig(:agent_ready) || false

          summary
        end

        def display_phase1_summary(results)
          puts "\n  Phase 1 Summary:"

          total_issues = 0
          if results[:ruby]
            puts "  • Ruby linters: #{results[:ruby][:total_issues]} issues found"
            total_issues += results[:ruby][:total_issues]
          end

          if results[:markdown]
            puts "  • Markdown linters: #{results[:markdown][:total_issues]} issues found"
            total_issues += results[:markdown][:total_issues]
          end

          status = results[:success] ? "✅ PASSED" : "❌ FAILED"
          puts "  • Overall status: #{status}"

          return unless total_issues > 0 && !@dry_run

          puts "\n  📄 Detailed report: .lint-report.md"
        end

        def display_phase2_summary(results)
          puts "\n  Phase 2 Summary:"

          if results[:autofix_summary]
            puts "  • Fixes applied: #{results[:autofix_summary][:total_fixed]}"
            puts "  • Fix failures: #{results[:autofix_summary][:total_failed]}"
          end

          return unless results[:error_distribution]

          puts "  • Error files generated: #{results[:error_distribution][:files_generated].size}"
        end

        def display_phase3_summary(results)
          puts "\n  Phase 3 Summary:"

          if results[:agent_ready]
            puts "  • Agent coordination: READY"
            puts "  • Error files: #{results[:error_files].size}"
            puts "  • Parallel agents supported: #{results[:agent_metadata][:parallel_agents]}"
          else
            puts "  • Agent coordination: NOT NEEDED (no errors to process)"
          end
        end

        def display_detailed_results(results)
          puts "\n📊 Detailed Results:"

          # Display Ruby linting results
          if results[:ruby] && results[:ruby][:linters]
            results[:ruby][:linters].each do |linter_name, linter_result|
              next unless linter_result[:findings] && !linter_result[:findings].empty?

              puts "\n  #{linter_name.to_s.upcase}:"
              linter_result[:findings].each do |finding|
                display_finding(finding, linter_name)
              end
            end
          end

          # Display Markdown linting results
          return unless results[:markdown] && results[:markdown][:linters]

          results[:markdown][:linters].each do |linter_name, linter_result|
            if linter_result[:findings] && !linter_result[:findings].empty?
              puts "\n  #{linter_name.to_s.upcase}:"
              linter_result[:findings].each do |finding|
                display_finding(finding, linter_name)
              end
            elsif linter_result[:errors] && !linter_result[:errors].empty?
              puts "\n  #{linter_name.to_s.upcase}:"
              linter_result[:errors].each do |error|
                puts "    ❌ #{error}"
              end
            end
          end
        end

        def display_finding(finding, linter_name)
          case linter_name
          when :standardrb
            relative_file = make_path_relative(finding[:file])
            location = "#{relative_file}:#{finding[:line]}:#{finding[:column]}"
            severity = (finding[:severity] == "error") ? "❌" : "⚠️"
            puts "    #{severity} #{location} - #{finding[:message]} (#{finding[:cop]})"
          when :security
            puts "    ⚠️  Security: #{finding}"
          when :cassettes
            relative_path = make_path_relative(finding[:path])
            puts "    ⚠️  #{relative_path} - #{finding[:size_formatted]} (threshold exceeded)"
          when :task_metadata, :link_validation, :template_embedding
            if finding.is_a?(Hash)
              file = finding[:file] || "unknown"
              relative_file = (file != "unknown") ? make_path_relative(file) : file
              message = finding[:message] || finding[:template] || finding[:link] || "issue"
              puts "    ❌ #{relative_file} - #{message}"
            else
              puts "    ❌ #{finding}"
            end
          else
            puts "    • #{finding}"
          end
        end

        def write_detailed_report(results, target)
          report_path = File.join(@path_resolver.project_root, ".lint-report.md")

          File.open(report_path, "w") do |f|
            f.puts "# Code Quality Report"
            f.puts "\n**Generated**: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
            f.puts "**Target**: #{target}"
            f.puts "\n## Summary"

            total_issues = 0
            if results[:ruby]
              f.puts "\n### Ruby Linters"
              f.puts "- Total issues: #{results[:ruby][:total_issues]}"
              total_issues += results[:ruby][:total_issues]
            end

            if results[:markdown]
              f.puts "\n### Markdown Linters"
              f.puts "- Total issues: #{results[:markdown][:total_issues]}"
              total_issues += results[:markdown][:total_issues]
            end

            f.puts "\n**Total Issues Found**: #{total_issues}"

            # Write detailed findings
            f.puts "\n## Detailed Findings"

            # Ruby findings
            if results[:ruby] && results[:ruby][:linters]
              results[:ruby][:linters].each do |linter_name, linter_result|
                # Show errors even if no findings
                if linter_result[:error]
                  f.puts "\n### #{linter_name.to_s.upcase} (ERROR)"
                  f.puts "\n```"
                  f.puts "❌ #{linter_result[:error]}"
                  f.puts "```"
                elsif linter_result[:findings] && !linter_result[:findings].empty?
                  f.puts "\n### #{linter_name.to_s.upcase}"
                  f.puts "\n```"
                  linter_result[:findings].each do |finding|
                    f.puts format_finding_for_report(finding, linter_name)
                  end
                  f.puts "```"
                else
                  # Show successful linters with no findings
                  f.puts "\n### #{linter_name.to_s.upcase}"
                  f.puts "\nNo issues found ✅"
                end
              end
            end

            # Markdown findings
            if results[:markdown] && results[:markdown][:linters]
              results[:markdown][:linters].each do |linter_name, linter_result|
                if linter_result[:findings] && !linter_result[:findings].empty?
                  f.puts "\n### #{linter_name.to_s.upcase}"
                  f.puts "\n```"
                  linter_result[:findings].each do |finding|
                    f.puts format_finding_for_report(finding, linter_name)
                  end
                  f.puts "```"
                elsif linter_result[:errors] && !linter_result[:errors].empty?
                  f.puts "\n### #{linter_name.to_s.upcase} ERRORS"
                  f.puts "\n```"
                  linter_result[:errors].each do |error|
                    f.puts "❌ #{error}"
                  end
                  f.puts "```"
                else
                  # Show successful linters with no findings
                  f.puts "\n### #{linter_name.to_s.upcase}"
                  f.puts "\nNo issues found ✅"
                end
              end
            end

            f.puts "\n## Next Steps"
            f.puts "\n1. Review the issues listed above"
            f.puts "2. Run `code-lint --autofix` to apply automatic fixes"
            f.puts "3. Manually fix remaining issues"
            f.puts "4. Re-run `code-lint` to verify all issues are resolved"
          end
        end

        def format_finding_for_report(finding, linter_name)
          case linter_name
          when :standardrb
            # Make path relative to project root
            relative_file = make_path_relative(finding[:file])
            location = "#{relative_file}:#{finding[:line]}:#{finding[:column]}"
            severity = (finding[:severity] == "error") ? "ERROR" : "WARNING"
            "#{severity}: #{location} - #{finding[:message]} (#{finding[:cop]})"
          when :security
            "Security Issue: #{finding}"
          when :cassettes
            relative_path = make_path_relative(finding[:path])
            "Cassette Issue: #{relative_path} - #{finding[:size_formatted]} (threshold exceeded)"
          when :task_metadata, :link_validation, :template_embedding
            if finding.is_a?(Hash)
              file = finding[:file] || "unknown"
              relative_file = (file != "unknown") ? make_path_relative(file) : file
              message = finding[:message] || finding[:template] || finding[:link] || "issue"
              "#{relative_file} - #{message}"
            else
              finding.to_s
            end
          else
            finding.to_s
          end
        end

        def make_path_relative(path)
          return path unless path && File.absolute_path?(path)

          project_root = @path_resolver.project_root
          path.start_with?(project_root) ? path.sub("#{project_root}/", "") : path
        end
      end
    end
  end
end
