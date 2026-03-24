# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Represents a configured reviewer entity with focus areas and filtering capabilities.
      #
      # Reviewers are configured entities that transform from simple model names to
      # full-featured review participants with focus areas, file filtering, and
      # weighted contributions.
      #
      # @example Creating a reviewer from config
      #   reviewer = Reviewer.new(
      #     name: "code-fit",
      #     model: "google:gemini-2.5-pro",
      #     focus: "code_quality",
      #     system_prompt_additions: "Focus on SOLID principles...",
      #     file_patterns: { include: ["lib/**/*.rb"], exclude: ["**/*_test.rb"] },
      #     weight: 1.0,
      #     critical: false
      #   )
      #
      class Reviewer
        # Default weight for reviewers (1.0 = full contribution)
        DEFAULT_WEIGHT = 1.0

        attr_reader :name, :model, :focus, :system_prompt_additions,
          :file_patterns, :weight, :critical

        # Initialize a new Reviewer from a configuration hash
        #
        # @param config [Hash] Configuration hash with reviewer settings
        # @option config [String] :name Human-readable name for the reviewer
        # @option config [String] :model LLM model identifier (e.g., "google:gemini-2.5-pro")
        # @option config [String] :focus Review focus area (e.g., "code_quality", "security")
        # @option config [String] :system_prompt_additions Additional system prompt text
        # @option config [Hash] :file_patterns File filtering patterns
        # @option config [Float] :weight Contribution weight (0.0-1.0, default: 1.0)
        # @option config [Boolean] :critical Whether findings are always highlighted
        def initialize(config = {})
          # Support both symbol and string keys
          config = normalize_keys(config)

          @name = config["name"]
          @model = config["model"]
          @focus = config["focus"]
          @system_prompt_additions = config["system_prompt_additions"]
          @file_patterns = normalize_file_patterns(config["file_patterns"])
          @weight = (config["weight"] || DEFAULT_WEIGHT).to_f
          @critical = config["critical"] || false

          validate!
        end

        # Create Reviewers from preset config (new reviewers array format)
        #
        # @param config [Hash] Preset configuration
        # @return [Array<Reviewer>] Array of reviewer instances
        def self.from_preset_config(config)
          config = normalize_hash_keys(config)

          # New format: reviewers array
          if config["reviewers"].is_a?(Array) && config["reviewers"].any?
            return config["reviewers"].map { |r| new(r) }
          end

          []
        end

        # Filter subject content based on reviewer's file patterns
        #
        # Delegates to SubjectFilter molecule for actual filtering logic.
        #
        # @param subject [Hash] Subject configuration with files/diff/content
        # @return [Hash] Filtered subject (deep copy with only matching content)
        def filter_subject(subject)
          Molecules::SubjectFilter.filter(subject, file_patterns)
        end

        # Enhance system prompt with reviewer's additions
        #
        # @param base_prompt [String] Original system prompt
        # @return [String] Enhanced prompt with reviewer additions
        def enhance_system_prompt(base_prompt)
          return base_prompt unless system_prompt_additions
          return system_prompt_additions if base_prompt.nil? || base_prompt.empty?

          "#{base_prompt}\n\n#{system_prompt_additions}"
        end

        # Check if this reviewer has file patterns configured
        #
        # Delegates to SubjectFilter molecule.
        #
        # @return [Boolean] True if file patterns are configured
        def has_file_patterns?
          Molecules::SubjectFilter.has_patterns?(file_patterns)
        end

        # Check if a file path matches this reviewer's patterns
        #
        # Delegates to SubjectFilter molecule.
        #
        # @param file_path [String] File path to check
        # @return [Boolean] True if file matches (or no patterns configured)
        def matches_file?(file_path)
          Molecules::SubjectFilter.matches_file?(file_path, file_patterns)
        end

        # Convert to hash representation
        #
        # @return [Hash] Hash with string keys
        def to_h
          {
            "name" => name,
            "model" => model,
            "focus" => focus,
            "system_prompt_additions" => system_prompt_additions,
            "file_patterns" => file_patterns,
            "weight" => weight,
            "critical" => critical
          }.compact
        end

        # Check equality with another reviewer
        #
        # @param other [Reviewer] Other reviewer to compare
        # @return [Boolean] True if equal
        def ==(other)
          return false unless other.is_a?(Reviewer)

          name == other.name &&
            model == other.model &&
            focus == other.focus &&
            weight == other.weight &&
            critical == other.critical
        end

        alias_method :eql?, :==

        # Hash code for use in hash tables
        #
        # @return [Integer] Hash code
        def hash
          [name, model, focus, weight, critical].hash
        end

        private

        # Validate required fields
        def validate!
          raise ArgumentError, "Reviewer model is required" if model.nil? || model.to_s.strip.empty?
          raise ArgumentError, "Reviewer weight must be between 0 and 1" if weight < 0 || weight > 1
        end

        # Normalize hash keys to strings (supports both symbol and string keys)
        def normalize_keys(hash)
          return {} unless hash.is_a?(Hash)
          hash.transform_keys(&:to_s)
        end

        # Class method for key normalization
        def self.normalize_hash_keys(hash)
          return {} unless hash.is_a?(Hash)
          hash.transform_keys(&:to_s)
        end

        # Normalize file patterns structure
        def normalize_file_patterns(patterns)
          return nil unless patterns.is_a?(Hash)

          normalized = normalize_keys(patterns)
          {
            "include" => Array(normalized["include"]),
            "exclude" => Array(normalized["exclude"])
          }
        end
      end
    end
  end
end
