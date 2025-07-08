# frozen_string_literal: true

require_relative "../../atoms/code_quality/configuration_loader"
require_relative "../../atoms/code_quality/path_resolver"
require_relative "../../molecules/code_quality/ruby_linting_pipeline"
require_relative "../../molecules/code_quality/markdown_linting_pipeline"
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

        def run(target: "all", autofix: false, review_diff: false)
          puts "🔍 Starting Code Quality Validation"
          
          # Phase 1: Detection & Validation
          phase1_results = run_phase1(target, autofix)
          
          return phase1_results unless autofix
          
          # Phase 2: Moderate Autofix & Error Distribution
          phase2_results = run_phase2(phase1_results, review_diff)
          
          # Prepare for Phase 3 (Agent Integration Foundation)
          phase3_results = prepare_phase3(phase2_results)
          
          # Combine all results
          combine_results(phase1_results, phase2_results, phase3_results)
        end

        private

        def run_phase1(target, autofix)
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
          if %w[ruby all].include?(target)
            ruby_pipeline = Molecules::CodeQuality::RubyLintingPipeline.new(
              config: @config,
              path_resolver: @path_resolver
            )
            results[:ruby] = ruby_pipeline.run(autofix: autofix)
            results[:success] &&= results[:ruby][:success]
          end

          # Run Markdown linters
          if %w[markdown all].include?(target)
            markdown_pipeline = Molecules::CodeQuality::MarkdownLintingPipeline.new(
              config: @config,
              path_resolver: @path_resolver
            )
            results[:markdown] = markdown_pipeline.run(autofix: autofix)
            results[:success] &&= results[:markdown][:success]
          end

          results[:before_snapshot] = before_snapshot if before_snapshot
          display_phase1_summary(results)
          
          results
        end

        def run_phase2(phase1_results, review_diff)
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
            revalidation = run_phase1(target, false)
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
          
          if results[:ruby]
            puts "  • Ruby linters: #{results[:ruby][:total_issues]} issues found"
          end
          
          if results[:markdown]
            puts "  • Markdown linters: #{results[:markdown][:total_issues]} issues found"
          end
          
          status = results[:success] ? "✅ PASSED" : "❌ FAILED"
          puts "  • Overall status: #{status}"
        end

        def display_phase2_summary(results)
          puts "\n  Phase 2 Summary:"
          
          if results[:autofix_summary]
            puts "  • Fixes applied: #{results[:autofix_summary][:total_fixed]}"
            puts "  • Fix failures: #{results[:autofix_summary][:total_failed]}"
          end
          
          if results[:error_distribution]
            puts "  • Error files generated: #{results[:error_distribution][:files_generated].size}"
          end
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
      end
    end
  end
end