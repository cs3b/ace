# frozen_string_literal: true

require "yaml"
require "fileutils"
require "ace/context"

module Ace
  module Prompt
    module Organisms
      # Manages enhancement sessions with materialized context files (following ace-review pattern)
      class EnhancementSessionManager
        class EnhancementError < Ace::Prompt::Error; end

        def initialize(config)
          @config = config
        end

        # Enhance prompt with context using materialized session files
        # @param content [String] User's prompt content to enhance
        # @param frontmatter [Hash] Parsed frontmatter with enhancement.context config
        # @return [String] Enhanced content
        def enhance_with_context(content, frontmatter)
          session_dir = create_session_directory

          begin
            # Create context configuration files
            user_context_path = create_user_context_file(session_dir, content, frontmatter)
            system_context_path = create_system_context_file(session_dir, frontmatter)

            # Process context files with ace-context
            user_prompt_path = File.join(session_dir, "user.prompt.md")
            system_prompt_path = File.join(session_dir, "system.prompt.md")

            execute_ace_context(user_context_path, user_prompt_path)
            execute_ace_context(system_context_path, system_prompt_path)

            # Read materialized prompts
            user_prompt = File.read(user_prompt_path)
            system_prompt = File.read(system_prompt_path)

            # Call LLM with materialized prompts
            enhanced = execute_llm(user_prompt, system_prompt, session_dir)

            enhanced
          rescue => e
            raise EnhancementError, "Enhancement session failed: #{e.message}"
          end
        end

        private

        def create_session_directory
          # Use configured default directory, not current working directory
          base_dir = @config["default_dir"]
          session_dir = File.join(base_dir, "enhancement")

          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def create_user_context_file(session_dir, content, frontmatter)
          # Extract enhancement context config from frontmatter
          enhancement_config = frontmatter.dig("enhancement", "context") || {}

          # Build ace-context configuration for user prompt
          ace_context_config = {
            "description" => "User prompt to enhance with context",
            "context" => enhancement_config
          }

          # Create context.md with frontmatter + user content as body
          context_content = "---\n#{YAML.dump(ace_context_config)}---\n\n#{content}"

          context_path = File.join(session_dir, "user.context.md")
          File.write(context_path, context_content)

          context_path
        end

        def create_system_context_file(session_dir, frontmatter)
          # Get system prompt URI from config or frontmatter
          system_prompt_uri = frontmatter.dig("enhancement", "system_prompt") ||
                              @config.dig("enhancement", "system_prompt") ||
                              "prompt://ace-prompt/base/enhance"

          # Build ace-context configuration for system prompt
          ace_context_config = {
            "description" => "System prompt for enhancement",
            "context" => {
              "sections" => {
                "instructions" => {
                  "title" => "Enhancement Instructions",
                  "files" => [system_prompt_uri]
                }
              }
            }
          }

          # Create context.md with frontmatter only (no body needed)
          context_content = "---\n#{YAML.dump(ace_context_config)}---\n\n"

          context_path = File.join(session_dir, "system.context.md")
          File.write(context_path, context_content)

          context_path
        end

        def execute_ace_context(input_file, output_file)
          # Use ace-context Ruby API (same as ace-review)
          context_result = Ace::Context.load_file(input_file)

          # Check for errors
          if context_result.metadata[:error]
            error_message = context_result.metadata[:error]
            raise EnhancementError, "Context processing failed: #{error_message}"
          end

          # Write rendered content to output file
          File.write(output_file, context_result.content)
          true
        rescue StandardError => e
          raise EnhancementError, "ace-context processing failed: #{e.message}"
        end

        def execute_llm(user_prompt, system_prompt, session_dir)
          model = resolve_model
          temperature = @config.dig("enhancement", "temperature") || 0.3
          output_file = File.join(session_dir, "enhanced.md")

          # Use ace-llm Ruby API directly (same as ace-review)
          result = Ace::LLM::QueryInterface.query(
            model,
            user_prompt,
            system: system_prompt,
            temperature: temperature,
            format: "text",
            output: output_file,
            force: true
          )

          result[:text].strip
        rescue => e
          raise EnhancementError, "LLM call failed: #{e.message}"
        end

        def resolve_model
          model = @config.dig("enhancement", "model") || "glite"
          Atoms::ModelAliasResolver.resolve(model)
        end
      end
    end
  end
end
