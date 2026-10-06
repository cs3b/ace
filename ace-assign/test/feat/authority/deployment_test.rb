# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require "ace/assign/authority/server"
require "timeout"

module Ace
  module Assign
    class ProtectedDeploymentTest < AceAssignTestCase
      class DescriptorArtifacts
        attr_reader :checked
        def initialize(bytes); @bytes = bytes; end
        def with; yield self; end
        def read!(reference)
          unless Digest::SHA256.hexdigest(@bytes) == reference.fetch("sha256") && @bytes.bytesize == reference.fetch("bytes")
            raise Ace::Runtime::RuntimeUnavailableError, "content mismatch"
          end
          @bytes
        end
        def verify_unchanged!; @checked = true; end
      end

      def authenticated_descriptor(value, bytes: JSON.generate(value))
        artifacts = DescriptorArtifacts.new(bytes)
        reference = {"path" => "/etc/ace/descriptors/#{Digest::SHA256.hexdigest(bytes)}.json",
          "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
        result = Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, artifacts) do
          Authority::Deployment.load_artifact(reference)
        end
        assert artifacts.checked
        assert result.frozen?
        assert result.data.frozen?
        result
      end

      def test_descriptor_artifact_is_strict_bounded_and_immutable
        descriptor = authenticated_descriptor(data)
        assert_raises(FrozenError) { descriptor.mapping("mapping")["project_id"] = "changed" }
        assert_raises(FrozenError) { descriptor.artifact_reference["path"].replace("/tmp/new") }
        assert_raises(JSON::ParserError) do
          authenticated_descriptor(data, bytes: '{"schema":"a","schema":"b"}')
        end
        assert_raises(ArgumentError) do
          Authority::Deployment.load_artifact({"path" => "/etc/ace/../bad", "bytes" => 1, "sha256" => "a" * 64})
        end
        assert_raises(ArgumentError) do
          Authority::Deployment.load_artifact({"path" => "/etc/ace/bad", "bytes" => 65_537, "sha256" => "a" * 64})
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          Authority::Deployment.new(data).maintenance_inventory(descriptor)
        end
      end

      def test_maintenance_inventory_preserves_original_and_rejects_reassociation
        original = authenticated_descriptor(data)
        value = data
        value["launch_mappings"]["mapping"]["bootstrap_sha256"] = "f" * 64
        candidate = authenticated_descriptor(value)
        inventory = original.maintenance_inventory(candidate)
        assert_same original, inventory.first[1]
        assert_equal "a" * 64, inventory.first[2].fetch("bootstrap_sha256")
        [->(v) { v["projects"]["project"]["journal_repository"] = "/var/lib/replaced" },
         ->(v) { v["authorities"]["authority"]["state_root"] = "/var/lib/replaced" },
         ->(v) { v["launch_mappings"]["mapping"]["execution_scope"]["slot_id"] = "replacement" }].each do |change|
          value = data
          change.call(value)
          assert_raises(ArgumentError) { original.maintenance_inventory(authenticated_descriptor(value)) }
        end
      end

      def replacement_descriptor
        value = data
        value["launch_mappings"]["new"] = value["launch_mappings"].delete("mapping")
        value["launch_mappings"]["new"]["execution_scope"].merge!("slot_id" => "new",
          "slice_unit" => "ace-new.slice", "service_unit" => "ace-new.service",
          "network_namespace_path" => "/run/netns/ace-new", "root_directory" => "/var/lib/ace-new/root",
          "runtime_directory" => "/run/ace-new")
        authenticated_descriptor(value)
      end

      def test_removed_original_is_retained_and_same_physical_slot_cannot_be_recycled
        original = authenticated_descriptor(data)
        inventory = original.maintenance_inventory(replacement_descriptor)
        assert_equal %w[mapping new], inventory.map(&:first)
        assert_same original, inventory.first[1]
        value = data
        value["launch_mappings"]["new"] = value["launch_mappings"].delete("mapping")
        assert_raises(ArgumentError) { original.maintenance_inventory(authenticated_descriptor(value)) }
      end

      class MaintenanceJournal
        attr_accessor :commit
        attr_reader :repo_root, :ref, :checkout_root, :reads
        def initialize(project)
          @repo_root, @ref, @checkout_root = project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root")
          @commit, @reads = "a" * 40, 0
        end
        def ref_value; commit; end
        def verify_commit!(value); raise "wrong commit" unless value == commit; true; end
        def assignment_ids(commit:); @reads += 1; []; end
      end

      class OrderedSlotLock
        def initialize(root, order); @root, @order = root, order; end
        def slot_key(slot); "execution-slot:#{slot}"; end
        def with_exclusive(key)
          @order << [:enter, @root, key]
          yield
        ensure
          @order << [:leave, @root, key]
        end
      end

      def test_maintenance_context_union_snapshot_lifetime_and_fail_closed_eligibility
        original = authenticated_descriptor(data)
        candidate = replacement_descriptor
        order = []
        journal = MaintenanceJournal.new(original.project("project"))
        owner = Authority::LaunchLifecycle.new(deployment: original, journals: {"project" => journal})
        owner.define_singleton_method(:verify_maintenance_root!) { |*| true }
        owner.define_singleton_method(:maintenance_journal_for) { |*| journal }
        factory = ->(root:) { OrderedSlotLock.new(root, order) }
        retained = nil
        Molecules::LifecycleExclusion.stub :new, factory do
          assert_raises(ArgumentError) { owner.with_execution_slots(mapping_ids: ["new"], candidate_deployment: candidate) {} }
          owner.with_execution_slots(mapping_ids: %w[new mapping], candidate_deployment: candidate) do |contexts|
            assert contexts.frozen?
            assert_raises(AttemptErrors::Conflict) do
              owner.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: original) {}
            end
            assert_equal %w[mapping new], contexts.map { |c| c.fetch(:mapping_id) }
            assert_equal 1, journal.reads
            contexts.each do |context|
              assert context.frozen?
              assert context.fetch(:commit).frozen?
              error = assert_raises(AttemptErrors::EvidenceUnavailable) { owner.slot_reusable!(**context) }
              assert_match(/complete original authentication/, error.message)
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.retire_released_parent!(**context) }
            end
            retained = contexts.first
            journal.commit = "b" * 40
            assert_raises(AttemptErrors::Conflict) { owner.slot_reusable!(**retained) }
            journal.commit = "a" * 40
          end
        end
        assert_equal [[:enter, "/var/lib/ace-authority/execution-slot-exclusion", "execution-slot:new"],
          [:enter, "/var/lib/ace-authority/execution-slot-exclusion", "execution-slot:slot"],
          [:leave, "/var/lib/ace-authority/execution-slot-exclusion", "execution-slot:slot"],
          [:leave, "/var/lib/ace-authority/execution-slot-exclusion", "execution-slot:new"]], order
        assert_raises(AttemptErrors::EvidenceUnavailable) { owner.slot_reusable!(**retained) }
      end

      def test_removed_and_added_same_project_ids_use_distinct_fixed_roots_and_lexical_locks
        original_data = data
        original_data["authorities"]["authority"]["state_root"] = "/var/lib/z-original"
        original = authenticated_descriptor(original_data)
        value = JSON.parse(JSON.generate(replacement_descriptor.data))
        value["authorities"]["authority"]["state_root"] = "/var/lib/a-candidate"
        value["projects"]["project"]["journal_repository"] = "/var/lib/new-journal"
        value["projects"]["project"]["evidence_checkout_root"] = "/var/lib/new-checkout"
        candidate = authenticated_descriptor(value)
        original_journal = MaintenanceJournal.new(original.project("project"))
        candidate_journal = MaintenanceJournal.new(candidate.project("project"))
        owner = Authority::LaunchLifecycle.new(deployment: original, journals: {"project" => original_journal})
        owner.define_singleton_method(:verify_maintenance_root!) { |*| true }
        owner.define_singleton_method(:maintenance_journal_for) do |selected, _map|
          selected.equal?(original) ? original_journal : candidate_journal
        end
        order = []
        Molecules::LifecycleExclusion.stub :new, ->(root:) { OrderedSlotLock.new(root, order) } do
          owner.with_execution_slots(mapping_ids: %w[mapping new], candidate_deployment: candidate) do |contexts|
            assert_equal [original_journal, candidate_journal], contexts.map { |context| context.fetch(:journal) }
            assert_equal [1, 1], [original_journal.reads, candidate_journal.reads]
          end
        end
        assert_equal ["/var/lib/a-candidate/execution-slot-exclusion", "/var/lib/z-original/execution-slot-exclusion"],
          order.select { |row| row.first == :enter }.map { |row| row[1] }
      end

      def test_real_maintenance_snapshot_and_normal_admission_lock_contention
        with_temp_cache do |root|
          repo = File.join(root, "journal")
          FileUtils.mkdir_p(repo)
          git_fixture(repo, "init", "-b", "main")
          git_fixture(repo, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "--allow-empty", "-m", "base")
          commit = git_fixture(repo, "rev-parse", "HEAD").strip
          ref = "refs/ace/execution"
          git_fixture(repo, "update-ref", ref, commit)
          value = data
          value["authorities"]["authority"]["state_root"] = File.join(root, "state")
          value["projects"]["project"].merge!("journal_repository" => repo,
            "evidence_checkout_root" => File.join(root, "checkout"))
          deployment = authenticated_descriptor(value)
          maintenance = Authority::LaunchLifecycle.new(deployment: deployment)
          maintenance.define_singleton_method(:verify_maintenance_root!) { |*| true }
          normal = Authority::LaunchLifecycle.new(deployment: deployment)
          started, admitted = Queue.new, Queue.new
          thread = nil
          maintenance.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: deployment) do |contexts|
            assert_equal commit, contexts.first.fetch(:commit)
            thread = Thread.new do
              started << true
              normal.send(:with_slot, deployment.mapping("mapping")) { admitted << true }
            end
            started.pop
            assert_raises(Timeout::Error) { Timeout.timeout(0.1) { admitted.pop } }
            git_fixture(repo, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "--allow-empty", "-m", "new")
            changed = git_fixture(repo, "rev-parse", "HEAD").strip
            git_fixture(repo, "update-ref", ref, changed)
            assert_raises(AttemptErrors::Conflict) { maintenance.slot_reusable!(**contexts.first) }
          end
          assert Timeout.timeout(2) { admitted.pop }
          thread.join
          git_fixture(repo, "update-ref", "-d", ref)
          yielded = false
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            maintenance.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: deployment) { yielded = true }
          end
          refute yielded
        ensure
          thread&.kill if thread&.alive?
          thread&.join
        end
      end

      def git_fixture(repo, *arguments)
        output, error, status = Open3.capture3("git", "-C", repo, *arguments)
        assert status.success?, error
        output
      end

      def test_descriptor_loader_rejects_invalid_utf8_and_changed_digest
        bad = "\xff".b
        assert_raises(ArgumentError) { authenticated_descriptor(data, bytes: bad) }
        bytes = JSON.generate(data)
        artifacts = DescriptorArtifacts.new(bytes)
        reference = {"path" => "/etc/ace/fixed.json", "sha256" => "f" * 64, "bytes" => bytes.bytesize}
        Ace::Runtime::Molecules::ProtectedArtifactSet.stub :new, artifacts do
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { Authority::Deployment.load_artifact(reference) }
        end
      end

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
