# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure function: extracts and validates `assign:` block from markdown frontmatter.
      #
      # Takes a raw YAML frontmatter hash (already parsed from a .s.md or .wf.md file),
      # extracts the `assign:` block, validates fields, and returns a structured result.
      #
      # No file I/O — reuses existing frontmatter extraction from StepFileParser or ace-support-markdown.
      #
      # @example
      #   frontmatter = { "id" => "v.0.9.0+task.148", "status" => "in-progress",
      #                    "assign" => { "goal" => "implement-with-pr", "variables" => { "taskref" => "148" } } }
      #   result = AssignFrontmatterParser.parse(frontmatter)
      #   result[:config][:goal]  # => "implement-with-pr"
      #   result[:valid]          # => true
      module AssignFrontmatterParser
        VALID_FIELDS = %w[goal variables hints sub-steps context parent].freeze
        VALID_HINT_ACTIONS = %w[include skip].freeze
        VALID_CONTEXTS = %w[fork].freeze

        # Parse and validate the assign: block from frontmatter.
        #
        # @param frontmatter [Hash] Full frontmatter hash from any .s.md or .wf.md file
        # @return [Hash] { config: Hash|nil, valid: Boolean, errors: Array<String> }
        def self.parse(frontmatter)
          return {config: nil, valid: true, errors: []} if frontmatter.nil? || !frontmatter.is_a?(Hash)

          assign_block = frontmatter["assign"]
          return {config: nil, valid: true, errors: []} if assign_block.nil?

          errors = validate(assign_block)
          return {config: nil, valid: false, errors: errors} if errors.any?

          config = extract_config(assign_block)
          {config: config, valid: true, errors: []}
        end

        # Validate the assign block fields.
        #
        # @param assign_block [Hash] The assign: block from frontmatter
        # @return [Array<String>] List of validation errors (empty if valid)
        def self.validate(assign_block)
          errors = []

          unless assign_block.is_a?(Hash)
            errors << "assign: must be a mapping (Hash), got #{assign_block.class}"
            return errors
          end

          # Check for unknown fields
          unknown = assign_block.keys - VALID_FIELDS
          errors << "Unknown assign fields: #{unknown.join(", ")}" if unknown.any?

          # Validate goal (string)
          if assign_block.key?("goal") && !assign_block["goal"].is_a?(String)
            errors << "assign.goal must be a string"
          end

          # Validate variables (hash)
          if assign_block.key?("variables") && !assign_block["variables"].is_a?(Hash)
            errors << "assign.variables must be a mapping (Hash)"
          end

          # Validate hints (array of hashes with include/skip keys)
          if assign_block.key?("hints")
            errors.concat(validate_hints(assign_block["hints"]))
          end

          # Validate sub-steps (array of strings)
          if assign_block.key?("sub-steps")
            if !assign_block["sub-steps"].is_a?(Array)
              errors << "assign.sub-steps must be an array"
            elsif assign_block["sub-steps"].any? { |s| !s.is_a?(String) }
              errors << "assign.sub-steps entries must be strings"
            end
          end

          # Validate context (string, must be in VALID_CONTEXTS)
          if assign_block.key?("context")
            ctx = assign_block["context"]
            if !ctx.is_a?(String)
              errors << "assign.context must be a string"
            elsif !VALID_CONTEXTS.include?(ctx)
              errors << "assign.context must be one of: #{VALID_CONTEXTS.join(", ")}"
            end
          end

          # Validate parent (string)
          if assign_block.key?("parent") && !assign_block["parent"].is_a?(String)
            errors << "assign.parent must be a string"
          end

          errors
        end
        private_class_method :validate

        # Extract structured config from a validated assign block.
        #
        # @param assign_block [Hash] Validated assign: block
        # @return [Hash] Structured config with symbolized keys
        def self.extract_config(assign_block)
          {
            goal: assign_block["goal"],
            variables: assign_block["variables"] || {},
            hints: normalize_hints(assign_block["hints"] || []),
            sub_steps: assign_block["sub-steps"] || [],
            context: assign_block["context"],
            parent: assign_block["parent"]
          }
        end
        private_class_method :extract_config

        # Validate hints array entries.
        #
        # @param hints [Object] The hints value to validate
        # @return [Array<String>] Validation errors
        def self.validate_hints(hints)
          errors = []

          unless hints.is_a?(Array)
            errors << "assign.hints must be an array"
            return errors
          end

          hints.each_with_index do |hint, idx|
            unless hint.is_a?(Hash)
              errors << "assign.hints[#{idx}] must be a mapping (Hash)"
              next
            end

            actions = hint.keys & VALID_HINT_ACTIONS
            if actions.empty?
              errors << "assign.hints[#{idx}] must have an 'include' or 'skip' key"
            elsif actions.size > 1
              errors << "assign.hints[#{idx}] cannot have both 'include' and 'skip'"
            else
              value = hint[actions.first]
              unless value.is_a?(String)
                errors << "assign.hints[#{idx}].#{actions.first} must be a string, got #{value.class}"
              end
            end

            unknown_keys = hint.keys - VALID_HINT_ACTIONS
            if unknown_keys.any?
              errors << "assign.hints[#{idx}] has unknown keys: #{unknown_keys.join(", ")}"
            end
          end

          errors
        end
        private_class_method :validate_hints

        # Normalize hints into a consistent structure.
        #
        # @param hints [Array<Hash>] Raw hints from frontmatter
        # @return [Array<Hash>] Normalized hints with :action and :step keys
        def self.normalize_hints(hints)
          hints.map do |hint|
            if hint.key?("include")
              {action: :include, step: hint["include"]}
            elsif hint.key?("skip")
              {action: :skip, step: hint["skip"]}
            end
          end.compact
        end
        private_class_method :normalize_hints
      end
    end
  end
end
