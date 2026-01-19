# frozen_string_literal: true

module Ace
  module Lint
    module Atoms
      # Registry mapping validator names to runner classes
      # Provides lookup and availability checking for validators
      class ValidatorRegistry
        # Map of validator name (symbol) to runner class
        VALIDATORS = {
          standardrb: "Ace::Lint::Atoms::StandardrbRunner",
          rubocop: "Ace::Lint::Atoms::RuboCopRunner"
        }.freeze

        # Aliases for common variations
        ALIASES = {
          standard: :standardrb,
          "standard-rb": :standardrb,
          rubocop_runner: :rubocop
        }.freeze

        # Get runner class for a validator name
        # @param name [String, Symbol] Validator name
        # @return [Class, nil] Runner class or nil if not found
        def self.runner_for(name)
          canonical = canonical_name(name)
          return nil unless canonical

          class_name = VALIDATORS[canonical]
          return nil unless class_name

          # Resolve class from string
          class_name.split("::").reduce(Object) { |mod, part| mod.const_get(part) }
        rescue NameError
          nil
        end

        # Check if a validator is registered
        # @param name [String, Symbol] Validator name
        # @return [Boolean] True if validator exists in registry
        def self.registered?(name)
          canonical_name(name) != nil
        end

        # Check if a validator is available (installed and runnable)
        # Results are cached to avoid repeated subprocess calls
        # @param name [String, Symbol] Validator name
        # @return [Boolean] True if validator can be used
        def self.available?(name)
          @availability_cache ||= {}
          canonical = canonical_name(name)
          return false unless canonical

          return @availability_cache[canonical] if @availability_cache.key?(canonical)

          runner = runner_for(canonical)
          result = runner&.respond_to?(:available?) && runner.available?
          @availability_cache[canonical] = result
        end

        # Get list of all registered validator names
        # @return [Array<Symbol>] List of validator names
        def self.registered_validators
          VALIDATORS.keys
        end

        # Get list of all available validators (installed and runnable)
        # @return [Array<Symbol>] List of available validator names
        def self.available_validators
          VALIDATORS.keys.select { |name| available?(name) }
        end

        # Resolve canonical name from input (handles aliases)
        # @param name [String, Symbol] Input name
        # @return [Symbol, nil] Canonical name or nil if not found
        def self.canonical_name(name)
          return nil if name.nil?

          sym = name.to_s.downcase.tr("-", "_").to_sym

          # Check direct match
          return sym if VALIDATORS.key?(sym)

          # Check aliases
          aliased = ALIASES[sym]
          return aliased if aliased && VALIDATORS.key?(aliased)

          # Check string key aliases
          str_sym = name.to_s.downcase.tr("_", "-").to_sym
          aliased = ALIASES[str_sym]
          return aliased if aliased && VALIDATORS.key?(aliased)

          nil
        end

        # Reset availability cache (for testing)
        # @return [void]
        def self.reset_cache!
          @availability_cache = {}
        end

        # Reset all caches across the validator system
        # Call this at CLI entry point to ensure fresh availability checks
        # @return [void]
        def self.reset_all_caches!
          reset_cache!
          StandardrbRunner.reset_availability_cache!
          RuboCopRunner.reset_availability_cache!
        end
      end
    end
  end
end
