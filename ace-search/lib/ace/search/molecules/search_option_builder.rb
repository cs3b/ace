# frozen_string_literal: true

module Ace
  module Search
    module Molecules
      # Builds search options from CLI options and configuration
      #
      # This molecule handles the merging of CLI-provided options with
      # configuration defaults, including type conversion and option aliasing.
      #
      # @example Building search options
      #   builder = SearchOptionBuilder.new(cli_options)
      #   options = builder.build
      #   # => { type: :content, format: :text, ... }
      class SearchOptionBuilder
        # @param cli_options [Hash] Options from CLI (dry-cli)
        # @param config [Hash] Configuration from Ace::Search.config (optional)
        def initialize(cli_options, config: nil)
          @cli_options = cli_options
          @config = config || Ace::Search.config
        end

        # Build the complete search options hash
        #
        # @return [Hash] Merged and normalized search options
        def build
          options = build_base_options
          apply_type_aliases(options)
          options
        end

        private

        # Build the base options hash from CLI and config
        def build_base_options
          {
            type: determine_type,
            format: determine_format,
            max_results: @cli_options[:max_results] || @config["max_results"],
            case_insensitive: @cli_options[:case_insensitive] || @config["case_insensitive"] || false,
            whole_word: @cli_options[:whole_word] || @config["whole_word"] || false,
            multiline: @cli_options[:multiline] || @config["multiline"] || false,
            context: @cli_options[:context] || @config["context"] || 0,
            interactive: @cli_options[:fzf] || false,
            preset: @cli_options[:preset],
            since: @cli_options[:since],
            before: @cli_options[:before],
            scope: determine_scope,
            glob: @cli_options[:glob] || @config["glob"],
            include: parse_include_option,
            exclude: parse_exclude_option,
            hidden: @cli_options[:hidden] || @config["hidden"] || false,
            count: @cli_options[:count] || @config["count"] || false,
            files_with_matches: @cli_options[:files_with_matches] || @config["files_with_matches"] || false,
            after_context: @cli_options[:after_context],
            before_context: @cli_options[:before_context]
          }
        end

        def determine_type
          @cli_options[:type]&.to_sym || @config["type"]&.to_sym || :auto
        end

        def determine_format
          if @cli_options[:json]
            :json
          elsif @cli_options[:yaml]
            :yaml
          else
            :text
          end
        end

        def determine_scope
          return :staged if @cli_options[:staged]
          return :tracked if @cli_options[:tracked]
          return :changed if @cli_options[:changed]
          nil
        end

        def parse_include_option
          config_include = @config["include"]
          include_value = @cli_options[:include]

          include_paths = Array(config_include || []).compact
          if include_value
            include_paths.concat(include_value.split(",").map(&:strip).compact)
          end
          include_paths
        end

        def parse_exclude_option
          default_excludes = @config["exclude"] || []
          exclude_value = @cli_options[:exclude]

          return [] if exclude_value&.downcase == "none"

          exclude_paths = Array(default_excludes || []).compact
          if exclude_value
            exclude_paths.concat(exclude_value.split(",").map(&:strip).compact)
          end
          exclude_paths
        end

        # Apply --files and --content type aliases
        def apply_type_aliases(options)
          options[:type] = :file if @cli_options[:files]
          options[:type] = :content if @cli_options[:content]
        end
      end
    end
  end
end
