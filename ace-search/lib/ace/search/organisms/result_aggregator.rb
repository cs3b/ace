# frozen_string_literal: true

module Ace
  module Search
    module Organisms
      # Aggregates and deduplicates search results
      # This is an organism - business logic for result aggregation
      class ResultAggregator
        # Aggregate results from multiple sources
        # @param results_list [Array<Hash>] Array of result sets
        # @return [Hash] Aggregated results
        def self.aggregate(results_list)
          all_results = []
          seen_results = Set.new

          results_list.each do |result_set|
            next unless result_set[:success]

            result_set[:results].each do |result|
              key = result_key(result)
              next if seen_results.include?(key)

              seen_results.add(key)
              all_results << result
            end
          end

          {
            success: true,
            results: all_results,
            count: all_results.size
          }
        end

        # Generate unique key for a result
        def self.result_key(result)
          case result[:type]
          when :file
            "file:#{result[:path]}"
          when :match
            "match:#{result[:path]}:#{result[:line] || result[:line_number]}"
          else
            "#{result[:type]}:#{result[:path]}"
          end
        end

        # Group results by file
        def self.group_by_file(results)
          grouped = {}

          results.each do |result|
            path = result[:path]
            grouped[path] ||= []
            grouped[path] << result
          end

          grouped
        end

        # Count results by type
        def self.count_by_type(results)
          counts = Hash.new(0)

          results.each do |result|
            counts[result[:type]] += 1
          end

          counts
        end
      end
    end
  end
end
