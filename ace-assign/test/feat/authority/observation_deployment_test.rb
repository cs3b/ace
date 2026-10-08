# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require_relative "../../support/deployment_data_fixture"
require_relative "../../support/execution_scope_observation_fixtures"
module Ace
  module Assign
    class ObservationDeploymentTest < AceAssignTestCase
      include DeploymentDataFixture
      def observation_data
        value = inbox_data
        project = value.fetch("projects").fetch("project")
        project["observer_uids"], project["signer_uids"] = [13008], [13010]
        [13008, 13010].each { |uid| project.fetch("peer_credentials")[uid.to_s] = {"gid" => uid, "groups" => [uid], "scratch_root" => "/var/lib/ace-peer-#{uid}"} }
        context = project.fetch("inbox_contexts").fetch("inbox")
        context.merge!("observer_uids" => [13008], "signer_uids" => [13010], "receipt_private_key" => {"path" => "/var/lib/ace-signer/private.pem", "bytes" => 2048, "sha256" => "c" * 64},
          "runtime_bindings" => {"codex" => {"assignment_id" => "assignment", "attempt_id" => "attempt", "provider" => "codex", "provider_version" => "0.159.3",
            "native_target" => {"session" => "w1", "pane" => "p1", "terminal_id" => "term1", "agent" => "codex", "thread" => "0123abcd-0000-4000-8000-000000000001", "thread_kind" => "id"},
            "runtime_process_binding" => {"pid" => 99, "uid" => 13009, "gid" => 13009, "groups" => [13009], "parent_pid" => 1,
              "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:99", "host" => "fixture"}, "endpoint_reference_sha256" => "d" * 64, "observer_uid" => 13008}})
        value
      end

      def test_observation_trust_requires_dedicated_fixed_principals_and_native_runtime
        assert Authority::Deployment.new(observation_data)
        changes = [->(context) { context["observer_uids"] = [13005] }, ->(context) { context.delete("signer_uids") },
          ->(context) { context["receipt_private_key"]["path"] = "relative" },
          ->(context) { context["runtime_bindings"]["codex"]["runtime_process_binding"]["uid"] = 13001 },
          ->(context) { context["runtime_bindings"]["codex"]["observer_uid"] = 13010 },
          ->(context) { context["runtime_bindings"]["codex"]["provider_version"] = "unknown" }]
        changes.each do |change|
          value = observation_data
          change.call(value["projects"]["project"]["inbox_contexts"]["inbox"])
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end

    end
  end
end
