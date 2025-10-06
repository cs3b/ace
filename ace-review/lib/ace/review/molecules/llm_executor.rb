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
        # @param prompt [String] the prompt to send
        # @param model [String] the model to use
        # @return [Hash] result with success, response, and error keys
        def execute(prompt:, model: nil)
          model ||= @default_model

          # Check if ace-llm-query is available
          unless command_exists?("ace-llm-query")
            return {
              success: false,
              response: nil,
              error: "ace-llm-query not found. Please install ace-llm gem or use --dry-run"
            }
          end

          # Execute via ace-llm
          result = execute_ace_llm(prompt, model)

          if result[:success]
            {
              success: true,
              response: result[:output],
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

        def execute_ace_llm(prompt, model)
          # Write prompt to temp file
          require "tempfile"
          temp_file = Tempfile.new(["review-prompt", ".md"])
          temp_file.write(prompt)
          temp_file.close

          begin
            # Execute ace-llm
            cmd = [
              "ace-llm",
              "query",
              "--model", model,
              "--file", temp_file.path
            ]

            stdout, stderr, status = Open3.capture3(*cmd)

            {
              success: status.success?,
              output: stdout,
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