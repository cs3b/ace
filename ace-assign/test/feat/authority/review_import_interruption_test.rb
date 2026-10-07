# frozen_string_literal: true
require_relative "review_request_test"

module Ace
  module Assign
    class ReviewImportInterruptionTest < ReviewRequestTest
      # Inherit controlled fixture helpers, not its test selection.
      ReviewRequestTest.instance_methods.grep(/^test_/).each { |name| undef_method name }

      def test_actual_endpoint_import_faults_preserve_original_request_and_atomic_acceptance
        %i[before_import after_plan lost_reply].each do |stage|
          fixture do
            issued_with_channel
            @launch.instance_variable_get(:@control_channels).each_value { |channel| channel.define_singleton_method(:close) { true } }
            request = request_params
            first = request_review(request).fetch(:data)
            review = first.fetch("assignment")
            artifact = "retained original review\0\n".b
            receipt = {"assignment_id" => "assignment", "attempt_id" => @attempt, "project_id" => "project", "scope" => "010",
              "operation" => "review", "head" => @head, "verdict" => "succeeded",
              "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
              "artifacts" => [{"path" => "report", "sha256" => Digest::SHA256.hexdigest(artifact)}],
              "checks" => [{"name" => "controlled-completed-review", "verdict" => "passed"}],
              "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => review.fetch("reviewer_actor")}}}
            params, input, = upload(parts: [artifact], receipt: receipt)
            params = params.except("transfer").merge("assignment_id" => "assignment", "attempt_id" => @attempt,
              "purpose_id" => review.fetch("review_id"), "expected_generation" => first.fetch("generation"))
            before = @journal.ref_value
            @kernel.peer_identity = @reviewer
            @server = Authority::Server.new(authority_id: "authority", lifecycle: @router, deployment: @deployment,
              kernel: @kernel, composition: "services")
            fault = true
            wire = Object.new
            wire.define_singleton_method(:root_path!) { |*_, **_| true }
            %i[socket_identity read deadline].each do |name|
              wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
            end
            wire.define_singleton_method(:write) do |socket, value, **options|
              if stage == :lost_reply && fault && value["status"] == "ok" && value.dig("data", "uploaded_receipt_sha256")
                fault = false
                socket.close
                raise IOError, "controlled lost committed acceptance reply"
              end
              WIRE.write(socket, value, **options)
            end
            @server.define_singleton_method(:wire) { wire }
            @owner = Thread.new { @server.serve }
            Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
            kernel = Kernel.new
            kernel.peer_identity = @service.slice("uid", "gid", "groups")
            client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
            real_new = Molecules::CanonicalEvidence.method(:new)
            constructor = lambda do |**options|
              canonical = real_new.call(**options)
              original = canonical.method(:import_plan)
              canonical.define_singleton_method(:import_plan) do |**arguments|
                if fault && stage != :lost_reply && arguments[:kind] == "review"
                  fault = false
                  original.call(**arguments) if stage == :after_plan
                  raise AttemptErrors::EvidenceUnavailable, "controlled interruption #{stage} before CAS"
                end
                original.call(**arguments)
              end
              canonical
            end
            Molecules::CanonicalEvidence.stub(:new, constructor) do
              assert_raises(stage == :lost_reply ? Ace::Runtime::RuntimeUnavailableError : AttemptErrors::EvidenceUnavailable) do
                client.call("accept_review", params, mutation_id: "accept", upload_parts: input.parts,
                  purpose: :receipt_artifacts, timeout: 30)
              end
            end
            refute fault, "the selected fault must actually be reached"
            observed = client.call("review_status", {"assignment_id" => "assignment", "attempt_id" => @attempt,
              "mutation_id" => "request"}, timeout: 30).data
            assert_equal first, observed.fetch("first_reply")
            assert_equal 1, @dispatches
            if stage == :lost_reply
              refute_equal before, @journal.ref_value
              refute_nil observed.fetch("accepted_review_event_id")
              committed = @journal.ref_value
              replay = client.call("accept_review", params, mutation_id: "accept", upload_parts: input.parts,
                purpose: :receipt_artifacts, timeout: 30)
              assert replay.replayed
              assert_equal committed, @journal.ref_value
              events = @journal.read_events("assignment").select { |event| event["attempt_id"] == @attempt }
              accepted = @endcap.send(:approved_review!, @journal, events,
                {"assignment_id" => "assignment", "attempt_id" => @attempt}, @map, {"head" => @head, "candidate_generation" => 1})
              assert_equal "approved", accepted.dig("review_receipt", "review", "verdict")
            else
              assert_equal before, @journal.ref_value
              assert_nil observed["accepted_review_event_id"]
              refute @journal.read_events("assignment").any? { |event| event["type"] == "evidence_import" }
            end
            assert_equal first, request_review(request).fetch(:data)
            assert_equal 1, @dispatches
          end
        end
      end
    end
  end
end
