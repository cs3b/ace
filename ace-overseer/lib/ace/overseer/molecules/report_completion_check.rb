# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Read existing coworker allocation and ace-assign completion truth before
      # the queue accepts success. This check owns no persisted state.
      class ReportCompletionCheck
        def initialize(handoff_probe: nil, assignment_probe_factory: nil, worktree_finder: nil)
          @worktree_finder = worktree_finder || Ace::Git::Worktree::Organisms::WorktreeManager.new
          @handoff_probe = handoff_probe || HandoffProbe.new
          @assignment_probe_factory = assignment_probe_factory || ->(root) {
            Ace::Coworker::Molecules::AssignmentProbe.new(project_root: root)
          }
        end

        def call(event:, manager:, step:)
          return "matched task allocation no longer exists" unless manager && step
          assignment = event["assignment"].to_s
          if assignment.empty?
            return nil if step.metadata["role"] == "planner" && step.metadata["assignment"].to_s.empty?
            return "unassigned readiness is not execution completion"
          end
          task = manager.metadata["project_task"].to_s
          role = step.metadata["role"].to_s
          worktree = step.metadata["worktree"].to_s
          worktree = manager.metadata["worktree"].to_s if worktree.empty?
          return "success requires recorded project task, role and worktree" if [task, role, worktree].any?(&:empty?)
          return "report task disagrees with the allocation" unless event["task"].to_s == task
          return "confirm-start requires coordinator session evidence" if role == "confirm-start"
          return "report assignment disagrees with the allocation" unless step.metadata["assignment"].to_s == assignment

          found = @worktree_finder.switch(task)
          return "task has no usable worktree: #{found[:error] || found[:message]}" unless found[:success]
          root = found.fetch(:worktree_path)
          legs = @handoff_probe.probe(root, task_id: task).fetch(:legs)
          matching = legs.select { |leg| leg["assignment"] == assignment }
          return "assignment has no unique allocation for this task" unless matching.size == 1
          return "assignment role disagrees with the recorded allocation" unless matching.first["role"] == role
          return "report role disagrees with the allocation" unless event["role"].to_s.empty? || event["role"] == role

          snapshot = @assignment_probe_factory.call(root).snapshot(assignment)
          return "assignment owner returned a different identity" unless snapshot.id == assignment
          return "assignment is not complete: #{snapshot.incomplete_reasons.join('; ')}" unless snapshot.completion_verdict == :complete
          nil
        rescue Ace::Coworker::Error, Ace::Overseer::Error, SystemCallError, KeyError, Psych::Exception => e
          "assignment completion could not be verified in #{worktree}: #{e.message}"
        end
      end
    end
  end
end
