# frozen_string_literal: true
module Ace
  module Assign
    module DeploymentDataFixture
      def data
        {"schema" => "ace.assign.authorities/v2", "authorities" => {"authority" => {"uid" => 13003,
          "gid" => 13003, "groups" => [13003], "socket_path" => "/run/ace-authority/control.sock",
          "state_root" => "/var/lib/ace-authority", "composition" => "launch"}},
         "projects" => {"project" => {"journal_repository" => "/var/lib/ace-journal", "evidence_git_ref" => "refs/ace/execution",
           "evidence_checkout_root" => "/var/lib/ace-checkout", "assignment_root" => "/var/lib/ace-assignments",
           "candidate_root" => "/var/lib/ace-candidates", "campaign_repository" => "/var/lib/ace-campaign-repository", "campaign_store_root" => "/var/lib/ace-campaign-store", "campaign_policy" => {"path" => "/etc/ace/campaign-policy.json", "sha256" => "a" * 64, "bytes" => 100}, "launcher_uids" => [13002], "reviewer_uids" => [],
           "worker_uids" => [13001], "service_executor_uids" => [], "supervisor_uids" => [],
           "peer_credentials" => {"13001" => {"gid" => 13001, "groups" => [13001], "scratch_root" => "/var/lib/ace-worker"},
             "13002" => {"gid" => 13002, "groups" => [13002], "scratch_root" => "/var/lib/ace-launcher"}}}},
         "launch_mappings" => {"mapping" => {"task_context_entry" => {"manifest" => {"path" => "/fixture/assign-entry.json", "bytes" => 100, "sha256" => "1" * 64}, "wrapper" => {"path" => "/fixture/assign-entry.py", "bytes" => 200, "sha256" => "2" * 64}}, "project_id" => "project", "authority_id" => "authority",
           "launcher_uid" => 13002, "launcher_gid" => 13002, "launcher_groups" => [13002],
           "worker_uid" => 13001, "worker_gid" => 13001, "worker_groups" => [13001], "worker_actor" => "worker",
           "worker_cwd" => "/home/worker", "worker_entry" => {"interpreter" => {"path" => "/usr/bin/python3", "bytes" => 100, "sha256" => "3" * 64}, "wrapper" => {"path" => "/usr/libexec/ace-worker.py", "bytes" => 200, "sha256" => "4" * 64}}, "worker_env" => {"PATH" => "/usr/bin:/bin"},
           "bootstrap" => "/usr/libexec/ace-worker-gate", "bootstrap_sha256" => "a" * 64,
           "execution_scope" => {"backend" => "linux_systemd_cgroup_v2", "slot_id" => "slot",
             "slice_unit" => "ace-slot.slice", "service_unit" => "ace-slot.service",
             "unit_manifest_sha256" => "c" * 64, "boundary_manifest_sha256" => "d" * 64,
             "root_directory" => "/var/lib/ace-slot/root", "runtime_directory" => "/run/ace-slot",
             "network_namespace_path" => "/run/netns/ace-slot"},
           "native" => {"workspace_id" => "w1", "socket_path" => "/run/herdr/control.sock",
             "executable" => "/usr/bin/herdr", "version" => "0.9.3", "protocol" => 22,
             "executable_sha256" => "e" * 64}}}}

      end

      def inbox_data
        value = data
        value["authorities"]["authority"]["composition"] = "services"
        project = value["projects"]["project"]
        project["service_executor_uids"] = [13004]
        project["supervisor_uids"] = [13005]
        project["peer_credentials"]["13004"] = {"gid" => 13004, "groups" => [13004], "scratch_root" => "/var/lib/ace-executor"}
        project["peer_credentials"]["13005"] = {"gid" => 13005, "groups" => [13005], "scratch_root" => "/var/lib/ace-supervisor"}
        project["service_receivers"] = {"setup" => {"executor_uid" => 13004,
          "socket_path" => "/run/ace-setup/control.sock", "staging_root" => "/var/lib/ace-setup"}}
        project["inbox_contexts"] = {"inbox" => {"deliveries_dir" => "/var/lib/ace-inbox", "control_socket_path" => "/run/ace-inbox/context.sock",
          "owner_credentials" => {"uid" => 13006, "gid" => 13006, "groups" => [13006]},
          "native_mapping_id" => "mapping",
          "pi_queue_client" => "/usr/libexec/ace-pi-identity", "pi_queue_client_sha256" => "b" * 64,
          "supervisor_uids" => [13005]}}
        value
      end

    end
  end
end
