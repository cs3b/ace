# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/protected_campaign_fixture"
require "yaml"

module Ace
  module Assign
    class ProtectedCampaignResultFlowTest < Minitest::Test
      include ProtectedCampaignFixture

      def test_canonical_children_record_export_and_submit_parent_result
        @campaign_requested_policy = {"revision" => "delivery-v1", "minimum_rounds" => 1, "clean_rounds" => 1,
          "required_scopes" => ["full"], "required_checks" => ["tests"]}
        artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: ArtifactProtection.new)
        policy = Authority::CampaignConsumerPolicy.new(artifacts: artifacts)
        Authority::CampaignConsumerPolicy.stub(:new, policy) do
          WIRE.stub(:root_path!, ->(*) { true }) do
            fixture do
              @base = @head
              File.binwrite(File.join(@journal.repo_root, "candidate.rb"), "checked = true\n")
              git(@journal.repo_root, "add", "candidate.rb")
              git(@journal.repo_root, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "candidate")
              @head = git(@journal.repo_root, "rev-parse", "HEAD")
              bundle = File.join(@root, "candidate.bundle")
              git(@journal.repo_root, "bundle", "create", bundle, "HEAD")
              @candidate_bytes = File.binread(bundle)
              call("submit_candidate", {"head" => @head, "candidate_generation" => 0, "expected_generation" => generation, "transfer" => candidate_descriptor},
                id: "parent-candidate", transfer: candidate_input)
              @round = {"attempt_id" => "pin", "round_id" => "round-1", "head" => @head, "base" => @base,
                "required_scopes" => ["full"], "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base}..#{@head}"]}},
                "sessions" => [], "dispositions" => []}
              record_round(@round, {})
              files = {"system.prompt.md" => "review system", "user.prompt.md" => "review candidate source",
                "review-report-reviewer.md" => "Checked candidate and frozen requirements; no remaining defects."}
              binding = @campaign.slice("campaign_id", "contract_identity", "subject").merge(
                "round_id" => "round-1", "scope" => "full", "head" => @head, "base" => @base,
                "scope_identity" => @round.fetch("scope_identity").fetch("full"))
              metadata = {"preset" => "code-valid", "head" => @head, "campaign_binding" => binding, "noop_round" => false,
                "models" => [{"status" => "success", "completed_at" => Time.now.utc.iso8601,
                  "execution" => {"status" => "succeeded", "provider" => "fixture", "model" => "reviewer"},
                  "output_file" => "review-report-reviewer.md", "report_sha256" => sha(files.fetch("review-report-reviewer.md")),
                  "prompt_sha256" => {"system" => sha(files.fetch("system.prompt.md")), "user" => sha(files.fetch("user.prompt.md"))}}],
                "feedback_extraction" => {"status" => "succeeded", "finding_ids" => [],
                  "report_sha256" => [sha(files.fetch("review-report-reviewer.md"))]}}
              files["metadata.yml"] = YAML.dump(metadata)
              collection = settle_child("collection", "review-collect", "review-execution", files, pid: 191)
              check = settle_child("check", "test", "tests", {"tests.txt" => "Executed checks passed"}, pid: 192)
              approval = settle_child("approval", "review", "review-approval", {"review-report-reviewer.md" => files.fetch("review-report-reviewer.md")}, pid: 193)
              report = ref("review-report-reviewer.md", files)
              approval_bytes = JSON.generate("head" => @head, "base" => @base, "contract_identity" => @campaign.fetch("contract_identity"),
                "required_scopes" => ["full"], "verdict" => "approved", "producer" => "worker", "reviewer" => approval.fetch("reviewer_actor"),
                "reports" => [report], "report_models" => [{"report" => report, "report_model" => "reviewer"}],
                "receipt" => approval.fetch("reference"), "checks" => [{"name" => "tests", "verdict" => "passed", "receipt" => check.fetch("reference")}])
              files["approval.json"] = approval_bytes
              complete = @round.merge("attempt_id" => "complete", "sessions" => [{"scope" => "full", "metadata" => ref("metadata.yml", files),
                "receipt" => collection.fetch("reference")}], "approval" => ref("approval.json", files))
              accepted = record_round(complete, files)
              assert accepted.fetch("accepted"), accepted.inspect
              before = @journal.ref_value
              params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "head" => @head, "candidate_generation" => 1}
              start_public_server
              @kernel.peer_identity = @worker
              exported = @client.call("campaign_export_result", params, timeout: 30, download: true, purpose: :artifacts)
              compact = JSON.parse(exported.parts.fetch(0))
              assert_equal "ace.review.accepted-result/v1", compact.fetch("schema")
              assert_equal before, @journal.ref_value
              assert_equal compact.fetch("result_identity"), exported.data.fetch("result_identity")
              result = submit_parent(compact, files.fetch("review-report-reviewer.md"))
              assert_equal "succeeded", result.fetch("state")
              assert @launch.campaign_children_settled!(journal: @journal, commit: @journal.ref_value,
                params: params.merge("mapping_id" => "mapping"), map: @map)
            end
          end
        end
      rescue StandardError => error
        chain = error
        6.times do
          break unless chain
          frames = Array(chain.backtrace).first(4).map { |frame| File.basename(frame.split(":in ").first) }
          warn "R2 controlled failure: #{chain.class}: #{frames.join(", ")}"
          chain = chain.cause
        end
        raise
      end

      def sha(bytes); Digest::SHA256.hexdigest(bytes); end
      def ref(name, files); {"path" => name, "sha256" => sha(files.fetch(name))}; end
      def candidate_descriptor
        Authority::TransferCodec.new(root: @root).descriptor([@candidate_bytes], purpose: :candidate)
      end
      def candidate_input
        Struct.new(:parts) { def bytes(index: 0); parts.fetch(index); end; def count; parts.length; end }.new([@candidate_bytes])
      end
      def record_round(round, files)
        bytes = JSON.generate("version" => 1, "round" => round, "artifacts" => files.map { |name, value| {"path" => name, "sha256" => sha(value)} })
        input = Struct.new(:parts) { def bytes(index: 0); parts.fetch(index); end; def count; parts.length; end }.new([bytes] + files.values)
        call("campaign_record_round", {"head" => @head, "candidate_generation" => 1, "input_sha256" => sha(bytes), "transfer" => Authority::TransferCodec.new(root: @root).descriptor(input.parts, purpose: :receipt_artifacts)},
          id: round.fetch("attempt_id"), peer: @launcher, role: :launcher, transfer: input).fetch(:data)
      end
      def child_call(operation, params, id:, peer:, role:, transfer: nil)
        selectors = {"mapping_id" => "child-mapping", "assignment_id" => @child}
        selectors["attempt_id"] = @child_attempt unless operation == "reserve_attempt"
        dispatch_request(request: {"version" => 1, "operation" => operation, "mutation_id" => id, "project_id" => "project",
          "params" => params.merge(selectors)},
          peer: peer, role: role, transfer: transfer).fetch(:data)
      end
      def child_generation
        @journal.authority_generation(@journal.read_events(@child).select { |event| event["attempt_id"] == @child_attempt })
      end
      def settle_child(phase, operation, check_name, files, pid:)
        @child = phase
        execution = {"version" => 1, "parent_assignment_id" => "assignment", "parent_attempt_id" => @attempt,
          "parent_scope" => "010", "parent_candidate_generation" => 1, "subject" => @campaign.fetch("subject"),
          "campaign_id" => @campaign.fetch("campaign_id"), "contract_identity" => @campaign.fetch("contract_identity"),
          "policy_digest" => Authority::CampaignExecution::Contract.digest(@campaign_policy), "round_id" => "round-1", "phase" => phase,
          "review_scope" => "full", "scope_identity_digest" => Authority::CampaignExecution::Contract.digest(@round.fetch("scope_identity").fetch("full")),
          "head" => @head, "base" => @base, "operation" => operation, "check_name" => check_name}
        work = PreparedRegistrationFixture.build(root: @root, definition: child_definition(@child, execution), scope: "010")
        registration = work.with_input(root: @root) do |input, descriptor|
          dispatch_request(request: {"version" => 1, "operation" => "register_assignment", "mutation_id" => "#{phase}-register", "project_id" => "project",
            "params" => work.header(expected_generation: 0).merge("mapping_id" => "child-mapping", "transfer" => descriptor)},
            peer: @launcher, role: :launcher, transfer: input).fetch(:data)
        end
        reserved = child_call("reserve_attempt", {"scope" => "010", "worker_uid" => 13001, "runtime" => "herdr", "base_head" => @base,
          "launcher_process_binding" => @launcher, "expected_generation" => registration.fetch("definition_generation")},
          id: "#{phase}-reserve", peer: @launcher, role: :launcher)
        @child_attempt = reserved.fetch("attempt_id")
        identity = @kernel.capture(pid).merge("parent_pid" => 90)
        binding = JSON.parse(JSON.generate(@binding))
        binding["process_identity"] = binding["shell_identity"] = identity
        binding.fetch("native_origin")["command"] = [@map.fetch("bootstrap"), "child-mapping", reserved.fetch("launch_ticket")]
        binding.fetch("native_origin")["cwd"] = @deployment.mapping("child-mapping").fetch("worker_cwd")
        child_call("record_launch", {"launch_ticket" => reserved.fetch("launch_ticket"), "process_binding" => binding,
          "guarded_origin" => {"terminal_id" => binding.fetch("terminal_id"), "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT, "child" => identity},
          "expected_generation" => child_generation}, id: "#{phase}-record", peer: @launcher, role: :launcher)
        child_call("bind_process", {"launch_ticket" => reserved.fetch("launch_ticket"), "process_binding" => binding,
          "expected_generation" => child_generation}, id: "#{phase}-bind", peer: @launcher, role: :launcher)
        gate_server, gate_worker = UNIXSocket.pair
        gate = Thread.new { @launch.gate_ready(request: {"params" => {"mapping_id" => "child-mapping", "launch_ticket" => reserved.fetch("launch_ticket")}},
          peer: identity, socket: gate_server, deadline: WIRE.deadline(5)) }
        WIRE.read(gate_worker, deadline: WIRE.deadline(5))
        child_call("release_launch", {"launch_ticket" => reserved.fetch("launch_ticket"), "process_binding" => binding,
          "expected_generation" => child_generation}, id: "#{phase}-release", peer: @launcher, role: :launcher)
        WIRE.read(gate_worker, deadline: WIRE.deadline(5)); gate.value
        gate_server.close; gate_worker.close
        child_call("submit_candidate", {"head" => @head, "candidate_generation" => 0, "expected_generation" => child_generation, "transfer" => candidate_descriptor},
          id: "#{phase}-candidate", peer: identity, role: :worker, transfer: candidate_input)
        review = child_call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => child_generation,
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer}, id: "#{phase}-review", peer: @launcher, role: :launcher)
        review_value = {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}}
        receipt = {"assignment_id" => @child, "attempt_id" => @child_attempt, "project_id" => "project", "scope" => "010",
          "operation" => operation, "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
          "head" => @head, "verdict" => "succeeded", "checks" => [{"name" => check_name, "verdict" => "passed"}],
          "artifacts" => files.map { |name, value| {"path" => name, "sha256" => sha(value)} }}
        receipt["review"] = review_value if phase == "approval"
        submitted = child_upload("submit_result", receipt, files, "#{phase}-result", identity, :worker)
        review_receipt = receipt.merge("operation" => "review", "review" => review_value)
        child_upload("accept_review", review_receipt, files, "#{phase}-accept", @reviewer, :reviewer, "purpose_id" => review.fetch("review_id"))
        selectors = {"mapping_id" => "child-mapping", "assignment_id" => @child, "attempt_id" => @child_attempt}
        2.times do |n|
          @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "#{phase}-close-#{n}", "expected_generation" => child_generation),
            peer: @supervisor, role: :supervisor)
          inhibit_child_input! if n.zero?
        end
        @kernel.dead << pid
        finished = child_call("finish", {"head" => @head, "candidate_generation" => 1, "result_id" => submitted.fetch("result_id"),
          "expected_generation" => child_generation}, id: "#{phase}-finish", peer: @supervisor, role: :supervisor)
        assert_equal "succeeded", finished.fetch("state")
        @launch.release_scope_reservation!(params: selectors.merge("mutation_id" => "#{phase}-reservation-release",
          "expected_generation" => child_generation), peer: @supervisor, role: :supervisor)
        {"reference" => {"attempt_id" => @child_attempt, "digest" => submitted.fetch("receipt_digest")}, "reviewer_actor" => review.fetch("reviewer_actor")}
      end
      def inhibit_child_input!
        events = @journal.read_events(@child).select { |event| event["attempt_id"] == @child_attempt }
        record = events.find { |event| event.dig("payload", "operation") == "record_launch" }
        seal = events.find { |event| event["type"] == "scope_sealed" }
        # Only the external native response is controlled; the maintained
        # completion owner authenticates its original origin and accepted seal.
        evidence = {"outcome" => "inhibited", "origin" => record.dig("payload", "data", "guarded_origin"),
          "input_state" => "inhibited", "pending_input" => 0}
        child_call("launch_input_inhibit_completion", {"original_binding_digest" => record.fetch("digest"),
          "seal_event_id" => seal.fetch("digest"), "guarded_evidence" => evidence}, id: nil, peer: @launcher, role: :launcher)
      end
      def child_upload(operation, receipt, files, id, peer, role, extra = {})
        bytes = JSON.generate(receipt)
        parts = [bytes] + files.values
        input = Struct.new(:parts) { def count; parts.length; end; def bytes(index: 0); parts.fetch(index); end }.new(parts)
        child_call(operation, {"head" => @head, "candidate_generation" => 1, "expected_generation" => child_generation,
          "receipt_sha256" => sha(bytes), "transfer" => Authority::TransferCodec.new(root: @root).descriptor(parts, purpose: :receipt_artifacts)}.merge(extra),
          id: id, peer: peer, role: role, transfer: input)
      end
      def submit_parent(compact, report)
        files = {"campaign-result.json" => JSON.generate(compact), "parent-review.md" => report}
        review = call("assign_review", {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer}, id: "parent-review", peer: @launcher, role: :launcher).fetch(:data)
        review_value = {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}}
        receipt = {"assignment_id" => "assignment", "attempt_id" => @attempt, "project_id" => "project", "scope" => "010",
          "operation" => "review", "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"}, "head" => @head,
          "verdict" => "succeeded", "checks" => [{"name" => "tests", "verdict" => "passed"}], "artifacts" => files.map { |name, bytes| ref(name, files) },
          "review" => review_value, "campaign" => {"id" => @campaign.fetch("campaign_id"), "result" => ref("campaign-result.json", files)}}
        params, input, = upload(parts: files.values, receipt: receipt)
        submitted = call("submit_result", params, id: "parent-result", transfer: input).fetch(:data)
        params, input, = upload(parts: files.values, receipt: receipt.reject { |key, _| key == "campaign" })
        call("accept_review", params.merge("purpose_id" => review.fetch("review_id")), id: "parent-accept", peer: @reviewer, role: :reviewer, transfer: input)
        selectors = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => @attempt}
        2.times { |n| @launch.close_execution_scope!(params: selectors.merge("mutation_id" => "parent-close-#{n}", "expected_generation" => generation), peer: @supervisor, role: :supervisor) }
        @kernel.dead << @worker.fetch("pid")
        call("finish", {"head" => @head, "candidate_generation" => 1, "result_id" => submitted.fetch("result_id"), "expected_generation" => generation},
          id: "parent-finish", peer: @supervisor, role: :supervisor).fetch(:data)
      end
    end
  end
end
