# frozen_string_literal: true

require "json"
require_relative "../molecules/cleanup_reporter"

module Ace
  module Git
    module Worktree
      module Commands
        # Cleanup command
        #
        # Generates a complete, deterministic, report-only worktree cleanup
        # inventory using ancestry as the first safe proof. No mutations are
        # performed — this is strictly a report.
        #
        # @example Generate a cleanup report
        #   CleanupCommand.new.run(["--target", "main", "--remote", "origin"])
        #
        # @example JSON output for automation
        #   CleanupCommand.new.run(["--target", "main", "--format", "json"])
        class CleanupCommand
          # Run the cleanup command
          #
          # @param args [Array<String>] Command arguments
          # @return [Integer] Exit code (0 for success, 1 for error)
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help]

            validate_options(options)

            reporter = Molecules::CleanupReporter.new(
              target: options[:target],
              remote: options[:remote],
              offline: options[:offline]
            )

            result = reporter.report

            if result[:success]
              display_result(result, options)
              0
            else
              if options[:format] == "json"
                puts JSON.pretty_generate(result)
              else
                puts "Error: #{result[:error]}"
              end
              1
            end
          rescue ArgumentError => e
            puts "Error: #{e.message}"
            puts
            show_help
            1
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          # Show help
          #
          # @return [Integer] Exit code
          def show_help
            puts <<~HELP
              USAGE
                ace-git-worktree cleanup --target <ref> --remote <name> [OPTIONS]

              OPTIONS
                --target <ref>      Target ref for ancestry proof (required)
                --remote <name>     Remote name (default: origin)
                --offline           Skip remote evidence refresh
                --format <type>     Output format: table, json (default: table)
                --help              Show this help

              DESCRIPTION
                Generates a complete cleanup inventory without performing any
                mutations. Each worktree, local ref, and remote ref is classified
                by ancestry proof and retention policy.

                The report includes a canonical SHA-256 plan digest that can be
                used with --apply (in a future version) to safely execute the
                reviewed plan.

              EXAMPLES
                ace-git-worktree cleanup --target main
                ace-git-worktree cleanup --target main --format json
                ace-git-worktree cleanup --target main --offline
            HELP
            0
          end

          private

          def parse_arguments(args)
            options = {target: nil, remote: "origin", offline: false, format: "table", help: false}
            i = 0
            while i < args.length
              case args[i]
              when "--target"
                i += 1
                options[:target] = args[i]
              when "--remote"
                i += 1
                options[:remote] = args[i]
              when "--offline"
                options[:offline] = true
              when "--format"
                i += 1
                options[:format] = args[i]
              when "--help", "-h"
                options[:help] = true
              else
                raise ArgumentError, "Unknown option: #{args[i]}"
              end
              i += 1
            end
            options
          end

          def validate_options(options)
            raise ArgumentError, "--target is required" unless options[:target]
            raise ArgumentError, "--remote is required" unless options[:remote]

            valid_formats = %w[table json]
            unless valid_formats.include?(options[:format])
              raise ArgumentError, "Invalid format '#{options[:format]}'. Use: #{valid_formats.join(", ")}"
            end
          end

          def display_result(result, options)
            if options[:format] == "json"
              puts JSON.pretty_generate(result)
            else
              display_terminal(result)
            end
          end

          def display_terminal(result)
            puts ""
            puts "🧹 Worktree Cleanup Report"
            puts "=" * 50
            puts "  Target: #{result[:target][:ref]} (#{result[:target][:sha][0..7]})"
            puts "  Remote: #{result[:remote][:name]} (#{result[:remote][:sha]&.slice(0, 8) || "n/a"})"
            puts "  Mode:   #{result[:refresh][:status]}"
            puts ""

            # Worktrees
            puts "Worktrees (#{result[:worktrees].length}):"
            puts "-" * 40
            result[:worktrees].each do |wt|
              glyph = wt[:action] == "remove" ? "✗" : "✓"
              status = wt[:primary] ? " [primary]" : ""
              status += " [locked]" if wt[:locked]
              status += " [dirty]" if wt[:dirty] && !wt[:dirty].values.all?(&:empty?)
              puts "  #{glyph} #{wt[:path]}#{status}"
              puts "    branch: #{wt[:branch] || "(detached)"}, sha: #{wt[:sha]&.slice(0, 8)}"
              puts "    ancestry: #{wt[:ancestry] || "n/a"}, action: #{wt[:action]}"
              puts "    reason: #{wt[:retention_reason]}" if wt[:retention_reason]
            end

            # Local refs
            puts ""
            puts "Local Refs (#{result[:local_refs].length}):"
            puts "-" * 40
            result[:local_refs].each do |ref|
              glyph = ref[:action] == "remove" ? "✗" : "✓"
              prot = ref[:protected] ? " [protected]" : ""
              puts "  #{glyph} #{ref[:name]}#{prot} (#{ref[:sha]&.slice(0, 8)})"
              puts "    ancestry: #{ref[:ancestry] || "n/a"}, action: #{ref[:action]}"
              puts "    reason: #{ref[:retention_reason]}" if ref[:retention_reason]
            end

            # Remote refs
            puts ""
            puts "Remote Refs (#{result[:remote_refs].length}):"
            puts "-" * 40
            result[:remote_refs].each do |ref|
              glyph = ref[:action] == "remove" ? "✗" : "✓"
              prot = ref[:protected] ? " [protected]" : ""
              puts "  #{glyph} #{ref[:name]}#{prot} (#{ref[:sha]&.slice(0, 8)})"
              puts "    ancestry: #{ref[:ancestry] || "n/a"}, action: #{ref[:action]}"
              puts "    reason: #{ref[:retention_reason]}" if ref[:retention_reason]
            end

            # Action plan
            removable = result[:actions]
            puts ""
            puts "Proposed Actions (#{removable.length}):"
            puts "-" * 40
            if removable.empty?
              puts "  No removable items found."
            else
              removable.each_with_index do |action, idx|
                puts "  #{idx + 1}. #{action[:type]}: #{action[:target]} (#{action[:sha]&.slice(0, 8)})"
              end
            end

            # Digest
            puts ""
            puts "Plan Digest: #{result[:plan_digest]}"
            puts "=" * 50
          end
        end
      end
    end
  end
end
