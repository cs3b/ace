# frozen_string_literal: true

require "json"
require "time"
require_relative "../atoms/duration_parser"
require_relative "../molecules/worktree_lister"
require_relative "../molecules/task_index_builder"
require_relative "../molecules/task_association_resolver"
require_relative "../molecules/pr_status_resolver"
require_relative "../molecules/recent_branch_counter"
require_relative "../molecules/worktree_table_formatter"
require_relative "../molecules/worktree_footer_formatter"
require_relative "worktree_probe_runner"

module Ace
  module Git
    module Worktree
      module Organisms
        # Builds the `ace-git-worktree list` report end to end.
        #
        # Pipeline: inventory worktrees once -> build the `.ace-tasks/` index
        # once -> fork-probe every worktree -> resolve task association ->
        # classify activity from one clock snapshot -> resolve PRs (one bounded
        # query) -> apply filters -> split active/inactive -> render.
        #
        # The report owns all ordering, clock reads, filtering, and rendering;
        # probe children only report raw signals.
        class WorktreeListReport
          # @param lister [Molecules::WorktreeLister, nil]
          # @param task_index_builder [Molecules::TaskIndexBuilder, nil]
          # @param probe_runner [Organisms::WorktreeProbeRunner, nil] injectable
          # @param pr_resolver [Molecules::PrStatusResolver, nil] injectable
          # @param branch_counter [Molecules::RecentBranchCounter, nil] injectable
          # @param clock [Proc, nil] injectable clock (`-> { Time }`) for tests
          # @param clock [Proc, nil]
          # @param project_root [String, nil]
          # @param env [Hash]
          # @param stdout [IO]
          def initialize(lister: nil, task_index_builder: nil, probe_runner: nil, pr_resolver: nil,
            branch_counter: nil, clock: nil, project_root: nil, env: ENV, stdout: $stdout)
            @lister = lister || Molecules::WorktreeLister.new
            @task_index_builder = task_index_builder
            @probe_runner = probe_runner
            @pr_resolver = pr_resolver
            @branch_counter = branch_counter
            @clock = clock
            @project_root = project_root
            @env = env
            @stdout = stdout
          end

          # Run the report.
          #
          # @param options [Hash] parsed list options
          # @return [Hash] `{success:, output:, worktrees:, statistics:}`
          def run(options = {})
            options = normalize_options(options)
            inventory = @lister.inventory
            unless inventory[:success]
              return {success: false, error: inventory[:error], worktrees: [], statistics: {}}
            end

            raw_worktrees = inventory[:worktrees]
            now = (@clock ? @clock.call : Time.now)
            task_index = build_task_index
            project_root = task_index.project_root || @project_root

            probes = probe_worktrees(raw_worktrees, project_root)
            enriched = enrich(raw_worktrees, probes, task_index, now, options)
            selected = apply_filters(enriched, options)
            active, inactive = selected.partition { |worktree| worktree.active_within_window }

            statistics = build_statistics(selected, active, inactive, now, options, raw_worktrees)
            output = render(selected, active, inactive, statistics, options)

            {
              success: true,
              output: output,
              worktrees: selected,
              statistics: statistics
            }
          end

          private

          def normalize_options(options)
            window = options[:active_within]
            window = Atoms::DurationParser.parse(window) if window.is_a?(String)
            window ||= Atoms::DurationParser.default
            options.merge(
              format: (options[:format] || :table).to_sym,
              window_hours: window[:hours],
              window_label: window[:label],
              full: options[:full] ? true : false,
              quiet: options[:quiet] ? true : false
            )
          end

          def build_task_index
            if @task_index_builder
              @task_index_builder.build
            else
              Molecules::TaskIndexBuilder.new(project_root: @project_root).build
            end
          end

          def probe_worktrees(raw_worktrees, project_root)
            runner = @probe_runner || WorktreeProbeRunner.new(
              project_root: project_root,
              base_ref: raw_worktrees.first&.commit
            )
            runner.run(raw_worktrees)
          end

          def enrich(raw_worktrees, probes, task_index, now, options)
            resolver = Molecules::TaskAssociationResolver.new(task_index: task_index)
            pr_resolver = @pr_resolver || Molecules::PrStatusResolver.new

            raw_worktrees.each_with_index.map do |worktree, index|
              probe = probes[index]
              associated = resolver.resolve(worktree, probe)
              last_commit = last_commit_hash(probe, now)
              uncommitted = uncommitted_hash(probe)
              active = active_worktree?(worktree, probe, options[:window_hours], now)
              pr = pr_resolver.resolve(associated, associated.task_id)

              associated.with_enrichment(
                last_commit: last_commit,
                uncommitted: uncommitted,
                active_within_window: active,
                pr: pr,
                probe_error: probe.nil?
              )
            end
          end

          def last_commit_hash(probe, now)
            return nil if probe.nil? || probe[:head_sha].nil?

            committed_at = Time.at(probe[:head_committer_epoch].to_i).utc
            {
              sha: probe[:head_sha],
              age_hours: ((now - committed_at) / 3600.0).round(2),
              committed_at: committed_at.iso8601,
              subject: probe[:head_subject].to_s
            }
          end

          def uncommitted_hash(probe)
            return nil if probe.nil?

            staged = probe[:staged].to_i
            unstaged = probe[:unstaged].to_i
            untracked = probe[:untracked].to_i
            total = staged + unstaged + untracked
            return nil unless total.positive?

            {staged: staged, unstaged: unstaged, untracked: untracked, total: total}
          end

          # A worktree is active inside the window when its HEAD commit is in
          # the window or it has uncommitted changes. Bare worktrees are never
          # active; probe failures classify as inactive.
          def active_worktree?(worktree, probe, window_hours, now)
            return false if worktree.bare || probe.nil?

            committed_at = probe[:head_committer_epoch]
            recent_commit = committed_at && now.to_i - committed_at.to_i <= (window_hours * 3600).to_i
            dirty = uncommitted_hash(probe)
            recent_commit || !dirty.nil?
          end

          def apply_filters(worktrees, options)
            filtered = Array(worktrees)

            if options[:task_associated] == true
              filtered = filtered.select { |worktree| worktree.task_associated? }
            elsif options[:task_associated] == false
              filtered = filtered.reject { |worktree| worktree.task_associated? }
            end

            if options[:usable] == true
              filtered = filtered.select(&:usable?)
            elsif options[:usable] == false
              filtered = filtered.reject(&:usable?)
            end

            if options[:search] && !options[:search].to_s.empty?
              pattern = Regexp.new(options[:search].to_s, Regexp::IGNORECASE)
              filtered = filtered.select { |worktree| worktree.branch&.match?(pattern) }
            end

            filtered
          end

          def build_statistics(selected, active, inactive, now, options, raw_worktrees)
            {
              total: selected.length,
              active: active.length,
              inactive: inactive.length,
              task_associated: selected.count(&:task_associated?),
              usable: selected.count(&:usable?),
              recent_branches: recent_branch_count(raw_worktrees, now, options),
              window_hours: options[:window_hours],
              window_label: options[:window_label]
            }
          end

          # Branch-based count; worktree filters never change it, so checkout
          # exclusions use the complete inventory.
          def recent_branch_count(raw_worktrees, now, options)
            if @branch_counter
              @branch_counter.call(worktrees: raw_worktrees, window_hours: options[:window_hours], now: now)
            else
              Molecules::RecentBranchCounter.new(
                worktrees: raw_worktrees, window_hours: options[:window_hours], now: now
              ).count
            end
          end

          # --- Rendering ---

          def render(selected, active, inactive, statistics, options)
            case options[:format]
            when :json
              render_json(selected)
            when :simple
              render_simple(selected)
            else
              render_table(active, inactive, statistics, options)
            end
          end

          def render_json(worktrees)
            JSON.generate(worktrees.map(&:to_h))
          end

          def render_simple(worktrees)
            @lister.format_for_display(worktrees, :simple)
          end

          def render_table(active, inactive, statistics, options)
            footer = Molecules::WorktreeFooterFormatter.new(
              window_label: statistics[:window_label],
              full: options[:full]
            )
            table = Molecules::WorktreeTableFormatter.new(env: @env, full: options[:full], stdout: @stdout)

            lines = [footer.header(active_count: active.length, total_count: statistics[:total])]

            if statistics[:total].zero?
              return "No worktrees found."
            end

            rows = options[:full] ? (active + inactive) : active
            if rows.empty?
              lines << footer.no_active_message
            else
              lines.concat(table.render(rows))
            end

            unless options[:quiet]
              lines << ""
              lines.concat(footer.lines(
                inactive: inactive.length,
                task_associated: statistics[:task_associated],
                usable: statistics[:usable],
                recent_branches: statistics[:recent_branches]
              ))
            end

            lines.join("\n")
          end
        end
      end
    end
  end
end
