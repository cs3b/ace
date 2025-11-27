# frozen_string_literal: true

require "yaml"
require "fileutils"

# Try to require ace-context, but don't fail if it's not available
begin
  require "ace/context"
rescue LoadError
  # ace-context not available, will use graceful fallback
end

# Try to require ace-llm, but don't fail if it's not available
begin
  require "ace/llm"
rescue LoadError
  # ace-llm not available, will use graceful fallback
end

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
          warn "[DEBUG] Starting context-based enhancement"

          session_dir = create_session_directory
          warn "[DEBUG] Session directory created: #{session_dir}"

          begin
            # Create context configuration files
            user_context_path = create_user_context_file(session_dir, content, frontmatter)
            system_context_path = create_system_context_file(session_dir, frontmatter)
            warn "[DEBUG] Context files created: user=#{user_context_path}, system=#{system_context_path}"

            # Process context files with ace-context
            user_prompt_path = File.join(session_dir, "user.prompt.md")
            system_prompt_path = File.join(session_dir, "system.prompt.md")

            warn "[DEBUG] Starting ace-context processing"
            execute_ace_context(user_context_path, user_prompt_path)
            execute_ace_context(system_context_path, system_prompt_path)
            warn "[DEBUG] ace-context processing completed"

            # Read materialized prompts
            warn "[DEBUG] Reading materialized prompts"
            user_prompt = File.read(user_prompt_path)
            system_prompt = File.read(system_prompt_path)
            warn "[DEBUG] Materialized prompts read: user=#{user_prompt.length} chars, system=#{system_prompt.length} chars"

            # Call LLM with materialized prompts
            warn "[DEBUG] Starting LLM enhancement"
            enhanced = execute_llm(user_prompt, system_prompt, session_dir)
            warn "[DEBUG] LLM enhancement completed"

            enhanced
          rescue => e
            warn "[DEBUG] Enhancement session failed: #{e.class}: #{e.message}"
            warn "[DEBUG] Backtrace: #{e.backtrace.first(3).join(', ')}"
            raise EnhancementError, "Enhancement session failed: #{e.message}"
          end
        end

        private

        def create_session_directory
          # Use configured default directory, not current working directory
          base_dir = @config["default_dir"]
          warn "[DEBUG] Base directory from config: #{base_dir}"
          session_dir = File.join(base_dir, "enhancement")
          warn "[DEBUG] Session directory path: #{session_dir}"

          FileUtils.mkdir_p(session_dir)
          warn "[DEBUG] Session directory created successfully"

          session_dir
        rescue => e
          warn "[DEBUG] Failed to create session directory: #{e.message}"
          raise
        end

        def create_user_context_file(session_dir, content, frontmatter)
          # Extract user context config for agent reporting
          user_context_config = frontmatter["context"] || {}

          # Extract the pure user prompt content (without any metadata)
          prompt_content = extract_user_prompt_content(content)

          # Create user context.md with:
          # 1. YAML frontmatter containing user context config
          # 2. User prompt as the body content
          frontmatter_content = user_context_config.empty? ? "" : "#{YAML.dump(user_context_config)}"

          if frontmatter_content.empty?
            context_content = prompt_content
          else
            context_content = "---\n#{frontmatter_content}---\n\n#{prompt_content}"
          end

          context_path = File.join(session_dir, "user.context.md")
          File.write(context_path, context_content)

          context_path
        end

        def create_system_context_file(session_dir, frontmatter)
          # Extract enhancement context config from frontmatter
          enhancement_config = frontmatter.dig("enhancement", "context") || {}

          # Get system prompt URI from config or frontmatter
          system_prompt_uri = frontmatter.dig("enhancement", "system_prompt") ||
                              @config.dig("enhancement", "system_prompt") ||
                              "prompt://enhance-instructions.system"

          # Load the system prompt content
          system_prompt_content = load_system_prompt_content(system_prompt_uri)

          # Create system context.md with:
          # 1. YAML frontmatter containing enhancement.context
          # 2. System prompt as the body content
          frontmatter_content = enhancement_config.empty? ? "" : "#{YAML.dump(enhancement_config)}"

          if frontmatter_content.empty?
            context_content = system_prompt_content
          else
            context_content = "---\n#{frontmatter_content}---\n\n#{system_prompt_content}"
          end

          context_path = File.join(session_dir, "system.context.md")
          File.write(context_path, context_content)

          context_path
        end

        # Extract user prompt content from enhancement-processed content
        # @param content [String] Content that may include enhancement metadata
        # @return [String] Pure user prompt content
        def extract_user_prompt_content(content)
          # Remove enhancement tracking frontmatter if present
          # Pattern: enhancement_of, enhancement_iteration, etc.
          if content.match?(/\A---\n.*?enhancement_of:.*?\n---\n/m)
            # Remove enhancement metadata and extract only the user prompt part
            cleaned_content = content.sub(/\A---\n.*?enhancement_of:.*?\n---\n/m, "")

            # Look for the original user frontmatter pattern
            if cleaned_content.match?(/\A---\n.*?\n---\n/m)
              cleaned_content.sub(/\A---\n.*?\n---\n/m, "")
            else
              cleaned_content
            end
          elsif content.match?(/\A---\n.*?\n---\n/m)
            # Simple case: just remove the frontmatter
            content.sub(/\A---\n.*?\n---\n/m, "")
          else
            # No frontmatter found, return as-is
            content
          end
        end

        # Load system prompt content from URI
        # @param system_prompt_uri [String] URI to system prompt file
        # @return [String] System prompt content
        def load_system_prompt_content(system_prompt_uri)
          # Try to resolve via ace-nav if it's a prompt:// URI
          if system_prompt_uri.start_with?("prompt://")
            begin
              require "ace/nav"
              require "ace/nav/organisms/navigation_engine"

              engine = Ace::Nav::Organisms::NavigationEngine.new
              path = engine.resolve(system_prompt_uri)
              return File.read(path) if path && File.exist?(path)
            rescue LoadError, StandardError
              # Fall through to direct file path
            end
          end

          # Direct file path
          return File.read(system_prompt_uri) if File.exist?(system_prompt_uri)

          # Fallback to basic system prompt
          default_system_prompt
        end

        # Fallback system prompt if loading fails
        def default_system_prompt
          <<~PROMPT
            You are an expert at refining and clarifying prompts for AI coding assistants.

            Your task: Transform the user's prompt to be more clear, specific, and actionable while preserving their original intent.

            Guidelines:
            - Break down vague requests into concrete steps
            - Specify expected inputs and outputs
            - Add relevant technical context when helpful
            - Keep the enhanced prompt concise and focused
            - Preserve the user's voice and requirements

            Output ONLY the enhanced prompt - no explanations, no meta-commentary, no quotation marks.
          PROMPT
        end

        def execute_ace_context(input_file, output_file)
          # Check if ace-context is available
          unless ace_context_available?
            warn "Warning: ace-context gem not available. Using original content."
            warn "Hint: Install ace-context with 'gem install ace-context' to enable context loading."
            # Copy input to output as-is
            FileUtils.cp(input_file, output_file)
            return true
          end

          # Use ace-context Ruby API (same as ace-review)
          context_result = Ace::Context.load_file(input_file, embed_source: true)

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
          # Check if ace-llm is available
          unless ace_llm_available?
            warn "Warning: ace-llm gem not available. Returning original prompt."
            warn "Hint: Install ace-llm with 'gem install ace-llm' to enable AI enhancement."
            return user_prompt.strip
          end

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

        # Check if ace-context is available
        # @return [Boolean] True if ace-context gem is loaded and functional
        def ace_context_available?
          defined?(Ace::Context) &&
            Ace::Context.respond_to?(:load_file)
        end

        # Check if ace-llm is available
        # @return [Boolean] True if ace-llm gem is loaded and functional
        def ace_llm_available?
          defined?(Ace::LLM) &&
            defined?(Ace::LLM::QueryInterface) &&
            Ace::LLM::QueryInterface.respond_to?(:query)
        end
      end
    end
  end
end
