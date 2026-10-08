# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

module Ace
  module Assign
    class ProtectedCampaignRegistrationTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      # The protected filesystem boundary is injected; held bytes, inode
      # replacement, Git bundles, sockets and canonical journal remain real.
      class ArtifactProtection
        def root_path!(_path); end
        def verify!(path, handle, directory:)
          raise Ace::Runtime::RuntimeUnavailableError, "unsafe fixture mode" unless
            (handle.stat.mode & 0o022).zero? && (directory ? handle.stat.directory? : handle.stat.file?)
        end
      end

      def configure_result_owner_fixture
        File.chmod(0700, @journal.repo_root)
        @project["campaign_repository"] = @journal.repo_root
        @project["campaign_store_root"] = File.join(@root, "campaign-store")
        @campaign_manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @journal.repo_root,
          store: Ace::Review::Molecules::CampaignStore.new(root: @project.fetch("campaign_store_root")))
        @campaign_policy = {"revision" => "delivery-v1", "minimum_rounds" => 3, "clean_rounds" => 2,
          "required_scopes" => ["full"], "required_checks" => ["tests"]}
        @campaign = @campaign_manager.start(subject: {"repository" => "local:#{@journal.repo_root}", "local_candidate_id" => "candidate"},
          contract: "Reviewed parent requirements", policy: @campaign_policy)
        File.chmod(0700, @project.fetch("campaign_store_root"))
        set_current_policy(@campaign_policy)
        parent_map = @map
        child_map = @map.merge("execution_scope" => @map.fetch("execution_scope").merge("slot_id" => "child-slot"))
        @deployment.define_singleton_method(:mapping) { |id| {"mapping" => parent_map, "child-mapping" => child_map}.fetch(id) }
      end

      def set_current_policy(policy)
        bytes = JSON.generate("schema" => "ace.review.consumer-policy/v1", "profiles" => {"delivery" => policy})
        path = File.join(@root, "consumer-#{Digest::SHA256.hexdigest(bytes)}.json")
        File.binwrite(path, bytes); File.chmod(0600, path)
        @project["campaign_policy"] = {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end

      def candidate(_number); end

      def call(operation, params, **options)
        if operation == "register_assignment"
          value = JSON.parse(params.fetch("definition_bytes"))
          value["review_campaign"] = {"version" => 1}.merge(@campaign.slice("campaign_id", "subject", "contract_identity"))
            .merge("policy" => @campaign.fetch("effective_policy"))
          bytes = JSON.generate(value)
          params = params.merge("definition_bytes" => bytes, "definition_digest" => Digest::SHA256.hexdigest(bytes))
        end
        super(operation, params, **options)
      end

      def start_public_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        kernel = Kernel.new; kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
      end

      def child_definition(id, execution)
        {"session_id" => id, "name" => "campaign child", "created_at" => "2026-10-08T00:00:00Z",
          "source_config" => "job.yaml", "task_id" => "task", "project_id" => "project",
          "parent" => "assignment", "campaign_execution" => execution}
      end

      def register_child(id, execution, mutation:, expected_generation: 0)
        work = PreparedRegistrationFixture.build(root: @root, definition: child_definition(id, execution), scope: "010")
        work.with_input(root: @root) do |_input, _descriptor|
          @client.call("register_assignment", work.header(expected_generation: expected_generation), mutation_id: mutation,
            upload_parts: [work.bundle], purpose: :candidate, timeout: 30)
        end
      end

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
              @campaign_manager.record_round(@campaign.fetch("campaign_id"), {"attempt_id" => "pin", "round_id" => "round-1",
                "head" => @head, "base" => @base, "required_scopes" => ["full"], "scope_identity" => scope_identity,
                "sessions" => [], "dispositions" => []})
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
                "runtime" => "herdr", "base_head" => @head, "launcher_process_binding" => @launcher,
                "expected_generation" => accepted.data.fetch("definition_generation")}
              assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("reserve_attempt", reserve, mutation_id: "revoked-reserve", timeout: 30) }
              assert_equal selected, @journal.ref_value
              set_current_policy(@campaign_policy)
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
            end
          end
        end
      end
    end
  end
end
