# frozen_string_literal: true

require "open3"
require "shellwords"
require "tempfile"

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
          base_message = "You are an assistant that generates concise and informative git commit messages. " \
                        "Only output the commit message without any additional commentary."

          # TODO: Load commit guidelines from a file
          # For now, use a basic guideline
          guidelines = "\n\nFollow these guidelines:\n" \
                      "- Use present tense (e.g., 'add feature' not 'added feature')\n" \
                      "- Keep first line under 50 characters\n" \
                      "- Be descriptive but concise\n" \
                      "- Focus on what the change does, not how it does it"

          base_message + guidelines
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
          # Create temporary files for system message and user prompt
          system_file = create_temp_file(system_message, "system", ".md")
          prompt_file = create_temp_file(user_prompt, "prompt", ".md")

          begin
            # Use full path to llm-query executable for development
            llm_query_path = find_llm_query_executable
            command = build_llm_query_command(llm_query_path, model, system_file.path, prompt_file.path)

            if debug
              puts "DEBUG: System file: #{system_file.path}"
              puts "DEBUG: Prompt file: #{prompt_file.path}"
              puts "DEBUG: Command: #{command}"
            end

            execute_llm_command(command, "LLM")
          ensure
            # Allow any background threads from Open3.capture3 to finish before cleanup
            sleep(0.1)
            
            # Clean up temporary files with defensive error handling
            begin
              system_file.close
              prompt_file.close
              
              # Small delay before unlinking to ensure file handles are fully released
              sleep(0.05)
              
              system_file.unlink
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
          cmd_parts << prompt_file_path
          cmd_parts << "--system" << system_file_path

          # Add debug flag if enabled
          cmd_parts << "--debug" if debug

          cmd_parts.map { |part| Shellwords.escape(part) }.join(" ")
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
          # Find project root by looking for characteristic files
          current_dir = Dir.pwd
          
          loop do
            if File.exist?(File.join(current_dir, "dev-tools")) &&
               File.exist?(File.join(current_dir, "dev-taskflow")) &&
               File.exist?(File.join(current_dir, "CLAUDE.md"))
              return current_dir
            end
            
            parent = File.dirname(current_dir)
            break if parent == current_dir # reached filesystem root
            current_dir = parent
          end
          
          # If we can't find the project root, return current directory
          Dir.pwd
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
