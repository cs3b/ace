# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/deployment"
require "ace/assign/authority/deployment_history"
require_relative "../../support/execution_boot_baseline_owner_fixture"
require "ace/assign/authority/server"
require "timeout"
require_relative "../../support/execution_scope_observation_fixtures"
require_relative "../../support/prepared_registration_fixture"
require_relative "../../support/protected_control_fixture"
require_relative "../../support/protected_workspace_fixture"

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

      class FixtureProtection
        def root_path!(_path); true; end
        def verify!(_path, handle, directory:)
          raise "unexpected fixture type" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      class MaintenanceKernel
        Handle = Struct.new(:identity) { def close; end }
        def capture(pid)
          {"pid" => pid, "uid" => 13002, "gid" => 13002, "groups" => [13002],
            "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:#{pid}", "host" => "fixture", "parent_pid" => 1}
        end
        def live!(_identity); true; end
        def pin(identity); Handle.new(identity); end
        def same?(left, right); left == right; end
      end

      include ExecutionBootBaselineOwnerFixture

      class MaintenanceScopeOwner
        attr_reader :retirements, :checks
        attr_accessor :resources
        def initialize(map, boot_baseline_selection:, network_selection:, deployment: nil)
          @map, @retirements, @checks = map, 0, 0
          @deployment = deployment
          @resources = []
          @boot_baseline_selection, @network_selection = boot_baseline_selection, network_selection
        end
        def activate_parent!(context)
          canonical = lambda do |value|
            case value
            when Hash then value.keys.sort.to_h { |key| [key, canonical.call(value[key])] }
            when Array then value.map { |item| canonical.call(item) }
            else value
            end
          end
          context.merge("slot_id" => @map.fetch("execution_scope").fetch("slot_id"),
            "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical.call(@map))),
            "boot_id" => ExecutionScopeObservationFixtures::BOOT, "slice_invocation_id" => "b" * 32,
            "resource_mount_namespace_identity" => {"device" => 4, "inode" => 11}, "resource_identities" => @resources,
            "network_namespace_identity" => {"device" => 7, "inode" => 88},
            "boot_baseline_selection" => @boot_baseline_selection, "network_installation_selection" => @network_selection,
            "cgroup_identity" => {"path" => "/sys/fs/cgroup/#{@map.fetch('execution_scope').fetch('slice_unit')}", "mount_id" => 4,
              "filesystem_type" => "cgroup2", "device" => 5, "inode" => @map.fetch("worker_uid")})
        end
        def maintenance_workspace_resource!(lineage)
          selected = lineage.binding.fetch("resource_identities").select { |entry| entry.fetch("host_path") == @map.fetch("worker_cwd") }
          raise AttemptErrors::EvidenceUnavailable, "controlled original workspace unavailable" unless selected.one? && selected.first.fetch("inode").positive?
          selected.first
        end
        def maintenance_parent_resource_declarations!(lineage)
          lineage.binding.fetch("resource_identities").map do |entry|
            entry.slice("host_path", "view_path").merge("stage" => "parent", "worker_visible" => true,
              "read_only" => entry.fetch("view_path") == "/run/ace/lifecycle-exclusion/mapping")
          end
        end
        def workspace_exclusion_projection!(lineage)
          declarations = maintenance_parent_resource_declarations!(lineage)
          files = Object.new
          files.define_singleton_method(:boundary_manifest) { |_scope| {"resources" => declarations} }
          Authority::ExecutionScopeObservation.new(mapping_id: "mapping", deployment: @deployment,
            kernel: Object.new, files: files, manager: Object.new).workspace_exclusion_projection!(lineage)
        end
        def observe(_lineage); {"populated" => 0}; end
        def native_admission_ready!(_lineage)
          raise AttemptErrors::EvidenceUnavailable, "controlled fixture stops before native admission"
        end
        def stop_sealed_service!; true; end
        def sealed_service_stop_required?(_lineage); false; end
        def closed_observation_for_proof!(lineage, events:)
          lineage.binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
        end
        def verify_closed!(lineage)
          raise AttemptErrors::EvidenceUnavailable, "missing canonical closed proof" unless lineage.proof_id
          lineage.require_positive!(scope_generation: lineage.binding.fetch("scope_generation"),
            scope_binding_event_id: lineage.binding_event.fetch("digest"), seal_event_id: lineage.seal_event.fetch("digest"), proof_id: lineage.proof_id)
          true
        end
        def verify_maintenance_closed!(lineages, retirement: nil)
          retirement.verify_consumption! if retirement
          @checks += 1
          lineages.each { |lineage| verify_closed!(lineage) }
          true
        end
        def retire_released_parent!(lineages)
          verify_maintenance_closed!(lineages)
          @retirements += 1
          {"state" => "retired"}
        end
      end

      def test_original_release_maintenance_candidate_publication_and_fresh_normal_reservation
        Dir.mktmpdir("original-control-", Etc.getpwuid(Process.uid).dir) do |root|
          root = File.realpath(root)
          value = data
          value.fetch("launch_mappings").fetch("mapping").merge!("workspace_repository_id" => "repo",
            "workspace_cleanup_config" => {"path" => "/fixed/cleanup-config.json", "sha256" => "a" * 64, "bytes" => 100})
          untouched = JSON.parse(JSON.generate(value.fetch("launch_mappings").fetch("mapping")))
          untouched.merge!("worker_uid" => 13006, "worker_gid" => 13006, "worker_groups" => [13006], "worker_actor" => "untouched-worker")
          untouched.fetch("execution_scope").merge!("slot_id" => "untouched", "slice_unit" => "ace-untouched.slice",
            "service_unit" => "ace-untouched.service", "root_directory" => "/var/lib/ace-untouched/root",
            "runtime_directory" => "/run/ace-untouched", "network_namespace_path" => "/run/netns/ace-untouched")
          untouched.fetch("native").merge!("workspace_id" => "w2", "socket_path" => "/run/herdr-untouched/control.sock")
          value.fetch("launch_mappings")["untouched"] = untouched
          value.dig("projects", "project", "worker_uids") << 13006
          value.dig("projects", "project", "peer_credentials")["13006"] = {"gid" => 13006, "groups" => [13006], "scratch_root" => "/var/lib/ace-untouched-worker"}
          value["authorities"]["authority"]["state_root"] = File.join(root, "state")
          project = value["projects"]["project"]
          %w[journal_repository evidence_checkout_root assignment_root candidate_root].each do |field|
            project[field] = File.join(root, field)
            FileUtils.mkdir_p(project[field], mode: 0o700)
          end
          FileUtils.mkdir_p(value["authorities"]["authority"]["state_root"], mode: 0o700)
          FileUtils.mkdir_p(File.join(value["authorities"]["authority"]["state_root"], "lifecycle-exclusion", "project", "control"), mode: 0o700)
          repo = project.fetch("journal_repository")
          _out, error, status = Open3.capture3("git", "init", "-b", "main", repo)
          assert status.success?, error
          _out, error, status = Open3.capture3("git", "-C", repo, "-c", "user.name=test", "-c", "user.email=test@fixture.invalid", "commit", "--allow-empty", "-m", "fixture")
          assert status.success?, error
          ref = lambda do |name, bytes|
            path = File.join(root, name); File.binwrite(path, bytes)
            {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
          end
          worktree = File.join(root, "original-worktree")
          _out, error, status = Open3.capture3("git", "-C", repo, "worktree", "add", "-b", "retirement-target", worktree, "HEAD")
          assert status.success?, error
          value.fetch("launch_mappings").fetch("mapping")["worker_cwd"] = worktree
          original_ref = ref.call("original.json", JSON.generate(value))
          changed = JSON.parse(JSON.generate(value))
          changed["launch_mappings"]["mapping"]["worker_actor"] = "rotated-worker"
          changed.fetch("launch_mappings").fetch("mapping").merge!("workspace_repository_id" => "successor-repo",
            "workspace_cleanup_config" => {"path" => "/fixed/successor-config.json", "sha256" => "b" * 64, "bytes" => 200})
          candidate_ref = ref.call("candidate.json", JSON.generate(changed))
          manifest_ref = ref.call("history.json", JSON.generate("schema" => "ace.assign.deployment-history/v1",
            "original_descriptor" => original_ref, "candidate_descriptor" => candidate_ref,
            "descriptors" => [original_ref, candidate_ref], "public_keys" => []))
          published = File.join(root, "published.json")
          File.binwrite(published, File.binread(original_ref.fetch("path")))
          selections = {Authority::Deployment::PATH => published, Authority::DeploymentHistory::PATH => manifest_ref.fetch("path")}
          factory = lambda do
            reader = Ace::Runtime::Molecules::ProtectedArtifactSet.allocate
            reader.send(:initialize, protection: FixtureProtection.new)
            held_read = reader.method(:read_path!)
            reader.define_singleton_method(:read_path!) do |path, limit:|
              bytes, selected = held_read.call(selections.fetch(path), limit: limit)
              [bytes, selected.merge("path" => path.dup.freeze).freeze]
            end
            reader
          end
          history, original = Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) do
            [Authority::DeploymentHistory.load, Authority::Deployment.load]
          end
          candidate = history.candidate
          assert_equal Authority::Deployment::PATH, original.artifact_reference.fetch("path")
          refute_equal original.artifact_reference.fetch("path"), history.original.artifact_reference.fetch("path")
          kernel = MaintenanceKernel.new
          peer = kernel.capture(Process.pid)
          journal = Molecules::EvidenceJournal.new(repo_root: repo, ref: project.fetch("evidence_git_ref"), checkout_root: project.fetch("evidence_checkout_root"),
            mode: :protected, evidence_reader: ->(*) { raise "no service evidence expected" }, service_authorizer: ->(*) { raise "no service mutation expected" })
          installer = ref.call("original-installer", "controlled retained installer")
          network = ExecutionScopeObservationFixtures::NETWORK_SELECTION.merge("installer_artifact" => installer)
          scope_for = lambda do |map, name, source_owner = original|
            proof = retained_boot_baseline_artifact(root: root, name: name, map: map, installer: installer)
            MaintenanceScopeOwner.new(map, boot_baseline_selection: proof, network_selection: network, deployment: source_owner)
          end
          owner = fresh = nil
          bad_current = File.join(root, "untrusted-current-boot.json")
          File.binwrite(bad_current, "wrong current pointer")
          pointers = %w[slot untouched-slot].to_h { |slot| ["/etc/ace/execution-slots/#{slot}/boot-baseline-selection.json", bad_current] }
          boot_factory = -> { fixture_boot_baseline_reader(protection: FixtureProtection.new, pointers: pointers) }
          Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, boot_factory) do
            observer = scope_for.call(original.mapping("mapping"), "original-boot.json")
            cwd_stat = File.stat(worktree)
            observer.resources = [{"host_path" => original.mapping("mapping").fetch("worker_cwd"), "view_path" => "/workspace",
              "mount_id" => 4, "filesystem_type" => "ext4", "device" => cwd_stat.dev, "inode" => cwd_stat.ino, "uid" => cwd_stat.uid, "gid" => cwd_stat.gid}]
            authority = original.authority(original.mapping("mapping").fetch("authority_id"))
            lock_selection = Molecules::LifecycleExclusion.workspace_selection(mapping_id: "mapping", project_id: "project",
              authority: authority, cwd_resource: observer.resources.first)
            lock_root = lock_selection.fetch("host_path")
            FileUtils.mkdir_p(lock_root, mode: 0o755)
            File.chmod(0o755, lock_root)
            File.write(File.join(lock_root, "#{Digest::SHA256.hexdigest(lock_selection.fetch('key'))}.lock"), "")
            File.write(File.join(lock_root, "#{Digest::SHA256.hexdigest(lock_selection.fetch('key'))}.state.json"), Atoms::EvidenceDigest.canonical_json(
              {"key" => lock_selection.fetch("key"), "removed" => false, "removed_at" => nil}))
            Dir.children(lock_root).each { |name| File.chmod(0o644, File.join(lock_root, name)) }
            lock_stat = File.stat(lock_root)
            observer.resources << lock_selection.slice("host_path", "view_path").merge("mount_id" => 4,
              "filesystem_type" => "ext4", "device" => lock_stat.dev, "inode" => lock_stat.ino, "uid" => authority.fetch("uid"), "gid" => authority.fetch("gid"))
            untouched_observer = scope_for.call(original.mapping("untouched"), "untouched-boot.json")
            observers = {"mapping" => observer, "untouched" => untouched_observer}
            owner = Authority::LaunchLifecycle.new(deployment: original, deployment_history: history, kernel: kernel,
              journals: {"project" => journal}, control_exclusion_factory: ProtectedControlFixture.factory, scope_observer_factory: ->(id) { observers.fetch(id) })
            owner.define_singleton_method(:verify_maintenance_root!) { |*| true }
            dispatch = lambda do |authority, operation, params, mutation|
              request = {"version" => 1, "operation" => operation, "mutation_id" => mutation,
                "project_id" => "project", "params" => params.merge("mapping_id" => params.fetch("mapping_id", "mapping"), "assignment_id" => params.fetch("assignment_id", "assignment"))}
              if operation == "register_assignment"
                fixture = PreparedRegistrationFixture.build(root: root, definition: JSON.parse(params.fetch("definition_bytes")), scope: params["mapping_id"] == "untouched" ? "020" : "010")
                fixture.with_input(root: root) do |input, descriptor|
                  authority.dispatch(request: request.merge("params" => fixture.header(expected_generation: params.fetch("expected_generation")).merge(request.fetch("params").slice("mapping_id", "assignment_id"), "transfer" => descriptor)), peer: peer, role: :launcher, transfer: input)
                end
              else
                authority.dispatch(request: request, peer: peer, role: :launcher)
              end
            end
            bytes = JSON.generate("session_id" => "assignment", "name" => "fixture", "created_at" => "2026-10-05T00:00:00Z",
              "source_config" => "job.yaml", "task_id" => "09j", "project_id" => "project")
            registered = dispatch.call(owner, "register_assignment", {"definition_bytes" => bytes, "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => 0}, "register").fetch(:data)
            empty_context = nil
            owner.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: candidate) do |contexts|
              empty_context = contexts.first
              empty = owner.maintenance_boot_baselines!(**empty_context)
              assert_equal [], empty
              assert empty.frozen?
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**empty_context) }
            reserve = {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => "a" * 40,
              "launcher_process_binding" => peer, "expected_generation" => registered.fetch("definition_generation")}
            state = dispatch.call(owner, "reserve_attempt", reserve, "reserve-old").fetch(:data)
            generation = -> { journal.authority_generation(journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }) }
            close_params = state.slice("attempt_id").merge("mapping_id" => "mapping", "assignment_id" => "assignment")
            owner.close_execution_scope!(params: close_params.merge("mutation_id" => "seal", "expected_generation" => generation.call), peer: peer, role: :launcher)
            closed = owner.close_execution_scope!(params: close_params.merge("mutation_id" => "proof", "expected_generation" => generation.call), peer: peer, role: :launcher)
            events = journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }
            lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: "project", assignment_id: "assignment", attempt_id: state.fetch("attempt_id"), mapping_id: "mapping")
            failure = JSON.generate("kind" => "protected_scope_before_release", "scope_generation" => lineage.binding.fetch("scope_generation"),
              "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "proof_id" => closed.dig(:data, "proof_id"))
            dispatch.call(owner, "abort_launch", state.slice("attempt_id", "launch_ticket").merge("expected_generation" => generation.call,
              "failure_evidence" => failure, "failure_digest" => Digest::SHA256.hexdigest(failure)), "abort-old")
            assert journal.read_events("assignment").any? { |event| event.dig("payload", "operation") == "scope_reservation_release" }
            other_bytes = JSON.generate(JSON.parse(bytes).merge("session_id" => "assignment-b"))
            other_registered = dispatch.call(owner, "register_assignment", {"mapping_id" => "untouched", "assignment_id" => "assignment-b",
              "definition_bytes" => other_bytes, "definition_digest" => Digest::SHA256.hexdigest(other_bytes), "expected_generation" => 0}, "register-untouched")
            active = dispatch.call(owner, "reserve_attempt", reserve.merge("mapping_id" => "untouched", "assignment_id" => "assignment-b", "scope" => "020", "worker_uid" => 13006,
              "expected_generation" => other_registered.dig(:data, "definition_generation")), "reserve-untouched")
            assert_equal "reserved", active.dig(:data, "phase")
            prior_retirements = observer.retirements
            snapshot = {mapping_id: "mapping", journal: journal, commit: journal.ref_value}
            assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**snapshot) }
            # One selected unreleased root prevents every retirement. An active
            # untouched slot is attributable and does not block slot A alone.
            owner.with_execution_slots(mapping_ids: %w[mapping untouched], candidate_deployment: candidate) do |contexts|
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.retire_released_parent!(**contexts.first) }
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**contexts.first) }
              released = journal.read_events("assignment").find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                owner.maintenance_workspace_target!(**contexts.first, assignment_id: "assignment", attempt_id: state.fetch("attempt_id"),
                  binding_event_digest: lineage.binding_event.fetch("digest"), release_event_digest: released.fetch("digest"),
                  descriptor_sha256: original.artifact_reference.fetch("sha256"))
              end
              assert_equal prior_retirements, observer.retirements
            end
            retained_context = nil
            target_params = nil
            advanced = nil
            owner.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: candidate) do |contexts|
              retained_context = contexts.first
              assert owner.slot_reusable!(**contexts.first)
              entries = owner.maintenance_boot_baselines!(**contexts.first)
              assert_equal 1, entries.size
              released = journal.read_events("assignment").find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
              target_params = contexts.first.merge(assignment_id: "assignment", attempt_id: state.fetch("attempt_id"),
                binding_event_digest: lineage.binding_event.fetch("digest"), release_event_digest: released.fetch("digest"),
                descriptor_sha256: original.artifact_reference.fetch("sha256"))
              target = owner.maintenance_workspace_target!(**target_params)
              assert_equal original.mapping("mapping").fetch("worker_cwd"), target.fetch("worker_cwd")
              assert_equal observer.resources.first, target.fetch("workspace_resource")
              assert_equal original.mapping_digest("mapping"), target.fetch("original_mapping_digest")
              assert_equal lineage.proof_event.fetch("digest"), target.fetch("proof_event_digest")
              assert_equal "repo", target.fetch("workspace_repository_id")
              assert_equal original.mapping("mapping").fetch("workspace_cleanup_config"), target.fetch("workspace_cleanup_config")
              refute_equal candidate.mapping("mapping").fetch("workspace_repository_id"), target.fetch("workspace_repository_id")
              refute_equal candidate.mapping("mapping").fetch("workspace_cleanup_config"), target.fetch("workspace_cleanup_config")
              assert_equal observer.resources, target.fetch("resource_identities")
              assert_equal observer.maintenance_parent_resource_declarations!(lineage), target.fetch("parent_resource_declarations")
              assert_equal lock_selection.fetch("key"), target.dig("workspace_exclusion", "key")
              assert_equal observer.resources.last, target.dig("workspace_exclusion", "root_resource")
              assert target.fetch("workspace_exclusion").frozen?
              assert_equal %w[assignment_id attempt_id binding_event_digest descriptor_sha256 journal_commit mapping_id original_mapping_digest parent_resource_declarations project_id proof_event_digest release_event_digest resource_identities worker_cwd workspace_cleanup_config workspace_exclusion workspace_repository_id workspace_resource], target.keys.sort
              assert_raises(FrozenError) { target.fetch("workspace_cleanup_config")["path"].replace("/wrong") }
              assert_raises(FrozenError) { target.fetch("parent_resource_declarations").first["read_only"] = true }
              assert_raises(FrozenError) { target.fetch("workspace_resource")["inode"] = 0 }
              assert_raises(FrozenError) { target.fetch("worker_cwd").replace("/replaced") }
              retirement_target = target.slice(*Authority::MaintenanceWorkspaceRetirement::TARGET_FIELDS).merge(
                "resource" => "workspace:project:mapping:assignment")
              collection = Object.new
              active_collection = false
              escaped_evidence = nil
              collection.define_singleton_method(:verify_retirement_evidence!) do |**|
                raise AttemptErrors::EvidenceUnavailable, "collection lifetime ended" unless active_collection
                true
              end
              collection.define_singleton_method(:with_retirement_evidence!) do |phase:, target:, projection:, deadline:, &block|
                active_collection = true
                rows = projection.fetch("parent_resource_declarations").select { |row| row.fetch("host_path") == projection.fetch("worker_cwd") }.map { |decl|
                  projection.fetch("resource_identities").find { |row| row.values_at("host_path", "view_path") == decl.values_at("host_path", "view_path") }}
                descriptor = {"schema" => Authority::MaintenanceWorkspaceRetirement::SCHEMA, "phase" => phase, "target" => target,
                  "resource" => projection.fetch("workspace_resource"), "covered_resources" => rows.map { |row|
                    {"original" => row, "captured_host_path" => File.join(root, "captured-worktree")} },
                  "invocation" => {"request_id" => "request", "input_digest" => "d" * 64,
                    "operation_owner_binding_digest" => "e" * 64, "dispatch_event_digest" => "f" * 64},
                  "refs" => Authority::MaintenanceWorkspaceRetirement::REFERENCES.fetch(phase).to_h { |key|
                    [key, {"path" => "/fixed/#{key}", "sha256" => "1" * 64, "bytes" => 10}] }}
                escaped_evidence = Authority::MaintenanceWorkspaceRetirement::Evidence.mint!(owner: self, descriptor: descriptor)
                block.call(escaped_evidence)
              ensure
                active_collection = false
              end
              observed = owner.maintenance_workspace_readback!(**contexts.first, target: retirement_target,
                evidence_owner: collection, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10) do |readback, evidence|
                assert active_collection
                assert_equal target, readback
                assert evidence.verify_consumption!
                "read-only observation"
              end
              assert_equal "read-only observation", observed
              refute active_collection
              # Namespace ownership is injected; maintained protection, real
              # lock descriptors, flock, fsync and Git admin mutation remain real.
              exclusion = target.fetch("workspace_exclusion")
              writer_files = ProtectedWorkspaceFixture::WriterFiles.new(lock_root, lock_selection.fetch("view_path"), lock_root)
              raw_open, raw_lstat = writer_files.method(:open), writer_files.method(:lstat)
              selected_owner = authority.values_at("uid", "gid")
              writer_files.define_singleton_method(:open) do |path, flags, mode = nil, &block|
                handle = raw_open.call(path, flags, mode)
                owner_ids = path.end_with?(".fence") || path.end_with?(".state.json") && marker_owner == [0, 0] ? [0, 0] : selected_owner
                held = ProtectedWorkspaceFixture::Handle.new(handle, owner_ids)
                return held unless block
                begin
                  block.call(held)
                ensure
                  held.close
                end
              end
              writer_files.define_singleton_method(:lstat) do |path|
                owner_ids = path.end_with?(".state.json") && marker_owner == [0, 0] ? [0, 0] : selected_owner
                ProtectedWorkspaceFixture::StatView.new(raw_lstat.call(path), owner_ids)
              end
              mounts = Object.new
              mounts.define_singleton_method(:mount_identity) { |_handle| {"filesystem_type" => "ext4"} }
              writer_protection = Molecules::LifecycleExclusion::WorkspaceWriter::Protection.new(projection: exclusion,
                mounts: mounts, acl: ProtectedWorkspaceFixture::ACL.new)
              writer = Molecules::LifecycleExclusion.workspace_writer(projection: exclusion, protection: writer_protection, files: writer_files)
              deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
              writer.acquire!(deadline: deadline)
              collection.define_singleton_method(:retirement_workspace_writer!) { writer }
              retained_session = nil
              captured_evidence = removed_evidence = nil
              begin
                callback_error = IOError.new("controlled caller failure")
                interrupted_session = nil
                raised = assert_raises(IOError) do
                  owner.with_workspace_retirement!(**contexts.first, target: retirement_target, evidence_owner: collection, deadline: deadline) do |session|
                    interrupted_session = session
                    raise callback_error
                  end
                end
                assert_same callback_error, raised
                assert writer.verify_unchanged!, "session borrows rather than closes the original writer"
                collection.with_retirement_evidence!(phase: "captured", target: retirement_target, projection: target, deadline: deadline) do |proof|
                  assert_raises(AttemptErrors::EvidenceUnavailable) { interrupted_session.verify_captured!(evidence: proof) }
                end
                assert_raises(AttemptErrors::MaintenanceBusy) { owner.with_workspace_retirement!(**contexts.first,
                  target: retirement_target, evidence_owner: collection, deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1) {} }
                owner.with_workspace_retirement!(**contexts.first, target: retirement_target, evidence_owner: collection, deadline: deadline) do |session|
                  retained_session = session
                  collection.with_retirement_evidence!(phase: "captured", target: retirement_target, projection: target, deadline: deadline) do |proof|
                    pinned_commit = contexts.first.fetch(:commit)
                    next_commit, error, status = Open3.capture3("git", "-C", repo, "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid",
                      "commit-tree", "#{pinned_commit}^{tree}", "-p", pinned_commit, "-m", "retirement current-ref invalidation")
                    assert status.success?, error
                    next_commit = next_commit.strip
                    journal.send(:git!, "update-ref", journal.ref, next_commit, pinned_commit)
                    begin
                      assert_raises(AttemptErrors::Conflict) { session.verify_captured!(evidence: proof) }
                    ensure
                      journal.send(:git!, "update-ref", journal.ref, pinned_commit, next_commit)
                    end
                  end
                  # No removed proof or cross-thread use can advance this session.
                  collection.with_retirement_evidence!(phase: "removed", target: retirement_target, projection: target, deadline: deadline) do |proof|
                    assert_raises(AttemptErrors::EvidenceUnavailable) { session.verify_removed!(evidence: proof) }
                  end
                  capture_path = File.join(root, "captured-worktree")
                  _out, error, status = Open3.capture3("git", "-C", repo, "worktree", "move", worktree, capture_path)
                  assert status.success?, error
                  assert_equal cwd_stat.ino, File.stat(capture_path).ino
                  collection.with_retirement_evidence!(phase: "captured", target: retirement_target, projection: target, deadline: deadline) do |proof|
                    captured_evidence = proof
                    assert_raises(AttemptErrors::EvidenceUnavailable) { Thread.new { Thread.current.report_on_exception = false; session.verify_captured!(evidence: proof) }.value }
                    assert session.verify_captured!(evidence: proof)
                    assert_raises(AttemptErrors::EvidenceUnavailable) { session.verify_captured!(evidence: proof) }
                  end
                  writer.publish_removed!(removed_at: "2026-10-08T00:00:00Z")
                  _out, error, status = Open3.capture3("git", "-C", repo, "worktree", "remove", "--force", capture_path)
                  assert status.success?, error
                  refute File.exist?(capture_path)
                  collection.with_retirement_evidence!(phase: "removed", target: retirement_target, projection: target, deadline: deadline) do |proof|
                    removed_evidence = proof
                    assert session.verify_removed!(evidence: proof)
                    refute proof.descriptor.fetch("refs").key?("receipt")
                  end
                end
                assert_raises(AttemptErrors::EvidenceUnavailable) { retained_session.verify_removed!(evidence: removed_evidence) }
                assert_raises(AttemptErrors::EvidenceUnavailable) { captured_evidence.verify_consumption! }
                assert_raises(AttemptErrors::EvidenceUnavailable) { removed_evidence.verify_consumption! }
              ensure
                writer.close!
              end
              assert_raises(AttemptErrors::EvidenceUnavailable) { escaped_evidence.verify_consumption! }
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_workspace_readback!(**contexts.first,
                target: retirement_target.merge("release_event_digest" => "0" * 64), evidence_owner: collection,
                deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10) {} }
              [:assignment_id, :attempt_id, :binding_event_digest, :release_event_digest, :descriptor_sha256].each do |selector|
                assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_workspace_target!(**target_params.merge(selector => "wrong")) }
              end
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_workspace_target!(**target_params.merge(commit: "f" * 40)) }
              entry = entries.first
              assert_equal lineage.binding.fetch("boot_baseline_selection"), entry.fetch("boot_baseline_selection")
              assert_equal lineage.binding.fetch("network_installation_selection"), entry.fetch("network_installation_selection")
              assert_equal lineage.binding.fetch("network_namespace_identity"), entry.fetch("network_namespace_identity")
              refute_same lineage.binding.fetch("network_installation_selection"), entry.fetch("network_installation_selection")
              assert_equal original.artifact_reference.fetch("sha256"), entry.fetch("descriptor_sha256")
              assert_equal lineage.binding_event.fetch("digest"), entry.fetch("scope_binding_event_id")
              assert_equal state.fetch("attempt_id"), entry.fetch("attempt_id")
              assert_equal ExecutionScopeObservationFixtures::DEVPTS_SELECTED, entry.dig("baseline", "selected_devpts")
              assert entries.frozen?
              assert_raises(FrozenError) { entry.fetch("boot_baseline_selection")["sha256"].replace("b" * 64) }
              assert_raises(FrozenError) { entry.dig("baseline", "selected_devpts")["path"].replace("/other") }
              assert_raises(FrozenError) { entry.dig("network_installation_selection", "installer_artifact", "path").replace("/other") }
              assert_raises(FrozenError) { entry.fetch("network_namespace_identity")["inode"] = 0 }
              assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**contexts.first.merge(commit: "f" * 40)) }
              proof_path = entry.fetch("boot_baseline_selection").fetch("path")
              original_bytes = File.binread(proof_path)
              begin
                File.binwrite(proof_path, original_bytes + " ")
                assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**contexts.first) }
              ensure
                File.binwrite(proof_path, original_bytes)
              end
              pinned = contexts.first.fetch(:commit)
              advanced, _, status = Open3.capture3("git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid",
                "commit-tree", "#{pinned}^{tree}", "-p", pinned, "-m", "controlled ref advance", chdir: repo)
              assert status.success?
              advanced = advanced.delete_suffix("\n")
              original_verify = owner.method(:verify_historical_boot_baseline!)
              changed = false
              owner.define_singleton_method(:verify_historical_boot_baseline!) do |binding|
                value = original_verify.call(binding)
                unless changed
                  _, _, update = Open3.capture3("git", "update-ref", journal.ref, advanced, pinned, chdir: repo)
                  raise "fixture ref advance failed" unless update.success?
                  changed = true
                end
                value
              end
              begin
                assert_raises(AttemptErrors::Conflict) { owner.maintenance_boot_baselines!(**contexts.first) }
                _, _, reset = Open3.capture3("git", "update-ref", journal.ref, pinned, advanced, chdir: repo)
                assert reset.success?
                changed = false
                assert_raises(AttemptErrors::Conflict) { owner.maintenance_workspace_target!(**target_params) }
              ensure
                owner.singleton_class.send(:remove_method, :verify_historical_boot_baseline!)
                _, _, restored = Open3.capture3("git", "update-ref", journal.ref, pinned, advanced, chdir: repo)
                assert restored.success?
              end
              assert_equal "retired", owner.retire_released_parent!(**contexts.first).fetch("state")
            end
            assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_boot_baselines!(**retained_context) }
            assert_raises(AttemptErrors::EvidenceUnavailable) { owner.maintenance_workspace_target!(**target_params) }
            source_commit = retained_context.fetch(:commit)
            _, _, advance_status = Open3.capture3("git", "update-ref", journal.ref, advanced, source_commit, chdir: repo)
            assert advance_status.success?
            owner.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: candidate) do |contexts|
              current_params = target_params.merge(contexts.first)
              historical = owner.maintenance_workspace_target!(**current_params, source_commit: source_commit)
              assert_equal source_commit, historical.fetch("journal_commit")
              assert_equal advanced, contexts.first.fetch(:commit)
              assert_equal target_params.fetch(:release_event_digest), historical.fetch("release_event_digest")
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                owner.maintenance_workspace_target!(**current_params, source_commit: "f" * 40)
              end
              abandoned, _, abandoned_status = Open3.capture3("git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid",
                "commit-tree", "#{source_commit}^{tree}", "-p", source_commit, "-m", "noncanonical sibling", chdir: repo)
              assert abandoned_status.success?
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                owner.maintenance_workspace_target!(**current_params, source_commit: abandoned.delete_suffix("\n"))
              end
            end
            assert_equal prior_retirements + 1, observer.retirements
            File.binwrite(published, File.binread(candidate_ref.fetch("path")))
            fresh_history, published_candidate = Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) do
              [Authority::DeploymentHistory.load, Authority::Deployment.load]
            end
            assert_equal Authority::Deployment::PATH, published_candidate.artifact_reference.fetch("path")
            assert_equal candidate_ref.fetch("sha256"), published_candidate.artifact_reference.fetch("sha256")
            fresh_observer = scope_for.call(published_candidate.mapping("mapping"), "candidate-boot.json", published_candidate)
            fresh = Authority::LaunchLifecycle.new(deployment: published_candidate, deployment_history: fresh_history, kernel: kernel,
              journals: {"project" => journal}, control_exclusion_factory: ProtectedControlFixture.factory, scope_observer_factory: ->(_) { fresh_observer })
            # Publication selects the immutable candidate; old canonical proofs
            # remain byte-identical and a genuinely eligible slot can be reused.
            before = journal.read_events("assignment")
            result = dispatch.call(fresh, "reserve_attempt", reserve, "reserve-new")
            assert_equal "reserved", result.dig(:data, "phase")
            old_events = journal.read_events("assignment").select { |event| event["attempt_id"] == state.fetch("attempt_id") }
            assert_equal before.select { |event| event["attempt_id"] == state.fetch("attempt_id") }, old_events
            provisioning = journal.read_events("assignment").find { |event| event["type"] == "scope_provisioning" && event["attempt_id"] == result.dig(:data, "attempt_id") }
            assert_equal candidate_ref.fetch("sha256"), provisioning.dig("payload", "descriptor_sha256")
          end
        ensure
          owner&.close
          fresh&.close
        end
      end

      def test_history_selects_exact_retained_descriptor_and_original_public_key
        Dir.mktmpdir do |root|
          root = File.realpath(root)
          reference = lambda do |name, bytes|
            path = File.join(root, name)
            File.binwrite(path, bytes)
            {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
          end
          original_ref = reference.call("original.json", JSON.generate(data))
          proposed = data
          proposed["launch_mappings"]["mapping"]["worker_actor"] = "replacement"
          candidate_ref = reference.call("candidate.json", JSON.generate(proposed))
          key = OpenSSL::PKey::RSA.new(2048)
          key_ref = reference.call("old-public.pem", key.public_key.to_pem)
          fingerprint = Digest::SHA256.hexdigest(key.public_key.to_der)
          manifest = {"schema" => "ace.assign.deployment-history/v1", "original_descriptor" => original_ref,
            "candidate_descriptor" => candidate_ref, "descriptors" => [original_ref, candidate_ref],
            "public_keys" => [{"ref" => key_ref, "public_key_sha256" => fingerprint}]}
          factory = -> { Ace::Runtime::Molecules::ProtectedArtifactSet.allocate.tap do |reader|
            reader.send(:initialize, protection: FixtureProtection.new)
          end }
          manifest_ref = reference.call("history.json", JSON.generate(manifest))
          Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) do
            history = Authority::DeploymentHistory.load_artifact(manifest_ref)
            assert history.frozen?
            assert_equal "worker", history.original.mapping("mapping").fetch("worker_actor")
            assert_equal "replacement", history.candidate.mapping("mapping").fetch("worker_actor")
            assert_same history.original, history.descriptor!(sha256: original_ref.fetch("sha256"))
            assert_equal key.public_key.to_der, history.public_key!(sha256: fingerprint).to_der
            assert_raises(AttemptErrors::EvidenceUnavailable) { history.public_key!(sha256: "f" * 64) }
            manifest["descriptors"] << original_ref
            duplicate_ref = reference.call("duplicate-history.json", JSON.generate(manifest))
            assert_raises(ArgumentError) { Authority::DeploymentHistory.load_artifact(duplicate_ref) }
            manifest["descriptors"].pop
            private_ref = reference.call("private.pem", key.to_pem)
            manifest["public_keys"].first["ref"] = private_ref
            private_manifest = reference.call("private-history.json", JSON.generate(manifest))
            assert_raises(ArgumentError) { Authority::DeploymentHistory.load_artifact(private_manifest) }
            File.binwrite(key_ref.fetch("path"), key.to_pem)
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { Authority::DeploymentHistory.load_artifact(manifest_ref) }
          end
        end
      end

      def test_fixed_deployment_load_retains_same_held_byte_provenance
        artifacts = DescriptorArtifacts.new(JSON.generate(data))
        artifacts.define_singleton_method(:read_path!) do |path, limit:|
          raise "wrong bound" unless limit == 65_536
          [@bytes, {"path" => path, "sha256" => Digest::SHA256.hexdigest(@bytes), "bytes" => @bytes.bytesize}.freeze]
        end
        Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, artifacts) do
          loaded = Authority::Deployment.load
          assert loaded.frozen?
          assert_equal Authority::Deployment::PATH, loaded.artifact_reference.fetch("path")
          assert_equal Digest::SHA256.hexdigest(JSON.generate(data)), loaded.artifact_reference.fetch("sha256")
          assert artifacts.checked
        end
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
        def with_exclusive(key, deadline: nil)
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
          normal.define_singleton_method(:verify_maintenance_root!) { |*| true }
          started, admitted = Queue.new, Queue.new
          thread = nil
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
          mutex = maintenance.instance_variable_get(:@mutex)
          mutex.lock
          begin
            assert_raises(AttemptErrors::MaintenanceBusy) do
              maintenance.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: deployment, deadline: deadline) { flunk "busy mutex entered" }
            end
          ensure
            mutex.unlock
          end
          assert_empty Thread.current[:ace_assign_scope_exclusions]
          maintenance.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: deployment, deadline: deadline) do |contexts|
            assert_raises(AttemptErrors::MaintenanceBusy) do
              normal.with_execution_slots(mapping_ids: ["mapping"], candidate_deployment: deployment, deadline: deadline) { flunk "busy slot entered" }
            end
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

      def test_task_context_entry_is_mandatory_closed_and_bounded
        assert Authority::Deployment.new(data)
        [nil, {}, {"manifest" => {}}].each do |entry|
          value = data
          value.fetch("launch_mappings").fetch("mapping")["task_context_entry"] = entry
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        value = data
        value.fetch("launch_mappings").fetch("mapping").delete("task_context_entry")
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        [["manifest", "bytes", 65_537], ["wrapper", "bytes", 33_554_433],
          ["wrapper", "bytes", 0], ["manifest", "sha256", "A" * 64],
          ["wrapper", "path", "/fixture/../entry.py"], ["wrapper", "extra", true]].each do |key, field, bad|
          value = data
          value.fetch("launch_mappings").fetch("mapping").fetch("task_context_entry").fetch(key)[field] = bad
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end

      def test_workspace_repository_pair_is_optional_atomic_closed_and_bounded
        assert Authority::Deployment.new(data)
        value = data
        map = value.fetch("launch_mappings").fetch("mapping")
        map.merge!("workspace_repository_id" => "repo", "workspace_cleanup_config" => {
          "path" => "/fixed/cleanup.json", "sha256" => "a" * 64, "bytes" => 65_536})
        assert Authority::Deployment.new(value)
        invalid = [->(m) { m.delete("workspace_repository_id") }, ->(m) { m.delete("workspace_cleanup_config") },
          ->(m) { m["workspace_repository_id"] = nil }, ->(m) { m["workspace_cleanup_config"] = nil },
          ->(m) { m["workspace_cleanup_config"]["bytes"] = 65_537 }, ->(m) { m["workspace_cleanup_config"]["bytes"] = 1.0 },
          ->(m) { m["workspace_cleanup_config"]["path"] = "/fixed/../cleanup" },
          ->(m) { m["workspace_cleanup_config"]["extra"] = true }, ->(m) { m["workspace_repository_id"] = "bad/id" }]
        invalid.each do |change|
          broken = JSON.parse(JSON.generate(value))
          change.call(broken.fetch("launch_mappings").fetch("mapping"))
          assert_raises(ArgumentError, KeyError, TypeError) { Authority::Deployment.new(broken) }
        end
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

      def test_worker_entry_is_exact_fixed_authority_adapter_without_argument_fallback
        assert Authority::Deployment.new(data)
        %w[interpreter wrapper].each do |key|
          [0, 1.0, key == "wrapper" ? 1_048_577 : 33_554_433].each do |bytes|
            value = data
            value.fetch("launch_mappings").fetch("mapping").fetch("worker_entry").fetch(key)["bytes"] = bytes
            assert_raises(ArgumentError) { Authority::Deployment.new(value) }
          end
          ["relative", "/a/../b", "/a\0b"].each do |path|
            value = data
            value.fetch("launch_mappings").fetch("mapping").fetch("worker_entry").fetch(key)["path"] = path
            assert_raises(ArgumentError) { Authority::Deployment.new(value) }
          end
        end
        value = data
        value.fetch("launch_mappings").fetch("mapping").fetch("worker_entry")["argv"] = ["authority", "worker"]
        assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        [["/usr/bin/true"], ["relative", "authority", "worker"],
          ["/usr/bin/true", "authority", "task-context"],
          ["/usr/bin/true", "authority", "worker", "extra"],
          ["/usr/bin/../true", "authority", "worker"]].each do |argv|
          value = data
          value.fetch("launch_mappings").fetch("mapping")["worker_argv"] = argv
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
      end

      def test_context_service_selection_is_closed_and_dedicated_before_any_observation
        value = inbox_data
        context = value.fetch("projects").fetch("project").fetch("inbox_contexts").fetch("inbox")
        scope = value.fetch("launch_mappings").fetch("mapping").fetch("execution_scope").merge(
          "slot_id" => "inbox-slot", "slice_unit" => "ace-inbox.slice", "service_unit" => "ace-inbox.service",
          "root_directory" => "/var/lib/ace-inbox-service/root", "runtime_directory" => "/run/ace-inbox-service",
          "network_namespace_path" => "/run/netns/ace-inbox-service")
        refs = %w[unit_manifest boundary_manifest entry interpreter bootstrap_manifest].to_h do |role|
          digest = role == "unit_manifest" ? "c" : role == "boundary_manifest" ? "d" : "e"
          [role, {"path" => "/etc/ace/inbox-service/#{role}", "bytes" => 100, "sha256" => digest * 64}]
        end
        context["service"] = refs.merge("execution_scope" => scope)
        assert_equal context.fetch("service"), Authority::Deployment.new(value).inbox_context("mapping", "inbox").fetch("service")
        [->(row) { row.fetch("service")["unknown"] = true },
         ->(row) { row.fetch("service").fetch("unit_manifest")["sha256"] = "f" * 64 },
         ->(row) { row.fetch("service").fetch("execution_scope")["slot_id"] = "slot" },
         ->(row) { row.fetch("service").fetch("execution_scope")["runtime_directory"] = "/run/ace-slot/nested" },
         ->(row) { row.fetch("owner_credentials")["uid"] = 13001 },
         ->(row) { row.fetch("owner_credentials")["uid"] = 13004 }].each do |change|
          candidate = Marshal.load(Marshal.dump(value))
          change.call(candidate.fetch("projects").fetch("project").fetch("inbox_contexts").fetch("inbox"))
          assert_raises(ArgumentError) { Authority::Deployment.new(candidate) }
        end
        candidate = Marshal.load(Marshal.dump(value))
        sibling = Marshal.load(Marshal.dump(candidate.fetch("projects").fetch("project").fetch("inbox_contexts").fetch("inbox")))
        sibling.delete("service")
        sibling["deliveries_dir"] = "/var/lib/ace-sibling-inbox"
        sibling["control_socket_path"] = "/run/ace-sibling-inbox/context.sock"
        candidate.fetch("projects").fetch("project").fetch("inbox_contexts")["sibling"] = sibling
        assert_raises(ArgumentError) { Authority::Deployment.new(candidate) }
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
