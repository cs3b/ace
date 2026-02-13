# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Pure functions for loading and applying composition rules.
      #
      # Composition rules define ordering constraints, phase pairs,
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

        # Validate phase ordering against rules.
        #
        # @param phase_names [Array<String>] Ordered list of phase names
        # @param rules [Hash] Loaded composition rules
        # @return [Array<Hash>] Violations, each with :rule and :message
        def self.validate_ordering(phase_names, rules)
          violations = []
          ordering_rules = rules["ordering"] || []

          ordering_rules.each do |rule|
            violation = check_ordering_rule(phase_names, rule)
            violations << violation if violation
          end

          violations
        end

        # Suggest additional phases based on the selected set and rules.
        #
        # @param phase_names [Array<String>] Currently selected phase names
        # @param rules [Hash] Loaded composition rules
        # @return [Array<Hash>] Suggestions, each with :phase, :strength, :reason
        def self.suggest_additions(phase_names, rules)
          suggestions = []

          # Check pair completeness
          (rules["pairs"] || []).each do |pair|
            pair_suggestions = check_pair_completeness(phase_names, pair)
            suggestions.concat(pair_suggestions)
          end

          # Check conditional rules
          (rules["conditional"] || []).each do |conditional|
            conditional_suggestions = check_conditional_rule(phase_names, conditional)
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

        # Check a single ordering rule against phase sequence.
        #
        # Uses prefix matching so a rule referencing "release" matches
        # phases named "release-minor" or "release-patch-1".
        #
        # @param phase_names [Array<String>] Ordered list of phase names
        # @param rule [Hash] Ordering rule definition
        # @return [Hash, nil] Violation hash or nil if rule is satisfied
        def self.check_ordering_rule(phase_names, rule)
          # Position rules (e.g., "onboard must be first")
          if rule["position"] == "first" && rule["phase"]
            phase = rule["phase"]
            idx = find_phase_index(phase_names, phase)
            if idx && idx != 0
              return { rule: rule["rule"], message: "'#{phase}' must be first" }
            end
          end

          # Before/after rules (e.g., "create-pr must come before review-pr")
          if rule["before"] && rule["after"]
            before_idx = find_phase_index(phase_names, rule["before"])
            after_idx = find_phase_index(phase_names, rule["after"])

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

        # Find the index of a phase by exact name or prefix match.
        #
        # Allows rules to reference base names (e.g., "release") that match
        # suffixed variants (e.g., "release-minor", "release-patch-1").
        #
        # Note: Rule names should be specific enough to avoid unintended matches.
        # A short prefix like "re" would match both "release-minor" and
        # "reorganize-commits". Use full base names in composition rules.
        #
        # @param phase_names [Array<String>] Phase name list
        # @param name [String] Name to find (exact or prefix)
        # @return [Integer, nil] Index or nil if not found
        def self.find_phase_index(phase_names, name)
          idx = phase_names.index(name)
          return idx if idx

          phase_names.index { |p| p.start_with?("#{name}-") }
        end
        private_class_method :find_phase_index

        # Check a conditional rule against the selected phases.
        #
        # Parses "assignment includes X or Y" patterns from the when field
        # and checks if any referenced phases are present.
        #
        # @param phase_names [Array<String>] Currently selected phase names
        # @param conditional [Hash] Conditional rule definition
        # @return [Array<Hash>] Suggestions for phases to add
        def self.check_conditional_rule(phase_names, conditional)
          suggestions = []
          when_clause = conditional["when"] || ""
          suggest_phases = conditional["suggest"] || []
          strength = conditional["strength"] || "recommended"

          # Parse "assignment includes X or/and Y" pattern.
          # Supports "or" (any trigger) and "and" (all triggers) separately.
          # Mixed conjunctions (e.g., "A or B and C") are not supported —
          # "and" takes precedence when present.
          if (match = when_clause.match(/assignment includes (.+)/i))
            raw = match[1]
            if raw.include?(" and ")
              trigger_phases = raw.split(/\s+and\s+/).map(&:strip)
              triggered = trigger_phases.all? { |p| phase_names.include?(p) }
            else
              trigger_phases = raw.split(/\s+or\s+/).map(&:strip)
              triggered = trigger_phases.any? { |p| phase_names.include?(p) }
            end

            if triggered
              suggest_phases.each do |phase|
                next if phase_names.include?(phase)

                suggestions << {
                  phase: phase,
                  strength: strength,
                  reason: when_clause
                }
              end
            end
          end

          suggestions
        end
        private_class_method :check_conditional_rule

        # Check if paired phases are complete.
        #
        # @param phase_names [Array<String>] Currently selected phase names
        # @param pair [Hash] Pair definition
        # @return [Array<Hash>] Suggestions for missing pair members
        def self.check_pair_completeness(phase_names, pair)
          suggestions = []
          pair_phases = pair["phases"] || []
          return suggestions if pair_phases.length < 2
          return suggestions if pair["pattern"] == "conditional"

          present = pair_phases.select { |p| phase_names.include?(p) }
          return suggestions if present.empty? || present.length == pair_phases.length

          missing = pair_phases - present
          missing.each do |phase|
            suggestions << {
              phase: phase,
              strength: "recommended",
              reason: "Part of '#{pair["name"]}' pair (#{pair["note"] || "paired phases"})"
            }
          end

          suggestions
        end
        private_class_method :check_pair_completeness
      end
    end
  end
end
