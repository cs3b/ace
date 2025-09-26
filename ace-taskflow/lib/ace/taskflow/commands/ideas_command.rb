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
          else
            # Default to 'recent' preset for ideas
            preset_name = 'recent'
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
            show_statistics_for_preset(preset_name)
            return
          end

          # Apply preset with additional filters
          preset_config = @preset_manager.apply_preset(preset_name, additional_filters)
          return unless preset_config

          # Override context if provided via legacy flags
          if additional_filters[:context]
            preset_config[:context] = additional_filters[:context]
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
          else
            display_ideas_with_preset(ideas, preset_config, original_count, additional_filters[:limit])
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
            # Legacy flag mappings to preset contexts
            when "--backlog"
              filters[:context] = "backlog"
              i += 1
            when "--release", "-r"
              filters[:context] = args[i + 1] if i + 1 < args.length
              i += 2
            when "--current"
              filters[:context] = "current"
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
          puts "Additional Options:"
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