# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    module Search
      # Aggregates and formats search results from multiple repositories
      class ResultAggregator
        # Initialize result aggregator
        def initialize
          @total_count = 0
          @repository_counts = {}
        end

        # Aggregate results from multiple repositories
        # @param results [Hash] Results keyed by repository name
        # @param options [Hash] Aggregation options
        # @return [Hash] Aggregated results
        def aggregate(results, options = {})
          reset_counts
          
          aggregated = {
            total_results: 0,
            repositories: {},
            summary: {},
            metadata: generate_metadata(options)
          }
          
          # Process each repository's results
          results.each do |repo_name, repo_data|
            processed = process_repository_results(repo_name, repo_data, options)
            aggregated[:repositories][repo_name] = processed
            aggregated[:total_results] += processed[:count]
            @repository_counts[repo_name] = processed[:count]
          end
          
          # Add summary information
          aggregated[:summary] = generate_summary(aggregated)
          
          # Apply result limits if specified
          if options[:max_results]
            aggregated = apply_result_limit(aggregated, options[:max_results])
          end
          
          # Format output based on requested format
          format_output(aggregated, options[:format] || :hash)
        end

        # Merge results from multiple searches
        # @param result_sets [Array<Hash>] Multiple result sets to merge
        # @return [Hash] Merged results
        def merge_results(*result_sets)
          merged = {
            total_results: 0,
            repositories: {},
            summary: {},
            metadata: { merged_at: Time.now.iso8601 }
          }
          
          result_sets.each do |results|
            next unless results.is_a?(Hash)
            
            # Merge repository results
            if results[:repositories]
              results[:repositories].each do |repo_name, repo_data|
                if merged[:repositories][repo_name]
                  # Merge with existing repository results
                  merged[:repositories][repo_name] = merge_repository_results(
                    merged[:repositories][repo_name],
                    repo_data
                  )
                else
                  merged[:repositories][repo_name] = repo_data
                end
              end
            end
            
            # Update total count
            merged[:total_results] += results[:total_results] || 0
          end
          
          # Regenerate summary
          merged[:summary] = generate_summary(merged)
          
          merged
        end

        # Sort results by relevance or other criteria
        # @param results [Hash] Results to sort
        # @param sort_by [Symbol] Sort criteria (:relevance, :path, :repository, :line)
        # @return [Hash] Sorted results
        def sort_results(results, sort_by = :relevance)
          sorted = results.dup
          
          sorted[:repositories].each do |repo_name, repo_data|
            if repo_data[:results].is_a?(Array)
              repo_data[:results] = sort_result_array(repo_data[:results], sort_by)
            elsif repo_data[:results].is_a?(Hash)
              # Handle hybrid results
              repo_data[:results][:files] = sort_result_array(repo_data[:results][:files], sort_by) if repo_data[:results][:files]
              repo_data[:results][:content] = sort_result_array(repo_data[:results][:content], sort_by) if repo_data[:results][:content]
            end
          end
          
          sorted
        end

        private

        # Reset internal counters
        def reset_counts
          @total_count = 0
          @repository_counts = {}
        end

        # Process results from a single repository
        def process_repository_results(repo_name, repo_data, options)
          results = repo_data[:results]
          
          processed = {
            name: repo_name,
            path: repo_data[:repository][:path],
            count: 0,
            results: results,
            metadata: repo_data[:metadata] || {}
          }
          
          # Count results
          processed[:count] = count_results(results)
          
          # Add repository label to each result
          if options[:label_results]
            processed[:results] = label_results(results, repo_name)
          end
          
          processed
        end

        # Count results in various formats
        def count_results(results)
          case results
          when Array
            results.size
          when Hash
            if results[:results].is_a?(Array)
              # Handle {success: bool, results: [...], count: n} format
              results[:results].size
            elsif results[:files] && results[:content]
              # Handle hybrid format
              (results[:files] || []).size + (results[:content] || []).size
            elsif results[:files]
              # Handle files-only format
              (results[:files] || []).size
            elsif results[:count].is_a?(Integer)
              # If count is explicitly provided, use it
              results[:count]
            elsif results[:error]
              0
            else
              # Fallback - count array values only
              results.values.select { |v| v.is_a?(Array) }.flatten.size
            end
          else
            0
          end
        end

        # Add repository label to results
        def label_results(results, repo_name)
          case results
          when Array
            results.map { |r| r.merge(repository: repo_name) }
          when Hash
            if results[:files] && results[:content]
              {
                files: results[:files].map { |r| r.merge(repository: repo_name) },
                content: results[:content].map { |r| r.merge(repository: repo_name) }
              }
            else
              results
            end
          else
            results
          end
        end

        # Generate summary information
        def generate_summary(aggregated)
          {
            total_results: aggregated[:total_results],
            repository_count: aggregated[:repositories].size,
            repositories_with_results: @repository_counts.select { |_, c| c > 0 }.keys,
            repositories_without_results: @repository_counts.select { |_, c| c == 0 }.keys,
            result_distribution: @repository_counts
          }
        end

        # Generate metadata
        def generate_metadata(options)
          {
            aggregated_at: Time.now.iso8601,
            options: options.slice(:type, :format, :max_results),
            version: "1.0"
          }
        end

        # Apply result limit across all repositories
        def apply_result_limit(aggregated, max_results)
          limited = aggregated.dup
          remaining = max_results
          
          limited[:repositories].each do |repo_name, repo_data|
            if remaining <= 0
              repo_data[:results] = []
              repo_data[:count] = 0
            elsif repo_data[:count] > remaining
              # Truncate results
              repo_data[:results] = truncate_results(repo_data[:results], remaining)
              repo_data[:count] = remaining
              remaining = 0
            else
              remaining -= repo_data[:count]
            end
          end
          
          # Update total count
          limited[:total_results] = [aggregated[:total_results], max_results].min
          
          limited
        end

        # Truncate results to limit
        def truncate_results(results, limit)
          case results
          when Array
            results.first(limit)
          when Hash
            if results[:files] && results[:content]
              # Split limit between files and content
              file_limit = limit / 2
              content_limit = limit - file_limit
              {
                files: results[:files].first(file_limit),
                content: results[:content].first(content_limit)
              }
            else
              results
            end
          else
            results
          end
        end

        # Merge two repository result sets
        def merge_repository_results(existing, new_data)
          merged = existing.dup
          
          if existing[:results].is_a?(Array) && new_data[:results].is_a?(Array)
            merged[:results] = (existing[:results] + new_data[:results]).uniq
          elsif existing[:results].is_a?(Hash) && new_data[:results].is_a?(Hash)
            merged[:results] = {}
            [:files, :content].each do |key|
              if existing[:results][key] && new_data[:results][key]
                merged[:results][key] = (existing[:results][key] + new_data[:results][key]).uniq
              elsif existing[:results][key]
                merged[:results][key] = existing[:results][key]
              elsif new_data[:results][key]
                merged[:results][key] = new_data[:results][key]
              end
            end
          end
          
          merged[:count] = count_results(merged[:results])
          merged
        end

        # Sort result array by criteria
        def sort_result_array(results, sort_by)
          return results unless results.is_a?(Array)
          
          case sort_by
          when :path
            results.sort_by { |r| r[:file] || r[:path] || "" }
          when :repository
            results.sort_by { |r| [r[:repository] || "", r[:file] || r[:path] || ""] }
          when :line
            results.sort_by { |r| [r[:file] || "", r[:line] || 0] }
          else
            results
          end
        end

        # Format output based on requested format
        def format_output(aggregated, format)
          case format
          when :json
            require "json"
            JSON.generate(aggregated)
          when :yaml
            require "yaml"
            YAML.dump(aggregated)
          when :text
            format_as_text(aggregated)
          else
            aggregated
          end
        end

        # Format results as text
        def format_as_text(aggregated)
          lines = []
          
          lines << "Search Results: #{aggregated[:total_results]} total"
          lines << ""
          
          aggregated[:repositories].each do |repo_name, repo_data|
            next if repo_data[:count] == 0
            
            lines << "Repository: #{repo_name} (#{repo_data[:count]} results)"
            lines << "-" * 40
            
            if repo_data[:results].is_a?(Array)
              repo_data[:results].each do |result|
                lines << format_result_line(result)
              end
            elsif repo_data[:results].is_a?(Hash)
              if repo_data[:results][:files]
                lines << "Files:"
                repo_data[:results][:files].each do |file|
                  lines << "  #{file}"
                end
              end
              if repo_data[:results][:content]
                lines << "Content:"
                repo_data[:results][:content].each do |result|
                  lines << format_result_line(result)
                end
              end
            end
            
            lines << ""
          end
          
          lines.join("\n")
        end

        # Format a single result line
        def format_result_line(result)
          if result[:line]
            "  #{result[:file]}:#{result[:line]}: #{result[:text]}"
          else
            "  #{result[:file] || result[:path] || result}"
          end
        end
      end
    end
  end
end