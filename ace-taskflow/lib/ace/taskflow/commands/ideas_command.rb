# frozen_string_literal: true

require_relative "../molecules/idea_loader"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/stats_formatter"
require_relative "../molecules/command_option_parser"
require_relative "../models/idea"
require_relative "../atoms/path_formatter"
require_relative "../molecules/task_filter"
require_relative "helpers"

module Ace
  module Taskflow
    module Commands
      class IdeasCommand
        include Helpers
        def initialize
          @root_path = Molecules::ConfigLoader.find_root
          @config = Taskflow.configuration
          @idea_loader = Molecules::IdeaLoader.new(@root_path)
          @preset_manager = Molecules::ListPresetManager.new
          @stats_formatter = Molecules::StatsFormatter.new(@root_path)
          @option_parser = build_option_parser
        end

        def execute(args)
          # Parse options using CommandOptionParser
          result = @option_parser.parse(args)
          return 0 if result[:help_requested]

          options = result[:parsed]
          remaining = result[:remaining]

          # Check if first remaining argument is a preset name
          preset_name = detect_preset_name(remaining)
          if preset_name
            remaining.shift # Remove preset name from args
          else
            # Default to 'next' preset (shows pending + in-progress items, excluding maybe/anyday)
            preset_name = 'next'
          end

          # Handle --all flag as preset override
          if options[:all]
            preset_name = 'all'
          end

          execute_with_preset(preset_name, options)
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        # Build the option parser for ideas command
        def build_option_parser
          Molecules::CommandOptionParser.new(
            option_sets: [:display, :release, :filter, :limits, :help],
            banner: "Usage: ace-taskflow ideas [preset] [options]"
          )
        end

        def detect_preset_name(args)
          return nil if args.empty? || args.first.start_with?('-')

          potential_preset = args.first
          # Check if it's a known preset or custom preset
          if @preset_manager.preset_exists?(potential_preset, :ideas)
            potential_preset
          else
            nil
          end
        end

        def execute_with_preset(preset_name, options)
          # Check for special flags
          if options[:stats]
            return show_statistics_for_preset(preset_name, options)
          end

          # Handle filter-clear: if set, don't pass old-style filters to preset
          if options[:filter_clear]
            # Apply preset but ignore its filters
            preset_config = @preset_manager.apply_preset(preset_name, {}, :ideas)
            return 1 unless preset_config
            # Clear the preset filters but keep release, sort, glob, display
            preset_config[:filters] = {}
          else
            # Apply preset with additional filters (normal flow)
            preset_config = @preset_manager.apply_preset(preset_name, options, :ideas)
            return 1 unless preset_config
          end

          # Add preset name to config for scope determination
          preset_config[:name] = preset_name

          # Store filter_specs in preset_config so filtering can access them
          if options[:filter_specs]
            preset_config[:filter_specs] = options[:filter_specs]
          end

          # Override release if provided via flags
          if options[:release]
            preset_config[:release] = options[:release]
          end

          # Get ideas based on preset configuration
          ideas = get_ideas_for_preset(preset_config)

          # Apply limit if specified
          original_count = ideas.size
          if options[:limit] && options[:limit] > 0
            ideas = ideas.take(options[:limit])
          end

          # Display ideas
          if ideas.empty?
            puts "No ideas found for preset '#{preset_name}'."
            return 0
          else
            # Check format option
            if options[:format] == "json"
              display_ideas_as_json(ideas, preset_config)
            else
              display_ideas_with_preset(ideas, preset_config, original_count, options[:limit], options[:short])
            end
          end
        end

        def get_ideas_for_preset(preset_config)
          release = preset_config[:release] || 'current'
          filters_raw = preset_config[:filters] || {}
          glob = preset_config[:glob]

          # If no glob provided, use 'all' preset to get default
          unless glob
            all_preset = @preset_manager.apply_preset('all', {}, :ideas)
            glob = all_preset[:glob] if all_preset
          end

          # Filter glob patterns to only include idea-related patterns (already prefixed by preset manager)
          glob = filter_glob_by_type(glob, @config.ideas_dir)

          # Load ideas
          ideas = case release
          when 'all'
            get_all_ideas_with_glob(glob)
          else
            @idea_loader.load_all(release: release, include_content: false, glob: glob)
          end

          # Apply filters from preset
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          # Add filter_specs to filters hash so TaskFilter can access them
          if preset_config[:filter_specs]
            filters[:filter_specs] = preset_config[:filter_specs]
          end

          # Apply TaskFilter (works with both tasks and ideas - they're both hashes with frontmatter)
          Molecules::TaskFilter.apply_filters(ideas, filters)
        end

        def get_all_ideas_with_glob(glob)
          all_ideas = []
          release_resolver = Molecules::ReleaseResolver.new(@root_path)

          # Active releases
          active_releases = release_resolver.find_active
          active_releases.each do |rel|
            ideas = @idea_loader.load_all(release: rel[:name], include_content: false, glob: glob)
            ideas.each { |idea| idea[:release] = rel[:name] }
            all_ideas.concat(ideas)
          end

          # Backlog
          backlog_ideas = @idea_loader.load_all(release: "backlog", include_content: false, glob: glob)
          backlog_ideas.each { |idea| idea[:release] = "backlog" }
          all_ideas.concat(backlog_ideas)

          all_ideas
        end

        def display_ideas_with_preset(ideas, preset_config, original_count = nil, limit = nil, short = false)
          # Check for misplaced ideas and show warning
          check_and_warn_misplaced_ideas

          # Display three-line header
          release = preset_config[:release] || 'current'

          # Get total count of ALL ideas for proper display - use 'all' preset for consistent glob
          all_preset = @preset_manager.apply_preset('all', {}, :ideas)
          total_glob = all_preset ? all_preset[:glob] : nil

          total_ideas = if total_glob
                         all_ideas = @idea_loader.load_all(release: release, include_content: false, glob: total_glob)
                         all_ideas.size
                       else
                         ideas.size  # Fallback to displayed count
                       end

          header = @stats_formatter.format_header(
            command_type: :ideas,
            displayed_count: ideas.size,
            release: release,
            total_count: total_ideas
          )
          puts header

          # Check if grouping is needed
          display_config = preset_config[:display] || {}
          if display_config[:group_by] == 'release' || display_config[:group_by] == :release
            # Group by release
            grouped = ideas.group_by { |idea| idea[:release] || 'current' }
            grouped.each do |rel_name, rel_ideas|
              puts ""
              puts "#{rel_name} (#{rel_ideas.length} ideas):"
              rel_ideas.each { |idea| display_idea_line(idea, display_config[:verbose] || false, short) }
            end
          else
            ideas.each { |idea| display_idea_line(idea, display_config[:verbose] || false, short) }
          end

          0
        end

        def show_statistics_for_preset(preset_name, additional_filters = {})
          preset_config = @preset_manager.apply_preset(preset_name, additional_filters, :ideas)
          return 1 unless preset_config

          # Override release if provided via flags
          if additional_filters[:release]
            release = additional_filters[:release]
          else
            release = preset_config[:release] || 'current'
          end

          puts @stats_formatter.format_stats_view(release: release)
          0
        end

        def display_ideas_as_json(ideas, preset_config)
          require 'json'

          release = preset_config[:release] || 'current'

          # Get summary statistics using presets
          all_preset = @preset_manager.apply_preset('all', {}, :ideas)
          done_preset = @preset_manager.apply_preset('done', {}, :ideas)

          all_ideas = all_preset ? @idea_loader.load_all(release: release, include_content: false, glob: all_preset[:glob]) : []
          done_ideas = done_preset ? @idea_loader.load_all(release: release, include_content: false, glob: done_preset[:glob]) : []
          active_ideas = all_ideas - done_ideas

          # Get release info
          release_resolver = Molecules::ReleaseResolver.new(@root_path)
          current_release = release_resolver.find_primary_active

          output = {
            release: current_release ? current_release[:name] : release,
            summary: {
              ideas: {
                total: all_ideas.size,
                active: active_ideas.size,
                completed: done_ideas.size
              }
            },
            ideas: ideas.map do |idea|
              idea_json = {
                id: idea[:id],
                title: idea[:title],
                type: idea[:is_directory] ? "rich" : "simple"
              }

              # Add path - point to idea.s.md for rich ideas
              if idea[:path]
                display_path = if idea[:is_directory]
                  File.join(idea[:path], "idea.s.md")
                else
                  idea[:path]
                end
                idea_json[:path] = format_relative_path(display_path)
              end

              # Add attachment info for rich ideas
              if idea[:attachments] && idea[:attachments].any?
                idea_json[:attachments] = idea[:attachments].size
                # Extract file extensions
                extensions = idea[:attachments].map { |f| File.extname(f) }.uniq.sort
                idea_json[:attachment_types] = extensions unless extensions.empty?
              end

              idea_json
            end
          }

          puts JSON.pretty_generate(output)
          0
        end





        def display_idea_line(idea, verbose, short = false)
          # Build title with attachment indicator
          title = idea[:title]
          if idea[:attachments] && idea[:attachments].any?
            attachment_count = idea[:attachments].size
            title = "#{title} 📎 #{attachment_count}"
          end

          # Show ID only when paths are hidden (--short mode)
          if short
            puts "• [#{idea[:id]}] #{title}"
          else
            puts "• #{title}"
          end

          # Show path unless --short flag is used
          unless short
            if idea[:path]
              # For rich ideas (directories), point to idea.s.md file
              display_path = if idea[:is_directory]
                File.join(idea[:path], "idea.s.md")
              else
                idea[:path]
              end

              relative_path = format_relative_path(display_path)
              puts "  #{relative_path}"
            end
          end

          # Show timestamp only in verbose mode
          if verbose && idea[:created_at]
            timestamp = idea[:created_at].strftime("%Y-%m-%d %H:%M")
            puts "  Created: #{timestamp}"
          end
        end

        def format_relative_path(path)
          # Use project root, not .ace-taskflow root
          root_path = Dir.pwd
          Atoms::PathFormatter.format_relative_path(path, root_path)
        end

        def check_and_warn_misplaced_ideas
          # Skip validation if disabled via environment variable (performance optimization)
          return if ENV["SKIP_IDEA_VALIDATION"]

          # Only check once per command execution
          return if @misplaced_check_done
          @misplaced_check_done = true

          # Detect misplaced ideas
          result = @idea_loader.detect_misplaced_ideas

          # Show warning if any misplaced ideas found
          if result[:misplaced].any?
            puts "⚠️  Warning: Found #{result[:misplaced].size} idea file(s) in incorrect locations."
            puts "   Run 'ace-taskflow idea validate-structure' for details."
            puts ""
          end
        end

        def show_help
          puts "Usage: ace-taskflow ideas [preset] [options]"
          puts ""
          puts "List and browse ideas across releases and backlog"
          puts ""
          puts "Presets (recommended):"
          available_presets = @preset_manager.list_presets(:ideas)
          available_presets.each do |preset|
            name = preset[:name]
            desc = preset[:description]
            default_marker = preset[:default] ? " (default for ideas)" : ""
            puts "  #{name.ljust(12)} #{desc}#{default_marker}"
          end
          puts ""
          puts "Preset Examples:"
          puts "  ace-taskflow ideas                           # Uses 'next' preset (pending ideas only)"
          puts "  ace-taskflow ideas all                       # All ideas including done"
          puts "  ace-taskflow ideas done                      # Only completed ideas"
          puts ""
          puts "Filtering Options:"
          puts "  --filter <key>:<value>                       Filter by any frontmatter field"
          puts "  --filter-clear                               Clear preset filters (keep release/scope/sort)"
          puts ""
          puts "Filter Examples:"
          puts "  ace-taskflow ideas --filter status:pending"
          puts "  ace-taskflow ideas --filter status:pending|done"
          puts "  ace-taskflow ideas all --filter status:!done"
          puts "  ace-taskflow ideas --filter-clear --filter priority:high"
          puts ""
          puts "Display Options:"
          puts "  --days <n>         Modify days for time-based presets"
          puts "  --limit <n>        Limit number of results displayed"
          puts "  --verbose, -v      Show detailed information"
          puts "  --short            Hide file paths (human-friendly)"
          puts "  --format <type>    Output format (json)"
          puts "  --stats            Show statistics for preset"
          puts ""
          puts "Display Formats:"
          puts "  Default            Shows paths (optimized for LLMs)"
          puts "  --short            Hides paths (optimized for humans)"
          puts "  --format json      JSON output (programmatic use)"
          puts ""
          puts "Custom Presets:"
          puts "  Create YAML files in .ace/taskflow/presets/ to define custom presets"
          puts "  Example: .ace/taskflow/presets/creative.yml"
        end
      end
    end
  end
end