# frozen_string_literal: true

require "set"

module Ace
  module Overseer
    module Organisms
      # Derived "attention" view for `ace-overseer status` (L7.4).
      #
      # Pure interpretation over an existing StatusCollector source
      # snapshot plus the read-only HitlInbox molecule — no new fetchers,
      # no persisted state (ADR-034). It splits what needs the overseer's
      # decision into three explicit categories so trouble is never
      # mistaken for healthy progress:
      #   blockers     - startable tasks whose dependencies are not
      #                  satisfied (DependencyReadiness reasons), plus
      #                  tasks explicitly marked blocked
      #   failures     - source errors, failed/stalled assignments,
      #                  per-worktree probe errors, and escalations
      #                  (pending ace-hitl questions awaiting an answer)
      #   missing_data - disabled sources, unknown config keys,
      #                  unreadable task trees, unknown task statuses,
      #                  unknown executor states, hitl inbox unreachable
      # Missing data never confirms a free worktree or a finished task
      # (program contract).
      class StatusAttention
        # label over source key for the dependency-readable task trees
        TASK_TREES = {"project_tasks" => "project", "overseer_tree" => "_overseer"}.freeze
        # statuses whose tasks are candidates to start (or already held)
        BLOCKED_SCAN_STATUSES = %w[pending blocked].freeze
        FAILED_ASSIGNMENT_STATES = %w[failed stalled].freeze
        UNKNOWN_EXECUTOR_STATES = %w[unknown unparseable].freeze
        # Program contract: absence of data is never success — a disabled
        # source confirms neither a free worktree nor a finished task.
        BLIND_SPOT_NOTE = "source disabled: absence of its data does not confirm a free worktree or a finished task".freeze

        TaskEntry = Struct.new(:id, :status, :dependencies, :title)

        # @param hitl_events [Proc] -> Array<Hash> incoming ace-hitl
        #   events (the existing HitlInbox molecule, read-only)
        def initialize(hitl_events: default_hitl_events)
          @hitl_events = hitl_events
        end

        # @param snapshot [Hash] {sources:, unknown_keys:} as produced by
        #   StatusCollector#collect_sources
        # @return [Hash] {blockers:, failures:, missing_data:} rows
        def scan(snapshot)
          sources = snapshot.fetch(:sources, {})
          hitl_events, hitl_error = fetch_hitl_events

          {
            blockers: dependency_blockers(sources),
            failures: source_failures(sources) +
              assignment_failures(sources) +
              escalations(hitl_events, processed_report_ids(sources)),
            missing_data: missing_data(snapshot, sources, hitl_error)
          }
        end

        private

        # Report IDs the existing owner already recorded: ReportProcessor
        # writes processed_report on the step's metadata (through the
        # ace-task update surface), and the overseer-tree source carries
        # it. A report whose ID is recorded is processed — no second
        # registry, and no permanent "unprocessed" warning for work that
        # already happened.
        def processed_report_ids(sources)
          tree = sources["overseer_tree"]
          return [] unless tree && tree[:status] == "ok"

          Array(tree[:data]).filter_map { |row| row[:processed_report].to_s }.reject(&:empty?).to_set
        end

        def default_hitl_events
          -> { Molecules::HitlInbox.new.incoming_events }
        end

        def fetch_hitl_events
          [@hitl_events.call, nil]
        rescue StandardError => e
          [[], "#{e.class}: #{e.message}"]
        end

        def tree_entries(sources)
          TASK_TREES.filter_map { |key, label| [label, task_entries(sources, key)] }
        end

        def task_entries(sources, key)
          result = sources[key]
          return [] unless result && result[:status] == "ok"

          Array(result[:data]).filter_map do |hash|
            next if hash[:id].to_s.empty?
            # Provenance: the project source lists EVERY folder
            # (in_folder: "all"), so special-folder entries (e.g.
            # _overseer, _archive) do not belong to the "project" tree —
            # keep them out to avoid duplicated/mislabeled rows. The
            # private-tree source stamps its own special_folder.
            next if key == "project_tasks" && !hash[:special_folder].to_s.empty?

            TaskEntry.new(hash[:id].to_s, hash[:status].to_s, Array(hash[:dependencies]), hash[:title].to_s)
          end
        end

        def dependency_blockers(sources)
          trees = tree_entries(sources)
          lookup = trees.each_with_object({}) do |(_, entries), map|
            entries.each { |entry| map[entry.id] = entry }
          end

          trees.flat_map do |label, entries|
            entries.filter_map do |entry|
              next unless BLOCKED_SCAN_STATUSES.include?(entry.status)

              verdict = Atoms::DependencyReadiness.check(entry, lookup: ->(ref) { lookup[ref] })
              reasons = Array(verdict[:reasons])
              next if reasons.empty? && entry.status != "blocked"

              reasons = ["marked blocked in the #{label} tree; dependencies satisfied"] if reasons.empty?
              {
                kind: "dependency",
                tree: label,
                task_id: entry.id,
                title: entry.title,
                reasons: reasons,
                next_action: "unblock the predecessor(s), then start or continue #{entry.id}"
              }
            end
          end
        end

        def source_failures(sources)
          sources.filter_map do |key, result|
            next unless result[:status] == "error"

            {
              kind: "source_error",
              subject: key,
              origin: result[:origin],
              detail: result[:error],
              next_action: "repair the '#{key}' source (#{result[:origin]}); until then its data is unavailable, not empty"
            }
          end
        end

        def assignment_failures(sources)
          coworkers = sources["coworkers"]
          return [] unless coworkers && coworkers[:status] == "ok"

          Array(coworkers[:data]).flat_map do |row|
            rows = []
            if row[:error]
              rows << {
                kind: "probe_error",
                subject: row[:worktree],
                detail: row[:error],
                next_action: "inspect executor state in '#{row[:worktree]}' manually; the probe cannot read it"
              }
            end
            Array(row[:assignments]).each do |assignment|
              state = assignment["state"].to_s
              next unless FAILED_ASSIGNMENT_STATES.include?(state)

              rows << {
                kind: "#{state}_assignment",
                subject: assignment["id"].to_s,
                worktree: row[:worktree],
                detail: "assignment #{assignment['id']} is #{state} in #{row[:worktree]}",
                next_action: "read the report for assignment #{assignment['id']} and decide retry or repair"
              }
            end
            rows
          end
        end

        def escalations(hitl_events, processed_ids = Set.new)
          Array(hitl_events).filter_map do |event|
            case event["type"]
            when "question"
              {
                kind: "escalation",
                subject: event["id"],
                task: event["task"],
                assignment: event["assignment"],
                detail: event["title"].to_s,
                next_action: "answer question #{event['id']} via ace-hitl"
              }
            when "report"
              # Unprocessed incoming reports equally wait on the overseer
              # (process-reports is the consumer); surface them instead of
              # leaving them invisible next to healthy progress. A report
              # whose ID the owner already recorded on a step is
              # processed — it is not re-surfaced as pending work.
              next if processed_ids.include?(event["id"].to_s)

              {
                kind: "unprocessed_report",
                subject: event["id"],
                task: event["task"],
                assignment: event["assignment"],
                detail: event["title"].to_s,
                next_action: "run ace-overseer process-reports to interpret report #{event['id']}"
              }
            end
          end
        end

        def missing_data(snapshot, sources, hitl_error)
          rows = disabled_source_rows(sources) +
            unknown_config_rows(snapshot[:unknown_keys]) +
            unverified_tree_rows(sources) +
            unknown_task_status_rows(sources) +
            unknown_executor_rows(sources)
          rows << hitl_row(hitl_error) if hitl_error
          rows
        end

        def disabled_source_rows(sources)
          sources.filter_map do |key, result|
            next unless result[:status] == "disabled"

            {
              kind: "source_disabled",
              subject: key,
              detail: BLIND_SPOT_NOTE,
              next_action: "enable '#{key}' under status_sources or accept that its view stays unknown"
            }
          end
        end

        def unknown_config_rows(keys)
          Array(keys).map do |key|
            {
              kind: "unknown_config",
              subject: key,
              detail: "status_sources key '#{key}' is unknown and ignored",
              next_action: "fix the status_sources configuration so it is respected"
            }
          end
        end

        # An errored task tree means dependency readiness of its tasks is
        # unverified — that gap stays explicit instead of reading as
        # "no blockers".
        def unverified_tree_rows(sources)
          TASK_TREES.filter_map do |key, label|
            result = sources[key]
            next unless result && result[:status] == "error"

            {
              kind: "tree_unverified",
              subject: key,
              detail: "#{label} task tree unreadable: dependency readiness of its tasks is unverified",
              next_action: "restore the '#{key}' source before trusting readiness of #{label} tasks"
            }
          end
        end

        def unknown_task_status_rows(sources)
          tree_entries(sources).flat_map do |label, entries|
            entries.filter_map do |entry|
              next if entry.status.empty? || Ace::Task::Atoms::TaskValidationRules.valid_status?(entry.status)

              {
                kind: "unknown_task_status",
                subject: entry.id,
                detail: "task #{entry.id} in the #{label} tree has unrecognized status '#{entry.status}'",
                next_action: "correct the status of #{entry.id} via ace-task"
              }
            end
          end
        end

        def unknown_executor_rows(sources)
          coworkers = sources["coworkers"]
          return [] unless coworkers && coworkers[:status] == "ok"

          Array(coworkers[:data]).filter_map do |row|
            next if row[:error]

            state = row[:evidence].is_a?(Hash) ? row[:evidence]["state"].to_s : ""
            next unless UNKNOWN_EXECUTOR_STATES.include?(state)

            {
              kind: "unknown_executor",
              subject: row[:worktree],
              detail: "executor state '#{state}' in #{row[:worktree]}: the worktree cannot be treated as free",
              next_action: "inspect the coworker config in '#{row[:worktree]}'; treat the worktree as busy meanwhile"
            }
          end
        end

        def hitl_row(error)
          {
            kind: "hitl_unavailable",
            subject: "ace-hitl inbox",
            detail: "pending questions unverified: #{error}",
            next_action: "check the ace-hitl event files (.ace-local/hitl) and retry"
          }
        end
      end
    end
  end
end
