# frozen_string_literal: true

require "dry/cli"
require "fileutils"
require_relative "../../../molecules/reflection/report_collector"
require_relative "../../../molecules/reflection/synthesis_orchestrator"
require_relative "../../../molecules/reflection/timestamp_inferrer"
require_relative "../../../organisms/taskflow_management/release_manager"

module CodingAgentTools
  module Cli
    module Commands
      module Reflection
        # Synthesize command for synthesizing multiple reflection notes
        class Synthesize < Dry::CLI::Command
          desc "Synthesize multiple reflection notes into unified analysis"

          argument :reflection_notes, required: false, type: :array,
            desc: "Reflection note files to synthesize (default: auto-discover from current release)"

          option :model, type: :string, default: "google:gemini-2.5-pro",
            desc: "LLM model to use (default: google:gemini-2.5-pro)"

          option :output, type: :string,
            desc: "Output file path (default: timestampfrom-timestampto-reflection-synthesis.md)"

          option :format, type: :string, values: ["text", "json", "markdown"], default: "markdown",
            desc: "Output format (default: markdown)"

          option :system_prompt, type: :string,
            desc: "Custom system prompt file path (default: dev-handbook/templates/release-reflections/synthsize.system.prompt.md)"

          option :force, type: :boolean, default: false,
            desc: "Force overwrite existing files without confirmation"

          option :dry_run, type: :boolean, default: false,
            desc: "Show what would be done without executing synthesis"

          option :debug, type: :boolean, default: false,
            desc: "Enable debug output for verbose error information"

          option :archived, type: :boolean, default: true,
            desc: "Automatically move reflection notes to archived directory after synthesis (default: true)"

          example [
            "# Auto-discover and synthesize all reflections in current release",
            "--archived",
            "# Synthesize specific files",
            "reflection-2024-01-15.md reflection-2024-01-20.md",
            "reflection-*.md --model anthropic:claude-4-0-sonnet-latest",
            "reflection-*.md --output team-learning-synthesis.md --archived"
          ]

          def call(reflection_notes: [], **options)
            # Initialize ReleaseManager for path resolution
            release_manager = Organisms::TaskflowManagement::ReleaseManager.new

            # Auto-discover reflection notes if none provided
            if reflection_notes.nil? || reflection_notes.empty?
              info_output("🔍 Auto-discovering reflection notes in current release...")
              reflection_notes = auto_discover_reflection_notes(release_manager)

              if reflection_notes.empty?
                error_output("No reflection notes found in current release.")
                error_output("Create some reflection notes first or specify paths explicitly.")
                return 1
              end

              info_output("✅ Found #{reflection_notes.length} reflection notes")
            end

            # Validate minimum reflection notes
            if reflection_notes.length < 2
              error_output("Error: At least 2 reflection note files are required for synthesis")
              error_output("Found: #{reflection_notes.length} reflection(s)")
              return 1
            end

            # Collect and validate reflection notes
            info_output("🔍 Collecting and validating reflection notes...")
            report_collector = Molecules::Reflection::ReportCollector.new
            collection_result = report_collector.collect_reports(reflection_notes)

            unless collection_result.valid?
              error_output("Error: #{collection_result.error}")
              return 1
            end
            info_output("✅ Found #{collection_result.reports.length} valid reflection notes")

            # Infer timestamp range from reflection notes
            info_output("📅 Inferring timestamp range from reflection notes...")
            timestamp_inferrer = Molecules::Reflection::TimestampInferrer.new
            timestamp_result = timestamp_inferrer.infer_timestamp_range(collection_result.reports)

            if timestamp_result.valid?
              info_output("✅ Timestamp range: #{timestamp_result.from_date} to #{timestamp_result.to_date}")
            else
              info_output("⚠️  Could not infer timestamp range, using current date")
            end

            # Determine output file path
            output_path = determine_output_path(options[:output], timestamp_result, release_manager)
            info_output("📄 Output will be saved to: #{File.basename(output_path)}")

            # Determine system prompt path
            system_prompt_path = determine_system_prompt_path(options[:system_prompt])
            info_output("🎯 Using system prompt: #{system_prompt_path}")

            # Handle dry run
            if options[:dry_run]
              return show_dry_run_info(collection_result, timestamp_result, output_path, system_prompt_path, options)
            end

            # Execute synthesis
            info_output("🧠 Starting synthesis with model: #{options[:model]}")
            synthesis_orchestrator = Molecules::Reflection::SynthesisOrchestrator.new

            synthesis_result = synthesis_orchestrator.synthesize_reflections(
              reflections: collection_result.reports,
              timestamp_info: timestamp_result,
              model: options[:model],
              output_path: output_path,
              format: options[:format],
              system_prompt_path: system_prompt_path,
              force: options[:force],
              debug: options[:debug]
            )

            if synthesis_result.success?
              success_output("✅ Synthesis completed successfully")
              success_output("📄 Report saved to: #{synthesis_result.output_path}")

              # Show synthesis metrics
              show_synthesis_metrics(synthesis_result)

              # Archive reflection notes if requested
              if options[:archived]
                archive_result = archive_reflection_notes(collection_result.reports)
                if archive_result[:success]
                  success_output("📦 Archived #{archive_result[:count]} reflection notes")
                  success_output("📁 Archive location: #{archive_result[:archive_dir]}")
                else
                  error_output("⚠️  Warning: Could not archive reflection notes: #{archive_result[:error]}")
                end
              end

              0
            else
              error_output("❌ Synthesis failed: #{synthesis_result.error}")
              1
            end
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def determine_output_path(explicit_output, timestamp_result, release_manager)
            return explicit_output if explicit_output

            # Generate timestamp-based filename
            output_filename = if timestamp_result.valid?
              from_date = timestamp_result.from_date.strftime("%Y%m%d")
              to_date = timestamp_result.to_date.strftime("%Y%m%d")
              "#{from_date}-#{to_date}-reflection-synthesis.md"
            else
              # Fallback to current date
              current_date = Time.now.strftime("%Y%m%d")
              "#{current_date}-reflection-synthesis.md"
            end

            # Use ReleaseManager to resolve the synthesis directory path
            begin
              synthesis_dir = release_manager.resolve_path("reflections/synthesis", create_if_missing: true)
              File.join(synthesis_dir, output_filename)
            rescue => e
              error_output("Warning: Could not resolve release path for synthesis directory: #{e.message}")
              error_output("This usually means no current release is active.")
              error_output("Falling back to current working directory")
              output_filename
            end
          end

          def determine_system_prompt_path(explicit_prompt)
            return explicit_prompt if explicit_prompt

            # Default system prompt path
            "dev-handbook/templates/release-reflections/synthsize.system.prompt.md"
          end

          def show_dry_run_info(collection_result, timestamp_result, output_path, system_prompt_path, options)
            info_output("🔍 Dry run - Reflection Synthesis Configuration:")
            info_output("")

            info_output("Reflection Notes to Synthesize:")
            collection_result.reports.each_with_index do |report, index|
              info_output("  #{index + 1}. #{report}")
            end
            info_output("")

            info_output("Timestamp Analysis:")
            if timestamp_result.valid?
              info_output("  ✅ Timestamp range detected: #{timestamp_result.from_date} to #{timestamp_result.to_date}")
              info_output("  📅 Coverage: #{timestamp_result.days_covered} days")
            else
              info_output("  ❌ No timestamp range detected")
              info_output("  📅 Using current date as fallback")
            end
            info_output("")

            info_output("Synthesis Configuration:")
            info_output("  🤖 Model: #{options[:model]}")
            info_output("  📄 Output: #{output_path}")
            info_output("  📝 Format: #{options[:format]}")
            info_output("  🎯 System prompt: #{system_prompt_path}")
            info_output("  💪 Force overwrite: #{options[:force]}")
            info_output("")

            0
          end

          def auto_discover_reflection_notes(release_manager)
            # Use ReleaseManager to find the reflections directory
            reflections_dir = release_manager.resolve_path("reflections")

            # Look for reflection note files (markdown files matching typical reflection patterns)
            reflection_patterns = [
              File.join(reflections_dir, "*.md"),
              File.join(reflections_dir, "reflection-*.md"),
              File.join(reflections_dir, "*-reflection.md")
            ]

            reflection_files = []
            reflection_patterns.each do |pattern|
              reflection_files.concat(Dir.glob(pattern))
            end

            # Remove duplicates and filter out synthesis files
            reflection_files.uniq.reject { |file| File.basename(file).include?("synthesis") }
          rescue => e
            error_output("Warning: Could not auto-discover reflections using ReleaseManager: #{e.message}")
            error_output("This usually means no current release is active.")
            error_output("Falling back to legacy path resolver...")

            # Fallback to legacy method
            begin
              path_resolver = CodingAgentTools::Molecules::PathResolver.new
              result = path_resolver.find_reflection_paths_in_current_release

              if result[:success]
                result[:paths] || []
              else
                error_output("Warning: Could not auto-discover reflections: #{result[:error]}")
                []
              end
            rescue => fallback_error
              error_output("Warning: Auto-discovery failed: #{fallback_error.message}")
              []
            end
          end

          def archive_reflection_notes(reflection_paths)
            return {success: false, error: "No reflection paths provided"} if reflection_paths.empty?

            begin
              # Create archive directory
              timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
              archive_dir = find_archive_directory_for_reflection(reflection_paths.first, timestamp)

              FileUtils.mkdir_p(archive_dir)

              # Move each reflection to archive
              archived_count = 0
              reflection_paths.each do |reflection_path|
                next unless File.exist?(reflection_path)

                filename = File.basename(reflection_path)
                archive_path = File.join(archive_dir, filename)

                FileUtils.mv(reflection_path, archive_path)
                archived_count += 1
              end

              # Create archive summary
              create_archive_summary(archive_dir, reflection_paths, archived_count)

              {success: true, count: archived_count, archive_dir: archive_dir}
            rescue => e
              {success: false, error: e.message}
            end
          end

          def find_archive_directory_for_reflection(sample_reflection_path, timestamp)
            # Find the reflections directory for this reflection
            reflection_dir = File.dirname(sample_reflection_path)

            # Create archived subdirectory
            File.join(reflection_dir, "archived", "synthesis-#{timestamp}")
          end

          def create_archive_summary(archive_dir, original_paths, archived_count)
            summary_path = File.join(archive_dir, "archive-summary.md")

            content = <<~MARKDOWN
              # Reflection Archive Summary

              **Archive Date**: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
              **Reflections Archived**: #{archived_count}
              **Archive Directory**: #{archive_dir}

              ## Archived Reflections

              #{original_paths.map { |path| "- #{File.basename(path)}" }.join("\n")}

              ## Next Steps

              1. Review synthesis report for action items
              2. Create tasks for critical and high-priority issues
              3. Implement recommended improvements
              4. Conduct follow-up synthesis after next development cycle
            MARKDOWN

            File.write(summary_path, content)
          end

          def show_synthesis_metrics(synthesis_result)
            return unless synthesis_result.metrics

            info_output("")
            info_output("📊 Synthesis Metrics:")

            metrics = synthesis_result.metrics
            info_output("  📝 Reflections processed: #{metrics[:reflections_count] || "unknown"}")
            info_output("  ⏱️  Processing time: #{metrics[:execution_time] || "unknown"}s") if metrics[:execution_time]
            info_output("  🔤 Output tokens: #{metrics[:output_tokens]}") if metrics[:output_tokens]
            info_output("  💰 Cost: $#{format("%.6f", metrics[:cost])}") if metrics[:cost]
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
