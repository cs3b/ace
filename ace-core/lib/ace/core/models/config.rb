# frozen_string_literal: true

module Ace
  module Core
    module Models
      # Configuration data structure
      class Config
        attr_reader :data, :source, :merge_strategy

        # Initialize configuration
        # @param data [Hash] Configuration data
        # @param source [String] Source file or identifier
        # @param merge_strategy [Symbol] How to merge with other configs
        def initialize(data = {}, source: nil, merge_strategy: :deep)
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

        # Create new config with additional data
        # @param other_data [Hash] Data to merge
        # @return [Config] New configuration instance
        def with(other_data)
          require_relative "../atoms/deep_merger"

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