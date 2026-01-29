# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/release_manager"
require_relative "../../molecules/list_preset_manager"
require_relative "../../molecules/stats_formatter"
require_relative "../../molecules/command_option_parser"
require_relative "../../models/release"
require_relative "../../molecules/task_filter"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the releases command
        #
        # This command lists and browses releases.
        class Releases < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "List and browse releases by status and progress"
          example [
            '                 # Show all releases',
            'active           # Show active releases',
            '--stats           # Show statistics'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

          option :stats, type: :boolean, desc: "Show statistics"
          option :limit, type: :integer, desc: "Limit number of results"
          option :filter, type: :string, desc: "Filter by key:value"
          option :filter_clear, type: :boolean, desc: "Clear preset filters"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            execute_releases(args, clean_options)
          end

          private

          def execute_releases(args, thor_options = {})
            @manager = Organisms::ReleaseManager.new
            @preset_manager = Molecules::ListPresetManager.new
            @stats_formatter = Molecules::StatsFormatter.new
            @option_parser = build_option_parser

            result = @option_parser.parse(args, thor_options: thor_options)
            return if result[:help_requested]

            options = result[:parsed]
            remaining = result[:remaining]

            preset_name = detect_preset_name(remaining)
            if preset_name
              remaining.shift
            else
              preset_name = 'all'
            end

            execute_with_preset(preset_name, options)
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def build_option_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:display, :filter, :limits, :help],
              banner: "Usage: ace-taskflow releases [preset] [options]"
            )
          end

          def detect_preset_name(args)
            return nil if args.empty? || args.first.start_with?('-')

            potential_preset = args.first
            if @preset_manager.preset_exists?(potential_preset, :releases)
              potential_preset
            else
              nil
            end
          end

          def execute_with_preset(preset_name, options)
            if options[:stats]
              show_statistics_for_preset(preset_name)
              return
            end

            if options[:filter_clear]
              preset_config = @preset_manager.apply_preset(preset_name, {}, :releases)
              raise Ace::Core::CLI::Error.new("Failed to apply preset '#{preset_name}'") unless preset_config
              preset_config[:filters] = {}
            else
              preset_config = @preset_manager.apply_preset(preset_name, options, :releases)
              raise Ace::Core::CLI::Error.new("Failed to apply preset '#{preset_name}'") unless preset_config
            end

            if options[:filter_specs]
              preset_config[:filter_specs] = options[:filter_specs]
            end

            releases = get_releases_for_preset(preset_config)

            original_count = releases.size
            if options[:limit] && options[:limit] > 0
              releases = releases.take(options[:limit])
            end

            if releases.empty?
              puts "No releases found for preset '#{preset_name}'."
            else
              display_releases_with_preset(releases, preset_config, original_count, options[:limit])
            end
          end

          def get_releases_for_preset(preset_config)
            release = preset_config[:release] || 'all'
            filters_raw = preset_config[:filters] || {}

            filter = case release
            when 'active' then 'active'
            when 'backlog' then 'backlog'
            when 'done' then 'done'
            else nil
            end

            releases = @manager.list_releases(filter)

            filters = {}
            filters_raw.each do |key, value|
              filters[key.to_sym] = value
            end

            if preset_config[:filter_specs]
              filters[:filter_specs] = preset_config[:filter_specs]
            end

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

            display_config = preset_config[:display] || {}
            if display_config[:group_by] == 'status' || display_config[:group_by] == :status
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
              releases.each { |release| display_release_line(release) }
            end
          end

          def show_statistics_for_preset(preset_name)
            preset_config = @preset_manager.apply_preset(preset_name, {}, :releases)
            return unless preset_config

            puts "Release Statistics for '#{preset_name}' preset:"
            puts preset_config[:description] if preset_config[:description]
            puts "=" * 50

            show_statistics
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

            if release.path
              relative_path = format_relative_path(release.path)
              puts "    #{relative_path}/"
            end

            puts "    Progress: #{progress}"

            puts "    In Progress: #{release.in_progress_count}" if release.in_progress_count > 0
            puts "    Pending: #{release.pending_count}" if release.pending_count > 0
          end

          def format_relative_path(path)
            root_path = @manager.instance_variable_get(:@root_path) || Dir.pwd
            relative = path.sub(/^#{Regexp.escape(root_path)}\/?/, "")

            max_length = 70
            if relative.length > max_length
              start_length = 35
              end_length = 32
              "#{relative[0...start_length]}...#{relative[-end_length..]}"
            else
              relative
            end
          end

          def show_statistics
            all_releases = @manager.list_releases

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
          end
        end
      end
    end
  end
end
