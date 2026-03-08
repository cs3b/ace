# frozen_string_literal: true

require "pathname"
require "json"

module Ace
  module GitCommit
    module Molecules
      # MessageGenerator generates commit messages using LLM
      class MessageGenerator
        DEFAULT_MODEL = "glite"
        MAX_TOKENS = 8192
        SYSTEM_PROMPT_PATH = "ace-git-commit/handbook/prompts/git-commit.system.md"
        COMMIT_HEADER_PATTERN = /\A(feat|fix|docs|style|refactor|test|chore|spec|perf|build|ci|revert)(\([^)]+\))?:\s+\S+/.freeze

        class BatchParseError < StandardError; end

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
        rescue BatchParseError => e
          repaired = retry_batch_parse(groups_context, intention, response[:text], e.message, config)
          return repaired if repaired

          raise Error, "Failed to generate batch commit messages: #{e.message}"
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

            OUTPUT MUST BE STRICT JSON ONLY (no markdown, no prose, no code fences):
            {
              "order": ["scope-a", "scope-b"],
              "messages": [
                {"scope": "scope-a", "message": "feat(scope-a): ..."},
                {"scope": "scope-b", "message": "fix(scope-b): ..."}
              ]
            }

            HARD RULES:
            - "order" must include every scope exactly once
            - "messages" must include every scope exactly once
            - each "message" must start with a valid conventional commit header
            - do not use "chore" unless the diff is actually build/config/maintenance only
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
          prompt << "Return STRICT JSON only with keys: order, messages."
          prompt << "Messages format: <type>(<scope>): <subject>"
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

        def parse_batch_response(response, groups_context)
          return { messages: [clean_commit_message(response)], order: [groups_context.first[:scope_name]] } if groups_context.length == 1

          scope_names = groups_context.map { |g| g[:scope_name] }
          parsed = parse_batch_json(response)
          order = Array(parsed["order"])
          messages_array = Array(parsed["messages"])

          message_by_scope = {}
          messages_array.each do |item|
            next unless item.is_a?(Hash)

            scope = item["scope"] || item[:scope]
            message = item["message"] || item[:message]
            next if scope.nil? || message.nil?

            message_by_scope[scope.to_s] = clean_commit_message(message.to_s)
          end

          validate_scope_list!("order", order, scope_names)
          validate_scope_list!("messages", message_by_scope.keys, scope_names)

          ordered_messages = order.map do |scope|
            msg = message_by_scope[scope]
            validate_commit_header!(scope, msg)
            msg
          end

          { messages: ordered_messages, order: order }
        end

        def parse_batch_json(response)
          raw = response.to_s.strip
          raw = raw.gsub(/\A```(?:json)?\s*/i, "").gsub(/\s*```\z/, "").strip
          raw = extract_json_block(raw)
          JSON.parse(raw)
        rescue JSON::ParserError => e
          raise BatchParseError, "Invalid batch JSON: #{e.message}"
        end

        def extract_json_block(text)
          start_idx = text.index("{")
          end_idx = text.rindex("}")
          raise BatchParseError, "Batch response does not include a JSON object." unless start_idx && end_idx

          text[start_idx..end_idx]
        end

        def validate_scope_list!(label, actual, expected)
          actual = actual.map(&:to_s)
          missing = expected - actual
          extra = actual - expected
          duplicates = actual.group_by(&:itself).select { |_k, v| v.length > 1 }.keys

          return if missing.empty? && extra.empty? && duplicates.empty?

          parts = []
          parts << "missing=#{missing.join(',')}" unless missing.empty?
          parts << "extra=#{extra.join(',')}" unless extra.empty?
          parts << "duplicates=#{duplicates.join(',')}" unless duplicates.empty?
          raise BatchParseError, "#{label} scope validation failed (#{parts.join(' | ')})"
        end

        def validate_commit_header!(scope, message)
          return if message && message.match?(COMMIT_HEADER_PATTERN)

          raise BatchParseError, "Invalid commit header for scope '#{scope}': #{message.inspect}"
        end

        def retry_batch_parse(groups_context, intention, previous_response, reason, config)
          warn "[ace-git-commit] Batch parse failed, retrying with strict JSON repair: #{reason}"

          repair_prompt = build_batch_repair_user_prompt(groups_context, intention, previous_response, reason)
          repair_response = Ace::LLM::QueryInterface.query(
            resolve_model(config),
            repair_prompt,
            system: load_batch_system_prompt,
            temperature: 0.2,
            timeout: 120,
            max_tokens: MAX_TOKENS
          )

          parse_batch_response(repair_response[:text], groups_context)
        rescue BatchParseError => e
          warn "[ace-git-commit] Batch parse retry failed: #{e.message}"
          nil
        end

        def build_batch_repair_user_prompt(groups_context, intention, bad_response, reason)
          scope_names = groups_context.map { |g| g[:scope_name] }
          prompt = []
          prompt << "Your previous response was invalid for strict JSON batch commit output."
          prompt << "Reason: #{reason}"
          prompt << "Allowed scopes: #{scope_names.join(', ')}"
          prompt << "Intention/context: #{intention}" if intention && !intention.empty?
          prompt << ""
          prompt << "Previous response:"
          prompt << bad_response.to_s
          prompt << ""
          prompt << "Return ONLY valid JSON in this exact shape:"
          prompt << '{"order":["scope-a","scope-b"],"messages":[{"scope":"scope-a","message":"feat(scope-a): ..."},{"scope":"scope-b","message":"fix(scope-b): ..."}]}'
          prompt.join("\n")
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
