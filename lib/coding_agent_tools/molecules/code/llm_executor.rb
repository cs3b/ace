# frozen_string_literal: true

require "tempfile"
require_relative "../../organisms/system/command_executor"

module CodingAgentTools
  module Molecules
    module Code
      # Executes LLM queries directly without persistent files
      class LLMExecutor
        attr_reader :executor

        def initialize
          @executor = CodingAgentTools::Organisms::System::CommandExecutor.new
        end

        # Execute LLM query with in-memory content or temporary files
        # @param model [String] The LLM model to use
        # @param subject_content [String] The subject/user prompt content
        # @param system_content [String] The system prompt content
        # @param output_file [String] Optional output file path
        # @param timeout [Integer] Timeout in seconds (default: 600)
        # @return [String] The LLM response
        def execute_query(model, subject_content, system_content, output_file: nil, timeout: 600)
          # Create temporary files for the prompts
          Tempfile.create(["subject-", ".md"]) do |subject_temp|
            subject_temp.write(subject_content)
            subject_temp.flush

            Tempfile.create(["system-", ".md"]) do |system_temp|
              system_temp.write(system_content)
              system_temp.flush

              # Build the llm-query command
              command_parts = [
                "llm-query",
                model,
                subject_temp.path,
                "--system", system_temp.path,
                "--timeout", timeout.to_s
              ]

              # Add output file if specified
              if output_file
                command_parts.push("--output", output_file)
              end

              # Execute the command
              result = executor.execute(*command_parts)

              if result.success?
                # Return the output
                if output_file && File.exist?(output_file)
                  File.read(output_file)
                else
                  result.stdout
                end
              else
                raise "LLM query failed: #{result.stderr}"
              end
            end
          end
        end

        # Execute query and stream output to console
        def execute_streaming(model, subject_content, system_content, timeout: 600)
          # Create temporary files for the prompts
          Tempfile.create(["subject-", ".md"]) do |subject_temp|
            subject_temp.write(subject_content)
            subject_temp.flush

            Tempfile.create(["system-", ".md"]) do |system_temp|
              system_temp.write(system_content)
              system_temp.flush

              # Build command for streaming execution
              command = [
                "llm-query",
                model,
                subject_temp.path,
                "--system", system_temp.path,
                "--timeout", timeout.to_s
              ].join(" ")

              # Execute with system call for real-time output
              success = system(command)

              unless success
                exit_code = $? ? $?.exitstatus : "unknown"
                raise "LLM query failed with exit code: #{exit_code}"
              end
            end
          end

          # Find llm-query executable using absolute path resolution
          # @return [String] Path to llm-query executable
          def find_llm_query_executable
            # Try relative path first (from dev-tools)
            relative_path = File.expand_path("../../../../exe/llm-query", __dir__)
            return relative_path if File.executable?(relative_path)

            # Try PATH
            which_result = `which llm-query 2>/dev/null`.strip
            return which_result unless which_result.empty?

            # Fallback to assumed location
            "llm-query"
          end
        end
      end
    end
  end
end
