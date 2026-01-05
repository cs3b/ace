# frozen_string_literal: true

require_relative "../organisms/release_manager"
require_relative "../molecules/list_preset_manager"
require_relative "../molecules/stats_formatter"
require_relative "../molecules/command_option_parser"
require_relative "../models/release"
require_relative "../molecules/task_filter"

module Ace
  module Taskflow
    module Commands
      # Handle releases (plural) subcommand for browsing/listing
      class ReleasesCommand
        def initialize
          @manager = Organisms::ReleaseManager.new
          @preset_manager = Molecules::ListPresetManager.new
          @stats_formatter = Molecules::StatsFormatter.new
          @option_parser = build_option_parser
        end

        def execute(args, thor_options = {})
          # Parse options using CommandOptionParser (merges Thor options automatically)
          result = @option_parser.parse(args, thor_options: thor_options)
          return 0 if result[:help_requested]

          options = result[:parsed]
          remaining = result[:remaining]

          # Check if first remaining argument is a preset name
          preset_name = detect_preset_name(remaining)
          if preset_name
            remaining.shift # Remove preset name from args
          else
            # Default to 'all' preset
            preset_name = 'all'
          end

          execute_with_preset(preset_name, options)
        rescue StandardError => e
          puts "Error: #{e.message}"
          1
        end

        private

        # Build the option parser for releases command
        def build_option_parser
          Molecules::CommandOptionParser.new(
            option_sets: [:display, :filter, :limits, :help],
            banner: "Usage: ace-taskflow releases [preset] [options]"
          )
        end

        def detect_preset_name(args)
          return nil if args.empty? || args.first.start_with?('-')

          potential_preset = args.first
          # Check if it's a known preset or custom preset
          if @preset_manager.preset_exists?(potential_preset, :releases)
            potential_preset
          else
            nil
          end
        end

        def execute_with_preset(preset_name, options)
          # Check for special flags
          if options[:stats]
            show_statistics_for_preset(preset_name)
            return 0
          end

          # Handle filter-clear: if set, don't pass old-style filters to preset
          if options[:filter_clear]
            # Apply preset but ignore its filters
            preset_config = @preset_manager.apply_preset(preset_name, {}, :releases)
            return 1 unless preset_config
            # Clear the preset filters but keep release, sort, glob, display
            preset_config[:filters] = {}
          else
            # Apply preset with additional filters (normal flow)
            preset_config = @preset_manager.apply_preset(preset_name, options, :releases)
            return 1 unless preset_config
          end

          # Store filter_specs in preset_config so filtering can access them
          if options[:filter_specs]
            preset_config[:filter_specs] = options[:filter_specs]
          end

          # Get releases based on preset configuration
          releases = get_releases_for_preset(preset_config)

          # Apply limit if specified
          original_count = releases.size
          if options[:limit] && options[:limit] > 0
            releases = releases.take(options[:limit])
          end

          # Display releases
          if releases.empty?
            puts "No releases found for preset '#{preset_name}'."
            0
          else
            display_releases_with_preset(releases, preset_config, original_count, options[:limit])
            0
          end
        end

        def get_releases_for_preset(preset_config)
          release = preset_config[:release] || 'all'
          filters_raw = preset_config[:filters] || {}

          # Map preset release to manager filter
          filter = case release
          when 'active'
            'active'
          when 'backlog'
            'backlog'
          when 'done'
            'done'
          else
            nil # Show all
          end

          # Load releases
          releases = @manager.list_releases(filter)

          # Apply filters from preset
          filters = {}
          filters_raw.each do |key, value|
            filters[key.to_sym] = value
          end

          # Add filter_specs to filters hash so TaskFilter can access them
          if preset_config[:filter_specs]
            filters[:filter_specs] = preset_config[:filter_specs]
          end

          # Apply TaskFilter (works with releases - they're hashes with metadata)
          Molecules::TaskFilter.apply_filters(releases, filters)
        end

        def display_releases_with_preset(releases, preset_config, original_count = nil, limit = nil)
          preset_name = preset_config[:name]
          description = preset_config[:description]

          if limit && original_count && original_count > limit
            puts "Releases: #{preset_name} (showing #{releases.size} of #{original_count} found)"
          else
            puts "Releases: #{preset_name} (#{releases.size} found)"
          end
          puts description if description && description != "#{preset_name} preset"
          puts "=" * 50

          # Check if grouping is needed
          display_config = preset_config[:display] || {}
          if display_config[:group_by] == 'status' || display_config[:group_by] == :status
            # Group by status (default releases display)
            grouped = releases.group_by { |r| r[:status] }

            if grouped["active"]
              puts ""
              puts "ACTIVE (#{grouped['active'].size}):"
              grouped["active"].each_with_index do |release, index|
                primary = index == 0 ? " [primary]" : ""
                display_release_line(release, primary)
              end
            end

            if grouped["backlog"]
              puts ""
              puts "BACKLOG (#{grouped['backlog'].size}):"
              grouped["backlog"].each { |release| display_release_line(release) }
            end

            if grouped["done"]
              puts ""
              puts "DONE (#{grouped['done'].size}):"
              grouped["done"].each { |release| display_release_line(release) }
            end
          else
            # Simple list display
            releases.each { |release| display_release_line(release) }
          end
        end

        def show_statistics_for_preset(preset_name)
          preset_config = @preset_manager.apply_preset(preset_name, {}, :releases)
          return unless preset_config

          puts "Release Statistics for '#{preset_name}' preset:"
          puts preset_config[:description] if preset_config[:description]
          puts "=" * 50

          # Use existing statistics logic
          show_statistics
        end

        def parse_options(args)
          options = {}

          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              raise ArgumentError, "Error: --backlog flag is no longer supported. Use: --filter status:backlog"
            when "--active"
              raise ArgumentError, "Error: --active flag is no longer supported. Use: --filter status:active"
            when "--done"
              raise ArgumentError, "Error: --done flag is no longer supported. Use: --filter status:done"
            when "--stats"
              options[:stats] = true
            when "--limit"
              options[:limit] = args[index + 1].to_i if index + 1 < args.length
            when "--help", "-h"
              show_help
              exit 0
            end
          end

          options
        end

        def display_releases(releases, options)
          if releases.empty?
            puts "No releases found."
            return
          end

          # Group releases by status
          grouped = releases.group_by { |r| r[:status] }

          if options[:filter]
            # Show filtered releases
            puts "#{options[:filter].capitalize} Releases (#{releases.size}):"
            puts "=" * 50
            releases.each { |release| display_release_line(release) }
          else
            # Show all grouped by status
            puts "All Releases:"
            puts "=" * 50

            if grouped["active"]
              puts ""
              puts "ACTIVE (#{grouped['active'].size}):"
              grouped["active"].each_with_index do |release, index|
                primary = index == 0 ? " [primary]" : ""
                display_release_line(release, primary)
              end
            end

            if grouped["backlog"]
              puts ""
              puts "BACKLOG (#{grouped['backlog'].size}):"
              grouped["backlog"].each { |release| display_release_line(release) }
            end

            if grouped["done"]
              puts ""
              puts "DONE (#{grouped['done'].size}):"
              grouped["done"].each { |release| display_release_line(release) }
            end
          end
        end

        def display_release_line(release_data, suffix = "")
          release = Models::Release.new(release_data)

          total = release.statistics[:total]
          if total > 0
            progress = "#{release.done_count}/#{total} tasks (#{release.completion_percentage}%)"
          else
            progress = "No tasks"
          end

          puts "  #{release.name}#{suffix}"

          # Show release directory path on second line
          if release.path
            relative_path = format_relative_path(release.path)
            puts "    #{relative_path}/"
          end

          puts "    Progress: #{progress}"

          if release.in_progress_count > 0
            puts "    In Progress: #{release.in_progress_count}"
          end

          if release.pending_count > 0
            puts "    Pending: #{release.pending_count}"
          end
        end

        def format_relative_path(path)
          # Make path relative to project root
          root_path = @manager.instance_variable_get(:@root_path) || Dir.pwd
          relative = path.sub(/^#{Regexp.escape(root_path)}\/?/, "")

          # Truncate if too long
          max_length = 70
          if relative.length > max_length
            # Keep the beginning and end, truncate middle
            start_length = 35
            end_length = 32
            "#{relative[0...start_length]}...#{relative[-end_length..]}"
          else
            relative
          end
        end

        def show_statistics
          all_releases = @manager.list_releases

          # Calculate statistics
          total = all_releases.size
          by_status = all_releases.group_by { |r| r[:status] }

          total_tasks = 0
          completed_tasks = 0

          all_releases.each do |release|
            stats = release[:statistics]
            total_tasks += stats[:total]
            completed_tasks += (stats[:statuses]["done"] || 0)
          end

          puts "Release Statistics:"
          puts "=" * 50
          puts "Total: #{total} releases"
          puts ""

          puts "By Status:"
          by_status.each do |status, releases|
            percentage = (releases.size.to_f / total * 100).round
            puts "  #{status.capitalize}: #{releases.size} (#{percentage}%)"
          end

          puts ""
          puts "Task Overview:"
          puts "  Total Tasks: #{total_tasks}"
          puts "  Completed: #{completed_tasks}"
          if total_tasks > 0
            completion = (completed_tasks.to_f / total_tasks * 100).round
            puts "  Overall Completion: #{completion}%"
          end

          # Show active release details
          active = by_status["active"]
          if active && !active.empty?
            puts ""
            puts "Active Releases:"
            active.each do |release|
              model = Models::Release.new(release)
              puts "  #{model.name}: #{model.completion_percentage}% complete"
            end
          end
        end

        def show_help
          puts "Usage: ace-taskflow releases [preset] [options]"
          puts ""
          puts "List and browse releases by status and progress"
          puts ""
          puts "Presets (recommended):"
          available_presets = @preset_manager.list_presets(:releases)
          available_presets.each do |preset|
            name = preset[:name]
            desc = preset[:description]
            default_marker = preset[:default] ? " (default for releases)" : ""
            puts "  #{name.ljust(12)} #{desc}#{default_marker}"
          end
          puts ""
          puts "Preset Examples:"
          puts "  ace-taskflow releases                         # Uses 'all' preset (default)"
          puts "  ace-taskflow releases all                     # All releases, grouped by status"
          puts "  ace-taskflow releases recent                  # Recently modified releases"
          puts ""
          puts "Filtering Options:"
          puts "  --filter <key>:<value>                        Filter by any frontmatter field"
          puts "  --filter-clear                                Clear preset filters (keep release/scope/sort)"
          puts ""
          puts "Filter Examples:"
          puts "  ace-taskflow releases --filter status:active"
          puts "  ace-taskflow releases --filter status:done"
          puts "  ace-taskflow releases all --filter status:!backlog"
          puts "  ace-taskflow releases --filter-clear --filter status:active"
          puts ""
          puts "Display Options:"
          puts "  --limit <n>  Limit number of results displayed"
          puts "  --stats      Show release statistics"
          puts ""
          puts "Custom Presets:"
          puts "  Create YAML files in .ace/taskflow/presets/ to define custom presets"
          puts "  Example: .ace/taskflow/presets/my-active.yml"
        end
      end
    end
  end
end