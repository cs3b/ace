# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      # Pure readiness gate for the overseer queue (L6.3): a step may start
      # only when every recorded dependency is satisfied by real task-tree
      # state. A dependency is satisfied exclusively by a predecessor whose
      # status is "done" -- the accepted *and* integrated result. A finished
      # worker ("work done" message, open PR) does not unlock anything because
      # merge is modeled by depending on the predecessor's integration step,
      # which stays non-done until the merge is confirmed.
      module DependencyReadiness
        SATISFIED_STATUS = "done"

        # @param task [Object] task responding to #id, #dependencies
        # @param lookup [Proc] ->(ref) returns the dependency task or nil
        # @param path [Array<String>] ancestor task ids (DIRECT cycle
        #   detection only: self/mutual refs one hop away; deeper cycles
        #   surface as ordinary "not integrated yet" blocks, which yields
        #   the same start decision)
        # @return [Hash] {status: :ready} or {status: :blocked, reasons: [String]}
        def self.check(task, lookup:, path: [])
          deps = task.respond_to?(:dependencies) ? Array(task.dependencies) : []
          return {status: :ready} if deps.empty?

          reasons = deps.map { |dep_ref| dependency_reason(dep_ref.to_s, lookup, path + [task.id]) }
          reasons.compact!

          reasons.empty? ? {status: :ready} : {status: :blocked, reasons: reasons}
        end

        # @return [String, nil] nil when the dependency is satisfied
        private_class_method def self.dependency_reason(dep_ref, lookup, path)
          dep = lookup.call(dep_ref)
          return "#{dep_ref}: dependency not found" if dep.nil?
          return "#{dep_ref}: cyclic dependency (#{(path + [dep.id]).join(" -> ")})" if path.include?(dep.id)

          status = dep.status.to_s
          return nil if status == SATISFIED_STATUS
          return "#{dep_ref}: predecessor #{status} (no accepted/integrated result)" if Ace::Task::Atoms::TaskValidationRules.terminal_status?(status)

          "#{dep_ref}: predecessor not integrated yet (status: #{status})"
        end
      end
    end
  end
end
