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
          assert_equal File.realpath(executable), policy.operation!("publish", project: "ace", service_id: "publisher")["argv"].first
          assert_equal binding["attempt_id"], policy.authorize!("decision-1", binding)["attempt_id"]
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("project_id" => "other")) }
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding.merge("candidate_head" => "c" * 40)) }
          document["authorizations"]["decision-1"]["expires_at"] = (Time.now.utc - 1).iso8601
          assert_raises(SecurityError) { policy.authorize!("decision-1", binding) }
          document["operations"]["publish"]["lease_expires_at"] = (Time.now.utc - 1).iso8601
          assert_raises(SecurityError) { policy.operation!("publish", project: "ace", service_id: "publisher") }
        end
      end

      def test_host_maintenance_placement_resolves_symlinks
        Dir.mktmpdir do |dir|
          deployment = File.join(dir, "deployment")
          outside = File.join(dir, "outside")
          maintainer = File.join(dir, "maintainer")
          FileUtils.mkdir_p(File.join(deployment, "bin"))
          FileUtils.mkdir_p(outside)
          FileUtils.mkdir_p(maintainer)
          executable = File.join(maintainer, "handler")
          File.write(executable, "#!/bin/sh\nexit 0\n")
          File.chmod(0o700, executable)

          operation = {"project" => "ace", "service_id" => "maintainer", "argv" => [executable],
            "executor_uid" => Process.uid, "lease_expires_at" => (Time.now.utc + 3600).iso8601,
            "host_maintenance" => true, "deployment_root" => deployment,
            "evidence_sink" => File.join(outside, "sink")}
          document = {"operations" => {"promote-runtime" => operation}, "authorizations" => {}}
          policy = Molecules::ServicePolicy.new(document)
          resolved = policy.operation!("promote-runtime", project: "ace", service_id: "maintainer")
          assert_equal File.join(outside, "sink"), resolved["evidence_sink"]

          # A sink configured inside the deployment fails placement even
          # through a symlink: the resolved location is what counts.
          linked = File.join(deployment, "sink-link")
          File.symlink(File.join(deployment, "evidence"), linked)
          operation["evidence_sink"] = linked
          assert_raises(Ace::Lab::InvalidConfigurationError) do
            policy.operation!("promote-runtime", project: "ace", service_id: "maintainer")
          end
        end
      end
    end
  end
end
