# frozen_string_literal: true

require "time"
require "yaml"
require "fileutils"
require_relative "llm_executor"

module Ace
  module Review
    module Molecules
      # Synthesizes multiple LLM review reports into a unified consolidated report
      # Uses LLM-powered analysis to identify consensus, conflicts, and prioritize actions
      class ReportSynthesizer
        attr_reader :llm_executor

        def initialize
          @llm_executor = LlmExecutor.new
        end

        # Synthesize multiple review reports into a consolidated report
        # @param report_paths [Array<String>] paths to review report files
        # @param model [String, nil] model to use for synthesis (default: gemini-2.5-flash)
        # @param session_dir [String] session directory for output
        # @param output_file [String, nil] custom output file path (default: synthesis-report.md)
        # @return [Hash] result with success, output_file, metadata, summary
        def synthesize(report_paths:, model: nil, session_dir:, output_file: nil)
          # Validate inputs
          return { success: false, error: "No report paths provided" } if report_paths.nil? || report_paths.empty?
          return { success: false, error: "Session directory required" } if session_dir.nil? || session_dir.empty?

          # Read all reports
          reports = read_reports(report_paths)

          # Check if we have enough reports
          if reports.empty?
            return { success: false, error: "No valid reports found" }
          end

          if reports.size < 2
            return {
              success: false,
              error: "Synthesis requires at least 2 reports (found #{reports.size})"
            }
          end

          # Use default synthesis model if not specified
          synthesis_model = model || default_synthesis_model

          # Build synthesis prompts via ace-context
          system_prompt = prepare_system_prompt(session_dir)
          user_prompt = prepare_user_prompt(reports, session_dir)

          # Determine output file
          final_output_file = output_file || File.join(session_dir, "synthesis-report.md")

          # Display synthesis start
          display_synthesis_start(reports.size, synthesis_model)

          # Execute LLM synthesis
          result = @llm_executor.execute(
            system_prompt: system_prompt,
            user_prompt: user_prompt,
            model: synthesis_model,
            session_dir: session_dir,
            output_file: final_output_file
          )

          if result[:success]
            # Add synthesis metadata header
            enhanced_content = add_synthesis_metadata(
              result[:response],
              reports,
              synthesis_model
            )

            # Write enhanced content
            File.write(final_output_file, enhanced_content)

            # Build summary from synthesized content
            summary = extract_summary_from_synthesis(enhanced_content)

            display_synthesis_complete(final_output_file, summary)

            {
              success: true,
              output_file: final_output_file,
              metadata: result[:metadata],
              summary: summary
            }
          else
            {
              success: false,
              error: result[:error],
              output_file: nil
            }
          end
        rescue StandardError => e
          {
            success: false,
            error: "Synthesis failed: #{e.message}",
            backtrace: e.backtrace.first(5)
          }
        end

        private

        # Read multiple report files
        # @param report_paths [Array<String>] paths to report files
        # @return [Array<Hash>] array of report hashes with :path, :model, :content
        def read_reports(report_paths)
          reports = []

          report_paths.each do |path|
            unless File.exist?(path)
              warn "Warning: Report not found: #{path}"
              next
            end

            content = File.read(path)
            model_name = extract_model_from_filename(path)

            reports << {
              path: path,
              model: model_name,
              content: content,
              size: content.bytesize
            }
          rescue StandardError => e
            warn "Warning: Failed to read report #{path}: #{e.message}"
          end

          reports
        end

        # Extract model name from report filename
        # @param path [String] report file path
        # @return [String] model name extracted from filename
        def extract_model_from_filename(path)
          basename = File.basename(path, ".md")

          # Handle different filename patterns:
          # review-dev-feedback.md -> Developer Feedback (special case for PR comments)
          # review-report-gemini-2.5-flash.md -> gemini-2.5-flash
          # review-gemini-2-5-flash.md -> gemini-2-5-flash
          # review-report-gpt-4.md -> gpt-4
          if basename == "review-dev-feedback"
            "Developer Feedback"
          elsif basename.start_with?("review-report-")
            basename.sub(/^review-report-/, "")
          elsif basename.start_with?("review-")
            basename.sub(/^review-/, "")
          else
            # Fallback: just use the basename
            basename
          end
        end

        # Prepare system prompt via ace-context with project-base preset
        # @param session_dir [String] session directory
        # @return [String] processed system prompt content
        def prepare_system_prompt(session_dir)
          # Get source path via ace-nav
          source_path = resolve_prompt_path("synthesis-review-reports.system.md")

          # Check if ace-context is available
          unless defined?(Ace::Bundle) && File.exist?(source_path)
            return fallback_system_prompt
          end

          # Copy to session as context file
          context_file = File.join(session_dir, "synthesis.system.context.md")
          FileUtils.cp(source_path, context_file)

          # Process via ace-context with embed_source to include the prompt content
          output_file = File.join(session_dir, "synthesis.system.prompt.md")
          result = Ace::Bundle.load_file(context_file, embed_source: true)
          File.write(output_file, result.content)

          result.content
        rescue StandardError => e
          warn "Warning: Failed to prepare system prompt via ace-context: #{e.message}" if Ace::Review.debug?
          fallback_system_prompt
        end

        # Fallback system prompt when ace-context is unavailable
        # @return [String] basic system prompt
        def fallback_system_prompt
          source_path = resolve_prompt_path("synthesis-review-reports.system.md")
          if File.exist?(source_path)
            File.read(source_path)
          else
            "You are a code review analyst. Synthesize the following review reports."
          end
        end

        # Prepare user prompt via ace-context with report files embedded
        # @param reports [Array<Hash>] array of report data
        # @param session_dir [String] session directory
        # @return [String] processed user prompt content
        def prepare_user_prompt(reports, session_dir)
          # Check if ace-context is available
          unless defined?(Ace::Bundle)
            return build_fallback_user_prompt(reports)
          end

          # Create user context file with report data
          context_file = File.join(session_dir, "synthesis.user.context.md")
          content = build_user_context_content(reports)
          File.write(context_file, content)

          # Process via ace-context with embed_source to include the prompt content
          output_file = File.join(session_dir, "synthesis.user.prompt.md")
          result = Ace::Bundle.load_file(context_file, embed_source: true)
          File.write(output_file, result.content)

          result.content
        rescue StandardError => e
          warn "Warning: Failed to prepare user prompt via ace-context: #{e.message}" if Ace::Review.debug?
          # Fallback to direct prompt building
          build_fallback_user_prompt(reports)
        end

        # Build user context content with frontmatter
        # @param reports [Array<Hash>] array of report data
        # @return [String] context file content with YAML frontmatter
        def build_user_context_content(reports)
          frontmatter = {
            "description" => "Synthesis user prompt with review reports",
            "context" => {
              "files" => reports.map { |r| r[:path] }
            }
          }

          body = <<~BODY
            # Synthesis Request

            Synthesize these #{reports.size} review reports into a unified analysis.
            Follow the output format specified in the system prompt.

            ## Report Summary

            #{reports.map.with_index { |r, i| "#{i + 1}. **#{r[:model]}** - #{format_size(r[:size])}" }.join("\n")}
          BODY

          "#{YAML.dump(frontmatter)}---\n\n#{body}"
        end

        # Fallback user prompt when ace-context is not available
        # @param reports [Array<Hash>] array of report data
        # @return [String] user prompt with all reports
        def build_fallback_user_prompt(reports)
          prompt = "Synthesize these #{reports.size} review reports:\n\n"

          reports.each_with_index do |report, idx|
            prompt += "## Report #{idx + 1}: #{report[:model]}\n\n"
            prompt += "**File**: #{File.basename(report[:path])}\n"
            prompt += "**Size**: #{format_size(report[:size])}\n\n"
            prompt += "```markdown\n"
            prompt += report[:content]
            prompt += "\n```\n\n"
            prompt += "---\n\n"
          end

          prompt += "\nGenerate a comprehensive synthesis following the output format specified in the system prompt."
          prompt
        end

        # Resolve prompt path via ace-nav or fallback to direct path
        # @param prompt_name [String] prompt filename
        # @return [String] resolved file path
        def resolve_prompt_path(prompt_name)
          # Try ace-nav first
          nav_result = `ace-nav prompt://#{prompt_name} 2>/dev/null`.strip
          return nav_result unless nav_result.empty?

          # Fallback to direct path
          File.join(__dir__, "../../../../handbook/prompts", prompt_name)
        end

        # Format file size for display
        # @param bytes [Integer] size in bytes
        # @return [String] formatted size (e.g., "2.4 KB")
        def format_size(bytes)
          if bytes < 1024
            "#{bytes} B"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          else
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          end
        end

        # Add synthesis metadata header to report
        # @param content [String] synthesized content from LLM
        # @param reports [Array<Hash>] source reports
        # @param model [String] synthesis model used
        # @return [String] content with metadata header
        def add_synthesis_metadata(content, reports, model)
          # Extract existing overview section if present, or create one
          if content.include?("## Overview")
            # LLM already created overview, just ensure it's complete
            content
          else
            # Add overview section at the top
            header = "# Multi-Model Review Synthesis\n\n"
            header += "## Overview\n\n"
            header += "- **Models**: #{reports.map { |r| r[:model] }.join(', ')}\n"
            header += "- **Synthesis Model**: #{model}\n"
            header += "- **Generated**: #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}\n"
            header += "- **Source Reports**: #{reports.size}\n\n"

            # Add content after header
            header + content
          end
        end

        # Extract summary statistics from synthesized content
        # @param content [String] synthesized report content
        # @return [Hash] summary statistics
        def extract_summary_from_synthesis(content)
          summary = {
            consensus_findings: 0,
            strong_recommendations: 0,
            unique_insights: 0,
            conflicts_resolved: 0,
            total_action_items: 0
          }

          # Count consensus findings (numbered items in section)
          if content =~ /## Consensus Findings.*?\n(.*?)(?=\n## |\z)/m
            consensus_section = Regexp.last_match(1)
            summary[:consensus_findings] = consensus_section.scan(/^\d+\./m).size
          end

          # Count strong recommendations
          if content =~ /## Strong Recommendations.*?\n(.*?)(?=\n## |\z)/m
            strong_section = Regexp.last_match(1)
            summary[:strong_recommendations] = strong_section.scan(/^\d+\./m).size
          end

          # Count unique insights (count ### headers in Unique Insights section)
          if content =~ /## Unique Insights.*?\n(.*?)(?=\n## |\z)/m
            unique_section = Regexp.last_match(1)
            summary[:unique_insights] = unique_section.scan(/^###/m).size
          end

          # Count conflicts
          if content =~ /## Conflicting Views.*?\n(.*?)(?=\n## |\z)/m
            conflicts_section = Regexp.last_match(1)
            summary[:conflicts_resolved] = conflicts_section.scan(/^###/m).size
          end

          # Count action items (all numbered items in Prioritized Action Items)
          if content =~ /## Prioritized Action Items.*?\n(.*?)(?=\n## |\z)/m
            actions_section = Regexp.last_match(1)
            summary[:total_action_items] = actions_section.scan(/^\d+\./m).size
          end

          summary
        end

        # Get default synthesis model from config
        # @return [String] default model
        def default_synthesis_model
          Ace::Review.get("synthesis", "model") || "google:gemini-2.5-flash"
        end

        # Display synthesis start message
        # @param report_count [Integer] number of reports
        # @param model [String] synthesis model
        def display_synthesis_start(report_count, model)
          $stderr.puts
          $stderr.puts "Synthesizing #{report_count} review reports..."
          $stderr.puts "  Using model: #{model}"
          $stderr.flush
        end

        # Display synthesis completion message
        # @param output_file [String] path to synthesis report
        # @param summary [Hash] synthesis summary statistics
        def display_synthesis_complete(output_file, summary)
          $stderr.puts "✓ Synthesis complete"
          $stderr.puts
          $stderr.puts "Saved: #{output_file}"
          $stderr.puts
          $stderr.puts "Summary:"
          $stderr.puts "  Consensus findings: #{summary[:consensus_findings]}"
          $stderr.puts "  Strong recommendations: #{summary[:strong_recommendations]}"
          $stderr.puts "  Unique insights: #{summary[:unique_insights]}"
          $stderr.puts "  Conflicts resolved: #{summary[:conflicts_resolved]}"
          $stderr.puts "  Action items: #{summary[:total_action_items]}"
          $stderr.flush
        end
      end
    end
  end
end
