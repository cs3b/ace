# frozen_string_literal: true

module Ace
  module Git
    module Organisms
      # Orchestrates the complete diff workflow (NO caching per task decisions)
      # Migrated from ace-git-diff
      class DiffOrchestrator
        class << self
          # Generate diff with full workflow: config -> generate -> filter -> result
          # @param options [Hash] Options for diff generation
          # @option options [String] :since Date or commit to diff from
          # @option options [Array<String>] :ranges Git ranges to diff
          # @option options [Array<String>] :paths Path patterns to include
          # @option options [Array<String>] :exclude_patterns Patterns to exclude
          # @option options [Boolean] :exclude_whitespace Exclude whitespace changes
          # @option options [Boolean] :exclude_renames Exclude renames
          # @option options [Symbol] :format Output format (:diff or :summary)
          # @return [Models::DiffResult] Complete diff result
          def generate(options = {})
            # Load configuration
            config = Molecules::ConfigLoader.load(options)

            # Generate raw diff
            raw_diff = Molecules::DiffGenerator.generate(config)

            # Filter diff
            filtered_diff = Molecules::DiffFilter.filter(raw_diff, config)

            # Parse and create result
            parsed = Atoms::DiffParser.parse(filtered_diff)

            if config.format == :grouped_stats
              return build_grouped_stats_result(config, parsed, filtered: !config.exclude_patterns.empty?)
            end

            Models::DiffResult.from_parsed(
              parsed,
              metadata: {
                config: config.to_h,
                generated_at: Time.now.iso8601,
                filtered: !config.exclude_patterns.empty?
              },
              filtered: !config.exclude_patterns.empty?
            )
          end

          # Generate diff from configuration hash
          # @param config_hash [Hash] Configuration from YAML or other source
          # @return [Models::DiffResult] Complete diff result
          def from_config(config_hash)
            diff_config = Molecules::ConfigLoader.extract_diff_config(config_hash)
            generate(diff_config)
          end

          # Generate diff for a specific range
          # @param range [String] Git range (e.g., "HEAD~5..HEAD")
          # @param options [Hash] Additional options
          # @return [Models::DiffResult] Complete diff result
          def for_range(range, options = {})
            generate(options.merge(ranges: [range]))
          end

          # Generate diff since a date or commit
          # @param since [String] Date or commit reference
          # @param options [Hash] Additional options
          # @return [Models::DiffResult] Complete diff result
          def since(since, options = {})
            generate(options.merge(since: since))
          end

          # Generate staged diff
          # @param options [Hash] Additional options
          # @return [Models::DiffResult] Complete diff result
          def staged(options = {})
            generate(options.merge(format: :staged))
          end

          # Generate working directory diff
          # @param options [Hash] Additional options
          # @return [Models::DiffResult] Complete diff result
          def working(options = {})
            generate(options.merge(format: :working))
          end

          # Generate diff with smart defaults (based on git state)
          # @param options [Hash] Additional options
          # @return [Models::DiffResult] Complete diff result
          def smart(options = {})
            # Use empty config to trigger smart default behavior in DiffGenerator
            generate(options)
          end

          # Generate raw (unfiltered) diff
          # @param options [Hash] Options for diff generation
          # @return [Models::DiffResult] Unfiltered diff result
          def raw(options = {})
            # Temporarily override exclude patterns to be empty
            options_with_no_filtering = options.merge(exclude_patterns: [])
            generate(options_with_no_filtering)
          end

          # Generate diff and save to file
          # @param output_path [String] Path to save the diff
          # @param options [Hash] Options for diff generation
          # @return [String] Path to the saved file
          def save_to_file(output_path, options = {})
            result = generate(options)

            # Create parent directories if needed
            require "fileutils"
            FileUtils.mkdir_p(File.dirname(output_path)) unless File.dirname(output_path) == "."

            # Write content to file
            File.write(output_path, result.content)

            output_path
          end

          # Generate diff and save to file (with explicit format)
          # @param output_path [String] Path to save the diff
          # @param format [Symbol] Format (:diff or :summary)
          # @param options [Hash] Options for diff generation
          # @return [String] Path to the saved file
          def save_with_format(output_path, format: :diff, **options)
            options_with_format = options.merge(format: format)
            save_to_file(output_path, options_with_format)
          end

          private

          def build_grouped_stats_result(config, parsed_diff, filtered:)
            numstat_output = Molecules::DiffGenerator.generate_numstat(config)
            entries = Atoms::DiffNumstatParser.parse(numstat_output)
            filtered_entries = filter_entries(entries, config.exclude_patterns)
            grouped = Atoms::FileGrouper.group(
              filtered_entries,
              layers: config.grouped_stats_layers,
              dotfile_groups: config.grouped_stats_dotfile_groups
            )
            content = Atoms::GroupedStatsFormatter.format(grouped, collapse_above: config.grouped_stats_collapse_above)
            totals = grouped[:total]

            Models::DiffResult.new(
              content: content,
              stats: {
                additions: totals[:additions],
                deletions: totals[:deletions],
                files: totals[:files],
                total_changes: totals[:additions] + totals[:deletions],
                line_count: parsed_diff[:line_count]
              },
              files: grouped[:files],
              metadata: {
                config: config.to_h,
                generated_at: Time.now.iso8601,
                filtered: filtered,
                grouped_stats: grouped.merge(collapse_above: config.grouped_stats_collapse_above)
              },
              filtered: filtered
            )
          end

          def filter_entries(entries, exclude_patterns)
            return entries if exclude_patterns.nil? || exclude_patterns.empty?

            patterns = Atoms::PatternFilter.glob_to_regex(exclude_patterns)
            entries.reject { |entry| Atoms::PatternFilter.should_exclude?(entry[:path], patterns) }
          end
        end
      end
    end
  end
end
