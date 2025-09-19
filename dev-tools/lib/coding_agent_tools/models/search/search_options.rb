# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Search
      # SearchOptions encapsulates all search configuration options
      # This is a model - pure data structure with no behavior
      class SearchOptions
        attr_reader :pattern, :mode, :paths, :context_lines, :max_results,
          :file_types, :exclude_patterns, :git_scope, :time_filter,
          :case_sensitive, :multiline, :json_output, :interactive_mode,
          :editor_open, :repositories, :preset_name

        # @param pattern [String] Search pattern
        # @param mode [Symbol] Search mode (:files, :content, :both)
        # @param paths [Array<String>] Paths to search in
        # @param context_lines [Integer] Number of context lines to show
        # @param max_results [Integer, nil] Maximum number of results
        # @param file_types [Array<String>] File types to include
        # @param exclude_patterns [Array<String>] Patterns to exclude
        # @param git_scope [Symbol, nil] Git-aware scope (:tracked, :staged, :changed, nil)
        # @param time_filter [Hash, nil] Time-based filtering options
        # @param case_sensitive [Boolean] Case-sensitive search
        # @param multiline [Boolean] Enable multiline search
        # @param json_output [Boolean] Output in JSON format
        # @param interactive_mode [Boolean] Use interactive (fzf) mode
        # @param editor_open [Boolean] Open results in editor
        # @param repositories [Array<String>, nil] Specific repositories to search
        # @param preset_name [String, nil] Name of preset to use
        def initialize(pattern:, mode: :content, paths: ["."], context_lines: 2,
          max_results: nil, file_types: [], exclude_patterns: [],
          git_scope: nil, time_filter: nil, case_sensitive: false,
          multiline: false, json_output: false, interactive_mode: false,
          editor_open: false, repositories: nil, preset_name: nil)
          @pattern = pattern
          @mode = mode
          @paths = paths
          @context_lines = context_lines
          @max_results = max_results
          @file_types = file_types
          @exclude_patterns = exclude_patterns
          @git_scope = git_scope
          @time_filter = time_filter
          @case_sensitive = case_sensitive
          @multiline = multiline
          @json_output = json_output
          @interactive_mode = interactive_mode
          @editor_open = editor_open
          @repositories = repositories
          @preset_name = preset_name
        end

        # Check if search should include files
        # @return [Boolean] True if files should be searched
        def search_files?
          @mode == :files || @mode == :both
        end

        # Check if search should include content
        # @return [Boolean] True if content should be searched
        def search_content?
          @mode == :content || @mode == :both
        end

        # Check if git-aware scoping is enabled
        # @return [Boolean] True if git scoping is requested
        def git_aware?
          !@git_scope.nil?
        end

        # Check if time filtering is enabled
        # @return [Boolean] True if time filtering is requested
        def time_filtered?
          !@time_filter.nil?
        end

        # Get time filter start time
        # @return [Time, nil] Start time for filtering
        def time_filter_since
          @time_filter&.dig(:since)
        end

        # Get time filter end time
        # @return [Time, nil] End time for filtering
        def time_filter_until
          @time_filter&.dig(:until)
        end

        # Get ripgrep-specific options
        # @return [Hash] Options for ripgrep
        def ripgrep_options
          options = {
            context: @context_lines,
            json_output: @json_output,
            line_numbers: true,
            with_filename: true
          }

          options[:type] = @file_types unless @file_types.empty?
          options[:glob] = @exclude_patterns.map { |p| "!#{p}" } unless @exclude_patterns.empty?
          options[:ignore_case] = !@case_sensitive
          options[:max_count] = @max_results if @max_results
          options[:multiline] = @multiline
          options[:multiline_dotall] = @multiline

          options
        end

        # Get fd-specific options
        # @return [Hash] Options for fd
        def fd_options
          options = {
            type: "file",
            absolute_path: false,
            follow_symlinks: false,
            include_hidden: false
          }

          options[:extension] = @file_types unless @file_types.empty?
          options[:exclude] = @exclude_patterns unless @exclude_patterns.empty?
          options[:ignore_case] = !@case_sensitive
          options[:max_results] = @max_results if @max_results

          options
        end

        # Convert to hash representation
        # @return [Hash] Hash representation of options
        def to_h
          {
            pattern: @pattern,
            mode: @mode,
            paths: @paths,
            context_lines: @context_lines,
            max_results: @max_results,
            file_types: @file_types,
            exclude_patterns: @exclude_patterns,
            git_scope: @git_scope,
            time_filter: @time_filter,
            case_sensitive: @case_sensitive,
            multiline: @multiline,
            json_output: @json_output,
            interactive_mode: @interactive_mode,
            editor_open: @editor_open,
            repositories: @repositories,
            preset_name: @preset_name
          }
        end

        # Merge with another options object or hash
        # @param other [SearchOptions, Hash] Other options to merge
        # @return [SearchOptions] New options object with merged values
        def merge(other)
          other_hash = other.is_a?(Hash) ? other : other.to_h
          merged_hash = to_h.merge(other_hash)

          self.class.new(**merged_hash)
        end

        # Create options from CLI arguments
        # @param args [Hash] CLI argument hash
        # @return [SearchOptions] New options object
        def self.from_cli_args(args)
          # Determine search mode
          mode = if args[:files_only] || args[:name_only]
            :files
          elsif args[:content_only]
            :content
          else
            :both
          end

          # Parse git scope
          git_scope = if args[:tracked]
            :tracked
          elsif args[:staged]
            :staged
          elsif args[:changed]
            :changed
          end

          # Parse time filter
          time_filter = if args[:since]
            {since: parse_time_string(args[:since])}
          elsif args[:until]
            {until: parse_time_string(args[:until])}
          end

          new(
            pattern: args[:pattern] || "",
            mode: mode,
            paths: args[:paths] || ["."],
            context_lines: args[:context] || 2,
            max_results: args[:max_results],
            file_types: args[:type] ? Array(args[:type]) : [],
            exclude_patterns: args[:exclude] ? Array(args[:exclude]) : [],
            git_scope: git_scope,
            time_filter: time_filter,
            case_sensitive: args[:case_sensitive] || false,
            multiline: args[:multiline] || false,
            json_output: args[:json] || false,
            interactive_mode: args[:fzf] || false,
            editor_open: args[:open] || false,
            repositories: args[:repositories] ? Array(args[:repositories]) : nil,
            preset_name: args[:preset]
          )
        end

        # Validate options
        # @return [Array<String>] Array of validation errors (empty if valid)
        def validate
          errors = []

          errors << "Pattern cannot be empty" if @pattern.nil? || @pattern.strip.empty?
          errors << "Mode must be :files, :content, or :both" unless [:files, :content, :both].include?(@mode)
          errors << "Context lines must be non-negative" if @context_lines&.negative?
          errors << "Max results must be positive" if @max_results&.negative?
          errors << "Paths cannot be empty" if @paths.empty?

          if @git_scope && ![:tracked, :staged, :changed].include?(@git_scope)
            errors << "Git scope must be :tracked, :staged, or :changed"
          end

          errors
        end

        # Check if options are valid
        # @return [Boolean] True if options are valid
        def valid?
          validate.empty?
        end

        private

        # Parse time string into Time object
        # @param time_str [String] Time string (e.g., "1 week ago", "2023-01-01")
        # @return [Time, nil] Parsed time or nil if invalid
        def self.parse_time_string(time_str)
          require "time"

          # Try parsing as absolute time first
          begin
            return Time.parse(time_str)
          rescue ArgumentError
            # Fall through to relative time parsing
          end

          # Parse relative time strings
          case time_str
          when /(\d+)\s*days?\s*ago/i
            Time.now - ($1.to_i * 24 * 60 * 60)
          when /(\d+)\s*weeks?\s*ago/i
            Time.now - ($1.to_i * 7 * 24 * 60 * 60)
          when /(\d+)\s*months?\s*ago/i
            Time.now - ($1.to_i * 30 * 24 * 60 * 60)
          when /(\d+)\s*hours?\s*ago/i
            Time.now - ($1.to_i * 60 * 60)
          when /(\d+)\s*minutes?\s*ago/i
            Time.now - ($1.to_i * 60)
          end
        end
      end
    end
  end
end
