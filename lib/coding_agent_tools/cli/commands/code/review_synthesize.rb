# frozen_string_literal: true

require "dry/cli"
require_relative "../../../molecules/code/report_collector"
require_relative "../../../molecules/code/session_path_inferrer"
require_relative "../../../molecules/code/synthesis_orchestrator"

module CodingAgentTools
  module Cli
    module Commands
      module Code
        # ReviewSynthesize command for synthesizing multiple code review reports
        class ReviewSynthesize < Dry::CLI::Command
          desc "Synthesize multiple code review reports into unified analysis"

          argument :reports, required: true, type: :array,
            desc: "Review report files to synthesize (minimum 2 files)"

          option :model, type: :string, default: "google:gemini-2.5-pro",
            desc: "LLM model to use (default: google:gemini-2.5-pro)"

          option :output, type: :string,
            desc: "Output file path (default: inferred from session or cr-report.md)"

          option :format, type: :string, values: %w[text json markdown], default: "markdown",
            desc: "Output format (default: markdown)"

          option :system_prompt, type: :string,
            desc: "Custom system prompt file path"

          option :force, type: :boolean, default: false,
            desc: "Force overwrite existing files without confirmation"

          option :dry_run, type: :boolean, default: false,
            desc: "Show what would be done without executing synthesis"

          option :debug, type: :boolean, default: false,
            desc: "Enable debug output for verbose error information"

          example [
            "cr-report-claude-opus.md cr-report-gpt4.md",
            "cr-report-*.md --model anthropic:claude-4-0-sonnet-latest",
            "cr-report-*.md --output final-synthesis.md",
            "cr-report-*.md --force"
          ]

          def call(reports:, **options)
            # Validate minimum reports
            if reports.length < 2
              error_output("Error: At least 2 report files are required for synthesis")
              return 1
            end

            # Collect and validate reports
            info_output("🔍 Collecting and validating review reports...")
            report_collector = Molecules::Code::ReportCollector.new
            collection_result = report_collector.collect_reports(reports)

            unless collection_result.valid?
              error_output("Error: #{collection_result.error}")
              return 1
            end
            info_output("✅ Found #{collection_result.reports.length} valid review reports")

            # Infer session directory from first report
            info_output("📁 Inferring session directory from report paths...")
            session_inferrer = Molecules::Code::SessionPathInferrer.new
            inference_result = session_inferrer.infer_session_path(collection_result.reports.first)
            
            if inference_result.has_session?
              info_output("✅ Session directory detected: #{File.basename(inference_result.session_directory)}")
            else
              info_output("📂 No session directory detected, using current directory")
            end

            # Determine output file path
            output_path = determine_output_path(options[:output], inference_result)
            info_output("📄 Output will be saved to: #{File.basename(output_path)}")

            # Handle dry run
            if options[:dry_run]
              return show_dry_run_info(collection_result, inference_result, output_path, options)
            end

            # Execute synthesis
            info_output("🧠 Starting synthesis with model: #{options[:model]}")
            synthesis_orchestrator = Molecules::Code::SynthesisOrchestrator.new
            
            synthesis_result = synthesis_orchestrator.synthesize_reports(
              reports: collection_result.reports,
              session_info: inference_result,
              model: options[:model],
              output_path: output_path,
              format: options[:format],
              system_prompt_path: options[:system_prompt],
              force: options[:force],
              debug: options[:debug]
            )

            if synthesis_result.success?
              success_output("✅ Synthesis completed successfully")
              success_output("📄 Report saved to: #{synthesis_result.output_path}")
              
              # Show synthesis metrics
              show_synthesis_metrics(synthesis_result)
              
              0
            else
              error_output("❌ Synthesis failed: #{synthesis_result.error}")
              return 1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def determine_output_path(explicit_output, inference_result)
            return explicit_output if explicit_output

            # If session directory inferred, use it for output
            if inference_result.session_directory
              File.join(inference_result.session_directory, "cr-report.md")
            else
              # Default to current directory
              "cr-report.md"
            end
          end

          def show_dry_run_info(collection_result, inference_result, output_path, options)
            info_output("🔍 Dry run - Code Review Synthesis Configuration:")
            info_output("")
            
            info_output("Reports to Synthesize:")
            collection_result.reports.each_with_index do |report, index|
              info_output("  #{index + 1}. #{report}")
            end
            info_output("")
            
            info_output("Session Analysis:")
            if inference_result.session_directory
              info_output("  ✅ Session directory detected: #{inference_result.session_directory}")
              info_output("  📁 Session type: #{inference_result.session_type}")
            else
              info_output("  ❌ No session directory detected")
              info_output("  📁 Working directory: #{Dir.pwd}")
            end
            info_output("")
            
            info_output("Synthesis Configuration:")
            info_output("  🤖 Model: #{options[:model]}")
            info_output("  📄 Output: #{output_path}")
            info_output("  📝 Format: #{options[:format]}")
            info_output("  🎯 System prompt: #{options[:system_prompt] || 'default'}")
            info_output("  💪 Force overwrite: #{options[:force]}")
            info_output("")
            
            0
          end

          def show_synthesis_metrics(synthesis_result)
            if synthesis_result.metrics
              info_output("")
              info_output("📊 Synthesis Metrics:")
              
              metrics = synthesis_result.metrics
              info_output("  📝 Reports processed: #{metrics[:reports_count] || 'unknown'}")
              info_output("  ⏱️  Processing time: #{metrics[:execution_time] || 'unknown'}s") if metrics[:execution_time]
              info_output("  🔤 Output tokens: #{metrics[:output_tokens]}") if metrics[:output_tokens]
              info_output("  💰 Cost: $#{sprintf('%.6f', metrics[:cost])}") if metrics[:cost]
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
            end
          end

          def success_output(message)
            puts message
          end

          def error_output(message)
            warn message
          end

          def info_output(message)
            puts message
          end
        end
      end
    end
  end
end