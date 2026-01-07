# frozen_string_literal: true

module Ace
  module Timestamp
    module Molecules
      # Resolves configuration for ace-timestamp using the ace-config cascade.
      #
      # Configuration sources (in order of precedence):
      # 1. Runtime options (passed directly to methods)
      # 2. Project config (.ace/timestamp/config.yml)
      # 3. User config (~/.ace/timestamp/config.yml)
      # 4. Gem defaults (.ace-defaults/timestamp/config.yml)
      #
      # @example Get resolved configuration
      #   config = ConfigResolver.resolve
      #   config[:year_zero]  # => 2000
      #   config[:alphabet]   # => "0123456789abcdefghijklmnopqrstuvwxyz"
      #
      # @example Override with runtime options
      #   config = ConfigResolver.resolve(year_zero: 2025)
      #   config[:year_zero]  # => 2025
      #
      module ConfigResolver
        # Fallback defaults (used only if .ace-defaults files cannot be loaded)
        FALLBACK_DEFAULTS = {
          year_zero: 2000,
          alphabet: "0123456789abcdefghijklmnopqrstuvwxyz"
        }.freeze

        class << self
          # Resolve configuration with optional overrides
          #
          # Uses Ace::Config::Models::Config.wrap for proper merging per ADR-022.
          #
          # @param overrides [Hash] Runtime configuration overrides
          # @return [Hash] Merged configuration
          # @raise [ArgumentError] If configuration values are invalid
          def resolve(overrides = {})
            base_config = load_config

            # Apply runtime overrides (symbolize keys, skip nil values)
            symbolized_overrides = {}
            overrides.each do |key, value|
              symbolized_overrides[key.to_sym] = value unless value.nil?
            end

            # Merge base config with runtime overrides
            config = Ace::Config::Models::Config.wrap(
              base_config,
              symbolized_overrides,
              source: "ace-timestamp"
            )

            # Validate the merged configuration
            validate_config!(config)

            config
          end

          # Get the year_zero value from configuration
          #
          # @param override [Integer, nil] Optional runtime override
          # @return [Integer] The year_zero value
          def year_zero(override = nil)
            override || resolve[:year_zero]
          end

          # Get the alphabet value from configuration
          #
          # @param override [String, nil] Optional runtime override
          # @return [String] The alphabet value
          def alphabet(override = nil)
            override || resolve[:alphabet]
          end

          # Reset cached configuration (useful for testing)
          def reset!
            @config = nil
          end

          private

          # Validate configuration values
          #
          # @param config [Hash] Configuration to validate
          # @raise [ArgumentError] If configuration values are invalid
          def validate_config!(config)
            alphabet = config[:alphabet]
            year_zero = config[:year_zero]

            unless alphabet.is_a?(String) && alphabet.length == 36
              raise ArgumentError, "alphabet must be exactly 36 characters, got #{alphabet&.length || 'nil'}"
            end

            # Verify all characters in the alphabet are unique
            unless alphabet.chars.uniq.length == 36
              raise ArgumentError, "alphabet must contain 36 unique characters (duplicates found)"
            end

            unless year_zero.is_a?(Integer) && year_zero.between?(1900, 2100)
              raise ArgumentError, "year_zero must be between 1900-2100, got #{year_zero.inspect}"
            end
          end

          # Load configuration using ace-config cascade
          #
          # @return [Hash] Loaded configuration with symbolized keys
          def load_config
            @config ||= begin
              gem_root = Gem.loaded_specs["ace-timestamp"]&.gem_dir ||
                         File.expand_path("../../..", __dir__)

              resolver = Ace::Config.create(
                config_dir: ".ace",
                defaults_dir: ".ace-defaults",
                gem_path: gem_root
              )

              loaded_config = resolver.resolve_namespace("timestamp")
              # loaded_config.data is already namespaced (no need to fetch "timestamp" key again)
              user_config = symbolize_keys(loaded_config.data)

              # Merge user config with fallback defaults (user values take precedence)
              FALLBACK_DEFAULTS.merge(user_config)
            rescue Psych::SyntaxError => e
              config_path = File.join(Dir.pwd, ".ace", "timestamp", "config.yml")
              warn "Error: Failed to parse #{config_path}: #{e.message}" if Ace::Timestamp.debug?
              warn "  Check YAML syntax at line #{e.line}, column #{e.column}" if Ace::Timestamp.debug? && e.line
              FALLBACK_DEFAULTS.dup
            rescue StandardError => e
              warn "Warning: Could not load ace-timestamp config: #{e.message}" if Ace::Timestamp.debug?
              FALLBACK_DEFAULTS.dup
            end
          end

          # Convert string keys to symbols
          #
          # @param hash [Hash] Hash with string or symbol keys
          # @return [Hash] Hash with symbol keys
          def symbolize_keys(hash)
            hash.transform_keys(&:to_sym)
          end
        end
      end
    end
  end
end
