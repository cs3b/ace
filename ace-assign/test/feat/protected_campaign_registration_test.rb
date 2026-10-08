# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require_relative "../support/protected_campaign_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/assign/authority/prepared_input"

module Ace
  module Assign
    class ProtectedCampaignRegistrationTest < AceAssignTestCase
      include ProtectedCampaignFixture

      def test_public_child_registration_consumes_actual_parent_candidate_and_pinned_round
        protection = ->(path, **options) { raise "not private: #{File.basename(path)}" if options[:directory] && (!File.directory?(path) || (File.stat(path).mode & 0o077) != 0) }
        artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: ArtifactProtection.new)
        policy_owner = Authority::CampaignConsumerPolicy.new(artifacts: artifacts)
        Authority::CampaignConsumerPolicy.stub(:new, policy_owner) do
          WIRE.stub(:root_path!, protection) do
            fixture do
              start_public_server
              @base = @head
              File.binwrite(File.join(@journal.repo_root, "candidate.rb"), "changed_candidate = true\n")
              git(@journal.repo_root, "add", "candidate.rb")
              git(@journal.repo_root, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "candidate change")
              @head = git(@journal.repo_root, "rev-parse", "HEAD")
              bundle_path = File.join(@root, "candidate.bundle")
              git(@journal.repo_root, "bundle", "create", bundle_path, "HEAD")
              candidate = @client.call("submit_candidate", {"assignment_id" => "assignment", "attempt_id" => @attempt,
                "head" => @head, "candidate_generation" => 0, "expected_generation" => generation}, mutation_id: "candidate",
                upload_parts: [File.binread(bundle_path)], purpose: :candidate, timeout: 30)
              assert_equal 1, candidate.data.fetch("candidate_generation")
              scope_identity = {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base}..#{@head}"]}}
              round = {"attempt_id" => "pin", "round_id" => "round-1", "head" => @head, "base" => @base,
                "required_scopes" => ["full"], "scope_identity" => scope_identity, "sessions" => [], "dispositions" => []}
              round_bytes = JSON.generate("version" => 1, "round" => round, "artifacts" => [])
              @kernel.peer_identity = @launcher
              pinned_ref = @journal.ref_value
              pinned = @client.call("campaign_record_round", {"assignment_id" => "assignment", "attempt_id" => @attempt,
                "head" => @head, "candidate_generation" => 1, "input_sha256" => Digest::SHA256.hexdigest(round_bytes)},
                mutation_id: "pin", upload_parts: [round_bytes], purpose: :receipt_artifacts, timeout: 30)
              assert_equal "round-1", pinned.data.fetch("round_id")
              assert_equal pinned_ref, @journal.ref_value, "R1 storage must not advance canonical authority"
              replay = @client.call("campaign_record_round", {"assignment_id" => "assignment", "attempt_id" => @attempt,
                "head" => @head, "candidate_generation" => 1, "input_sha256" => Digest::SHA256.hexdigest(round_bytes)},
                mutation_id: "pin", upload_parts: [round_bytes], purpose: :receipt_artifacts, timeout: 30)
              assert_equal true, replay.data.fetch("replayed")
              changed_round = JSON.generate("version" => 1, "round" => round.merge("round_id" => "changed-round"), "artifacts" => [])
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                @client.call("campaign_record_round", {"assignment_id" => "assignment", "attempt_id" => @attempt,
                  "head" => @head, "candidate_generation" => 1, "input_sha256" => Digest::SHA256.hexdigest(changed_round)},
                  mutation_id: "pin", upload_parts: [changed_round], purpose: :receipt_artifacts, timeout: 30)
              end
              assert_equal pinned_ref, @journal.ref_value
              assert_equal "round-1", @campaign_manager.status(@campaign.fetch("campaign_id")).fetch("attempts").first.fetch("round_id")
              execution = {"version" => 1, "parent_assignment_id" => "assignment", "parent_attempt_id" => @attempt,
                "parent_scope" => "010", "parent_candidate_generation" => 1, "subject" => @campaign.fetch("subject"),
                "campaign_id" => @campaign.fetch("campaign_id"), "contract_identity" => @campaign.fetch("contract_identity"),
                "policy_digest" => Authority::CampaignExecution::Contract.digest(@campaign_policy), "round_id" => "round-1",
                "phase" => "collection", "review_scope" => "full",
                "scope_identity_digest" => Authority::CampaignExecution::Contract.digest(scope_identity.fetch("full")),
                "head" => @head, "base" => @base, "operation" => "review-collect", "check_name" => "review-execution"}
              @kernel.peer_identity = @launcher
              child_kernel = Kernel.new
              child_kernel.peer_identity = @service.slice("uid", "gid", "groups")
              @client = Authority::Client.new(mapping_id: "child-mapping", deployment: @deployment, kernel: child_kernel)
              original_mutate = @journal.method(:mutate)
              test = self
              kernel = @kernel
              worker_pid = @worker.fetch("pid")
              control_root = File.join(@service.fetch("state_root"), "lifecycle-exclusion", "project", "control")
              @journal.define_singleton_method(:mutate) do |**options, &plan|
                original_mutate.call(**options) do |events, commit, generation|
                  if options.fetch(:assignment_id) == "child"
                    %w[task:task assignment:assignment assignment:child].each do |key|
                      File.open(File.join(control_root, Digest::SHA256.hexdigest(key) + ".lock"), File::RDONLY) do |lock|
                        test.refute lock.flock(File::LOCK_EX | File::LOCK_NB), "both canonical owners must remain excluded"
                      end
                    end
                  end
                  kernel.dead << worker_pid if options.fetch(:assignment_id) == "parent-exited-at-cas"
                  plan.call(events, commit, generation)
                end
              end
              selected_before_child = @journal.ref_value
              @kernel.peer_identity = @worker
              assert_raises(AttemptErrors::EvidenceUnavailable) { register_child("worker-selected", execution, mutation: "worker-selected") }
              assert_equal selected_before_child, @journal.ref_value
              @kernel.peer_identity = @launcher
              accepted = register_child("child", execution, mutation: "child-register")
              assert_equal "child", accepted.data.fetch("assignment_id")
              stored = JSON.parse(@journal.blob(accepted.data.fetch("definition_ref"), commit: accepted.data.fetch("journal_commit")))
              assert_equal execution, stored.fetch("campaign_execution")
              assert_equal "assignment", stored.fetch("parent")
              selected = @journal.ref_value
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                register_child("wrong-generation", execution.merge("parent_candidate_generation" => 2), mutation: "wrong-generation")
              end
              assert_equal selected, @journal.ref_value
              assert_raises(AttemptErrors::EvidenceUnavailable) { register_child("duplicate-phase", execution, mutation: "duplicate-phase") }
              assert_equal selected, @journal.ref_value
              check = execution.merge("phase" => "check", "operation" => "test", "check_name" => "tests")
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                register_child("child", check, mutation: "replace-child-phase", expected_generation: 1)
              end
              assert_equal selected, @journal.ref_value
              assert_raises(AttemptErrors::EvidenceUnavailable) do
                register_child("parent-exited-at-cas", check, mutation: "parent-exited-at-cas")
              end
              assert_includes @kernel.dead, @worker.fetch("pid")
              assert_equal selected, @journal.ref_value
              @kernel.dead.clear
              set_current_policy(@campaign_policy.merge("required_checks" => %w[tests lint]))
              assert_raises(AttemptErrors::EvidenceUnavailable) { register_child("tightened", check, mutation: "tightened") }
              assert_equal selected, @journal.ref_value
              set_current_policy(nil)
              assert_raises(AttemptErrors::EvidenceUnavailable) { register_child("revoked", check, mutation: "revoked") }
              assert_equal selected, @journal.ref_value
              reserve = {"assignment_id" => "child", "scope" => "010", "worker_uid" => @map.fetch("worker_uid"),
                "runtime" => "herdr", "base_head" => @base, "launcher_process_binding" => @launcher,
                "expected_generation" => accepted.data.fetch("definition_generation")}
              assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("reserve_attempt", reserve, mutation_id: "revoked-reserve", timeout: 30) }
              assert_equal selected, @journal.ref_value
              set_current_policy(@campaign_policy)
              refusal = assert_raises(AttemptErrors::EvidenceUnavailable) do
                @client.call("reserve_attempt", reserve.merge("base_head" => @head), mutation_id: "wrong-child-base", timeout: 30)
              end
              assert_includes refusal.message, "(conflict)"
              assert_equal selected, @journal.ref_value
              native_failure = nil
              %i[provision_reserved_parent_held! admit_native_service_held! complete_native_start!].each do |name|
                original = @launch.method(name)
                @launch.define_singleton_method(name) do |*arguments|
                  original.call(*arguments)
                rescue StandardError => error
                  native_failure = error
                  raise
                end
              end
              @kernel.dead << @worker.fetch("pid")
              assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("reserve_attempt", reserve, mutation_id: "dead-parent-reserve", timeout: 30) }
              assert_equal selected, @journal.ref_value
              @kernel.dead.clear
              set_current_policy(nil)
              # Exact accepted replay is historical, even after current revocation.
              # It uses identical retained bundle bytes, not a rebuilt producer.
              original = @journal.blob(accepted.data.fetch("prepared_bundle_ref"), commit: selected)
              registration = accepted.data.fetch("prepared_work")
              replay_header = {"assignment_id" => "child", "definition_digest" => accepted.data.fetch("definition_digest"),
                "prepared_head" => registration.fetch("prepared_head"), "prepared_tree" => registration.fetch("prepared_tree"),
                "manifest_sha256" => registration.fetch("manifest_sha256"), "expected_generation" => 0}
              replay = @client.call("register_assignment", replay_header, mutation_id: "child-register", upload_parts: [original], purpose: :candidate, timeout: 30)
              assert replay.replayed
              assert_equal accepted.data, replay.data
              assert_equal selected, @journal.ref_value
              set_current_policy(@campaign_policy)
              dispatch = @router.method(:dispatch)
              refusal = nil
              @router.define_singleton_method(:dispatch) do |**arguments|
                dispatch.call(**arguments)
              rescue StandardError => error
                refusal = error
                raise
              end
              begin
                reserved = @client.call("reserve_attempt", reserve, mutation_id: "live-parent-reserve", timeout: 30)
              rescue AttemptErrors::EvidenceUnavailable
                raise(refusal || $!)
              end
              assert_equal "reserved", reserved.data.fetch("phase")
              assert_equal "child-mapping", reserved.data.fetch("mapping_id")
              assert_equal "child", reserved.data.fetch("assignment_id")
              assert_equal "010", reserved.data.fetch("scope")
              raise native_failure if native_failure
              child_events = @journal.read_events("child", commit: @journal.ref_value)
              child_chain = child_events.select { |event| event["attempt_id"] == reserved.data.fetch("attempt_id") }
              assert Models::EvidenceEvent.chain_valid?(child_chain)
              provisioning = child_chain.find { |event| event["type"] == "scope_provisioning" }.fetch("payload")
              assert_equal "child-slot", provisioning.fetch("slot_id")
              assert_equal @deployment.artifact_reference.fetch("sha256"), provisioning.fetch("descriptor_sha256")
              mutation = child_chain.find { |event| event["type"] == "authority_mutation" }.fetch("payload")
              assert_equal "reserve_attempt", mutation.fetch("operation")
              assert_equal "live-parent-reserve", mutation.fetch("mutation_id")
              child_identity = @kernel.capture(191).merge("parent_pid" => 90)
              child_binding = JSON.parse(JSON.generate(@binding))
              child_binding["process_identity"] = child_binding["shell_identity"] = child_identity
              child_binding.fetch("native_origin")["command"] = [@map.fetch("bootstrap"), "child-mapping", reserved.data.fetch("launch_ticket")]
              child_binding.fetch("native_origin")["cwd"] = @deployment.mapping("child-mapping").fetch("worker_cwd")
              current = @client.call("attempt_status", {"assignment_id" => "child", "attempt_id" => reserved.data.fetch("attempt_id"),
                "result_candidate_generation" => nil}, timeout: 30)
              refusal = nil
              begin
                recorded = @client.call("record_launch", {"assignment_id" => "child", "attempt_id" => reserved.data.fetch("attempt_id"),
                "launch_ticket" => reserved.data.fetch("launch_ticket"), "process_binding" => child_binding,
                "guarded_origin" => {"terminal_id" => child_binding.fetch("terminal_id"), "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT, "child" => child_identity},
                "expected_generation" => current.data.fetch("generation")}, mutation_id: "child-record", timeout: 30)
              rescue AttemptErrors::EvidenceUnavailable
                raise(refusal || $!)
              end
              assert_equal "recorded", recorded.data.fetch("phase")
              bound = @client.call("bind_process", {"assignment_id" => "child", "attempt_id" => reserved.data.fetch("attempt_id"),
                "launch_ticket" => reserved.data.fetch("launch_ticket"), "process_binding" => child_binding,
                "expected_generation" => recorded.data.fetch("generation")}, mutation_id: "child-bind", timeout: 30)
              assert_equal "bound", bound.data.fetch("phase")
              bound_chain = @journal.read_events("child").select { |event| event["attempt_id"] == reserved.data.fetch("attempt_id") }
              assert Models::EvidenceEvent.chain_valid?(bound_chain)
              assert_equal child_binding, bound_chain.find { |event| event["type"] == "scope_child_bound" }.dig("payload", "original_process_binding")
              assert_equal child_identity, bound_chain.find { |event| event["type"] == "process_start" }.dig("payload", "process_identity")
              child_params = {"mapping_id" => "child-mapping", "assignment_id" => "child",
                "attempt_id" => reserved.data.fetch("attempt_id")}
              receipt = {"operation" => execution.fetch("operation"), "head" => execution.fetch("head"), "verdict" => "succeeded",
                "checks" => [{"name" => execution.fetch("check_name"), "verdict" => "passed"}]}
              assert_equal execution, @endcap.send(:campaign_child_result!, journal: @journal, commit: @journal.ref_value,
                events: bound_chain, params: child_params, map: @deployment.mapping("child-mapping"), receipt: receipt)
              assert_raises(AttemptErrors::ReceiptRejected) do
                @endcap.send(:campaign_child_result!, journal: @journal, commit: @journal.ref_value,
                  events: bound_chain, params: child_params, map: @deployment.mapping("child-mapping"),
                  receipt: receipt.merge("operation" => "merge"))
              end
              code, bundle = @endcap.send(:campaign_prepared_candidate!, journal: @journal, commit: @journal.ref_value,
                execution: execution, map: @deployment.mapping("child-mapping"))
              assert_equal @head, code.fetch("head")
              assert_equal 1, code.fetch("candidate_generation")
              materialized = Authority::CandidateTransfer.new(root: @root).materialize_repository(bytes: bundle,
                sha256: code.fetch("sha256"), size: code.fetch("bytes"), head: code.fetch("head"),
                tree: code.fetch("tree"), root: @root)
              assert File.directory?(materialized.fetch("directory"))
              gate_server, gate_worker = UNIXSocket.pair
              gate = Thread.new do
                @launch.gate_ready(request: {"params" => {"mapping_id" => "child-mapping", "launch_ticket" => reserved.data.fetch("launch_ticket")}},
                  peer: child_identity, socket: gate_server, deadline: WIRE.deadline(5))
              end
              assert_equal "ready", WIRE.read(gate_worker, deadline: WIRE.deadline(5)).dig("data", "phase")
              released = @client.call("release_launch", child_params.except("mapping_id").merge(
                "launch_ticket" => reserved.data.fetch("launch_ticket"), "process_binding" => child_binding,
                "expected_generation" => bound.data.fetch("generation")), mutation_id: "child-release", timeout: 30)
              assert_equal "issued", released.data.fetch("phase")
              assert_equal "release", WIRE.read(gate_worker, deadline: WIRE.deadline(5)).fetch("operation")
              gate.join(2)
              refute gate.alive?
              gate_server.close; gate_worker.close
              @kernel.peer_identity = child_identity
              worker_kernel = Kernel.new
              worker_kernel.define_singleton_method(:capture) { |_| child_identity }
              worker_kernel.peer_identity = @service.slice("uid", "gid", "groups")
              @client = Authority::Client.new(mapping_id: "child-mapping", deployment: @deployment, kernel: worker_kernel)
              input = Authority::PreparedInput.fetch(client: @client, assignment_id: "child", attempt_id: child_params.fetch("attempt_id"))
              assert_equal @head, git(input.working_directory, "rev-parse", "HEAD")
              assert_equal "child", input.descriptor.fetch("assignment_id")
              assert_equal execution, input.work.definition.fetch("campaign_execution")
              assert_raises(AttemptErrors::Conflict) do
                @launch.campaign_children_settled!(journal: @journal, commit: @journal.ref_value,
                  params: {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}, map: @map)
              end
            end
          end
        end
      end
    end
  end
end
