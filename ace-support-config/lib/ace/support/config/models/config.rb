# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Models
        # Configuration data structure
        class Config
          attr_reader :data, :source, :merge_strategy

          # Initialize configuration
          # @param data [Hash] Configuration data
          # @param source [String] Source file or identifier
          # @param merge_strategy [Symbol] How to merge with other configs
          def initialize(data = {}, source: nil, merge_strategy: :replace)
            @data = data || {}
            @source = source
            @merge_strategy = merge_strategy
            freeze
          end

          # Get configuration value by key path
          # @param keys [Array<String,Symbol>] Path to value
          # @return [Object] Value at path or nil
          def get(*keys)
            keys = keys.flatten.map(&:to_s)
            keys.reduce(data) do |current, key|
              return nil unless current.is_a?(Hash)

              current[key]
            end
          end

          # Check if configuration has key path
          # @param keys [Array<String,Symbol>] Path to check
          # @return [Boolean] true if path exists
          def key?(*keys)
            !get(*keys).nil?
          end

          # Convert to hash
          # @return [Hash] Configuration data
          def to_h
            data.dup
          end

          # Get all keys at root level
          # @return [Array<String>] Root level keys
          def keys
            data.keys
          end

          # Check if configuration is empty
          # @return [Boolean] true if no configuration data
          def empty?
            data.empty?
          end

          # Iterate over root level key-value pairs
          def each(&block)
            data.each(&block)
          end

          # Create new config with additional data merged in
          # @param other_data [Hash] Data to merge
          # @return [Config] New configuration instance
          def merge(other_data)
            merged_data = Atoms::DeepMerger.merge(
              data,
              other_data,
              array_strategy: merge_strategy
            )

            self.class.new(
              merged_data,
              source: "#{source}+merged",
              merge_strategy: merge_strategy
            )
          end

          # Alias for backward compatibility
          alias_method :with, :merge

          # Factory method to wrap a hash and merge additional data, returning a hash
          # Provides a convenient one-liner for the common pattern:
          #   Config.new(base, source: "...").merge(overrides).to_h
          #
          # @param base [Hash, nil] Base configuration data (nil coerced to empty hash)
          # @param overrides [Hash, nil] Data to merge on top of base (default: {}, nil coerced to empty hash)
          # @param source [String] Source identifier for debugging (default: "wrap")
          # @param merge_strategy [Symbol] How to merge arrays (default: :replace)
          # @return [Hash] Merged configuration as a plain hash
          #
          # @example Single hash wrapping
          #   Config.wrap(defaults)
          #   # => { "key" => "default_value" }
          #
          # @example Merge two hashes
          #   Config.wrap(defaults, overrides)
          #   # => { "key" => "override_value", "other" => "default" }
          #
          # @example With options
          #   Config.wrap(defaults, overrides, source: "git_config", merge_strategy: :union)
          #
          # @example Handling nil inputs (type coercion)
          #   Config.wrap(nil)           # => {}
          #   Config.wrap({}, nil)       # => {}
          #   Config.wrap(nil, nil)      # => {}
          #
          def self.wrap(base, overrides = {}, source: "wrap", merge_strategy: :replace)
            # Type coercion: ensure base and overrides are hashes to prevent unexpected behavior
            base_hash = base.is_a?(Hash) ? base : {}
            overrides_hash = overrides.is_a?(Hash) ? overrides : {}

            new(base_hash, source: source, merge_strategy: merge_strategy)
              .merge(overrides_hash)
              .to_h
          end

          def ==(other)
            other.is_a?(self.class) &&
              other.data == data &&
              other.source == source &&
              other.merge_strategy == merge_strategy
          end

          def inspect
            "#<#{self.class.name} source=#{source.inspect} keys=#{keys.inspect}>"
          end
        end
      end
    end
  end
end
