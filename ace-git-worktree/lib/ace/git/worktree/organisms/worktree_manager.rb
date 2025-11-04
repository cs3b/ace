# frozen_string_literal: true

require_relative "task_worktree_orchestrator"
require_relative "../molecules/worktree_creator"
require_relative "../molecules/worktree_lister"
require_relative "../molecules/worktree_remover"
require_relative "../molecules/mise_trustor"
require_relative "../atoms/slug_generator"
require_relative "../atoms/path_expander"

module Ace
  module Git
    module Worktree
      module Organisms
        # Manages all worktree operations (task-aware and traditional)
        class WorktreeManager
          attr_reader :config, :task_orchestrator

          def initialize(config = nil)
            @config = config || Worktree.configuration
            @task_orchestrator = TaskWorktreeOrchestrator.new(@config)
          end

          # Create a worktree (task-aware or traditional)
          # @param identifier [String] Task ID or branch name
          # @param options [Hash] Options
          # @return [Hash] Result
          def create(identifier = nil, options = {})
            # If --task flag is used, delegate to task orchestrator
            if options[:task]
              task_ref = options[:task] == true ? identifier : options[:task]

              if options[:dry_run]
                @task_orchestrator.dry_run(task_ref, options)
              else
                @task_orchestrator.create_task_worktree(task_ref, options)
              end
            else
              # Traditional worktree creation
              create_traditional(identifier, options)
            end
          end

          # Create a traditional worktree (non-task)
          # @param branch [String] Branch name
          # @param options [Hash] Options
          # @return [Hash] Result
          def create_traditional(branch, options = {})
            return error_result("Branch name required") if branch.nil? || branch.empty?

            # Determine path
            path = if options[:path]
                    options[:path]
                  else
                    # Use configured root path
                    File.join(@config.root_path, branch)
                  end

            # Dry run
            if options[:dry_run]
              return {
                success: true,
                dry_run: true,
                would_create: {
                  directory: path,
                  branch: branch,
                  mise_trust: should_trust_mise?(options)
                }
              }
            end

            # Create the worktree
            result = Molecules::WorktreeCreator.create(
              path: path,
              branch: branch,
              create_branch: options[:create_branch] != false,
              timeout: @config.git_timeout
            )

            return result unless result[:success]

            # Trust mise if configured
            if should_trust_mise?(options)
              mise_result = Molecules::MiseTrustor.trust(result[:path])
              if mise_result[:warning]
                result[:warnings] ||= []
                result[:warnings] << mise_result[:output]
              end
            end

            # Format output
            {
              success: true,
              path: result[:path],
              branch: branch,
              outputs: {
                absolute_path: File.expand_path(result[:path]),
                relative_path: path
              }
            }.merge(result.slice(:warnings))
          end

          # List all worktrees
          # @param options [Hash] Options
          # @return [Hash] Result with list of worktrees
          def list(options = {})
            worktrees = Molecules::WorktreeLister.list(
              include_tasks: options[:show_tasks],
              config: @config
            )

            format_list_output(worktrees, options)
          end

          # Switch to a worktree
          # @param identifier [String] Worktree identifier
          # @return [Hash] Result with path
          def switch(identifier)
            return error_result("Identifier required") if identifier.nil? || identifier.empty?

            worktree = Molecules::WorktreeLister.find(identifier)

            if worktree
              {
                success: true,
                path: worktree.absolute_path,
                branch: worktree.branch
              }
            else
              error_result("Worktree not found: #{identifier}")
            end
          end

          # Remove a worktree
          # @param identifier [String] Worktree identifier
          # @param options [Hash] Options
          # @return [Hash] Result
          def remove(identifier, options = {})
            Molecules::WorktreeRemover.remove(identifier, options)
          end

          # Prune deleted worktrees
          # @return [Hash] Result
          def prune
            Molecules::WorktreeRemover.prune
          end

          # Display current configuration
          # @return [Hash] Configuration
          def show_config
            {
              success: true,
              configuration: @config.to_h
            }
          end

          private

          def error_result(message)
            {
              success: false,
              error: message
            }
          end

          def should_trust_mise?(options)
            return false if options[:no_mise_trust]
            @config.mise_trust_auto
          end

          def format_list_output(worktrees, options)
            format = options[:format] || @config.default_output_format || "table"

            case format
            when "json"
              format_json_output(worktrees)
            else
              format_table_output(worktrees, options)
            end
          end

          def format_json_output(worktrees)
            {
              success: true,
              worktrees: worktrees.map(&:to_json_h)
            }
          end

          def format_table_output(worktrees, options)
            if worktrees.empty?
              return {
                success: true,
                output: "No worktrees found"
              }
            end

            # Build table
            headers = ["DIRECTORY", "BRANCH"]
            headers << "TASK" if options[:show_tasks]

            rows = worktrees.map do |wt|
              row = [wt.directory, wt.branch]
              row << (wt.task_id || "-") if options[:show_tasks]
              row
            end

            # Simple table formatting
            col_widths = headers.each_with_index.map do |header, i|
              [header.length, *rows.map { |r| r[i].to_s.length }].max
            end

            output = []

            # Headers
            header_line = headers.each_with_index.map { |h, i| h.ljust(col_widths[i]) }.join("  ")
            output << header_line

            # Separator
            output << header_line.gsub(/[^  ]/, "-")

            # Rows
            rows.each do |row|
              output << row.each_with_index.map { |cell, i| cell.to_s.ljust(col_widths[i]) }.join("  ")
            end

            {
              success: true,
              output: output.join("\n"),
              count: worktrees.size
            }
          end
        end
      end
    end
  end
end