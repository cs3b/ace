# frozen_string_literal: true

module Ace
  module Assign
    module Models
      # Immutable start-time facts for an assignment attempt.
      #
      # A binding freezes exactly what an attempt owns: the immutable attempt
      # ID, the assignment and step/subtree scope, the project, the
      # authenticated actor/role and runtime identity resolved at the
      # execution boundary, the source task ID, the base head captured once at
      # start, and the configured evidence ref. Bindings are never mutated;
      # changes require a new attempt.
      class AttemptBinding
        attr_reader :attempt_id, :assignment_id, :scope, :project_id, :task_id,
          :actor, :role, :runtime, :base_head, :evidence_git_ref, :created_at

        # @param attempt_id [String] Immutable attempt ID (ace-b36ts)
        # @param assignment_id [String] Owning assignment ID
        # @param scope [String] Canonical step/subtree scope
        # @param project_id [String] Project the attempt executes in
        # @param actor [String] Authenticated actor from the execution boundary
        # @param role [String] Trusted role (coordinator, service, worker)
        # @param runtime [String] Runtime identity of the executing boundary
        # @param base_head [String] Git HEAD captured exactly once at start
        # @param task_id [String, nil] Source task ID (nil for taskless assignments)
        # @param evidence_git_ref [String, nil] Evidence ref for managed attempts
        # @param created_at [Time] Binding creation time
        def initialize(attempt_id:, assignment_id:, scope:, project_id:, actor:, role:, runtime:, base_head:,
          task_id: nil, evidence_git_ref: nil, created_at:)
          @attempt_id = attempt_id.freeze
          @assignment_id = assignment_id.freeze
          @scope = scope.freeze
          @project_id = project_id.freeze
          @task_id = task_id&.freeze
          @actor = actor.freeze
          @role = role.freeze
          @runtime = runtime.freeze
          @base_head = base_head.freeze
          @evidence_git_ref = evidence_git_ref&.freeze
          @created_at = created_at
        end

        # @return [Boolean] True when the attempt is bound to a source task and
        #   eligible for managed evidence-ref delivery
        def managed?
          !task_id.nil? && !task_id.to_s.strip.empty?
        end

        # Recovery mode implied by task attachment: git-backed journaling for
        # task-attached attempts, disposable local state otherwise.
        #
        # @return [String] "git" or "local_only"
        def recovery_mode
          managed? ? "git" : "local_only"
        end

        # Identity facts repeated by receipts must match the binding exactly.
        #
        # @param other [AttemptBinding] Binding to compare
        # @return [Boolean] True if both bindings own the same attempt identity
        def same_identity?(other)
          attempt_id == other.attempt_id &&
            assignment_id == other.assignment_id &&
            scope == other.scope &&
            project_id == other.project_id
        end

        # Convert to a hash for canonical serialization.
        # @return [Hash] Binding data with string keys
        def to_h
          {
            "attempt_id" => attempt_id,
            "assignment_id" => assignment_id,
            "scope" => scope,
            "project_id" => project_id,
            "task_id" => task_id,
            "actor" => actor,
            "role" => role,
            "runtime" => runtime,
            "base_head" => base_head,
            "evidence_git_ref" => evidence_git_ref,
            "created_at" => created_at.iso8601
          }
        end

        # Rebuild a binding from serialized data.
        #
        # @param data [Hash] Serialized binding (string keys)
        # @return [AttemptBinding] Rebuilt binding
        def self.from_h(data)
          new(
            attempt_id: data["attempt_id"],
            assignment_id: data["assignment_id"],
            scope: data["scope"],
            project_id: data["project_id"],
            task_id: data["task_id"],
            actor: data["actor"],
            role: data["role"],
            runtime: data["runtime"],
            base_head: data["base_head"],
            evidence_git_ref: data["evidence_git_ref"],
            created_at: parse_time(data["created_at"])
          )
        end

        def self.parse_time(value)
          return value if value.is_a?(Time)
          require "time"
          Time.parse(value)
        end
        private_class_method :parse_time
      end
    end
  end
end
