# frozen_string_literal: true

require_relative "../organisms/release_manager"
require_relative "../models/release"

module Ace
  module Taskflow
    module Commands
      # Handle releases (plural) subcommand for browsing/listing
      class ReleasesCommand
        def initialize
          @manager = Organisms::ReleaseManager.new
        end

        def execute(args)
          # Parse options
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
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

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
          puts "Usage: ace-taskflow releases [options]"
          puts ""
          puts "Options:"
          puts "  --backlog    List backlog releases"
          puts "  --active     List active releases"
          puts "  --done       List completed releases"
          puts "  --stats      Show release statistics"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow releases"
          puts "  ace-taskflow releases --active"
          puts "  ace-taskflow releases --backlog"
          puts "  ace-taskflow releases --done"
          puts "  ace-taskflow releases --stats"
        end
      end
    end
  end
end