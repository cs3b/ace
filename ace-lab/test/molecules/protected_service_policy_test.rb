# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/molecules/protected_service_policy"

module Ace
  module Lab
    # Policy/input mechanics with source-injected deployment document. These
    # tests do not stand in for kernel-peer or installed distinct-UID proof.
    class ProtectedServicePolicyTest < Minitest::Test
      def setup
        @input = {"target" => {"resource" => "fixture"}, "value" => "bounded"}
        @bytes = JSON.generate(@input)
        uid = Process.uid.positive? ? Process.uid : Etc.getpwnam("nobody").uid
        @binding = {"request_id" => "request-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1",
          "project_id" => "fixture", "operation" => "fixture", "service_id" => "executor", "candidate_head" => "a" * 40,
          "caller_uid" => uid, "authorization" => "decision-1", "input_digest" => Atoms::ServiceInput.digest(@input),
          "target" => Atoms::ServiceInput.target(@input)}
        @document = {"principals" => {uid.to_s => {"projects" => ["fixture"]}},
          "operations" => {"fixture" => {"project" => "fixture", "service_id" => "executor", "argv" => ["/usr/bin/true"],
            "executor_uid" => uid == 1 ? 2 : 1, "transport" => "local", "lease_expires_at" => (Time.now.utc + 3600).iso8601}},
          "authorizations" => {"decision-1" => @binding.merge("expires_at" => (Time.now.utc + 3600).iso8601)}}
        @policy = Molecules::ProtectedServicePolicy.new(document_loader: -> { @document },
          proposal_resolver: ->(*) { raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "canonical producer unavailable" })
      end

      def test_preview_selects_only_installed_prune_receiver_without_proposal_authorization
        operation = @document.fetch("operations").delete("fixture")
        @document.fetch("operations")["prune-preserved-workspace"] = operation
        uid = @binding.fetch("caller_uid")
        selected = operation.fetch("executor_uid")
        arguments = {project: "fixture", uid: uid, service_id: "executor", executor_uid: selected}
        assert @policy.workspace_prune_receiver!(**arguments)
        assert_raises(SecurityError) { @policy.workspace_prune_receiver!(**arguments.merge(service_id: "other")) }
        assert_raises(SecurityError) { @policy.workspace_prune_receiver!(**arguments.merge(executor_uid: selected + 1)) }
        assert_raises(SecurityError) { @policy.workspace_prune_receiver!(**arguments.merge(project: "hidden")) }
        operation["executor_uid"] = uid
        assert_raises(SecurityError) { @policy.workspace_prune_receiver!(**arguments.merge(executor_uid: uid)) }
        operation["executor_uid"] = selected
        @document.fetch("operations")["fixture"] = @document.fetch("operations").delete("prune-preserved-workspace")
        assert_raises(SecurityError) { @policy.workspace_prune_receiver!(**arguments) }
      end

      def test_existing_input_and_policy_owners_compute_exact_bound_request_without_executing_handler
        prepared = @policy.prepare!(@binding, input_bytes: @bytes)
        assert_equal @input, prepared.fetch(:input)
        assert_equal "unix", prepared.fetch(:binding).fetch("transport")
        assert_equal @document["operations"]["fixture"]["executor_uid"], prepared.fetch(:binding).fetch("executor_uid")
        assert_match(/\A[0-9a-f]{64}\z/, prepared.fetch(:policy_digest))
        assert_equal File.realpath("/usr/bin/true"), prepared.fetch(:operation).fetch("argv").first
        assert_raises(FrozenError) { prepared.fetch(:input).fetch("target")["resource"] = "changed" }
        assert_raises(FrozenError) { prepared.fetch(:binding).fetch("target")["resource"].replace("changed") }
        assert_raises(FrozenError) { prepared.fetch(:operation).fetch("argv") << "changed" }
        @binding.fetch("target")["resource"] = "caller mutation"
        assert_equal "fixture", prepared.fetch(:binding).fetch("target").fetch("resource")
      end

      def test_hostile_digest_or_target_assertion_is_refused_before_policy
        assert_raises(SecurityError) { @policy.prepare!(@binding.merge("input_digest" => "b" * 64), input_bytes: @bytes) }
        assert_raises(SecurityError) { @policy.prepare!(@binding.merge("target" => {"resource" => "other"}), input_bytes: @bytes) }
        changed = JSON.generate(@input.merge("value" => "changed"))
        assert_raises(SecurityError) { @policy.prepare!(@binding, input_bytes: changed) }
      end

      def test_existing_byte_schema_secret_and_depth_limits_are_preserved_without_echoing_values
        deep = "leaf"
        18.times { deep = {"nested" => deep} }
        ["x" * (Atoms::ServiceInput::MAX_BYTES + 1), "[]", "not-json",
          JSON.generate(@input.merge("password" => "sensitive-value")), JSON.generate(deep)].each do |bytes|
          error = assert_raises(ArgumentError) { @policy.prepare!(@binding, input_bytes: bytes) }
          refute_includes error.message, "sensitive-value"
        end
      end

      def test_policy_change_grant_revocation_and_expired_lease_are_rechecked_against_recorded_binding
        prepared = @policy.prepare!(@binding, input_bytes: @bytes)
        record = prepared.fetch(:binding).merge("policy_digest" => prepared.fetch(:policy_digest))
        @document["operations"]["fixture"]["argv"] << "changed-fixed-argument"
        assert_raises(SecurityError) { @policy.prepare!(record, input_bytes: @bytes) }
        @document["operations"]["fixture"]["argv"].pop
        @document["principals"] = {}
        assert_raises(SecurityError) { @policy.prepare!(record, input_bytes: @bytes) }
        @document["principals"] = {@binding.fetch("caller_uid").to_s => {"projects" => ["fixture"]}}
        @document["operations"]["fixture"]["lease_expires_at"] = (Time.now.utc - 1).iso8601
        assert_raises(SecurityError) { @policy.prepare!(record, input_bytes: @bytes) }
      end

      def test_yaml_proposal_prefix_cannot_replace_canonical_owner
        @document["authorizations"]["proposal-forged"] = @document["authorizations"]["decision-1"]
        assert_raises(SecurityError) { @policy.prepare!(@binding.merge("authorization" => "proposal-forged"), input_bytes: @bytes) }
      end

      def test_root_or_worker_executor_account_is_refused
        @document["operations"]["fixture"]["executor_uid"] = 0
        assert_raises(SecurityError) { @policy.prepare!(@binding, input_bytes: @bytes) }
        @document["operations"]["fixture"]["executor_uid"] = @binding.fetch("caller_uid")
        assert_raises(SecurityError) { @policy.prepare!(@binding, input_bytes: @bytes) }
      end
    end
  end
end
