# frozen_string_literal: true

require "ace/task/molecules/git_ignored_path"

module Ace
  module Overseer
    module Molecules
      # References live in ace-task; execution truth stays in coworker/Herdr.
      # Call under the manager and task delegation exclusions. Creation tags are
      # written by ace-task with the child, so a crash before update is recoverable.
      class ManagerBinding
        def initialize(task_manager:)
          @tasks = task_manager
        end

        def validate!(manager_ref:, task:, roles:)
          manager = @tasks.show(manager_ref)
          raise Error, "Manager not found: #{manager_ref}" unless manager
          unless Ace::Task::Molecules::GitIgnoredPath.ignored_task?(manager)
            raise Error, "manager #{manager.id} must be a private Git-ignored task"
          end
          raise Error, "manager must be a top-level task" if manager.metadata["parent"]
          if Ace::Task::Atoms::TaskValidationRules.terminal_status?(manager.status.to_s)
            raise Error, "manager #{manager.id} is terminal"
          end
          expected = manager.metadata["project_task"].to_s
          raise Error, "manager #{manager.id} belongs to task #{expected}" if !expected.empty? && expected != task.id.to_s
          existing_roles = manager.metadata["roles"]
          if existing_roles && existing_roles != roles
            raise Error, "manager #{manager.id} has a different role sequence"
          end
          managers = @tasks.list(in_folder: "_overseer")
          unless managers.any? { |other| other.id == manager.id }
            raise Error, "manager #{manager.id} must belong to the private _overseer tree"
          end
          conflicts = managers.reject { |other| other.id == manager.id }.select do |other|
            other.metadata["project_task"].to_s == task.id.to_s
          end
          raise Error, "task #{task.id} already belongs to manager #{conflicts.first.id}" unless conflicts.empty?
          manager
        end

        def prepare(manager_ref:, task:, sequence:, worktree_path:, project_root:)
          roles = sequence.map { |leg| leg.fetch("role") }
          manager = validate!(manager_ref: manager_ref, task: task, roles: roles)
          # Refuse conflicts before creating any child. Otherwise a malformed
          # later role could leave a newly created earlier role on every retry.
          matched_roles = {}
          sequence.each do |leg|
            role = leg.fetch("role")
            children = Array(manager.subtasks)
            matches = children.select { |step| step.metadata["role"] == role || Array(step.tags).include?("overseer-role:#{role}") }
            raise Error, "manager #{manager.id} has ambiguous children for #{role}" if matches.size > 1
            matches.each do |step|
              if matched_roles.key?(step.id) && matched_roles[step.id] != role
                raise Error, "manager child #{step.id} matches conflicting roles"
              end
              matched_roles[step.id] = role
            end
            assigned = children.select { |step| step.metadata["assignment"].to_s == leg.fetch("assignment") }
            if assigned.any? { |step| !matches.include?(step) }
              raise Error, "assignment #{leg.fetch('assignment')} belongs to a different manager role"
            end
            assignment = matches.first&.metadata&.fetch("assignment", nil)
            if assignment && assignment != leg.fetch("assignment")
              raise Error, "role #{role} already belongs to assignment #{assignment}"
            end
          end
          if roles.include?("bootstrap-verifier") && Array(manager.subtasks).count { |step|
              step.metadata["role"] == "confirm-start" || Array(step.tags).include?("overseer-role:confirm-start")
            } > 1
            raise Error, "manager has ambiguous confirm-start children"
          end
          if Array(manager.subtasks).any? { |step| matched_roles.key?(step.id) &&
              (step.metadata["role"] == "confirm-start" || Array(step.tags).include?("overseer-role:confirm-start")) }
            raise Error, "confirm-start child also matches an execution role"
          end
          update!(manager.id, set: {"project_task" => task.id.to_s,
            "project_root" => project_root, "roles" => roles, "worktree" => worktree_path})
          previous = nil
          bindings = sequence.map do |leg|
            manager = @tasks.show(manager.id)
            role = leg.fetch("role")
            tag = "overseer-role:#{role}"
            matches = Array(manager.subtasks).select do |step|
              step.metadata["role"] == role || Array(step.tags).include?(tag)
            end
            raise Error, "manager #{manager.id} has ambiguous children for #{role}" if matches.size > 1
            step = matches.first || @tasks.create_subtask(manager.id, role, tags: [tag], status: "pending")
            assignment = step.metadata["assignment"].to_s
            if !assignment.empty? && assignment != leg.fetch("assignment")
              raise Error, "role #{role} already belongs to assignment #{assignment}"
            end
            update!(step.id, set: {"role" => role, "assignment" => leg.fetch("assignment"),
              "project_task" => task.id.to_s, "worktree" => worktree_path,
              "dependencies" => (Array(step.dependencies) + Array(previous)).uniq})
            previous = step.id.to_s
            {"role" => role, "assignment" => leg.fetch("assignment"), "step" => previous}
          end
          if roles.include?("bootstrap-verifier")
            manager = @tasks.show(manager.id)
            matches = Array(manager.subtasks).select do |step|
              step.metadata["role"] == "confirm-start" || Array(step.tags).include?("overseer-role:confirm-start")
            end
            raise Error, "manager has ambiguous confirm-start children" if matches.size > 1
            step = matches.first || @tasks.create_subtask(manager.id, "confirm-start",
              tags: ["overseer-role:confirm-start"], status: "pending")
            update!(step.id, set: {"role" => "confirm-start",
              "dependencies" => (Array(step.dependencies) + Array(previous)).uniq})
          end
          bindings
        end

        def ready!(manager_ref:, assignment:, allow_unbound: false)
          manager = @tasks.show(manager_ref)
          step = Array(manager.subtasks).find { |child| child.metadata["assignment"] == assignment }
          raise Error, "assignment #{assignment} has no manager step" unless step || allow_unbound
          [manager, step].compact.each do |task|
            result = Atoms::DependencyReadiness.check(task, lookup: ->(ref) { @tasks.show(ref) })
            raise Error, "delegation blocked: #{result[:reasons].join('; ')}" if result[:status] == :blocked
          end
        end

        private def update!(ref, **options)
          @tasks.update(ref, **options) || raise(Error, "task #{ref} disappeared while recording delegation; retry to reconcile")
        end

        def record_execution(manager_ref:, assignment:, execution:)
          manager = @tasks.show(manager_ref)
          matches = Array(manager.subtasks).select { |step| step.metadata["assignment"] == assignment }
          raise Error, "assignment #{assignment} has no unique manager step" unless matches.size == 1
          update!(matches.first.id, set: {"terminal" => execution["terminal_id"],
            "executor" => execution["agent"], "start_config" => execution["config_path"]}.compact)
        end
      end
    end
  end
end
