# frozen_string_literal: true

require "open3"
require "shellwords"
require "tempfile"
require_relative "../../atoms/project_root_detector"
require_relative "../../error"

module CodingAgentTools
  module Molecules
    module Git
      class CommitMessageGenerationError < StandardError; end

      class CommitMessageGenerator
        DEFAULT_MODEL = "google:gemini-2.0-flash-lite"

        def self.generate_message(diff, options = {})
          new(options).generate_message(diff)
        end

        def initialize(options = {})
          @intention = options[:intention]
          @debug = options.fetch(:debug, false)
          @model = options[:model] || DEFAULT_MODEL
        end

        def generate_message(diff)
          validate_diff(diff)

          system_message = build_system_message
          user_prompt = build_user_prompt(diff)

          generate_with_llm(system_message, user_prompt)
        end

        private

        attr_reader :intention, :debug, :model

        def validate_diff(diff)
          if diff.nil? || diff.strip.empty?
            raise CommitMessageGenerationError, "Diff cannot be empty"
          end
        end

        def build_system_message
          template_path = find_system_prompt_template_path

          unless File.exist?(template_path)
            raise CommitMessageGenerationError, "System prompt template not found at: #{template_path}"
          end

          File.read(template_path)
        end

        def build_user_prompt(diff)
          prompt = "Generate a commit message"

          if intention && !intention.strip.empty?
            prompt += ", taking into account the following intention: #{intention}"
          end

          prompt += "\n\nFor the following diff:\n\n#{diff}"
          prompt
        end

        def generate_with_llm(system_message, user_prompt)
          # Use template file path directly for system message
          system_template_path = find_system_prompt_template_path

          # Create temporary file only for user prompt
          prompt_file = create_temp_file(user_prompt, "prompt", ".md")

          begin
            # Use full path to llm-query executable for development
            llm_query_path = find_llm_query_executable
            command = build_llm_query_command(llm_query_path, model, system_template_path, prompt_file.path)

            if debug
              puts "DEBUG: System template: #{system_template_path}"
              puts "DEBUG: Prompt file: #{prompt_file.path}"
              puts "DEBUG: Command: #{command}"
            end

            execute_llm_command(command, "LLM")
          ensure
            # Allow any background threads from Open3.capture3 to finish before cleanup
            sleep(0.1)

            # Clean up temporary files with defensive error handling
            begin
              prompt_file.close

              # Small delay before unlinking to ensure file handles are fully released
              sleep(0.05)

              prompt_file.unlink
            rescue => cleanup_error
              # Log cleanup errors but don't fail the operation
              puts "Warning: Error during tempfile cleanup: #{cleanup_error.message}" if debug
            end
          end
        end

        def create_temp_file(content, prefix, extension)
          temp_file = Tempfile.new([prefix, extension])
          temp_file.write(content)
          temp_file.flush # Ensure content is written to disk
          temp_file
        end

        def build_llm_query_command(executable, model_name, system_file_path, prompt_file_path)
          # Use the new llm-query command format with file paths: llm-query PROVIDER_MODEL prompt_file --system system_file
          cmd_parts = [executable]
          cmd_parts << model_name
          cmd_parts << Shellwords.escape(prompt_file_path)  # Only escape file paths that might contain spaces
          cmd_parts << "--system" << Shellwords.escape(system_file_path)  # Only escape file paths that might contain spaces

          # Add debug flag if enabled
          cmd_parts << "--debug" if debug

          cmd_parts.join(" ")  # Join without additional escaping
        end

        def execute_llm_command(command, model_description)
          stdout_str, stderr_str, status = Open3.capture3(command)

          unless status.success?
            error_message = "Failed to generate commit message using #{model_description}."

            if debug
              error_message += "\nCommand: #{command}"
              error_message += "\nError: #{stderr_str.strip}" unless stderr_str.strip.empty?
            elsif stderr_str.include?("Error:")
              # Find the actual error message after "Error:"
              error_lines = stderr_str.split("\n").select { |line| line.include?("Error:") }
              error_message += "\n#{error_lines.first}" unless error_lines.empty?
            else
              error_message += "\nRun with --debug for more details."
            end

            raise CommitMessageGenerationError, error_message
          end

          clean_response(stdout_str)
        end

        def find_llm_query_executable
          # Try to find llm-query in the local exe directory first (for development)
          project_root = find_project_root
          local_exe = File.join(project_root, "dev-tools", "exe", "llm-query")

          if File.executable?(local_exe)
            return local_exe
          end

          # Fall back to system PATH
          "llm-query"
        end

        def find_project_root
          CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
        rescue CodingAgentTools::Error => e
          # If project root detection fails, raise a more specific error
          raise CommitMessageGenerationError, "Failed to find project root: #{e.message}"
        end

        def find_system_prompt_template_path
          project_root = find_project_root
          File.join(project_root, "dev-handbook", ".meta", "tpl", "git-commit.system.prompt.md")
        end

        def clean_response(response)
          return "" if response.nil?

          # Remove markdown code block markers
          cleaned = response.gsub(/^```[a-zA-Z0-9_-]*\s*/, "")
            .gsub(/```\s*$/, "")

          # Trim whitespace and ensure single newline at end
          cleaned = cleaned.strip

          if cleaned.empty?
            raise CommitMessageGenerationError, "LLM returned empty commit message after cleaning"
          end

          cleaned
        end
      end
    end
  end
end
