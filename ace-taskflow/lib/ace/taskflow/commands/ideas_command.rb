# frozen_string_literal: true

require_relative "../molecules/idea_loader"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/stats_formatter"
require_relative "../models/idea"
require_relative "../atoms/path_formatter"
require_relative "../atoms/filter_parser"
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
        end

        def execute(args)
          if args.include?("--help") || args.include?("-h")
            show_help
            exit 0
          end

          # Check if first argument is a preset name
          preset_name = detect_preset_name(args)
          if preset_name
            args.shift # Remove preset name from args
          else
            # Default to 'next' preset (shows pending + in-progress items, excluding maybe/anyday)
            preset_name = 'next'
          end

          execute_with_preset(preset_name, args)
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

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

        def execute_with_preset(preset_name, remaining_args)
          # Parse additional filters from remaining args
          additional_filters = parse_additional_filters(remaining_args)

          # Handle preset override from legacy --all flag
          if additional_filters[:_preset_override]
            preset_name = additional_filters.delete(:_preset_override)
          end

          # Check for special flags
          if additional_filters[:stats]
            return show_statistics_for_preset(preset_name, additional_filters)
          end

          # Handle filter-clear: if set, don't pass old-style filters to preset
          if additional_filters[:filter_clear]
            # Apply preset but ignore its filters
            preset_config = @preset_manager.apply_preset(preset_name, {}, :ideas)
            return 1 unless preset_config
            # Clear the preset filters but keep release, sort, glob, display
            preset_config[:filters] = {}
          else
            # Apply preset with additional filters (normal flow)
            preset_config = @preset_manager.apply_preset(preset_name, additional_filters, :ideas)
            return 1 unless preset_config
          end

          # Add preset name to config for scope determination
          preset_config[:name] = preset_name

          # Store filter_specs in preset_config so filtering can access them
          if additional_filters[:filter_specs]
            preset_config[:filter_specs] = additional_filters[:filter_specs]
          end

          # Override release if provided via flags
          if additional_filters[:release]
            preset_config[:release] = additional_filters[:release]
          end

          # Get ideas based on preset configuration
          ideas = get_ideas_for_preset(preset_config)

          # Apply limit if specified
          original_count = ideas.size
          if additional_filters[:limit] && additional_filters[:limit] > 0
            ideas = ideas.take(additional_filters[:limit])
          end

          # Display ideas
          if ideas.empty?
            puts "No ideas found for preset '#{preset_name}'."
            return 0
          else
            # Check format option
            if additional_filters[:format] == "json"
              display_ideas_as_json(ideas, preset_config)
            else
              display_ideas_with_preset(ideas, preset_config, original_count, additional_filters[:limit], additional_filters[:short])
            end
          end
        end


        def parse_additional_filters(args)
          filters = {}
          filter_strings = []

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            # NEW: Unified filter syntax
            when "--filter"
              if i + 1 < args.length
                filter_strings << args[i + 1]
                i += 2
              else
                raise ArgumentError, "Missing value for --filter flag. Use: --filter key:value"
              end
            when "--filter-clear"
              filters[:filter_clear] = true
              i += 1
            # REMOVED: Legacy filter flags with helpful error messages
            when "--status"
              suggested_value = args[i + 1] if i + 1 < args.length
              suggested_filter = if suggested_value
                converted = suggested_value.gsub(/,\s*/, '|')
                "--filter status:#{converted}"
              else
                "--filter status:value"
              end
              raise ArgumentError, "Error: --status flag is no longer supported. Use: #{suggested_filter}"
            when "--priority"
              suggested_value = args[i + 1] if i + 1 < args.length
              suggested_filter = if suggested_value
                converted = suggested_value.gsub(/,\s*/, '|')
                "--filter priority:#{converted}"
              else
                "--filter priority:value"
              end
              raise ArgumentError, "Error: --priority flag is no longer supported. Use: #{suggested_filter}"
            # KEPT: Display and formatting flags
            when "--days"
              filters[:days] = args[i + 1].to_i if i + 1 < args.length
              i += 2
            when "--limit"
              filters[:limit] = args[i + 1].to_i if i + 1 < args.length
              i += 2
            when "--stats"
              filters[:stats] = true
              i += 1
            when "--verbose", "-v"
              filters[:verbose] = true
              i += 1
            when "--short"
              filters[:short] = true
              i += 1
            when "--format"
              filters[:format] = args[i + 1] if i + 1 < args.length
              i += 2
            # KEPT: Release selection flags (not filters)
            when "--backlog"
              filters[:release] = "backlog"
              i += 1
            when "--release", "-r"
              filters[:release] = args[i + 1] if i + 1 < args.length
              i += 2
            when "--current"
              filters[:release] = "current"
              i += 1
            when "--all"
              # Map to 'all' preset
              filters[:_preset_override] = "all"
              i += 1
            when "--help", "-h"
              show_help
              exit 0
            else
              i += 1
            end
          end

          # Parse filter strings into filter specifications
          if filter_strings.any?
            filters[:filter_specs] = Atoms::FilterParser.parse(filter_strings)
          end

          filters
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