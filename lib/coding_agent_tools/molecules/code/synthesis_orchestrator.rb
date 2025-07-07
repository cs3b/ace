# frozen_string_literal: true

require "shellwords"
require "open3"
require "time"

module CodingAgentTools
  module Molecules
    module Code
      # SynthesisOrchestrator handles LLM orchestration for review synthesis
      # This molecule integrates with existing llm-query infrastructure
      class SynthesisOrchestrator
        # Result class for synthesis operations
        class SynthesisResult
          attr_reader :output_path, :metrics, :error, :success

          def initialize(output_path: nil, metrics: {}, error: nil, success: false)
            @output_path = output_path
            @metrics = metrics
            @error = error
            @success = success
          end

          def success?
            @success
          end

          def failure?
            !@success
          end
        end

        # Default system prompt template location
        DEFAULT_SYSTEM_PROMPT = "dev-handbook/templates/review-synthesizer/system.prompt.md"

        # Initialize the synthesis orchestrator
        # @param options [Hash] Configuration options
        def initialize(**options)
          @file_handler = options[:file_handler] || create_file_handler
          @debug = options[:debug] || false
        end

        # Synthesize multiple review reports using LLM
        # @param reports [Array<String>] Array of report file paths
        # @param session_info [SessionPathInferrer::InferenceResult] Session information
        # @param model [String] LLM model to use
        # @param output_path [String] Path for output file
        # @param format [String] Output format
        # @param system_prompt_path [String, nil] Custom system prompt path
        # @param force [Boolean] Force overwrite existing files
        # @param debug [Boolean] Enable debug output
        # @return [SynthesisResult] Result of synthesis operation
        def synthesize_reports(reports:, session_info:, model:, output_path:, format: "markdown", system_prompt_path: nil, force: false, debug: false)
          start_time = Time.now

          # Prepare synthesis prompt
          puts "📝 Building comprehensive synthesis prompt..."
          prompt_content = build_synthesis_prompt(reports, session_info, system_prompt_path)
          puts "✅ Synthesis prompt prepared (#{prompt_content.length} characters)"
          
          # Handle output file sequencing
          puts "📂 Checking output file path and sequencing..."
          final_output_path = handle_output_sequencing(output_path, force)
          if final_output_path != output_path
            puts "📁 Using sequenced output path: #{File.basename(final_output_path)}"
          end
          
          # Execute LLM query
          puts "🚀 Executing LLM synthesis (this may take a moment)..."
          execution_result = execute_llm_synthesis(model, prompt_content, final_output_path, format, debug)
          
          end_time = Time.now
          execution_time = end_time - start_time

          if execution_result[:success]
            puts "✅ LLM synthesis completed successfully"
            metrics = extract_synthesis_metrics(execution_result, execution_time, reports.length)
            
            SynthesisResult.new(
              output_path: final_output_path,
              metrics: metrics,
              success: true
            )
          else
            puts "❌ LLM synthesis failed"
            SynthesisResult.new(
              error: execution_result[:error],
              success: false
            )
          end
        rescue => e
          SynthesisResult.new(
            error: "Synthesis orchestration failed: #{e.message}",
            success: false
          )
        end

        private

        # Build comprehensive synthesis prompt
        # @param reports [Array<String>] Report file paths
        # @param session_info [SessionPathInferrer::InferenceResult] Session information
        # @param system_prompt_path [String, nil] Custom system prompt path
        # @return [String] Complete synthesis prompt
        def build_synthesis_prompt(reports, session_info, system_prompt_path)
          prompt_parts = []

          # Add system prompt
          system_prompt = load_system_prompt(system_prompt_path)
          prompt_parts << "# System Instructions\n\n#{system_prompt}" if system_prompt

          # Add session context
          if session_info.has_session?
            prompt_parts << build_session_context(session_info)
          end

          # Add combined reports
          prompt_parts << build_combined_reports_section(reports)

          # Add synthesis instructions
          prompt_parts << build_synthesis_instructions(reports.length)

          prompt_parts.join("\n\n---\n\n")
        end

        # Load system prompt from file or use default
        # @param system_prompt_path [String, nil] Custom system prompt path
        # @return [String, nil] System prompt content
        def load_system_prompt(system_prompt_path)
          prompt_path = system_prompt_path || DEFAULT_SYSTEM_PROMPT
          
          return nil unless prompt_path && File.exist?(prompt_path)
          
          File.read(prompt_path, encoding: "UTF-8").strip
        rescue => e
          # Log error but continue without system prompt
          warn "Warning: Could not load system prompt from #{prompt_path}: #{e.message}" if @debug
          nil
        end

        # Build session context section
        # @param session_info [SessionPathInferrer::InferenceResult] Session information
        # @return [String] Session context content
        def build_session_context(session_info)
          context_parts = ["# Session Context"]
          
          context_parts << "**Session Directory**: #{session_info.session_directory}"
          context_parts << "**Session Type**: #{session_info.session_type}"
          context_parts << "**Session ID**: #{session_info.session_id}" if session_info.session_id
          
          if session_info.metadata && !session_info.metadata.empty?
            context_parts << "\n**Session Metadata**:"
            session_info.metadata.each do |key, value|
              context_parts << "- #{key}: #{value}"
            end
          end

          context_parts.join("\n")
        end

        # Build combined reports section
        # @param reports [Array<String>] Report file paths
        # @return [String] Combined reports content
        def build_combined_reports_section(reports)
          section_parts = ["# Review Reports to Synthesize"]
          
          section_parts << "The following #{reports.length} review reports need to be synthesized:"
          section_parts << ""

          reports.each_with_index do |report_path, index|
            section_parts << "## Report #{index + 1}: #{File.basename(report_path)}"
            section_parts << ""
            
            begin
              report_content = File.read(report_path, encoding: "UTF-8").strip
              section_parts << report_content
            rescue => e
              section_parts << "**Error reading report**: #{e.message}"
            end
            
            section_parts << ""
            section_parts << "---" unless index == reports.length - 1
            section_parts << ""
          end

          section_parts.join("\n")
        end

        # Build synthesis instructions
        # @param report_count [Integer] Number of reports being synthesized
        # @return [String] Synthesis instructions
        def build_synthesis_instructions(report_count)
          instructions = ["# Synthesis Instructions"]
          
          instructions << "Please synthesize these #{report_count} review reports into a unified analysis following these guidelines:"
          instructions << ""
          instructions << "## Synthesis Goals"
          instructions << "- Create a consolidated executive summary"
          instructions << "- Identify consensus findings across all reports"
          instructions << "- Resolve conflicts between different recommendations"
          instructions << "- Prioritize action items based on frequency and impact"
          instructions << "- Provide a unified implementation timeline"
          instructions << "- Highlight unique insights from individual reports"
          instructions << ""
          instructions << "## Output Structure"
          instructions << "Please structure your synthesis using these sections:"
          instructions << "1. **Executive Summary** - Overall assessment and key findings"
          instructions << "2. **Consensus Findings** - Issues identified by multiple reports"
          instructions << "3. **Conflict Resolution** - Areas where reports disagreed and recommended approach"
          instructions << "4. **Prioritized Action Items** - Unified priority list with 🔴🟡🟢 indicators"
          instructions << "5. **Implementation Timeline** - Phased approach to address findings"
          instructions << "6. **Unique Insights** - Valuable findings that appeared in only one report"
          instructions << "7. **Synthesis Methodology** - Brief explanation of how conflicts were resolved"

          instructions.join("\n")
        end

        # Handle output file sequencing to preserve existing files
        # @param output_path [String] Desired output path
        # @param force [Boolean] Force overwrite
        # @return [String] Final output path to use
        def handle_output_sequencing(output_path, force)
          return output_path if force || !File.exist?(output_path)

          # Find next available sequence number
          base_path = output_path.sub(/\.([^.]+)$/, '')
          extension = File.extname(output_path)
          
          sequence = 1
          loop do
            sequenced_path = "#{base_path}.#{sequence}#{extension}"
            break sequenced_path unless File.exist?(sequenced_path)
            sequence += 1
          end
        end

        # Execute LLM synthesis using llm-query
        # @param model [String] LLM model to use
        # @param prompt_content [String] Complete synthesis prompt
        # @param output_path [String] Output file path
        # @param format [String] Output format
        # @param debug [Boolean] Enable debug output
        # @return [Hash] Execution result
        def execute_llm_synthesis(model, prompt_content, output_path, format, debug)
          # Create temporary prompt file
          prompt_file = create_temp_prompt_file(prompt_content)
          
          begin
            # Build llm-query command
            cmd = build_llm_query_command(model, prompt_file, output_path, format, debug)
            
            # Execute command
            stdout, stderr, status = Open3.capture3(*cmd)
            
            if status.success?
              # Extract metrics from llm-query output
              metrics = parse_llm_query_output(stdout, stderr)
              
              {
                success: true,
                stdout: stdout,
                stderr: stderr,
                metrics: metrics
              }
            else
              {
                success: false,
                error: "LLM query failed: #{stderr.strip.empty? ? stdout : stderr}",
                stdout: stdout,
                stderr: stderr
              }
            end
          ensure
            # Clean up temporary file
            File.unlink(prompt_file) if prompt_file && File.exist?(prompt_file)
          end
        end

        # Create temporary file for synthesis prompt
        # @param content [String] Prompt content
        # @return [String] Path to temporary file
        def create_temp_prompt_file(content)
          require "tempfile"
          
          temp_file = Tempfile.new(["synthesis-prompt", ".md"])
          temp_file.write(content)
          temp_file.close
          
          temp_file.path
        end

        # Build llm-query command array
        # @param model [String] LLM model
        # @param prompt_file [String] Prompt file path
        # @param output_path [String] Output file path
        # @param format [String] Output format
        # @param debug [Boolean] Enable debug output
        # @return [Array<String>] Command array
        def build_llm_query_command(model, prompt_file, output_path, format, debug)
          # Find llm-query executable
          llm_query_path = find_llm_query_executable
          
          cmd = [llm_query_path, model, prompt_file]
          cmd += ["--output", output_path]
          cmd += ["--format", format] if format && format != "text"
          cmd += ["--force"] # Always force since we handle sequencing ourselves
          cmd += ["--debug"] if debug
          
          cmd
        end

        # Find llm-query executable
        # @return [String] Path to llm-query executable
        def find_llm_query_executable
          # Try relative path first (from dev-tools)
          relative_path = File.expand_path("../../../../../exe/llm-query", __FILE__)
          return relative_path if File.executable?(relative_path)
          
          # Try PATH
          which_result = `which llm-query 2>/dev/null`.strip
          return which_result unless which_result.empty?
          
          # Fallback to assumed location
          "llm-query"
        end

        # Parse llm-query output for metrics
        # @param stdout [String] Standard output
        # @param stderr [String] Standard error
        # @return [Hash] Extracted metrics
        def parse_llm_query_output(stdout, stderr)
          metrics = {}
          
          # Parse token usage from output
          output_text = stdout + stderr
          
          if match = output_text.match(/Input:\s*(\d+)\s*tokens/)
            metrics[:input_tokens] = match[1].to_i
          end
          
          if match = output_text.match(/Output:\s*(\d+)\s*tokens/)
            metrics[:output_tokens] = match[1].to_i
          end
          
          if match = output_text.match(/Cost:\s*\$(\d+\.\d+)/)
            metrics[:cost] = match[1].to_f
          end

          metrics
        end

        # Extract synthesis metrics from execution result
        # @param execution_result [Hash] Result from LLM execution
        # @param execution_time [Float] Total execution time
        # @param reports_count [Integer] Number of reports processed
        # @return [Hash] Synthesis metrics
        def extract_synthesis_metrics(execution_result, execution_time, reports_count)
          metrics = execution_result[:metrics] || {}
          
          metrics[:execution_time] = execution_time.round(2)
          metrics[:reports_count] = reports_count
          
          metrics
        end

        # Create file I/O handler instance
        # @return [FileIoHandler] File handler
        def create_file_handler
          require_relative "../file_io_handler"
          FileIoHandler.new
        end
      end
    end
  end
end