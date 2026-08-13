# frozen_string_literal: true

require "json"
require_relative "../molecules/cleanup_reporter"
require_relative "../molecules/cleanup_applier"

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
              if options[:apply]
                applier = Molecules::CleanupApplier.new(result, options[:approved_digest])
                apply_result = applier.apply

                if apply_result[:success]
                  # Strict rescan
                  final_reporter = Molecules::CleanupReporter.new(
                    target: options[:target],
                    remote: options[:remote],
                    offline: options[:offline]
                  )
                  final_result = final_reporter.report
                  
                  if final_result[:success]
                    # Check require_only_target if needed
                    if options[:require_only_target] && has_non_target_state?(final_result)
                      puts "Cleanup applied successfully, but non-target state remains (failed strict --require-only-target check)."
                      display_result(final_result, options)
                      return 1
                    end
                    
                    display_apply_result(apply_result, final_result, options)
                    return 0
                  else
                    puts "Cleanup applied successfully, but final strict rescan failed: #{final_result[:error]}"
                    return 1
                  end
                else
                  puts "Error applying cleanup: #{apply_result[:error]}"
                  display_apply_result(apply_result, nil, options)
                  return 1
                end
              else
                display_result(result, options)
                return 0
              end
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
                --apply             Apply a reviewed plan
                --approved-digest <sha256>   Approved plan digest to apply
                --require-only-target        Fail if final rescan has retained non-target state
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
            options = {
              target: nil, remote: "origin", offline: false, format: "table", help: false,
              apply: false, approved_digest: nil, require_only_target: false
            }
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
              when "--apply"
                options[:apply] = true
              when "--approved-digest"
                i += 1
                options[:approved_digest] = args[i]
              when "--require-only-target"
                options[:require_only_target] = true
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
            
            if options[:apply] && !options[:approved_digest]
              raise ArgumentError, "--approved-digest is required when --apply is used"
            end
            
            if options[:approved_digest] && !options[:apply]
              raise ArgumentError, "--apply is required when --approved-digest is used"
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

          def has_non_target_state?(final_result)
            # A strict rescan ensures no retained worktrees/refs except target
            # Worktrees: only primary should remain.
            worktrees_ok = final_result[:worktrees].all? { |wt| wt[:primary] }
            
            # Local refs: only the target should remain.
            local_refs_ok = final_result[:local_refs].all? { |r| r[:name] == final_result[:target][:ref] }
            
            # Remote refs: only the target should remain.
            remote_refs_ok = final_result[:remote_refs].all? { |r| r[:short_name] == final_result[:target][:ref] }
            
            !(worktrees_ok && local_refs_ok && remote_refs_ok)
          end

          def display_apply_result(apply_result, final_result, options)
            if options[:format] == "json"
              out = { apply: apply_result }
              out[:rescan] = final_result if final_result
              puts JSON.pretty_generate(out)
              return
            end
            
            puts ""
            puts "🧹 Cleanup Apply Results"
            puts "=" * 50
            
            if apply_result[:ledger].empty?
              puts "  No actions were required."
            else
              apply_result[:ledger].each_with_index do |entry, i|
                glyph = entry[:success] ? "✓" : "✗"
                puts "  #{glyph} #{entry[:action][:type]}: #{entry[:action][:target]}"
                puts "    Error: #{entry[:error]}" if entry[:error]
              end
            end
            
            if final_result
              puts ""
              puts "Strict Rescan Digest: #{final_result[:plan_digest]}"
            end
            puts "=" * 50
          end
        end
      end
    end
  end
end
