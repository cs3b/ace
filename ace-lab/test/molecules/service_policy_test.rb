# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    class ServicePolicyTest < Minitest::Test
      def test_exact_authorization_and_expired_lease
        Dir.mktmpdir do |dir|
          executable = File.join(dir, "handler")
          File.write(executable, "#!/bin/sh\nexit 0\n")
          File.chmod(0o700, executable)
          binding = {"operation" => "publish", "project_id" => "ace", "assignment_id" => "assign-1",
                     "attempt_id" => "attempt-1", "input_digest" => "a" * 64,
                     "target" => {"resource" => "release"}, "candidate_head" => "b" * 40,
                     "caller_uid" => Process.uid}
          document = {"operations" => {"publish" => {"project" => "ace", "service_id" => "publisher",
            "argv" => [executable], "executor_uid" => Process.uid,
            "lease_expires_at" => (Time.now.utc + 3600).iso8601}},
            "authorizations" => {"decision-1" => binding.merge("expires_at" => (Time.now.utc + 3600).iso8601)}}
          policy = Molecules::ServicePolicy.new(document)
          assert_equal executable, policy.operation!("publish", project: "ace", service_id: "publisher")["argv"].first
          assert_equal binding["attempt_id"], policy.authorize!("decision-1", binding)["attempt_id"]
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("project_id" => "other")) }
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("candidate_head" => "c" * 40)) }
          document["authorizations"]["decision-1"]["expires_at"] = (Time.now.utc - 1).iso8601
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding) }
          document["operations"]["publish"]["lease_expires_at"] = (Time.now.utc - 1).iso8601
          assert_raises(SecurityError) { policy.operation!("publish", project: "ace", service_id: "publisher") }
        end
      end
    end
  end
end
