# frozen_string_literal: true

require_relative "../molecules/idea_loader"
require_relative "../models/idea"

module Ace
  module Taskflow
    module Commands
      class IdeasCommand
        def initialize
          @root_path = Molecules::ConfigLoader.find_root
          @idea_loader = Molecules::IdeaLoader.new(@root_path)
        end

        def execute(args)
          if args.include?("--help") || args.include?("-h")
            show_help
            exit 0
          end

          # Parse options
          options = parse_options(args)

          if options[:stats]
            show_statistics
          else
            list_ideas(options)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

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
            puts "All Ideas (#{all_ideas.length} total):"
            puts "=" * 60

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
          puts "Ideas in #{context_name} (#{ideas.length} total):"
          puts "=" * 60

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
          counts = @idea_loader.count_by_context
          total = counts.values.sum

          puts "Ideas Statistics:"
          puts "=" * 60
          puts "Total ideas: #{total}"
          puts ""
          puts "By context:"

          # Sort with active releases first, then backlog
          sorted_counts = counts.sort_by do |context, _count|
            context == "backlog" ? "zzz" : context
          end

          sorted_counts.each do |context, count|
            next if count == 0
            bar = "█" * [count, 50].min
            puts "  #{context.ljust(15)} #{count.to_s.rjust(3)} #{bar}"
          end
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
          puts "Usage: ace-taskflow ideas [options]"
          puts ""
          puts "List and browse ideas across releases and backlog"
          puts ""
          puts "Options:"
          puts "  --backlog          Show ideas from backlog"
          puts "  --release <name>   Show ideas from specific release"
          puts "  --current          Show ideas from current/active release (default)"
          puts "  --all              Show all ideas across all contexts"
          puts "  --stats            Show idea statistics"
          puts "  --verbose, -v      Show detailed information"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow ideas                      # List ideas in current release"
          puts "  ace-taskflow ideas --backlog            # List backlog ideas"
          puts "  ace-taskflow ideas --release v.0.9.0    # List ideas from specific release"
          puts "  ace-taskflow ideas --all                # List all ideas"
          puts "  ace-taskflow ideas --stats              # Show statistics"
        end
      end
    end
  end
end