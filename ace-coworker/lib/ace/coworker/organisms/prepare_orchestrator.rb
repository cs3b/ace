# frozen_string_literal: true

require_relative "../molecules/project_root"
require_relative "../molecules/task_probe"
require_relative "../molecules/config_loader"
require_relative "../molecules/worktree_provision_probe"
require_relative "../molecules/worktree_executor_probe"
require_relative "../molecules/role_sequence_composer"
require_relative "../molecules/hitl_reporter"
require_relative "../atoms/active_executor_rule"

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker prepare`: the planner accepts a
      # preparation commission (task + expected role sequence), finds or
      # prepares exactly one proper worktree for that task, and composes
      # the role-sequence assignments for the WHOLE sequence in one go
      # (L4.2), so roles hand off sequentially after start without the
      # overseer re-commissioning preparation per step. Re-preparation
      # reuses the existing worktree and the already-composed assignments
      # with zero redundant writes; an active executor or a mismatched
      # worktree escalates to the overseer via ace-hitl instead of
      # overwriting work. dry_run: performs the full resolution and
      # conflict detection with zero effects (assignments are planned, not
      # written, because the worktree does not exist yet).
      class PrepareOrchestrator
        DISPOSITIONS = {
          created: "created", recovered: "recovered", reuse: "reused",
          would_create: "would_create", would_recover: "would_recover"
        }.freeze

        def initialize(project_root: nil, task_probe: nil, provision_probe: nil,
          executor_probe: nil, hitl_reporter: nil, config_loader: nil, config: nil,
          sequence_composer: nil)
          @config = config || Ace::Coworker.config
          @project_root = project_root || Molecules::ProjectRoot.new.resolve
          @task_probe = task_probe || Molecules::TaskProbe.new(project_root: @project_root)
          @provision_probe = provision_probe || Molecules::WorktreeProvisionProbe.new(project_root: @project_root)
          @executor_probe = executor_probe || Molecules::WorktreeExecutorProbe.new(project_root: @project_root)
          @hitl_reporter = hitl_reporter || Molecules::HitlReporter.new(project_root: @project_root)
          @config_loader = config_loader ||
            Molecules::ConfigLoader.new(project_root: @project_root, defaults: @config)
          @sequence_composer = sequence_composer
        end

        # @param task_ref [String] task reference
        # @param roles [Array<String>] expected role sequence (already
        #   normalized: non-blank, deduplicated, order preserved)
        # @param to [String, nil] escalation recipient override
        # @param config_path [String, nil] explicit planner config path
        # @param dry_run [Boolean] suppress all effects
        # @return [Models::Preparation]
        # @raise [Error] for an unresolvable task or an operational failure
        def call(task_ref:, roles:, to: nil, config_path: nil, dry_run: false)
          task = @task_probe.resolve(task_ref)
          raise Error, "task '#{task_ref}' not found in this worktree" if task.nil?

          task_path = task.respond_to?(:path) && task.path ? task.path : task.id.to_s
          task_id = task.id.to_s

          decision = @provision_probe.ensure_prepared(
            task_ref: task_ref, expected_task_id: task_id, dry_run: dry_run)
          return conflict_result(task: task_id, task_path: task_path, roles: roles,
            kind: "mismatched_worktree", detail: decision[:reason],
            worktree_path: decision[:worktree_path], to: to,
            config_path: config_path, dry_run: dry_run) if decision[:disposition] == :conflict_mismatch
          if decision[:disposition] == :error
            raise Error, "cannot prepare worktree for task '#{task_ref}': #{decision[:reason]}"
          end

          disposition = DISPOSITIONS.fetch(decision[:disposition])
          return success(task: task_id, task_path: task_path, roles: roles,
            disposition: disposition, worktree_path: decision[:worktree_path],
            branch: decision[:branch], assignments: [], dry_run: dry_run) if would_disposition?(disposition)

          executor = @executor_probe.probe(decision[:worktree_path])
          rule = Atoms::ActiveExecutorRule.evaluate(
            config: executor[:config], assignments: executor[:assignments])
          if rule[:active]
            return conflict_result(task: task_id, task_path: task_path, roles: roles,
              kind: "active_executor", detail: active_detail(rule),
              worktree_path: decision[:worktree_path], to: to,
              config_path: config_path, dry_run: dry_run,
              assignments: executor[:assignments], active_executor: rule[:evidence])
          end

          sequence = compose_sequence(task_id, roles, decision[:worktree_path])
          success(task: task_id, task_path: task_path, roles: roles,
            disposition: disposition, worktree_path: decision[:worktree_path],
            branch: decision[:branch], assignments: sequence,
            worktree_assignments: executor[:assignments],
            dry_run: dry_run)
        end

        private

        # Composes the whole role sequence in one go via ace-assign's plan
        # storage in the prepared worktree. A missing role process is
        # reported (Error) — never substituted with another role's.
        def compose_sequence(task_id, roles, worktree_path)
          composer = @sequence_composer || Molecules::RoleSequenceComposer.new(project_root: worktree_path)
          composer.call(task: task_id, roles: roles)
        end

        def would_disposition?(disposition)
          %w[would_create would_recover].include?(disposition)
        end

        def active_detail(rule)
          evidence = rule[:evidence]
          if evidence["source"] == "config"
            "a commissioned executor holds the worktree: assignment #{evidence['assignment']} " \
              "(state #{evidence['state']})"
          else
            "an uncommissioned assignment is in flight: #{evidence['assignment']} " \
              "(state #{evidence['state']})"
          end
        end

        def conflict_result(task:, task_path:, roles:, kind:, detail:, worktree_path:,
          to:, config_path:, dry_run:, assignments: [], active_executor: nil)
          hitl_event = nil
          delivered = nil
          recipient, recipient_note = escalation_recipient(to: to, config_path: config_path)
          detail = detail.dup

          unless dry_run
            if recipient.to_s.strip.empty?
              detail << "\ncannot report conflict: no overseer address (--to or coworker config)"
              detail << "\n#{recipient_note}" if recipient_note
            else
              begin
                result = @hitl_reporter.create_conflict(
                  title: "Preparation conflict - #{task}/#{worktree_dir(worktree_path)}",
                  question_lines: conflict_question(kind: kind, detail: detail, worktree_path: worktree_path),
                  task: task, to: recipient)
                if result.is_a?(Molecules::HitlReporter::Failure)
                  detail << "\ncannot report conflict: #{result.message}"
                else
                  hitl_event = result
                  delivered = @hitl_reporter.send_report(hitl_event) == true
                end
              rescue Error => e
                # e.g. the ace-hitl binary is missing: keep the structured
                # conflict visible instead of replacing it with a bare error.
                detail << "\ncannot report conflict: #{e.message}"
              end
            end
          end

          Models::Preparation.new(task: task, task_path: task_path, roles: roles,
            worktree: nil, worktree_assignments: assignments,
            active_executor: active_executor,
            conflict: {"kind" => kind, "detail" => detail,
                       "hitl_event" => hitl_event, "delivered" => delivered},
            dry_run: dry_run)
        end

        def conflict_question(kind:, detail:, worktree_path:)
          [
            "kind: #{kind}",
            detail,
            "worktree preserved at #{worktree_path} - decide whether to resume, " \
              "reassign, or remove it before re-preparing"
          ]
        end

        # Resolves the escalation recipient: the --to override, else the
        # coworker config's overseer. A config that fails full validation is
        # still consulted leniently (field-only read, mirroring
        # WorktreeExecutorProbe#read_config) so a partial planner-side config
        # can name its overseer; a config that supplies no overseer anywhere
        # yields a nil address plus the load error for the conflict detail
        # instead of a silent "no address".
        #
        # @return [Array<String, String, nil>] recipient address and an
        #   optional diagnostic note
        def escalation_recipient(to:, config_path:)
          return [to, nil] unless to.to_s.strip.empty?

          cfg = @config_loader.load(path: config_path)
          [cfg&.overseer, nil]
        rescue Error => e
          overseer = @config_loader.overseer(path: config_path).to_s
          overseer.empty? ? [nil, "coworker config load failed: #{e.message}"] : [overseer, nil]
        end

        def worktree_dir(worktree_path)
          worktree_path ? File.basename(worktree_path) : "?"
        end

        def success(task:, task_path:, roles:, disposition:, worktree_path:,
          branch:, assignments: [], worktree_assignments: [], dry_run:)
          Models::Preparation.new(task: task, task_path: task_path, roles: roles,
            worktree: {"path" => worktree_path, "branch" => branch, "disposition" => disposition},
            worktree_assignments: worktree_assignments, assignments: assignments,
            dry_run: dry_run)
        end
      end
    end
  end
end
