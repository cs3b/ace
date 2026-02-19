# frozen_string_literal: true

require "optparse"
require_relative "../atoms/filter_parser"

module Ace
  module Taskflow
    module Molecules
      # Unified command option parser using composable option sets
      #
      # This molecule orchestrates option parsing with controlled side effects (banner output).
      # It uses Ruby's stdlib OptionParser and supports composable option sets that commands
      # can mix-and-match based on their needs.
      #
      # Design Principles:
      # 1. Composable - commands select which option sets they need
      # 2. Type-safe - automatic coercion to Integer, Boolean, String, Array
      # 3. Thor-compatible - merges pre-parsed Thor options
      # 4. Extensible - new option sets can be added without modifying core
      #
      # @example Basic usage
      #   parser = CommandOptionParser.new(
      #     option_sets: [:display, :release, :filter],
      #     banner: "Usage: ace-taskflow tasks [preset] [options]"
      #   )
      #   result = parser.parse(args, thor_options: options)
      #   # result => { parsed: {}, remaining: [], help_requested: false }
      #
      # @example Custom options
      #   parser = CommandOptionParser.new(
      #     option_sets: [:display, :help],
      #     banner: "Usage: ace-taskflow doctor [OPTIONS]"
      #   ) do |opts, parsed|
      #     opts.on("--component TYPE", "Check specific component") do |v|
      #       parsed[:component] = v
      #     end
      #   end
      #
      class CommandOptionParser
        # Standard option sets available for composition
        OPTION_SETS = {
          # Display/formatting options
          display: %i[stats tree path list flat verbose short format output],

          # Release selection options
          release: %i[release backlog current all],

          # Filtering options (new unified --filter syntax)
          filter: %i[filter filter_clear],

          # Numeric limit options
          limits: %i[limit days],

          # Subtask display options
          subtasks: %i[subtasks_display],

          # Sort options
          sort: %i[sort],

          # Common action options
          actions: %i[dry_run],

          # Help flag (usually included by default)
          help: %i[help]
        }.freeze

        # Default values for options by type
        OPTION_DEFAULTS = {
          stats: false,
          tree: false,
          path: false,
          list: false,
          flat: false,
          verbose: false,
          short: false,
          dry_run: false,
          filter_clear: false,
          all: false
        }.freeze

        attr_reader :option_sets, :banner, :custom_options

        # Initialize parser with option sets
        # @param option_sets [Array<Symbol>] Which option sets to include
        # @param banner [String] Help banner text
        # @param custom_options [Proc] Block to add custom options
        def initialize(option_sets: [:display, :release, :filter, :limits, :help], banner: nil, &custom_options)
          @option_sets = option_sets
          @banner = banner
          @custom_options = custom_options
        end

        # Parse arguments with Thor options merging
        # @param args [Array<String>] Command line arguments
        # @param thor_options [Hash] Pre-parsed Thor options to merge
        # @return [Hash] Result with :parsed, :remaining, :help_requested
        def parse(args, thor_options: {})
          # Work with a copy to avoid mutating the original
          args = args.dup

          # Start with defaults
          parsed = build_defaults
          positional_args = []
          help_requested = false

          parser = build_parser(parsed) do
            help_requested = true
          end

          # Parse known options, collecting positional args
          # We use a loop to handle unknown options gracefully
          begin
            while args.any?
              begin
                parser.order!(args) do |non_option|
                  positional_args << non_option
                end
                break # Successfully parsed remaining args
              rescue OptionParser::InvalidOption => e
                # Unknown option - add to remaining and continue parsing
                positional_args.concat(e.args)
              end
            end
          rescue OptionParser::MissingArgument => e
            raise ArgumentError, "Missing argument for #{e.args.first}"
          end

          # Merge Thor options (they take precedence)
          merge_thor_options!(parsed, thor_options)

          # Post-process special options
          post_process!(parsed)

          {
            parsed: parsed,
            remaining: positional_args,
            help_requested: help_requested
          }
        end

        # Get help text without parsing
        # @return [String] Help text
        def help_text
          parsed = build_defaults
          build_parser(parsed) {}.to_s
        end

        private

        def build_defaults
          defaults = {}

          # Apply defaults for all included option sets
          option_sets.each do |set_name|
            options = OPTION_SETS[set_name] || []
            options.each do |opt|
              defaults[opt] = OPTION_DEFAULTS[opt] if OPTION_DEFAULTS.key?(opt)
            end
          end

          # Special defaults for multi-value options
          defaults[:filter] = [] if includes_option_set?(:filter)

          defaults
        end

        def build_parser(parsed, &on_help)
          OptionParser.new do |opts|
            opts.banner = banner if banner

            # Add options from each included set
            option_sets.each do |set_name|
              method_name = "add_#{set_name}_options"
              if respond_to?(method_name, true)
                if set_name == :help
                  send(method_name, opts, parsed, &on_help)
                else
                  send(method_name, opts, parsed)
                end
              end
            end

            # Add custom options if provided
            custom_options&.call(opts, parsed)
          end
        end

        # Display options
        def add_display_options(opts, parsed)
          opts.on("--stats", "Show statistics") { parsed[:stats] = true }
          opts.on("--tree", "Show tree structure") { parsed[:tree] = true }
          opts.on("--path", "Show paths only") { parsed[:path] = true }
          opts.on("--list", "Show simple list format") { parsed[:list] = true }
          opts.on("--flat", "Show all items without hierarchy") { parsed[:flat] = true }
          opts.on("--verbose", "-v", "Show detailed information") { parsed[:verbose] = true }
          opts.on("--short", "Hide file paths") { parsed[:short] = true }
          opts.on("--format FORMAT", "Output format (json, markdown)") { |v| parsed[:format] = v }
          opts.on("--output FILE", "-o FILE", "Output file path") { |v| parsed[:output] = v }
        end

        # Release selection options
        def add_release_options(opts, parsed)
          opts.on("--release VERSION", "Work with specific release") { |v| parsed[:release] = v }
          opts.on("--backlog", "Work with backlog") { parsed[:release] = "backlog" }
          opts.on("--current", "Work with current release") { parsed[:release] = "current" }
          opts.on("--all", "Include all releases") { parsed[:all] = true }
        end

        # Filter options (unified --filter syntax)
        def add_filter_options(opts, parsed)
          opts.on("--filter KEY:VALUE", "Filter by field (can repeat)") do |v|
            parsed[:filter] << v
          end
          opts.on("--filter-clear", "Clear preset filters") { parsed[:filter_clear] = true }
        end

        # Numeric limit options
        def add_limits_options(opts, parsed)
          opts.on("--limit N", Integer, "Limit number of results") { |v| parsed[:limit] = v }
          opts.on("--days N", Integer, "Days to look back") { |v| parsed[:days] = v }
        end

        # Subtask display options
        def add_subtasks_options(opts, parsed)
          opts.on("--subtasks", "Show subtasks in hierarchical display") do
            parsed[:subtasks_display] = :show
          end
          opts.on("--no-subtasks", "Hide subtasks, show count instead") do
            parsed[:subtasks_display] = :hide
          end
        end

        # Sort options
        def add_sort_options(opts, parsed)
          opts.on("--sort FIELD[:DIR]", "Sort by field (optional :asc/:desc)") do |v|
            parsed[:sort] = parse_sort_spec(v)
          end
        end

        # Action options
        def add_actions_options(opts, parsed)
          opts.on("--dry-run", "-n", "Preview without executing") { parsed[:dry_run] = true }
        end

        # Help option
        def add_help_options(opts, parsed, &on_help)
          opts.on("--help", "-h", "Show this help message") do
            puts opts
            on_help&.call
          end
        end

        # Parse sort specification
        def parse_sort_spec(spec)
          return nil unless spec

          if spec.include?(":")
            field, direction = spec.split(":", 2)
            { by: field.to_sym, ascending: direction == "asc" }
          else
            { by: spec.to_sym, ascending: true }
          end
        end

        # Merge Thor options into parsed results
        def merge_thor_options!(parsed, thor_options)
          return if thor_options.nil? || thor_options.empty?

          # Map Thor options to our option names
          thor_mappings = {
            status: :status,
            stats: :stats,
            tree: :tree,
            all: :all,
            limit: :limit,
            format: :format,
            json: :json,
            markdown: :markdown,
            verbose: :verbose,
            quiet: :quiet,
            debug: :debug,
            output: :output,
            recently_done_limit: :recently_done_limit,
            up_next_limit: :up_next_limit,
            include_drafts: :include_drafts,
            include_activity: :include_activity,
            auto_fix: :fix,
            auto_fix_with_agent: :fix_with_agent,
            model: :model,
            verbose_info: :verbose_info
          }

          thor_mappings.each do |thor_key, our_key|
            value = thor_options[thor_key]
            next if value.nil?

            # Thor booleans should override if true
            if [true, false].include?(value)
              parsed[our_key] = value if value
            else
              parsed[our_key] = value
            end
          end
        end

        # Post-process parsed options
        def post_process!(parsed)
          # Parse filter strings into filter specifications
          if parsed[:filter]&.any?
            parsed[:filter_specs] = Atoms::FilterParser.parse(parsed[:filter])
          end

          # Convert json format flag
          parsed[:format] = "json" if parsed[:json]
          parsed[:format] = "markdown" if parsed[:markdown] && !parsed[:json]
        end

        def includes_option_set?(set_name)
          option_sets.include?(set_name)
        end
      end
    end
  end
end
