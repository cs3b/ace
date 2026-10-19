# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Overseer
    module Organisms
      class StatusCollector
        # Display/aggregation order of the configurable status sources.
        STATUS_SOURCE_ORDER = %w[worktrees forge project_tasks overseer_tree herdr coworkers].freeze

        def initialize(worktree_manager: nil, context_collector: nil, project_root: nil, config: nil,
          sources: nil)
          @worktree_manager = worktree_manager || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @context_collector = context_collector || Molecules::WorktreeContextCollector.new
          @project_root = project_root
          @config = config
          @sources = sources
        end

        # Aggregate the configurable status sources (L7.2). Each enabled
        # source contributes {status: "ok", origin:, data:}; a disabled
        # source {status: "disabled"}; a failing source {status: "error",
        # origin:, error:} — rendered next to the healthy results, never
        # mistaken for empty data. Read-only, computed live, nothing
        # persisted (ADR-034).
        def collect_sources
          source_map = @sources || default_sources
          configured = status_sources_config

          results = STATUS_SOURCE_ORDER.to_h do |key|
            source = source_map[key]
            [key, source_result(source, configured[key])]
          end
          {sources: results}
        end

        def to_sources_h(snapshot)
          {sources: snapshot[:sources]}
        end

        def to_sources_table(snapshot)
          STATUS_SOURCE_ORDER.filter_map do |key|
            render_source_section(key, snapshot[:sources][key])
          end.join("\n\n")
        end

        def collect
          result = @worktree_manager.list_all
          raise Error, result[:error] || "Failed to list worktrees" unless result[:success]

          all_worktrees = Array(result[:worktrees]).reject(&:bare)
          # Exclude main worktree (handled separately via collect_main_context)
          main_root = @project_root || resolve_project_root
          non_main = all_worktrees.reject { |wt| main_root && wt.path == main_root }

          contexts = collect_contexts_parallel(non_main)

          # Keep task worktrees always; non-task worktrees only if they have assignments
          contexts.select! { |ctx| ctx.task_id != "unknown" || ctx.assignments.any? }

          main_context = collect_main_context
          contexts.unshift(main_context) if main_context && main_context.assignments.any?

          {
            contexts: contexts
          }
        end

        def collect_quick(previous_snapshot)
          previous_contexts = previous_snapshot[:contexts]
          return collect if previous_contexts.nil? || previous_contexts.empty?

          contexts = previous_contexts.map do |prev_ctx|
            @context_collector.collect_assignments_only(
              prev_ctx.worktree_path,
              cached_branch: prev_ctx.branch,
              cached_git_status: prev_ctx.git_status,
              location_type: prev_ctx.location_type
            )
          rescue
            nil
          end.compact

          {contexts: contexts}
        end

        def to_table(snapshot)
          Atoms::StatusFormatter.format_dashboard(snapshot[:contexts])
        end

        def to_h(snapshot)
          {
            worktrees: snapshot[:contexts].map { |context| context_to_h(context) }
          }
        end

        private

        def source_result(source, options)
          return {status: "disabled"} if source.nil? || options.is_a?(Hash) && options["enabled"] == false

          begin
            {status: "ok", origin: source.origin, data: source.fetch}
          rescue StandardError => e
            {status: "error", origin: source.origin, error: "#{e.class}: #{e.message}"}
          end
        end

        def status_sources_config
          config = @config || Ace::Overseer.config
          configured = config["status_sources"]
          configured.is_a?(Hash) ? configured : {}
        end

        def default_sources
          {
            "worktrees" => StatusSources::WorktreesSource.new(collector: self),
            "forge" => StatusSources::ForgeSource.new(config: status_sources_config["forge"] || {}),
            "project_tasks" => StatusSources::ProjectTasksSource.new,
            "overseer_tree" => StatusSources::OverseerTreeSource.new,
            "herdr" => StatusSources::HerdrSource.new,
            "coworkers" => StatusSources::CoworkersSource.new(worktree_manager: @worktree_manager)
          }
        end

        def render_source_section(key, result)
          header = "-- #{key}"
          case result[:status]
          when "disabled"
            "#{header}: disabled"
          when "error"
            "#{header} [#{result[:origin]}]: ERROR #{result[:error]}"
          else
            "#{header} [#{result[:origin]}]\n#{render_source_data(key, result[:data])}"
          end
        end

        def render_source_data(key, data)
          case key
          when "worktrees" then Atoms::StatusFormatter.format_dashboard(
            data[:worktrees].map { |entry| context_from_h(entry) }
          )
          when "project_tasks", "overseer_tree" then format_task_rows(data)
          when "forge" then format_forge_rows(data)
          when "herdr" then format_herdr_tree(data)
          when "coworkers" then format_coworker_rows(data)
          else data.inspect
          end
        end

        # Rebuild a minimal WorkContext for the shared dashboard formatter
        # (rendering only; the JSON payload stays the serialized form).
        def context_from_h(entry)
          Models::WorkContext.new(
            task_id: entry[:task_id],
            worktree_path: entry[:worktree_path],
            branch: entry[:branch],
            assignments: entry[:assignments],
            git_status: entry[:git]
          )
        end

        def format_task_rows(tasks)
          return "(no tasks)" if tasks.empty?

          tasks.map do |task|
            line = "#{task[:id]}  #{task[:status]}  #{task[:title]}"
            deps = task[:dependencies]
            line += "  [deps: #{deps.join(", ")}]" if deps.is_a?(Array) && deps.any?
            line
          end.join("\n")
        end

        def format_forge_rows(pull_requests)
          return "(no recent pull requests)" if pull_requests.empty?

          pull_requests.map do |pr|
            draft = pr[:draft] ? " draft" : ""
            "##{pr[:number]}  #{pr[:state]}#{draft}  #{pr[:title]}  (#{pr[:head_ref]})"
          end.join("\n")
        end

        def format_herdr_tree(tree)
          workspaces = tree[:workspaces]
          return "(no live herdr workspaces)" if workspaces.empty?

          lines = ["#{workspaces.length} workspace(s), " \
            "#{workspaces.sum { |ws| ws[:tab_count] }} tab(s), " \
            "#{workspaces.sum { |ws| ws[:pane_count] }} pane(s)"]
          workspaces.each do |ws|
            lines << "  #{ws[:id]}  #{ws[:title]}  (#{ws[:tab_count]} tab(s))"
            ws[:tabs].each do |tab|
              lines << "    #{tab[:id]}  #{tab[:title]}  (#{tab[:pane_count]} pane(s))"
              tab[:panes].each do |pane|
                lines << "      #{pane[:id]}  #{pane[:title]}"
              end
            end
          end
          lines.join("\n")
        end

        def format_coworker_rows(rows)
          return "(no worktrees)" if rows.empty?

          rows.map do |row|
            if row[:error]
              "#{row[:worktree]}  ERROR #{row[:error]}"
            elsif row[:active]
              evidence = row[:evidence] || {}
              "#{row[:worktree]}  busy (#{evidence["assignment"]} #{evidence["state"]}, #{evidence["source"]})"
            else
              "#{row[:worktree]}  no active executor"
            end
          end.join("\n")
        end

        def collect_main_context
          root = @project_root || resolve_project_root
          return nil unless root

          @context_collector.collect(root, location_type: :main)
        rescue
          nil
        end

        def resolve_project_root
          stdout, status = Open3.capture2(
            "git", "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          return nil unless status.success?

          common_dir = stdout.to_s.strip
          return nil if common_dir.empty?

          File.dirname(common_dir)
        rescue
          nil
        end

        # Collect worktree contexts in parallel for ~Nx speedup
        # Each worktree involves GitHub API calls (~1s each), so parallelizing
        # reduces total time from N seconds to ~1-2 seconds
        #
        # Uses subprocess isolation (fork + exec) because Dir.chdir is process-global
        # and cannot be safely used in threads. Each subprocess runs context collection
        # independently, avoiding race conditions.
        def collect_contexts_parallel(worktrees)
          return [] if worktrees.empty?

          # For single worktree, skip subprocess overhead
          return [@context_collector.collect(worktrees.first.path)] if worktrees.size == 1

          # Build the worker script that collects context for a single worktree
          worker_script = <<~RUBY
            # frozen_string_literal: true
            require "ace/overseer"
            require "json"

            worktree_path = ARGV[0]
            collector = Ace::Overseer::Molecules::WorktreeContextCollector.new
            context = collector.collect(worktree_path)

            # Serialize for IPC
            puts JSON.generate({
              task_id: context.task_id,
              worktree_path: context.worktree_path,
              branch: context.branch,
              assignments: context.assignments,
              git_status: context.git_status
            })
          RUBY

          # Spawn parallel subprocesses
          pipes = worktrees.map do |worktree|
            pipe_read, pipe_write = IO.pipe
            pid = fork do
              pipe_read.close
              $stdout.reopen(pipe_write)
              pipe_write.close
              exec("ruby", "-e", worker_script, worktree.path.to_s)
              exit!(1) # unreachable unless exec fails
            end
            pipe_write.close
            {pid: pid, pipe: pipe_read, worktree: worktree}
          end

          # Collect results, preserving order
          contexts = Array.new(worktrees.size)
          pipes.each_with_index do |p, idx|
            output = p[:pipe].read
            p[:pipe].close
            Process.wait(p[:pid])

            if $?.success? && !output.empty?
              data = JSON.parse(output)
              contexts[idx] = Models::WorkContext.new(
                task_id: data["task_id"],
                worktree_path: data["worktree_path"],
                branch: data["branch"],
                assignments: data["assignments"] || [],
                git_status: data["git_status"]
              )
            end
          end

          contexts.compact
        end

        def context_to_h(context)
          {
            task_id: context.task_id,
            worktree_path: context.worktree_path,
            branch: context.branch,
            assignments: context.assignments,
            git: context.git_status
          }
        end
      end
    end
  end
end
