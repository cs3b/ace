# frozen_string_literal: true

require_relative "../organisms/release_manager"
require_relative "../molecules/list_preset_manager"
require_relative "../models/release"

module Ace
  module Taskflow
    module Commands
      # Handle releases (plural) subcommand for browsing/listing
      class ReleasesCommand
        def initialize
          @manager = Organisms::ReleaseManager.new
          @preset_manager = Molecules::ListPresetManager.new
        end

        def execute(args)
          # Check if first argument is a preset name
          preset_name = detect_preset_name(args)
          if preset_name
            args.shift # Remove preset name from args
            execute_with_preset(preset_name, args)
          elsif args.empty? || (!args.first.start_with?('-') && !@preset_manager.preset_exists?(args.first, :releases))
            # Default to 'all' preset for releases when no arguments or no valid preset/flag
            execute_with_preset('all', args)
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
          if @preset_manager.preset_exists?(potential_preset, :releases)
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

          # Get releases based on preset configuration
          releases = get_releases_for_preset(preset_config)

          # Display releases
          if releases.empty?
            puts "No releases found for preset '#{preset_name}'."
          else
            display_releases_with_preset(releases, preset_config)
          end
        end

        def execute_legacy(args)
          # Original implementation for backward compatibility
          options = parse_options(args)

          if options[:stats]
            show_statistics
          else
            # Get releases based on filter
            releases = if options[:filter]
              @manager.list_releases(options[:filter])
            else
              @manager.list_releases
            end

            display_releases(releases, options)
          end
        end

        def parse_additional_filters(args)
          filters = {}

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--stats"
              filters[:stats] = true
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

        def get_releases_for_preset(preset_config)
          context = preset_config[:context] || 'all'
          filters = preset_config[:filters] || {}

          # Map preset context to manager filter
          filter = case context
          when 'active'
            'active'
          when 'backlog'
            'backlog'
          when 'done'
            'done'
          else
            nil # Show all
          end

          @manager.list_releases(filter)
        end

        def display_releases_with_preset(releases, preset_config)
          preset_name = preset_config[:name]
          description = preset_config[:description]

          puts "Releases: #{preset_name} (#{releases.size} found)"
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
          preset_config = @preset_manager.apply_preset(preset_name)
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
              options[:filter] = "backlog"
            when "--active"
              options[:filter] = "active"
            when "--done"
              options[:filter] = "done"
            when "--stats"
              options[:stats] = true
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
          puts "  ace-taskflow releases                    # Uses 'all' preset (default)"
          puts "  ace-taskflow releases all               # All releases, grouped by status"
          puts "  ace-taskflow releases recent            # Recently modified releases"
          puts "  ace-taskflow releases all --stats       # Statistics for all preset"
          puts ""
          puts "Legacy Flag Options (backward compatibility):"
          puts "  --backlog    List backlog releases"
          puts "  --active     List active releases"
          puts "  --done       List completed releases"
          puts "  --stats      Show release statistics"
          puts ""
          puts "Additional Preset Filters:"
          puts "  --stats      Show statistics for preset"
          puts ""
          puts "Custom Presets:"
          puts "  Create YAML files in .ace/taskflow/presets/ to define custom presets"
          puts "  Example: .ace/taskflow/presets/my-active.yml"
        end
      end
    end
  end
end