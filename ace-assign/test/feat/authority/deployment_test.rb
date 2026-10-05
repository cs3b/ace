# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require "ace/assign/authority/server"

module Ace
  module Assign
    class ProtectedDeploymentTest < AceAssignTestCase
      def data
        {"schema" => "ace.assign.authorities/v1", "authorities" => {"authority" => {"uid" => 13003,
          "gid" => 13003, "groups" => [13003], "socket_path" => "/run/ace-authority/control.sock",
          "state_root" => "/var/lib/ace-authority", "composition" => "launch"}},
         "projects" => {"project" => {"journal_repository" => "/var/lib/ace-journal", "evidence_git_ref" => "refs/ace/execution",
           "evidence_checkout_root" => "/var/lib/ace-checkout", "assignment_root" => "/var/lib/ace-assignments",
           "candidate_root" => "/var/lib/ace-candidates", "launcher_uids" => [13002], "reviewer_uids" => [],
           "worker_uids" => [13001], "service_executor_uids" => [], "supervisor_uids" => [],
           "peer_credentials" => {"13001" => {"gid" => 13001, "groups" => [13001], "scratch_root" => "/var/lib/ace-worker"},
             "13002" => {"gid" => 13002, "groups" => [13002], "scratch_root" => "/var/lib/ace-launcher"}}}},
         "launch_mappings" => {"mapping" => {"project_id" => "project", "authority_id" => "authority",
           "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002],
           "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001], "worker_actor" => "worker",
           "worker_cwd" => "/home/worker", "worker_argv" => ["/usr/bin/true"], "worker_env" => {"PATH" => "/usr/bin:/bin"},
           "bootstrap" => "/usr/libexec/ace-worker-gate", "bootstrap_sha256" => "a" * 64,
           "native" => {"workspace_id" => "w1", "socket_path" => "/run/herdr/control.sock", "socket_identity" => [1, 2, 13001],
             "executable" => "/usr/bin/herdr", "version" => "0.9.3", "server_identity" => {"pid" => 90,
               "uid" => 13001, "gid" => 13001, "groups" => [13001], "parent_pid" => 1,
               "started_at" => "linux:0123-abcd:199", "host" => "fixture"}}}}}
      end

      def test_fixed_mapping_and_source_composition_match
        deployment = Authority::Deployment.new(data)
        assert deployment.verify_composition!("authority", composition: "launch")
        assert_raises(ArgumentError) { deployment.verify_composition!("authority", composition: "services") }
        assert_raises(ArgumentError) do
          Authority::Server.new(authority_id: "authority", lifecycle: Object.new, deployment: deployment, composition: "services")
        end
        assert_equal "/etc/ace/assignment-authorities.json", Authority::Deployment::PATH
      end

      def test_duplicate_endpoint_and_project_owner_are_refused_before_server_construction
        endpoint = data
        endpoint["authorities"]["second"] = endpoint["authorities"].fetch("authority").dup
        assert_raises(ArgumentError) { Authority::Deployment.new(endpoint) }
        owners = data
        owners["authorities"]["second"] = owners["authorities"].fetch("authority").merge("socket_path" => "/run/second/control.sock")
        owners["launch_mappings"]["second"] = owners["launch_mappings"].fetch("mapping").merge("authority_id" => "second")
        assert_raises(ArgumentError) { Authority::Deployment.new(owners) }
      end

      def test_installed_native_workspace_is_required_and_canonical
        [nil, "current", "w0", "w01", "w1:t1", "w" + "1" * 10].each do |workspace|
          value = data
          value["launch_mappings"]["mapping"]["native"]["workspace_id"] = workspace
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end

      def test_unknown_fields_loader_environment_and_changed_groups_are_rejected
        [->(value) { value["config_path"] = "/tmp/worker-map" },
         ->(value) { value["launch_mappings"]["mapping"]["worker_env"]["LD_PRELOAD"] = "/home/worker/inject.so" },
         ->(value) { value["launch_mappings"]["mapping"]["worker_groups"] = [13001, 13003] },
         ->(value) { value["launch_mappings"]["mapping"]["bootstrap"] = "/usr/libexec/../worker-gate" },
         ->(value) { value["authorities"]["authority"]["composition"] = "worker-selected-class" }].each do |change|
          value = data
          change.call(value)
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end
    end
  end
end
