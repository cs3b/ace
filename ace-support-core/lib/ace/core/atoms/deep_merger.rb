# frozen_string_literal: true

module Ace
  module Core
    module Atoms
      # Pure deep merge functions for hashes
      module DeepMerger
        module_function

        # Deep merge two hashes
        # @param base [Hash] Base hash
        # @param other [Hash] Hash to merge into base
        # @param options [Hash] Merge options
        # @option options [Symbol] :array_strategy (:replace) How to handle arrays (:replace, :concat, :union)
        # @return [Hash] Merged hash (new object)
        def merge(base, other, options = {})
          return other.dup if base.nil?
          return base.dup if other.nil?

          array_strategy = options[:array_strategy] || :replace

          result = base.dup

          other.each do |key, other_value|
            base_value = result[key]

            result[key] = if base_value.is_a?(Hash) && other_value.is_a?(Hash)
                            merge(base_value, other_value, options)
                          elsif base_value.is_a?(Array) && other_value.is_a?(Array)
                            merge_arrays(base_value, other_value, array_strategy)
                          else
                            other_value
                          end
          end

          result
        end

        # Deep merge multiple hashes in order
        # @param hashes [Array<Hash>] Hashes to merge
        # @param options [Hash] Merge options
        # @return [Hash] Merged result
        def merge_all(*hashes, **options)
          hashes = hashes.flatten.compact
          return {} if hashes.empty?

          hashes.reduce({}) do |result, hash|
            merge(result, hash, options)
          end
        end

        # Check if value is mergeable
        # @param value [Object] Value to check
        # @return [Boolean] true if value can be deep merged
        def mergeable?(value)
          value.is_a?(Hash) || value.is_a?(Array)
        end

        # Merge two arrays based on strategy
        # @param base_array [Array] Base array
        # @param other_array [Array] Array to merge
        # @param strategy [Symbol] Merge strategy
        # @return [Array] Merged array
        def merge_arrays(base_array, other_array, strategy)
          case strategy
          when :concat
            base_array + other_array
          when :union
            base_array | other_array
          when :replace
            other_array
          else
            raise MergeStrategyError, "Unknown array merge strategy: #{strategy}"
          end
        end
      end
    end
  end
end