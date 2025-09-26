# frozen_string_literal: true

require "pathname"

module Ace
  module GitCommit
    module Molecules
      # MessageGenerator generates commit messages using LLM
      class MessageGenerator
        DEFAULT_MODEL = "glite"
        SYSTEM_PROMPT_PATH = "dev-handbook/templates/prompts/git-commit.system.md"

        def initialize(config = nil)
          @config = config || {}
          @model = @config.fetch("model", DEFAULT_MODEL)
        end

        # Generate a commit message from diff
        # @param diff [String] The git diff
        # @param intention [String, nil] Optional intention/context
        # @param files [Array<String>] List of changed files
        # @return [String] Generated commit message
        def generate(diff, intention: nil, files: [])
          system_prompt = load_system_prompt
          user_prompt = build_user_prompt(diff, intention, files)

          # Use QueryInterface with named parameters matching CLI
          response = Ace::LLM::QueryInterface.query(
            @model,
            user_prompt,
            system: system_prompt,
            temperature: 0.7,
            timeout: 60
          )

          clean_commit_message(response[:text])
        rescue Ace::LLM::Error => e
          raise Error, "Failed to generate commit message: #{e.message}"
        end

        private

        # Load system prompt from template
        # @return [String] System prompt content
        def load_system_prompt
          # Try to find the prompt in the project structure
          prompt_path = find_system_prompt_path

          if prompt_path && File.exist?(prompt_path)
            File.read(prompt_path)
          else
            # Fallback to embedded prompt
            default_system_prompt
          end
        end

        # Find the system prompt file path
        # @return [String, nil] Path to system prompt or nil
        def find_system_prompt_path
          # Look for dev-handbook in current directory or parent directories
          current = Pathname.pwd

          while current.parent != current
            prompt_file = current.join(SYSTEM_PROMPT_PATH)
            return prompt_file.to_s if prompt_file.exist?

            # Also check if we're already in ace-meta
            if current.basename.to_s == "ace-git-commit"
              parent_prompt = current.parent.join(SYSTEM_PROMPT_PATH)
              return parent_prompt.to_s if parent_prompt.exist?
            end

            current = current.parent
          end

          nil
        end

        # Build user prompt from diff and context
        # @param diff [String] The git diff
        # @param intention [String, nil] Optional intention
        # @param files [Array<String>] Changed files
        # @return [String] User prompt
        def build_user_prompt(diff, intention, files)
          prompt = []

          if intention && !intention.empty?
            prompt << "Intention/Context: #{intention}"
            prompt << ""
          end

          if files && !files.empty?
            prompt << "Changed files:"
            files.each { |f| prompt << "  - #{f}" }
            prompt << ""
          end

          prompt << "Git diff:"
          prompt << diff

          prompt.join("\n")
        end

        # Clean and format the generated commit message
        # @param message [String] Raw generated message
        # @return [String] Cleaned message
        def clean_commit_message(message)
          return "" if message.nil?

          # Remove any markdown code blocks
          message = message.gsub(/```[a-z]*\n?/, "")
          message = message.gsub(/```\n?/, "")

          # Remove leading/trailing whitespace
          message = message.strip

          # Ensure proper formatting
          lines = message.lines.map(&:rstrip)

          # Remove empty lines at the beginning
          while lines.first && lines.first.strip.empty?
            lines.shift
          end

          # Ensure single blank line between title and body
          if lines.length > 1
            # Find the first non-empty line after the title
            title_index = 0
            body_start = 1

            while body_start < lines.length && lines[body_start].strip.empty?
              body_start += 1
            end

            if body_start < lines.length
              # Reconstruct with single blank line
              result = [lines[title_index]]
              result << ""
              result.concat(lines[body_start..-1])
              lines = result
            end
          end

          lines.join("\n")
        end

        # Default system prompt if template not found
        # @return [String] Default prompt
        def default_system_prompt
          <<~PROMPT
            You are a git commit message generator. Generate clear, concise commit messages following conventional commit format.

            Format:
            <type>(<scope>): <subject>

            <body>

            Types:
            - feat: New feature
            - fix: Bug fix
            - docs: Documentation changes
            - style: Code style changes (formatting, etc.)
            - refactor: Code refactoring
            - test: Test changes
            - chore: Build process or auxiliary tool changes

            Rules:
            - Subject line: max 72 characters, imperative mood
            - Scope: optional, component or area affected
            - Body: explain what and why, not how
            - Keep messages clear and professional

            Generate only the commit message, no additional commentary.
          PROMPT
        end
      end
    end
  end
end