# frozen_string_literal: true

require "json"
require_relative "../organisms/worktree_manager"
require_relative "../molecules/toolchain_truster"
require_relative "../molecules/bootstrap_executor"
require_relative "../molecules/config_loader"

module Ace
  module Git
    module Worktree
      module Commands
        # Bootstrap command
        #
        # Reruns recoverable preparation phases (toolchain trust and bootstrap policy)
        # for an existing worktree in place.
        class BootstrapCommand
          def initialize(manager: nil)
            @manager = manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          end

          # Run bootstrap retry on existing worktree
          #
          # @param args [Array<String>] Arguments including identifier and optional flags
          # @return [Integer] Exit code
          def run(args = [])
            options = parse_arguments(args)
            return show_help if options[:help] || options[:identifier].nil?

            worktree_info = find_target_worktree(options[:identifier])
            unless worktree_info
              puts "Error: Worktree matching '#{options[:identifier]}' not found."
              return 1
            end

            wt_path = worktree_info[:path]
            project_root = Dir.pwd
            config = Molecules::ConfigLoader.new(project_root).load_without_validation

            # Phase 1: Toolchain Trust
            truster = Molecules::ToolchainTruster.new(project_root: wt_path, policy: "required")
            trust_res = truster.verify_and_trust

            # Phase 2: Bootstrap execution
            executor = Molecules::BootstrapExecutor.new(
              project_root: project_root,
              worktree_path: wt_path,
              bootstrap_config: config.bootstrap,
              no_bootstrap: options[:no_bootstrap] || false
            )
            bootstrap_res = executor.run

            phases = [trust_res, bootstrap_res]

            req_failed = phases.any? { |p| p[:status] == "required_failed" }
            adv_failed = phases.any? { |p| p[:status] == "advisory_failed" }

            readiness = if req_failed
              "not_ready"
            elsif adv_failed
              "ready_with_warning"
            else
              "ready"
            end

            result = {
              identifier: options[:identifier],
              worktree_path: wt_path,
              branch: worktree_info[:branch],
              readiness: readiness,
              phases: phases,
              retry_command: (readiness == "not_ready") ? "ace-git-worktree bootstrap #{options[:identifier]}" : nil
            }

            if options[:json]
              puts JSON.pretty_generate(result)
            else
              puts "Worktree Preparation Retry: #{wt_path}"
              puts "Readiness: #{readiness}"
              puts
              puts "Phases:"
              phases.each do |p|
                st = p[:status]
                icon = case st
                       when "succeeded", "not_applicable" then "✓"
                       when "skipped" then "↷"
                       when "advisory_failed" then "⚠️"
                       else "❌"
                       end
                puts "  #{icon} #{p[:phase]}: #{st}"
                puts "    Command: #{p[:command]}" if p[:command]
                puts "    Output: #{p[:output]}" if p[:output] && !p[:output].empty? && st.include?("failed")
              end
              if readiness == "not_ready"
                puts
                puts "Retry with: ace-git-worktree bootstrap #{options[:identifier]}"
              end
            end

            (readiness == "not_ready") ? 1 : 0
          rescue => e
            puts "Error: #{e.message}"
            1
          end

          def show_help
            puts <<~HELP
              ace-git-worktree bootstrap - Rerun preparation phases on existing worktree

              USAGE:
                  ace-git-worktree bootstrap <identifier> [OPTIONS]

              OPTIONS:
                  --json                  Output format as JSON
                  --help, -h              Show this help message

              EXAMPLES:
                  ace-git-worktree bootstrap 081
                  ace-git-worktree bootstrap t.8vb.t.vyz.2 --json
            HELP
            0
          end

          private

          def parse_arguments(args)
            options = {identifier: nil, json: false, help: false}
            i = 0
            while i < args.length
              arg = args[i]
              case arg
              when "--json"
                options[:json] = true
              when "--help", "-h"
                options[:help] = true
              when /^--/
                raise ArgumentError, "Unknown option: #{arg}"
              else
                options[:identifier] = arg if options[:identifier].nil?
              end
              i += 1
            end
            options
          end

          def find_target_worktree(identifier)
            worktrees = @manager.list[:worktrees] || []
            worktrees.find do |wt|
              wt[:path]&.end_with?("/#{identifier}") ||
                wt[:path]&.include?("/t.#{identifier}") ||
                wt[:branch]&.include?(identifier) ||
                wt[:task_id] == identifier
            end
          end
        end
      end
    end
  end
end
