# frozen_string_literal: true

require_relative "../molecules/idea_loader"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/stats_formatter"
require_relative "../models/idea"

module Ace
  module Taskflow
    module Commands
      class IdeasCommand
        def initialize
          @root_path = Molecules::ConfigLoader.find_root
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
            execute_with_preset(preset_name, args)
          elsif args.empty? || (!args.first.start_with?('-') && !@preset_manager.preset_exists?(args.first, :ideas))
            # Default to 'recent' preset for ideas when no arguments or no valid preset/flag
            execute_with_preset('recent', args)
          else
            # Fallback to legacy flag-based execution for backward compatibility
            execute_legacy(args)
          end
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

          # Check for special flags
          if additional_filters[:stats]
            show_statistics_for_preset(preset_name)
            return
          end

          # Apply preset with additional filters
          preset_config = @preset_manager.apply_preset(preset_name, additional_filters)
          return unless preset_config

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
          else
            display_ideas_with_preset(ideas, preset_config, original_count, additional_filters[:limit])
          end
        end

        def execute_legacy(args)
          # Original implementation for backward compatibility
          options = parse_options(args)

          if options[:stats]
            show_statistics
          else
            list_ideas(options)
          end
        end

        def parse_additional_filters(args)
          filters = {}

          i = 0
          while i < args.length
            arg = args[i]
            case arg
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
            when "--help", "-h"
              show_help
              exit 0
            else
              i += 1
            end
          end

          filters
        end

        def get_ideas_for_preset(preset_config)
          context = preset_config[:context] || 'current'
          # Note: ideas_loader doesn't use filters in the same way as tasks,
          # but we keep this consistent for future expansion

          case context
          when 'all'
            get_all_ideas_for_preset
          when 'backlog'
            @idea_loader.load_all(context: "backlog", include_content: false)
          when 'current'
            @idea_loader.load_all(context: "current", include_content: false)
          else
            # Assume it's a specific release context
            @idea_loader.load_all(context: context, include_content: false)
          end
        end

        def get_all_ideas_for_preset
          all_ideas = []
          release_resolver = Molecules::ReleaseResolver.new(@root_path)

          # Active releases
          active_releases = release_resolver.find_active
          active_releases.each do |release|
            ideas = @idea_loader.load_all(context: release[:name], include_content: false)
            ideas.each { |idea| idea[:release] = release[:name] }
            all_ideas.concat(ideas)
          end

          # Backlog
          backlog_ideas = @idea_loader.load_all(context: "backlog", include_content: false)
          backlog_ideas.each { |idea| idea[:release] = "backlog" }
          all_ideas.concat(backlog_ideas)

          all_ideas
        end

        def display_ideas_with_preset(ideas, preset_config, original_count = nil, limit = nil)
          # Display three-line header
          context = preset_config[:context] || 'current'
          header = @stats_formatter.format_header(
            command_type: :ideas,
            displayed_count: ideas.size,
            context: context
          )
          puts header

          # Check if grouping is needed
          display_config = preset_config[:display] || {}
          if display_config[:group_by] == 'context' || display_config[:group_by] == :context
            # Group by release/context
            grouped = ideas.group_by { |idea| idea[:release] || 'current' }
            grouped.each do |context, context_ideas|
              puts ""
              puts "#{context} (#{context_ideas.length} ideas):"
              context_ideas.each { |idea| display_idea_line(idea, display_config[:verbose] || false) }
            end
          else
            ideas.each { |idea| display_idea_line(idea, display_config[:verbose] || false) }
          end
        end

        def show_statistics_for_preset(preset_name)
          preset_config = @preset_manager.apply_preset(preset_name)
          return unless preset_config

          context = preset_config[:context] || 'current'
          puts @stats_formatter.format_stats_view(context: context)
        end

        def parse_options(args)
          options = {
            context: "current",
            all: false,
            stats: false,
            verbose: false
          }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              options[:context] = "backlog"
              i += 1
            when "--release", "-r"
              options[:context] = args[i + 1]
              i += 2
            when "--current"
              options[:context] = "current"
              i += 1
            when "--all"
              options[:all] = true
              i += 1
            when "--stats"
              options[:stats] = true
              i += 1
            when "--verbose", "-v"
              options[:verbose] = true
              i += 1
            else
              i += 1
            end
          end

          options
        end

        def list_ideas(options)
          if options[:all]
            list_all_ideas(options[:verbose])
          else
            ideas = @idea_loader.load_all(context: options[:context], include_content: false)

            if ideas.empty?
              puts "No ideas found in #{context_name(options[:context])}"
              puts "Use 'ace-taskflow idea create' to capture a new idea"
            else
              display_ideas_list(ideas, context_name(options[:context]), options[:verbose])
            end
          end
        end

        def list_all_ideas(verbose)
          all_ideas = []

          # Get ideas from all contexts
          release_resolver = Molecules::ReleaseResolver.new(@root_path)

          # Active releases
          active_releases = release_resolver.find_active
          active_releases.each do |release|
            ideas = @idea_loader.load_all(context: release[:name], include_content: false)
            ideas.each { |idea| idea[:release] = release[:name] }
            all_ideas.concat(ideas)
          end

          # Backlog
          backlog_ideas = @idea_loader.load_all(context: "backlog", include_content: false)
          backlog_ideas.each { |idea| idea[:release] = "backlog" }
          all_ideas.concat(backlog_ideas)

          if all_ideas.empty?
            puts "No ideas found across all releases and backlog"
          else
            # Display three-line header for all ideas
            header = @stats_formatter.format_header(
              command_type: :ideas,
              displayed_count: all_ideas.length,
              context: 'all'
            )
            puts header

            # Group by context
            grouped = all_ideas.group_by { |idea| idea[:release] }

            grouped.each do |context, ideas|
              puts "\n#{context} (#{ideas.length} ideas):"
              puts "-" * 40
              ideas.each do |idea|
                display_idea_line(idea, verbose)
              end
            end
          end
        end

        def display_ideas_list(ideas, context_name, verbose)
          # Display three-line header
          # Determine context from context_name
          context = case context_name
                   when /^Release v\.\d+\.\d+\.\d+/
                     context_name.sub('Release ', '')
                   when 'Current Release'
                     'current'
                   when 'Backlog'
                     'backlog'
                   else
                     context_name
                   end

          header = @stats_formatter.format_header(
            command_type: :ideas,
            displayed_count: ideas.size,
            context: context
          )
          puts header

          ideas.each do |idea|
            display_idea_line(idea, verbose)
          end
        end

        def display_idea_line(idea, verbose)
          puts "• [#{idea[:id]}] #{idea[:title]}"

          # Always show path on second line
          if idea[:path]
            relative_path = format_relative_path(idea[:path])
            puts "  #{relative_path}"
          end

          # Show timestamp only in verbose mode
          if verbose && idea[:created_at]
            timestamp = idea[:created_at].strftime("%Y-%m-%d %H:%M")
            puts "  Created: #{timestamp}"
          end
        end

        def format_relative_path(path)
          # Make path relative to project root
          root_path = Molecules::ConfigLoader.find_root
          relative = path.sub(/^#{Regexp.escape(root_path)}\//, "")

          # Truncate if too long
          max_length = 68
          if relative.length > max_length
            # Smart truncation for .ace-taskflow paths
            if relative.start_with?(".ace-taskflow/")
              parts = relative.split("/")
              if parts.length >= 4
                # .ace-taskflow/release/subfolder/filename.md
                prefix = parts[0..2].join("/")  # .ace-taskflow/v.0.9.0/ideas
                filename = parts[-1]
                if filename.length > 35
                  filename = "#{filename[0..15]}...#{filename[-15..]}"
                end
                "#{prefix}/#{filename}"
              else
                relative[0..67]
              end
            else
              "#{relative[0...32]}...#{relative[-32..]}"
            end
          else
            relative
          end
        end

        def show_statistics
          # Use the new stats formatter for all contexts
          puts @stats_formatter.format_stats_view(context: 'all')
        end

        def context_name(context)
          case context
          when "current", "active", nil
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{context}"
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
          puts "  ace-taskflow ideas                    # Uses 'recent' preset (default)"
          puts "  ace-taskflow ideas all               # All ideas, grouped by context"
          puts "  ace-taskflow ideas recent --days 3   # Recent ideas with custom filter"
          puts "  ace-taskflow ideas all --stats       # Statistics for all preset"
          puts ""
          puts "Legacy Flag Options (backward compatibility):"
          puts "  --backlog          Show ideas from backlog"
          puts "  --release <name>   Show ideas from specific release"
          puts "  --current          Show ideas from current/active release"
          puts "  --all              Show all ideas across all contexts"
          puts "  --stats            Show idea statistics"
          puts "  --verbose, -v      Show detailed information"
          puts ""
          puts "Additional Preset Filters:"
          puts "  --days <n>         Modify days for time-based presets"
          puts "  --limit <n>        Limit number of results displayed"
          puts "  --verbose, -v      Show detailed information"
          puts "  --stats            Show statistics for preset"
          puts ""
          puts "Custom Presets:"
          puts "  Create YAML files in .ace/taskflow/presets/ to define custom presets"
          puts "  Example: .ace/taskflow/presets/creative.yml"
        end
      end
    end
  end
end