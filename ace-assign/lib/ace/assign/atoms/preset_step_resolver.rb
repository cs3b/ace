# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Resolves preset step definitions by exact or base-name matching.
      module PresetStepResolver
        ITERATION_SUFFIX_REGEX = /-\d+\z/.freeze

        def self.find_steps(preset, names)
          Array(names).map { |name| find_step(preset, name) }
        end

        def self.find_step(preset, name)
          requested = name.to_s.strip
          raise Ace::Support::Cli::Error, "Step name cannot be empty" if requested.empty?

          steps = Array(preset["steps"])
          if steps.empty?
            raise Ace::Support::Cli::Error,
              "Preset '#{preset['name'] || 'unknown'}' has no steps defined. Add a non-empty 'steps' array."
          end

          exact = steps.find { |step| step_name(step) == requested }
          return exact if exact

          base = base_name(requested)
          matched = steps.find { |step| base_name(step_name(step)) == base }
          return matched if matched

          available = available_names(steps)
          raise Ace::Support::Cli::Error,
            "Step '#{requested}' not found in preset '#{preset['name'] || 'unknown'}'. " \
            "Available: #{available.join(', ')}"
        end

        def self.base_name(name)
          name.to_s.sub(ITERATION_SUFFIX_REGEX, "")
        end

        def self.iteration_name?(name)
          name.to_s.match?(ITERATION_SUFFIX_REGEX)
        end

        def self.next_iteration_name(base, existing_names)
          stem = base_name(base)
          existing = Array(existing_names).map(&:to_s)
          numbers = existing.filter_map do |name|
            match = name.match(/\A#{Regexp.escape(stem)}-(\d+)\z/)
            match && match[1].to_i
          end

          next_number = numbers.empty? ? 1 : numbers.max + 1
          "#{stem}-#{next_number}"
        end

        def self.step_name(step)
          step.is_a?(Hash) ? step["name"].to_s : ""
        end
        private_class_method :step_name

        def self.available_names(steps)
          names = steps.map { |step| step_name(step) }.reject(&:empty?)
          (names + names.map { |name| base_name(name) }).uniq.sort
        end
        private_class_method :available_names
      end
    end
  end
end
