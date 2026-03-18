# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Pure functions for loading and applying composition rules.
      #
      # Composition rules define ordering constraints, step pairs,
      # and conditional suggestions for building assignments.
      #
      # @example Validating ordering
      #   rules = CompositionRules.load("/path/to/catalog")
      #   violations = CompositionRules.validate_ordering(
      #     ["work-on-task", "onboard"],
      #     rules
      #   )
      #   # => [{ rule: "onboard-first", message: "onboard must be first" }]
      module CompositionRules
        # Load composition rules from catalog directory.
        #
        # @param catalog_dir [String] Path to catalog/ directory
        # @return [Hash] Parsed rules with ordering, pairs, conditional, review_cycles
        def self.load(catalog_dir)
          rules_path = File.join(catalog_dir, "composition-rules.yml")
          return default_rules unless File.exist?(rules_path)

          YAML.safe_load_file(rules_path, permitted_classes: [Date]) || default_rules
        rescue StandardError
          default_rules
        end

        # Validate step ordering against rules.
        #
        # @param step_names [Array<String>] Ordered list of step names
        # @param rules [Hash] Loaded composition rules
        # @return [Array<Hash>] Violations, each with :rule and :message
        def self.validate_ordering(step_names, rules)
          violations = []
          ordering_rules = rules["ordering"] || []

          ordering_rules.each do |rule|
            violation = check_ordering_rule(step_names, rule)
            violations << violation if violation
          end

          violations
        end

        # Suggest additional steps based on the selected set and rules.
        #
        # @param step_names [Array<String>] Currently selected step names
        # @param rules [Hash] Loaded composition rules
        # @return [Array<Hash>] Suggestions, each with :step, :strength, :reason
        def self.suggest_additions(step_names, rules)
          suggestions = []

          # Check pair completeness
          (rules["pairs"] || []).each do |pair|
            pair_suggestions = check_pair_completeness(step_names, pair)
            suggestions.concat(pair_suggestions)
          end

          # Check conditional rules
          (rules["conditional"] || []).each do |conditional|
            conditional_suggestions = check_conditional_rule(step_names, conditional)
            suggestions.concat(conditional_suggestions)
          end

          suggestions
        end

        # Default empty rules structure.
        #
        # @return [Hash] Empty rules
        def self.default_rules
          {
            "ordering" => [],
            "pairs" => [],
            "conditional" => [],
            "review_cycles" => {
              "default_count" => 2,
              "max_count" => 5
            }
          }
        end
        private_class_method :default_rules

        # Check a single ordering rule against step sequence.
        #
        # Uses prefix matching so a rule referencing "release" matches
        # steps named "release-minor" or "release-patch-1".
        #
        # @param step_names [Array<String>] Ordered list of step names
        # @param rule [Hash] Ordering rule definition
        # @return [Hash, nil] Violation hash or nil if rule is satisfied
        def self.check_ordering_rule(step_names, rule)
          # Position rules (e.g., "onboard must be first")
          if rule["position"] == "first" && rule["step"]
            step = rule["step"]
            idx = find_step_index(step_names, step)
            if idx && idx != 0
              return { rule: rule["rule"], message: "'#{step}' must be first" }
            end
          end

          # Before/after rules (e.g., "create-pr must come before review-pr")
          if rule["before"] && rule["after"]
            before_idx = find_step_index(step_names, rule["before"])
            after_idx = find_step_index(step_names, rule["after"])

            if before_idx && after_idx && before_idx >= after_idx
              return {
                rule: rule["rule"],
                message: "'#{rule["before"]}' must come before '#{rule["after"]}'"
              }
            end
          end

          nil
        end
        private_class_method :check_ordering_rule

        # Find the index of a step by exact name or prefix match.
        #
        # Allows rules to reference base names (e.g., "release") that match
        # suffixed variants (e.g., "release-minor", "release-patch-1").
        #
        # Note: Rule names should be specific enough to avoid unintended matches.
        # A short prefix like "re" would match both "release-minor" and
        # "reorganize-commits". Use full base names in composition rules.
        #
        # @param step_names [Array<String>] Step name list
        # @param name [String] Name to find (exact or prefix)
        # @return [Integer, nil] Index or nil if not found
        def self.find_step_index(step_names, name)
          idx = step_names.index(name)
          return idx if idx

          step_names.index { |p| p.start_with?("#{name}-") }
        end
        private_class_method :find_step_index

        # Check a conditional rule against the selected steps.
        #
        # Parses "assignment includes X or Y" patterns from the when field
        # and checks if any referenced steps are present.
        #
        # @param step_names [Array<String>] Currently selected step names
        # @param conditional [Hash] Conditional rule definition
        # @return [Array<Hash>] Suggestions for steps to add
        def self.check_conditional_rule(step_names, conditional)
          suggestions = []
          when_clause = conditional["when"] || ""
          suggest_steps = conditional["suggest"] || []
          strength = conditional["strength"] || "recommended"

          # Parse "assignment includes X or/and Y" pattern.
          # Supports "or" (any trigger) and "and" (all triggers) separately.
          # Mixed conjunctions (e.g., "A or B and C") are not supported —
          # "and" takes precedence when present.
          if (match = when_clause.match(/assignment includes (.+)/i))
            raw = match[1]
            if raw.include?(" and ")
              trigger_steps = raw.split(/\s+and\s+/).map(&:strip)
              triggered = trigger_steps.all? { |p| step_names.include?(p) }
            else
              trigger_steps = raw.split(/\s+or\s+/).map(&:strip)
              triggered = trigger_steps.any? { |p| step_names.include?(p) }
            end

            if triggered
              suggest_steps.each do |step|
                next if step_names.include?(step)

                suggestions << {
                  step: step,
                  strength: strength,
                  reason: when_clause
                }
              end
            end
          end

          suggestions
        end
        private_class_method :check_conditional_rule

        # Check if paired steps are complete.
        #
        # @param step_names [Array<String>] Currently selected step names
        # @param pair [Hash] Pair definition
        # @return [Array<Hash>] Suggestions for missing pair members
        def self.check_pair_completeness(step_names, pair)
          suggestions = []
          pair_steps = pair["steps"] || []
          return suggestions if pair_steps.length < 2
          return suggestions if pair["pattern"] == "conditional"

          present = pair_steps.select { |p| step_names.include?(p) }
          return suggestions if present.empty? || present.length == pair_steps.length

          missing = pair_steps - present
          missing.each do |step|
            suggestions << {
              step: step,
              strength: "recommended",
              reason: "Part of '#{pair["name"]}' pair (#{pair["note"] || "paired steps"})"
            }
          end

          suggestions
        end
        private_class_method :check_pair_completeness
      end
    end
  end
end
