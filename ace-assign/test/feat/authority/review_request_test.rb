# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/launch_driver"

module Ace
  module Assign
    class ReviewRequestTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def issued_with_channel(mode: :assigned)
        events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
        origin = @launch.origin(events, assignment_id: "assignment", attempt_id: @attempt, mapping_id: "mapping")
        # Launch issuance is a canonical fixture. No installed/native launch is
        # claimed; request/assignment/reply mutations below use real admission.
        @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "issued",
          operation: "release_launch", parameters_digest: "a" * 64, expected_generation: generation) do
          {data: origin.merge("phase" => "issued")}
        end
        @dispatches = 0
        channel = Object.new
        held = nil
        channel.define_singleton_method(:reserve_dispatch!) { held = Object.new }
        channel.define_singleton_method(:dispatch_reserved?) { |value| held.equal?(value) }
        channel.define_singleton_method(:release_dispatch!) { |_value| held = nil }
        owner = self
        channel.define_singleton_method(:dispatch_review) do |frame:, **_|
          owner.instance_variable_set(:@dispatches, owner.instance_variable_get(:@dispatches) + 1)
          owner.delegate(frame, mode)
        end
        @launch.instance_variable_get(:@control_channels)[["project", "mapping", "assignment", @attempt]] = channel
      end

      def delegate(frame, mode)
        raise AttemptErrors::EvidenceUnavailable, "controlled missing ACK" if mode == :lost
        query = frame.slice("mutation_id", "request_event_id", "journal_commit", "original_binding_digest")
        intent = call("launch_review_intent", query, peer: @launcher, role: :launcher).fetch(:data)
        result = call("assign_review", intent.fetch("assignment_params"),
          id: "review-delegate.#{frame.fetch('request_event_id')}", peer: @launcher, role: :launcher)
        raise AttemptErrors::EvidenceUnavailable, "controlled lost accepted ACK" if mode == :assigned_lost
        frame.slice("mutation_id", "request_event_id", "original_binding_digest").merge(
          "version" => 1, "type" => "launch_review_assigned", "assignment_event_id" => result.dig(:data, "assignment_event_id"),
          "journal_commit" => result.dig(:data, "journal_commit"))
      end

      def request_params
        {"head" => @head, "candidate_generation" => 1, "expected_generation" => generation}
      end

      def request_review(params, id: "request")
        call("request_review", params, id: id, peer: @reviewer, role: :reviewer)
      end

      def review_status(peer: @reviewer)
        call("review_status", {"mutation_id" => "request"}, peer: peer, role: :reviewer)
      end

      def test_actual_request_delegation_and_reply_are_canonical_and_replay_never_redispatches
        fixture do
          issued_with_channel(mode: :assigned_lost)
          params = request_params
          reply = request_review(params)
          assert_equal "assigned", reply.dig(:data, "state")
          assignment = reply.dig(:data, "assignment")
          assert_match(/\A[0-9a-f]{32}\z/, assignment.fetch("review_id"))
          assert_equal params.fetch("expected_generation") + 2, assignment.fetch("generation")
          before = @journal.ref_value
          assert_equal reply.fetch(:data), request_review(params).fetch(:data)
          assert_equal 1, @dispatches
          assert_equal before, @journal.ref_value
          status = review_status(peer: @reviewer.merge("pid" => 182)).fetch(:data)
          assert_equal assignment, status.fetch("assignment")
          assert_equal reply.fetch(:data), status.fetch("first_reply")
          assert_raises(AttemptErrors::Conflict) { request_review(params.merge("expected_generation" => generation)) }
        end
      end

      def test_acceptance_uses_public_reply_generation_and_cancel_keeps_first_reply_immutable
        fixture do
          issued_with_channel
          requested = request_params
          first = request_review(requested).fetch(:data)
          assignment = first.fetch("assignment")
          artifact = "controlled independent verdict"
          receipt = {"assignment_id" => "assignment", "attempt_id" => @attempt, "project_id" => "project", "scope" => "010",
            "operation" => "review", "head" => @head, "verdict" => "succeeded",
            "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
            "artifacts" => [{"path" => "review-report", "sha256" => Digest::SHA256.hexdigest(artifact)}],
            "checks" => [{"name" => "controlled-review", "verdict" => "passed"}],
            "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => assignment.fetch("reviewer_actor")}}}
          params, input, = upload(parts: [artifact], receipt: receipt)
          params.merge!("purpose_id" => assignment.fetch("review_id"), "expected_generation" => first.fetch("generation"))
          accepted = call("accept_review", params, id: "accept", peer: @reviewer, role: :reviewer, transfer: input)
          assert_equal assignment.fetch("review_id"), accepted.dig(:data, "review_id")
          assert review_status.dig(:data, "accepted_review_event_id")
          cancelled = call("cancel_review", {"head" => @head, "candidate_generation" => 1,
            "review_event_id" => first.fetch("request_event_id"), "expected_generation" => generation},
            id: "cancel", peer: @reviewer.merge("pid" => 182), role: :reviewer)
          status = review_status.fetch(:data)
          assert_equal "cancelled", status.fetch("state")
          assert_equal cancelled.dig(:data, "cancellation_event_id"), status.fetch("cancellation_event_id")
          assert_equal first, status.fetch("first_reply")
          assert_equal first, request_review(requested).fetch(:data)
          assert_equal 1, @dispatches
        end
      end

      def test_lost_unassigned_request_is_immutable_uncertainty_without_redispatch
        fixture do
          issued_with_channel(mode: :lost)
          params = request_params
          first = request_review(params)
          assert_equal "uncertain", first.dig(:data, "state")
          assert_equal "inspect_review_status", first.dig(:data, "required_action")
          assert_nil first.dig(:data, "assignment")
          assert_equal first.fetch(:data), request_review(params).fetch(:data)
          assert_equal 1, @dispatches
          assert_nil review_status.dig(:data, "assignment")
          assert_raises(AttemptErrors::UnauthorizedIdentity) { review_status(peer: @reviewer.merge("groups" => [999])) }
        end
      end

      def test_actual_public_socket_channel_and_original_driver_join_canonical_assignment
        require "ace/overseer/organisms/protected_review"
        require "ace/review"
        fixture do
          bundle_path = File.join(@root, "actual-review.bundle")
          git(@journal.repo_root, "bundle", "create", bundle_path, "HEAD")
          bundle = File.binread(bundle_path)
          descriptor = Authority::TransferCodec.new(root: @root).descriptor([bundle], purpose: :candidate)
          input = Struct.new(:body) do
            def count = 1
            def bytes(index: 0) = body
          end.new(bundle)
          call("submit_candidate", {"head" => @head, "candidate_generation" => 1,
            "expected_generation" => generation, "transfer" => descriptor}, id: "actual-candidate", transfer: input)
          issued_with_channel
          left, right = UNIXSocket.pair
          channel = Authority::LaunchControlChannel.new(socket: left, codec: Object.new,
            outcome: ->(*) { flunk "review cannot invoke native prompt outcome" })
          @launch.instance_variable_get(:@control_channels)[["project", "mapping", "assignment", @attempt]] = channel
          channel_thread = Thread.new { channel.serve }
          original = @journal.read_events("assignment").find { |event| event.dig("payload", "operation") == "record_launch" }
          owner = self
          bridge = Object.new
          bridge.define_singleton_method(:call) do |operation, params, mutation_id:, **_|
            result = owner.call(operation, params, id: mutation_id, peer: owner.instance_variable_get(:@launcher), role: :launcher)
            Authority::Client::Reply.new(data: result.fetch(:data), replayed: result.fetch(:replayed))
          end
          driver = Authority::LaunchDriver.new(mapping_id: "mapping", deployment: @deployment, kernel: @kernel, client: bridge)
          driver_thread = Thread.new do
            loop do
              frame = WIRE.read(right, deadline: WIRE.deadline(30))
              if frame["type"] == "launch_control_idle"
                WIRE.write(right, frame.merge("type" => "launch_control_idle_ack"), deadline: WIRE.deadline(5))
                next
              end
              driver.send(:original_review_delegate!, right, {"assignment_id" => "assignment", "attempt_id" => @attempt},
                {"original_binding_digest" => original.fetch("digest")}, frame, WIRE.deadline(30))
              break
            end
          end
          @kernel.peer_identity = @reviewer
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
          kernel = Kernel.new
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
          # Both transport ends use controlled identities, while all protocol,
          # original channel, snapshot, review and canonical import owners run.
          reviewer = @reviewer
          kernel.define_singleton_method(:capture) { |_| reviewer }
          provider = Object.new
          provider.define_singleton_method(:execute) do |system_prompt:, user_prompt:, model:, session_dir:, output_file: nil, **_|
            if model == "role:review-default"
              packet = JSON.parse(user_prompt)
              response = JSON.generate("schema" => "ace.review.candidate-verdict/v1", "head" => packet.dig("candidate", "head"),
                "tree" => packet.dig("candidate", "tree"), "subject_sha256" => packet.fetch("subject_sha256"),
                "verdict" => "approved", "summary" => "Controlled executed review of full snapshot", "findings" => [])
              output_file ||= File.join(session_dir, "review-report-controlled.md")
            else
              response = '{"findings":[]}'
            end
            FileUtils.mkdir_p(session_dir)
            File.write(output_file, response)
            {success: true, response: response, output_file: output_file,
              execution: {"status" => "succeeded", "provider" => "controlled", "model" => "fixture"}}
          end
          calls = []
          original_call = client.method(:call)
          client.define_singleton_method(:call) do |operation, *arguments, **options|
            calls << operation
            original_call.call(operation, *arguments, **options)
          end
          consumer = Ace::Overseer::Organisms::ProtectedReview.new(deployment_loader: -> { @deployment }, kernel: kernel,
            client_factory: ->(*_) { client })
          limits = Struct.new(:context_limit, :output_limit).new(200_000, 8192)
          result = Ace::Review::Molecules::LlmExecutor.stub(:new, provider) do
            Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, limits) do
              consumer.call(project: "project", agent: "mapping", assignment: "assignment", attempt: @attempt,
                mutation: "request", head: @head, candidate_generation: 2, expected_generation: generation, accept_mutation: "accept")
            end
          end
          assert_equal "accepted", result.fetch("state"), "#{result.inspect}; calls=#{calls.inspect}"
          selectors = {"assignment_id" => "assignment", "attempt_id" => @attempt}
          status = client.call("review_status", selectors.merge("mutation_id" => "request"), timeout: 30)
          first_reply = JSON.parse(File.read(File.join(result.fetch("session_dir"), "assignment.json")))
          assert_equal first_reply, status.data.fetch("first_reply")
          assert_equal first_reply.fetch("assignment"), status.data.fetch("assignment")
          refute_nil status.data.fetch("accepted_review_event_id")
          events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
          approved = @endcap.send(:approved_review!, @journal, events, selectors, @map,
            {"head" => @head, "candidate_generation" => 2})
          assert_equal "approved", approved.dig("review_receipt", "review", "verdict")
          assert_equal 3, approved.dig("review_receipt", "artifacts").size
          assert driver_thread.join(3)
          driver_thread.value
        ensure
          channel&.close
          left&.close
          right&.close
          channel_thread&.join(3)
          driver_thread&.join(3)
        end
      end

      def test_missing_original_channel_and_unknown_status_never_create_request
        fixture do
          before = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) { request_review(request_params) }
          assert_raises(AttemptErrors::NotFound) { review_status }
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end
