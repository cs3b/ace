# frozen_string_literal: true

require "pathname"
require "set"

module Ace
  module GitCommit
    module Molecules
      # MessageGenerator generates commit messages using LLM
      class MessageGenerator
        DEFAULT_MODEL = "glite"
        MAX_TOKENS = 8192
        SYSTEM_PROMPT_PATH = "ace-git-commit/handbook/prompts/git-commit.system.md"

        def initialize(config = nil)
          @config = config || {}
          @model = @config.fetch("model", DEFAULT_MODEL)
        end

        # Generate a commit message from diff
        # @param diff [String] The git diff
        # @param intention [String, nil] Optional intention/context
        # @param files [Array<String>] List of changed files
        # @param config [Hash, nil] Optional per-invocation config override
        # @return [String] Generated commit message
        def generate(diff, intention: nil, files: [], config: nil)
          system_prompt = load_system_prompt
          user_prompt = build_user_prompt(diff, intention, files)

          # Use QueryInterface with named parameters matching CLI
          response = Ace::LLM::QueryInterface.query(
            resolve_model(config),
            user_prompt,
            system: system_prompt,
            temperature: 0.7,
            timeout: 60,
            max_tokens: MAX_TOKENS
          )

          clean_commit_message(response[:text])
        rescue Ace::LLM::Error => e
          raise Error, "Failed to generate commit message: #{e.message}"
        end

        # Generate commit messages for multiple groups in one LLM call
        # @param groups_context [Array<Hash>] Array of {scope_name:, diff:, files:, type_hint:, description:}
        # @param intention [String, nil] Optional intention/context
        # @param config [Hash, nil] Optional config override
        # @return [Hash] { messages: Array<String>, order: Array<String> } with LLM-recommended order
        def generate_batch(groups_context, intention: nil, config: nil)
          return { messages: [], order: [] } if groups_context.empty?

          if groups_context.length == 1
            msg = generate(groups_context.first[:diff], intention: intention, files: groups_context.first[:files], config: config)
            return { messages: [msg], order: [groups_context.first[:scope_name]] }
          end

          system_prompt = load_batch_system_prompt
          user_prompt = build_batch_user_prompt(groups_context, intention)

          response = Ace::LLM::QueryInterface.query(
            resolve_model(config),
            user_prompt,
            system: system_prompt,
            temperature: 0.7,
            timeout: 120,
            max_tokens: MAX_TOKENS
          )

          parse_batch_response(response[:text], groups_context)
        rescue Ace::LLM::Error => e
          raise Error, "Failed to generate batch commit messages: #{e.message}"
        end

        private

        def load_batch_system_prompt
          <<~PROMPT
            You are a git commit message generator. Generate clear, concise commit messages following conventional commit format.

            You will receive MULTIPLE groups of changes that need SEPARATE commit messages.
            Each group represents a different scope/area of the codebase.

            CRITICAL: Generate DISTINCT messages for each group. Each message must:
            - Accurately describe what changed in THAT specific group
            - Use different wording than other groups
            - Focus on the specific scope/area of that group

            Format for EACH message:
            <type>(<scope>): <subject>

            <body>

            Types: feat, fix, docs, style, refactor, test, chore, spec

            TYPE SELECTION - VERY IMPORTANT:
            - Each group MAY have a "PREFERRED TYPE" hint - this hint applies ONLY to that specific group
            - Groups WITHOUT a type hint: analyze the actual code changes and select appropriately:
              * feat = new functionality, new features, new capabilities
              * fix = bug fixes
              * refactor = code restructuring without behavior change
              * test = test additions/changes
              * docs = documentation OF the software (user guides, API docs, README)
              * chore = build/config changes only
              * spec = specifications and artifacts from making software (task specs, planning docs, retros, ideas)
            - DO NOT let hints from one group influence your type selection for other groups
            - For code packages (lib/, src/, actual implementation): prefer feat/fix/refactor based on changes

            COMMIT ORDER - Output groups in logical commit order:
            - Implementation/feature code FIRST (the actual functionality)
            - Supporting libraries/dependencies that the feature uses
            - Configuration that enables/configures the feature
            - Documentation, specs, retros LAST (they document what was done)

            Rules of thumb:
            - feat/fix commits usually come before chore/docs
            - Core packages before config packages
            - But use judgment - sometimes config must come first if it enables the feature

            Output format (IN YOUR RECOMMENDED COMMIT ORDER):
            ---GROUP scope-name---
            <commit message>
            ---GROUP another-scope---
            <commit message>
            ... and so on

            IMPORTANT: Use exactly "---GROUP scope-name---" format with the actual scope name.
          PROMPT
        end

        def build_batch_user_prompt(groups_context, intention)
          prompt = []

          if intention && !intention.empty?
            prompt << "Overall intention/context: #{intention}"
            prompt << ""
          end

          prompt << "Generate #{groups_context.length} DISTINCT commit messages for these groups."
          prompt << "OUTPUT THEM IN YOUR RECOMMENDED COMMIT ORDER (implementation first, docs last)."
          prompt << "Use ---GROUP scope-name--- format with the exact scope name shown below."
          prompt << ""

          groups_context.each_with_index do |ctx, _index|
            prompt << "=" * 60
            prompt << "SCOPE: #{ctx[:scope_name]}"
            prompt << "=" * 60

            # Include type hint OR explicit instruction to analyze
            if ctx[:type_hint] && !ctx[:type_hint].to_s.empty?
              prompt << "PREFERRED TYPE FOR THIS GROUP ONLY: #{ctx[:type_hint]}"
            else
              prompt << "TYPE: Analyze changes and select appropriate type (feat/fix/refactor/test/docs/chore)"
            end

            # Include description if provided
            if ctx[:description] && !ctx[:description].to_s.empty?
              prompt << "Scope context: #{ctx[:description]}"
            end

            prompt << ""

            if ctx[:files] && !ctx[:files].empty?
              prompt << "Files in this group:"
              ctx[:files].each { |f| prompt << "  - #{f}" }
              prompt << ""
            end

            prompt << "Diff for this group:"
            prompt << ctx[:diff]
            prompt << ""
          end

          prompt.join("\n")
        end

        # Parse batch response and return ordered results
        # @param response [String] LLM response
        # @param groups_context [Array<Hash>] Original groups context
        # @return [Hash] { messages: Array<String>, order: Array<String> } ordered by LLM recommendation
        def parse_batch_response(response, groups_context)
          return { messages: [clean_commit_message(response)], order: [groups_context.first[:scope_name]] } if groups_context.length == 1

          # Parse groups with their scope names
          # Format: ---GROUP scope-name---
          parsed = {}
          current_scope = nil
          current_content = []

          response.lines.each do |line|
            if line =~ /---GROUP\s+(.+?)---/i
              # Save previous group
              if current_scope
                parsed[current_scope] = clean_commit_message(current_content.join)
              end
              current_scope = $1.strip
              current_content = []
            elsif current_scope
              current_content << line
            end
          end

          # Save last group
          if current_scope
            parsed[current_scope] = clean_commit_message(current_content.join)
          end

          # Build ordered results based on LLM output order
          scope_names = groups_context.map { |g| g[:scope_name] }
          llm_order = parsed.keys

          # Match LLM scope names to our scope names using priority-based matching
          ordered_scopes = []
          ordered_messages = []
          used_scopes = Set.new

          llm_order.each do |llm_scope|
            matched = match_scope_name(llm_scope, scope_names, used_scopes)
            if matched
              used_scopes.add(matched)
              ordered_scopes << matched
              ordered_messages << parsed[llm_scope]
            end
          end

          # Add any missing scopes at the end (fallback)
          scope_names.each do |scope|
            unless ordered_scopes.include?(scope)
              ordered_scopes << scope
              # Try to find a message from parsed that wasn't matched, or generate fallback
              fallback_msg = find_unmatched_message(scope, parsed, ordered_messages) ||
                             "chore: update #{scope}"
              ordered_messages << fallback_msg
            end
          end

          { messages: ordered_messages, order: ordered_scopes }
        end

        # Match LLM scope name to actual scope names with priority-based matching
        # Priority: 1) exact match, 2) case-insensitive exact, 3) careful substring match
        # @param llm_scope [String] Scope name from LLM response
        # @param scope_names [Array<String>] Valid scope names
        # @param used_scopes [Set<String>] Already matched scopes
        # @return [String, nil] Matched scope name or nil
        def match_scope_name(llm_scope, scope_names, used_scopes)
          available = scope_names.reject { |s| used_scopes.include?(s) }
          return nil if available.empty?

          # 1. Exact match (case-sensitive)
          exact = available.find { |s| s == llm_scope }
          return exact if exact

          # 2. Case-insensitive exact match
          case_insensitive = available.find { |s| s.downcase == llm_scope.downcase }
          return case_insensitive if case_insensitive

          # 3. Substring match with minimum length requirement to avoid false positives
          # Only match if substring is significant (>= 4 chars or >= 50% of shorter string)
          substring_match = available.find do |s|
            min_len = [4, [s.length, llm_scope.length].min / 2].max
            (s.downcase.include?(llm_scope.downcase) && llm_scope.length >= min_len) ||
              (llm_scope.downcase.include?(s.downcase) && s.length >= min_len)
          end

          if substring_match
            warn "[ace-git-commit] Scope name fallback: LLM returned '#{llm_scope}', matched to '#{substring_match}' via substring"
          end

          substring_match
        end

        # Find an unmatched message from parsed responses for fallback
        def find_unmatched_message(scope, parsed, already_used)
          # Try to find a message that mentions this scope but wasn't matched
          parsed.each do |llm_scope, message|
            next if already_used.include?(message)

            # Check if the message content references this scope
            if message.downcase.include?(scope.downcase)
              return message
            end
          end
          nil
        end

        def resolve_model(config_override)
          return @model unless config_override.is_a?(Hash)

          config_override.fetch("model", @model)
        end

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
          # Look for ace-git-commit/handbook in current directory or parent directories
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
