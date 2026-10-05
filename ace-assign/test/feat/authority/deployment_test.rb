# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require "ace/assign/authority/server"

module Ace
  module Assign
    class ProtectedDeploymentTest < AceAssignTestCase
      def data
        {"schema" => "ace.assign.authorities/v2", "authorities" => {"authority" => {"uid" => 13003,
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
        project["inbox_contexts"] = {"inbox" => {"deliveries_dir" => "/var/lib/ace-inbox",
          "receipt_public_key" => "/etc/ace/inbox-public.pem", "native_mapping_id" => "mapping",
          "pi_queue_client" => "/usr/libexec/ace-pi-identity", "pi_queue_client_sha256" => "b" * 64,
          "supervisor_uids" => [13005]}}
        value
      end

      def test_obsolete_pid_pinned_map_and_incomplete_scope_are_refused
        value = data
        value["schema"] = "ace.assign.authorities/v1"
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        value = data
        value["launch_mappings"]["mapping"]["native"]["server_identity"] = {"pid" => 90}
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        value = data
        value["launch_mappings"]["mapping"]["execution_scope"].delete("boundary_manifest_sha256")
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
      end

      def test_slot_ownership_and_worker_principals_are_unique_across_mappings
        value = data
        value["launch_mappings"]["another"] = JSON.parse(JSON.generate(value["launch_mappings"]["mapping"]))
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        scope = value["launch_mappings"]["another"]["execution_scope"]
        scope.merge!("slot_id" => "another", "slice_unit" => "ace-another.slice", "service_unit" => "ace-another.service",
          "root_directory" => "/var/lib/ace-another/root", "runtime_directory" => "/run/ace-another")
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
      end

      def test_inbox_context_is_fixed_project_selection_without_native_repinnning
        deployment = Authority::Deployment.new(inbox_data)
        context = deployment.inbox_context("mapping", "inbox")
        assert_equal "mapping", context.fetch("native_mapping_id")
        refute context.key?("server_identity")
        refute context.key?("socket_identity")
        context["deliveries_dir"] = "/tmp/caller-change"
        assert_equal "/var/lib/ace-inbox", deployment.inbox_context("mapping", "inbox").fetch("deliveries_dir")
        assert_raises(AttemptErrors::EvidenceUnavailable) { deployment.inbox_context("mapping", "missing") }
      end

      def test_inbox_context_filesystem_refusal_preserves_private_directory_and_never_runs_client
        Dir.mktmpdir("ace-inbox-context-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          deliveries = File.join(root, "deliveries")
          Dir.mkdir(deliveries, 0700)
          File.write(File.join(deliveries, "retained"), "original")
          key = File.join(root, "key.pem")
          File.write(key, OpenSSL::PKey::RSA.new(1024).public_to_pem)
          client = File.join(root, "client")
          File.write(client, "#!/bin/sh\nexit 1\n")
          File.chmod(0700, client)
          value = inbox_data
          service = value["authorities"]["authority"]
          service.merge!("uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort)
          context = value["projects"]["project"]["inbox_contexts"]["inbox"]
          context.merge!("deliveries_dir" => deliveries, "receipt_public_key" => key,
            "pi_queue_client" => client, "pi_queue_client_sha256" => Digest::SHA256.file(client).hexdigest)
          deployment = Authority::Deployment.new(value)
          # Genuine filesystem ownership fails root-installed artifact policy;
          # no chmod/chown, global fallback or identity subprocess is attempted.
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_inbox_context!("mapping", "inbox") }
          File.chmod(0770, deliveries)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_inbox_context!("mapping", "inbox") }
          File.chmod(0700, deliveries)
          File.rename(deliveries, deliveries + "-original")
          File.symlink(deliveries + "-original", deliveries)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_inbox_context!("mapping", "inbox") }
          assert_equal "original", File.read(File.join(deliveries, "retained"))
          assert_equal 0700, File.stat(deliveries + "-original").mode & 0777
        end
      end

      def test_inbox_effective_acl_mask_cannot_hide_foreign_write_or_private_read
        deployment = Authority::Deployment.new(inbox_data)
        rows = nil
        acl = Object.new
        acl.define_singleton_method(:entries) { |path| path == "/installed" ? rows : nil }
        deployment.define_singleton_method(:receiver_acl) { acl }
        rows = [[1, 7, 0xffffffff], [4, 0, 0xffffffff], [32, 0, 0xffffffff], [16, 6, 0xffffffff], [2, 6, 13001]]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.send(:verify_inbox_acl!, "/installed") }
        rows[3][1] = 4
        deployment.send(:verify_inbox_acl!, "/installed")
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.send(:verify_inbox_acl!, "/installed", private_leaf: true) }
        rows[3][1] = 0
        deployment.send(:verify_inbox_acl!, "/installed", private_leaf: true)
      end

      def test_inbox_context_rejects_unknown_fields_bad_roles_native_selection_and_artifacts
        [->(context) { context["executable"] = "/tmp/arbitrary" },
         ->(context) { context["supervisor_uids"] = [13001] },
         ->(context) { context["supervisor_uids"] = [13005, 13005] },
         ->(context) { context["native_mapping_id"] = "unknown" },
         ->(context) { context["receipt_public_key"] = "relative.pem" },
         ->(context) { context["pi_queue_client"] = "/usr/../tmp/client" },
         ->(context) { context["pi_queue_client_sha256"] = "B" * 64 }].each do |change|
          value = inbox_data
          change.call(value["projects"]["project"]["inbox_contexts"]["inbox"])
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end

      def test_inbox_context_roots_cannot_alias_worker_receiver_authority_or_sibling_state
        ["/var/lib/ace-worker/messages", "/var/lib/ace-setup", "/var/lib/ace-authority/inbox",
          "/var/lib/ace-checkout", "/var/lib"].each do |root|
          value = inbox_data
          value["projects"]["project"]["inbox_contexts"]["inbox"]["deliveries_dir"] = root
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        value = inbox_data
        contexts = value["projects"]["project"]["inbox_contexts"]
        contexts["second"] = contexts["inbox"].merge("deliveries_dir" => "/var/lib/ace-inbox/nested")
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        value = inbox_data
        value["authorities"]["authority"]["composition"] = "launch"
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
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
