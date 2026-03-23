# frozen_string_literal: true

require_relative "../atoms/format_specs"

module Ace
  module B36ts
    module Molecules
      # Resolves configuration for ace-b36ts using the ace-config cascade.
      #
      # Configuration sources (in order of precedence):
      # 1. Runtime options (passed directly to methods)
      # 2. Project config (.ace/b36ts/config.yml)
      # 3. User config (~/.ace/b36ts/config.yml)
      # 4. Gem defaults (.ace-defaults/b36ts/config.yml)
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
          alphabet: "0123456789abcdefghijklmnopqrstuvwxyz",
          default_format: :"2sec"
        }.freeze

        class << self
          # Resolve configuration with optional overrides
          #
          # Uses Ace::Support::Config::Models::Config.wrap for proper merging per ADR-022.
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
            config = Ace::Support::Config::Models::Config.wrap(
              base_config,
              symbolized_overrides,
              source: "ace-b36ts"
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

          # Get the default_format value from configuration
          #
          # @param override [Symbol, String, nil] Optional runtime override
          # @return [Symbol] The default_format value (always a symbol)
          def default_format(override = nil)
            value = override || resolve[:default_format]
            value.is_a?(String) ? value.to_sym : value
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
            default_format = config[:default_format]

            unless alphabet.is_a?(String) && alphabet.length == 36
              raise ArgumentError, "alphabet must be exactly 36 characters, got #{alphabet&.length || "nil"}"
            end

            # Verify all characters in the alphabet are unique
            unless alphabet.chars.uniq.length == 36
              raise ArgumentError, "alphabet must contain 36 unique characters (duplicates found)"
            end

            unless year_zero.is_a?(Integer) && year_zero.between?(1900, 2100)
              raise ArgumentError, "year_zero must be between 1900-2100, got #{year_zero.inspect}"
            end

            # Validate default_format is a supported format
            format_sym = default_format.is_a?(String) ? default_format.to_sym : default_format
            unless format_sym.nil? || Ace::B36ts::Atoms::FormatSpecs.valid_format?(format_sym)
              raise ArgumentError, "default_format must be one of #{Ace::B36ts::Atoms::FormatSpecs.all_formats.join(", ")}, got #{default_format.inspect}"
            end
          end

          # Load configuration using ace-config cascade
          #
          # @return [Hash] Loaded configuration with symbolized keys
          def load_config
            @config ||= begin
              gem_root = Gem.loaded_specs["ace-b36ts"]&.gem_dir ||
                File.expand_path("../../../..", __dir__)

              resolver = Ace::Support::Config.create(
                config_dir: ".ace",
                defaults_dir: ".ace-defaults",
                gem_path: gem_root
              )

              loaded_config = resolver.resolve_namespace("b36ts")
              # loaded_config.data is already namespaced (no need to fetch "b36ts" key again)
              user_config = symbolize_keys(loaded_config.data)

              # Merge user config with fallback defaults (user values take precedence)
              FALLBACK_DEFAULTS.merge(user_config)
            rescue Psych::SyntaxError => e
              config_path = File.join(Dir.pwd, ".ace", "b36ts", "config.yml")
              warn "Error: Failed to parse #{config_path}: #{e.message}" if Ace::B36ts.debug?
              warn "  Check YAML syntax at line #{e.line}, column #{e.column}" if Ace::B36ts.debug? && e.line
              FALLBACK_DEFAULTS.dup
            rescue => e
              warn "Warning: Could not load ace-b36ts config: #{e.message}" if Ace::B36ts.debug?
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
