# frozen_string_literal: true

require_relative "../organisms/release_manager"
require_relative "../organisms/release_creator"
require_relative "../models/release"
require_relative "../molecules/release_arg_parser"
require_relative "../atoms/path_formatter"

module Ace
  module Taskflow
    module Commands
      # Handle release subcommand
      class ReleaseCommand
        def initialize
          @manager = Organisms::ReleaseManager.new
        end

        def execute(args)
          # Parse display mode options first
          display_options = parse_display_mode(args)
          display_mode = display_options[:mode]
          subfolder = display_options[:subfolder]

          subaction = args.shift

          case subaction
          when nil, "show"
            show_active_releases(display_mode: display_mode, subfolder: subfolder)
          when "create"
            create_release(args)
          when "promote"
            promote_release(args)
          when "demote"
            demote_release(args)
          when "reschedule"
            reschedule_release(args)
          when "validate"
            validate_release(args)
          when "changelog"
            generate_changelog(args)
          when "--help", "-h"
            show_help
          else
            # Try to show specific release
            show_release(subaction, display_mode: display_mode, subfolder: subfolder)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def parse_display_mode(args)
          Molecules::ReleaseArgParser.parse_display_mode(args)
        end

        def show_active_releases(display_mode: "formatted", subfolder: nil)
          releases = @manager.show_active

          if releases.empty?
            puts "No active releases found."
            puts "Use 'ace-taskflow release promote' to activate a release from backlog."
            return
          end

          if releases.size == 1
            release = releases.first
            case display_mode
            when "path"
              display_release_path(release, subfolder: subfolder)
            else
              display_release(release)
            end
          else
            # For multiple releases, show all paths if in path mode
            if display_mode == "path"
              releases.each do |release|
                display_release_path(release, subfolder: subfolder)
              end
            else
              puts "Active Releases (#{releases.size}):"
              puts ""
              releases.each_with_index do |release, index|
                primary = index == 0 ? " (primary)" : ""
                puts "  #{release[:name]}#{primary}"
                puts "    Path: #{release[:path]}"
                puts "    Progress: #{progress_bar(release[:statistics])}"
                puts ""
              end
            end
          end
        end

        def show_release(name, display_mode: "formatted", subfolder: nil)
          release = @manager.show_release(name)

          unless release
            puts "Release '#{name}' not found."
            exit 1
          end

          case display_mode
          when "path"
            display_release_path(release, subfolder: subfolder)
          else
            display_release(release)
          end
        end

        def create_release(args)
          # Parse arguments
          codename = nil
          version = nil
          location = "backlog"

          while args.any?
            arg = args.shift
            case arg
            when "--release", "-r"
              version = args.shift
            when "--current", "-c"
              location = "active"
            when "--backlog", "-b"
              location = "backlog"
            else
              codename = arg
            end
          end

          unless codename
            puts "Usage: ace-taskflow release create <codename> [options]"
            puts ""
            puts "Options:"
            puts "  --release, -r <version>  Specify version (e.g., v.0.10.0)"
            puts "  --current, -c            Create as active release"
            puts "  --backlog, -b            Create in backlog (default)"
            puts ""
            puts "Examples:"
            puts "  ace-taskflow release create authentication-refactor"
            puts "  ace-taskflow release create dark-mode --release v.0.12.0"
            puts "  ace-taskflow release create api-v2 --current"
            exit 1
          end

          # Create the release using the new creator
          creator = Organisms::ReleaseCreator.new(@manager.root_path)
          result = creator.create(codename, version: version, location: location)

          if result[:success]
            puts result[:message]
            puts "Version: #{result[:version]}"
            puts "Path: #{result[:path]}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def promote_release(args)
          name = args.first
          result = @manager.promote_release(name)

          if result[:success]
            puts result[:message]
            puts "Path: #{result[:path]}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def reschedule_release(args)
          reference = args.shift

          unless reference
            puts "Usage: ace-taskflow release reschedule <reference> [options]"
            puts "Options:"
            puts "  --status <value>           Update release status"
            puts "  --target-date <YYYY-MM-DD> Update target completion date"
            exit 1
          end

          # Parse options
          options = {}
          i = 0
          while i < args.length
            case args[i]
            when "--status"
              options[:status] = args[i + 1]
              i += 2
            when "--target-date"
              options[:target_date] = args[i + 1]
              i += 2
            else
              i += 1
            end
          end

          # Reschedule the release
          require_relative "../organisms/release_scheduler"
          scheduler = Organisms::ReleaseScheduler.new
          result = scheduler.reschedule(reference, options)

          if result[:success]
            puts result[:message]
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def demote_release(args)
          # Parse options
          name = nil
          to = "done"

          args.each_with_index do |arg, index|
            if arg == "--to"
              to = args[index + 1]
            elsif !arg.start_with?("--")
              name = arg
            end
          end

          result = @manager.demote_release(name, to: to)

          if result[:success]
            puts result[:message]
            puts "Path: #{result[:path]}"
          else
            puts "Error: #{result[:message]}"
            exit 1
          end
        end

        def validate_release(args)
          name = args.first
          result = @manager.validate_release(name)

          if result[:valid]
            puts "✓ Release validation: PASSED"
            display_statistics(result[:statistics])
          else
            puts "✗ Release validation: FAILED"
            puts ""
            puts "Issues:"
            result[:issues].each do |issue|
              puts "  - #{issue}"
            end
            puts ""
            display_statistics(result[:statistics])
            exit 1
          end
        end

        def generate_changelog(args)
          name = args.first
          changelog = @manager.generate_changelog(name)
          puts changelog
        end

        def display_release(release)
          model = Models::Release.new(release)

          puts "Release: #{model.name}"
          puts "Status: #{model.status}"
          puts "Path: #{model.path}"
          puts ""
          display_statistics(model.statistics)
        end

        def display_release_path(release, subfolder: nil)
          model = Models::Release.new(release)
          if model.path
            # Use project root for relative path
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(model.path, root_path)

            # Append subfolder if provided
            final_path = subfolder ? File.join(relative_path, subfolder) : relative_path
            puts final_path
          else
            puts "# Release has no path"
            exit 1
          end
        end

        def display_statistics(stats)
          total = stats[:total]
          done = stats[:statuses]["done"] || 0
          in_progress = stats[:statuses]["in-progress"] || 0
          pending = stats[:statuses]["pending"] || 0
          blocked = stats[:statuses]["blocked"] || 0

          if total > 0
            percentage = (done.to_f / total * 100).round
            puts "Progress: #{progress_bar(stats)} #{percentage}% (#{done}/#{total})"
          else
            puts "Progress: No tasks"
          end

          puts "Status breakdown:"
          puts "  ✓ Done: #{done}" if done > 0
          puts "  ⚡ In Progress: #{in_progress}" if in_progress > 0
          puts "  ○ Pending: #{pending}" if pending > 0
          puts "  ⊘ Blocked: #{blocked}" if blocked > 0
        end

        def progress_bar(stats)
          total = stats[:total]
          return "□" * 20 if total == 0

          done = stats[:statuses]["done"] || 0
          percentage = (done.to_f / total * 100).round
          filled = (percentage / 5).round
          empty = 20 - filled

          "█" * filled + "░" * empty
        end

        def show_help
          puts "Usage: ace-taskflow release [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  (none)                    Show active release(s)"
          puts "  <name>                    Show specific release info"
          puts "  create <codename> [opts]  Create new release with auto-versioning"
          puts "    --release <version>     Specify version (default: auto-increment)"
          puts "    --current               Create as active release"
          puts "    --backlog               Create in backlog (default)"
          puts "  promote [<name>]          Promote release from backlog to active"
          puts "  demote [<name>]           Demote release from active to done"
          puts "    --to backlog            Demote to backlog instead of done"
          puts "  reschedule <ref> [opts]   Update release metadata"
          puts "    --status <value>        Update release status"
          puts "    --target-date <date>    Update target date (YYYY-MM-DD)"
          puts "  validate [<name>]         Validate release for completion"
          puts "  changelog [<name>]        Generate changelog for release"
          puts ""
          puts "Display Options:"
          puts "  --path [subfolder]        Show release directory path, optionally with subfolder"
          puts "  --content                 Show full release details (default)"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow release"
          puts "  ace-taskflow release --path"
          puts "  ace-taskflow release --path retro"
          puts "  ace-taskflow release v.0.9.0"
          puts "  ace-taskflow release v.0.9.0 --path"
          puts "  ace-taskflow release v.0.9.0 --path docs"
          puts "  ace-taskflow release create authentication    # auto-increments to v.0.10.0"
          puts "  ace-taskflow release create api-v2 --release v.0.12.0"
          puts "  ace-taskflow release create dark-mode --current"
          puts "  ace-taskflow release promote v.0.10.0"
          puts "  ace-taskflow release demote --to backlog"
        end
      end
    end
  end
end