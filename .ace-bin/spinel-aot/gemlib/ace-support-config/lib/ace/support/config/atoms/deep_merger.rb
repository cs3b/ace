# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Atoms
        # Pure deep merge functions for hashes
        module DeepMerger
          module_function

          # Deep merge two hashes
          #
          # @param base [Hash] Base hash
          # @param other [Hash] Hash to merge into base
          # @param options [Hash] Merge options
          # @option options [Symbol] :array_strategy How to handle arrays
          #   :replace - Replace base array with overlay (default)
          #   :concat - Concatenate arrays
          #   :union - Set union (dedupe by value)
          #   :coerce_union - Coerce scalars to arrays, union, filter blanks
          # @return [Hash] Merged hash (new object)
          #
          # @note Uses shallow dup at top level (standard Ruby pattern). Nested hashes
          #   are recursively merged into new objects, so mutation risk is minimal.
          #   For a completely isolated deep copy, use: `merge({}, original_hash)`
          def merge(base, other, options = {})
            return other.dup if base.nil?
            return base.dup if other.nil?

            array_strategy = options[:array_strategy] || :replace

            result = base.dup

            other.each do |key, other_value|
              base_value = result[key]

              result[key] = if base_value.is_a?(Hash) && other_value.is_a?(Hash)
                merge(base_value, other_value, options)
              elsif array_strategy == :coerce_union
                merge_with_coercion(base_value, other_value)
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

          # Merge values with scalar-to-array coercion for :coerce_union strategy
          # @param base_value [Object] Base value (may be array, scalar, or nil)
          # @param other_value [Object] Overlay value
          # @return [Object] Merged result
          def merge_with_coercion(base_value, other_value)
            base_arr = coerce_to_array(base_value)
            other_arr = coerce_to_array(other_value)

            # New key with scalar: keep as scalar
            return other_value if base_arr.nil? && !other_value.is_a?(Array)
            # New key with array: normalize
            return normalize_array(other_arr) if base_arr.nil?
            # Existing key, new value nil: keep existing normalized
            return normalize_array(base_arr) if other_arr.nil?

            # Both have values: union and normalize
            normalize_array(base_arr | other_arr)
          end

          # Coerce value to array if not nil
          # @param value [Object] Value to coerce
          # @return [Array, nil] Array or nil if value was nil
          def coerce_to_array(value)
            return nil if value.nil?
            value.is_a?(Array) ? value : [value]
          end

          # Normalize array: remove nil/empty, deduplicate
          # @param arr [Array] Array to normalize
          # @return [Array] Normalized array
          def normalize_array(arr)
            arr.reject { |v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }.uniq
          end
        end
      end
    end
  end
end
