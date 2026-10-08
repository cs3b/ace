# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/maintenance_workspace_retirement"

module Ace
  module Assign
    class MaintenanceWorkspaceRetirementTest < AceAssignTestCase
      Retirement = Authority::MaintenanceWorkspaceRetirement
      class CollectionOwner
        attr_reader :calls
        def initialize; @calls = 0; end
        def verify_retirement_evidence!(evidence:, projection:, deadline:)
          raise AttemptErrors::EvidenceUnavailable, "original deadline expired" unless deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @calls += 1
          true
        end
      end

      def setup
        super
        @owner = CollectionOwner.new
        @resource = {"host_path" => "/workspace", "view_path" => "/workspace", "mount_id" => 10,
          "filesystem_type" => "ext4", "device" => 8, "inode" => 42, "uid" => 13001, "gid" => 13001}
        @child = @resource.merge("host_path" => "/workspace/nested", "view_path" => "/nested", "inode" => 43)
        @target = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt",
          "resource" => "workspace:project:mapping:assignment", "journal_commit" => "a" * 40,
          "binding_event_digest" => "b" * 64, "release_event_digest" => "c" * 64, "descriptor_sha256" => "d" * 64}
        @projection = {"worker_cwd" => "/workspace", "workspace_resource" => @resource,
          "resource_identities" => [@child, @resource], "parent_resource_declarations" => [@child, @resource].map { |row|
            row.slice("host_path", "view_path").merge("stage" => "parent", "worker_visible" => true, "read_only" => false) }}
        @deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
      end

      def descriptor(phase = "captured")
        {"schema" => Retirement::SCHEMA, "phase" => phase, "target" => @target, "resource" => @resource,
          "covered_resources" => [@resource, @child].map { |row| {"original" => row,
            "captured_host_path" => "/fixed/invocation/captured-worktree" + row.fetch("host_path").delete_prefix("/workspace")} },
          "invocation" => {"request_id" => "request", "input_digest" => "e" * 64,
            "operation_owner_binding_digest" => "f" * 64, "dispatch_event_digest" => "1" * 64},
          "refs" => Retirement::REFERENCES.fetch(phase).to_h { |key| [key, {"path" => "/fixed/#{key}", "sha256" => "2" * 64, "bytes" => 10}] }}
      end

      def verify(evidence, phase = "captured", **changes)
        evidence.verify!(**{owner: @owner, target: @target, projection: @projection, phase: phase, deadline: @deadline}.merge(changes))
      end

      def test_complete_exact_declared_parent_rows_are_immutable_and_ordered
        original = descriptor
        evidence = Retirement::Evidence.mint!(owner: @owner, descriptor: original)
        assert verify(evidence)
        assert evidence.descriptor.frozen?
        assert evidence.descriptor.fetch("covered_resources").all? { |row| row.frozen? && row.fetch("original").frozen? }
        original.fetch("refs").fetch("intent")["bytes"] = 20
        assert_equal 10, evidence.descriptor.dig("refs", "intent", "bytes")
        assert_equal 1, @owner.calls
      end

      def test_missing_substituted_and_extra_covered_rows_refuse_before_collection_recheck
        missing = descriptor
        missing.fetch("covered_resources").pop
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(Retirement::Evidence.mint!(owner: @owner, descriptor: missing)) }
        changed = descriptor
        changed.fetch("covered_resources").last["original"] = @child.merge("inode" => 44)
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(Retirement::Evidence.mint!(owner: @owner, descriptor: changed)) }
        extra = descriptor
        extra.fetch("covered_resources") << {"original" => @child.merge("host_path" => "/workspace/foreign", "inode" => 45),
          "captured_host_path" => "/fixed/invocation/captured-worktree/foreign"}
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(Retirement::Evidence.mint!(owner: @owner, descriptor: extra)) }
        assert_equal 0, @owner.calls
      end

      def test_wrong_relative_capture_numeric_identity_and_receipt_cycle_refuse
        changed = descriptor
        changed.fetch("covered_resources").last["captured_host_path"] = "/fixed/unrelated"
        assert_raises(AttemptErrors::EvidenceUnavailable) { Retirement::Evidence.mint!(owner: @owner, descriptor: changed) }
        changed = descriptor
        changed["resource"] = @resource.merge("inode" => 42.0)
        assert_raises(AttemptErrors::EvidenceUnavailable) { Retirement::Evidence.mint!(owner: @owner, descriptor: changed) }
        removed = descriptor("removed")
        removed.fetch("refs")["receipt"] = descriptor("completed").fetch("refs").fetch("receipt")
        assert_raises(AttemptErrors::EvidenceUnavailable) { Retirement::Evidence.mint!(owner: @owner, descriptor: removed) }
        assert verify(Retirement::Evidence.mint!(owner: @owner, descriptor: descriptor("removed")), "removed")
        assert verify(Retirement::Evidence.mint!(owner: @owner, descriptor: descriptor("completed")), "completed")
      end

      def test_foreign_owner_thread_phase_and_expired_deadline_cannot_consume_proof
        evidence = Retirement::Evidence.mint!(owner: @owner, descriptor: descriptor)
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(evidence, owner: CollectionOwner.new) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(evidence, "removed") }
        assert_raises(AttemptErrors::EvidenceUnavailable) { Thread.new { Thread.current.report_on_exception = false; verify(evidence) }.value }
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(evidence, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1) }
        assert_equal 0, @owner.calls
      end

      def test_observation_capability_is_only_live_inside_same_operation
        evidence = Retirement::Evidence.mint!(owner: @owner, descriptor: descriptor)
        assert_raises(AttemptErrors::EvidenceUnavailable) { evidence.verify_consumption! }
        calls = 0
        evidence.with_consumption(-> { verify(evidence); calls += 1 }) do
          assert evidence.verify_consumption!
          assert_raises(AttemptErrors::EvidenceUnavailable) { evidence.with_consumption(-> {}) {} }
          assert evidence.verify_consumption!, "nested refusal must retain outer operation"
        end
        assert_equal 2, calls
        assert_raises(AttemptErrors::EvidenceUnavailable) { evidence.verify_consumption! }
        evidence.expire!
        assert_raises(AttemptErrors::EvidenceUnavailable) { verify(evidence) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { evidence.with_consumption(-> {}) {} }
        assert_raises(AttemptErrors::EvidenceUnavailable) { Retirement::Evidence.mint!(owner: @owner, descriptor: nil) }
      end
    end
  end
end
