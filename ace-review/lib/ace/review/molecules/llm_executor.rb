# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Review
    module Molecules
      # Executes LLM queries for code reviews
      class LlmExecutor
        def initialize
          @default_model = Ace::Review.get("defaults", "model") || "google:gemini-2.5-flash"
        end

        # Execute an LLM query
        # @param prompt [String] the prompt to send (legacy format)
        # @param system_prompt [String] system prompt (new format)
        # @param user_prompt [String] user prompt (new format)
        # @param model [String] the model to use
        # @param session_dir [String] the session directory for output
        # @return [Hash] result with success, response, output_file, and error keys
        def execute(prompt: nil, system_prompt: nil, user_prompt: nil, model: nil, session_dir:)
          model ||= @default_model

          # Check if ace-llm-query is available
          unless command_exists?("ace-llm-query")
            return {
              success: false,
              response: nil,
              error: "ace-llm-query not found. Please install ace-llm gem or use --dry-run"
            }
          end

          # Handle new system/user prompt format vs legacy single prompt
          if system_prompt && user_prompt
            # New format: separate system and user prompts
            result = execute_with_system_user_prompts(system_prompt, user_prompt, model, session_dir)
          elsif prompt
            # Legacy format: single combined prompt
            result = execute_ace_llm_query(prompt, model, session_dir)
          else
            return {
              success: false,
              response: nil,
              error: "Either prompt (legacy) or system_prompt + user_prompt (new) must be provided"
            }
          end

          if result[:success]
            {
              success: true,
              response: result[:output],
              output_file: result[:output_file],
              error: nil
            }
          else
            {
              success: false,
              response: nil,
              error: result[:error] || "LLM execution failed"
            }
          end
        end

        private

        def command_exists?(command)
          system("which #{command} > /dev/null 2>&1")
        end

        def execute_with_system_user_prompts(system_prompt, user_prompt, model, session_dir)
          require "tempfile"

          # Create temporary files for system and user prompts
          system_temp_file = Tempfile.new(["system-prompt", ".md"])
          system_temp_file.write(system_prompt)
          system_temp_file.close

          user_temp_file = Tempfile.new(["user-prompt", ".md"])
          user_temp_file.write(user_prompt)
          user_temp_file.close

          begin
            # Extract model short name for output filename
            model_short = model.include?(":") ? model.split(":", 2).last : model

            # Build output file path in session directory
            output_file = File.join(session_dir, "review-report-#{model_short}.md")

            # Execute ace-llm-query with system and user prompt files
            cmd = [
              "ace-llm-query",
              model,                        # PROVIDER:MODEL format
              "--system-prompt", system_temp_file.path,  # System prompt file
              "--user-prompt", user_temp_file.path,      # User prompt file
              "--output", output_file,     # Output to session directory
              "--timeout", "600",          # 600 seconds timeout
              "--format", "markdown"       # Markdown format
            ]

            stdout, stderr, status = Open3.capture3(*cmd)

            {
              success: status.success?,
              output: stdout,
              output_file: output_file,
              error: stderr
            }
          ensure
            system_temp_file.unlink
            user_temp_file.unlink
          end
        end

        def execute_ace_llm_query(prompt, model, session_dir)
          # Write prompt to temp file
          require "tempfile"
          temp_file = Tempfile.new(["review-prompt", ".md"])
          temp_file.write(prompt)
          temp_file.close

          begin
            # Extract model short name for output filename
            # "google:gemini-2.5-flash" -> "gemini-2.5-flash"
            model_short = model.include?(":") ? model.split(":", 2).last : model

            # Build output file path in session directory
            output_file = File.join(session_dir, "review-report-#{model_short}.md")

            # Execute ace-llm-query with correct flags
            cmd = [
              "ace-llm-query",
              model,                      # PROVIDER:MODEL format
              "--prompt", temp_file.path, # Prompt file (replaces --file)
              "--output", output_file,    # Output to session directory
              "--timeout", "600",         # 600 seconds timeout
              "--format", "markdown"      # Markdown format
            ]

            stdout, stderr, status = Open3.capture3(*cmd)

            {
              success: status.success?,
              output: stdout,
              output_file: output_file,
              error: stderr
            }
          ensure
            temp_file.unlink
          end
        end
      end
    end
  end
end