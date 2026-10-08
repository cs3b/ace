# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-git/test/support/protected_merge_flow_fixture"
require_relative "../support/managed_prepared_registration_fixture"

module Ace
  module Assign
    class PreparedDeliveryFlowTest < AceAssignTestCase
      include ProtectedMergeFlowFixture
      include ManagedPreparedRegistrationFixture

      def test_original_prepared_child_delivers_before_queue_completion
        @managed_flow = @managed_delivery = @public_lab = true
        @pending_delivery_observations = 0
        exercise_completion
        assert_equal 1, @pending_delivery_observations
        assert_equal 1, @provider_calls
      end

      def test_actual_authorization_denial_leaves_captured_child_unfinished
        @managed_flow = @managed_delivery = @public_lab = true
        @authorization_mode = :missing
        error = assert_raises(AttemptErrors::EvidenceUnavailable) { exercise_completion }
        assert_equal "prepared provider exited before selected queue completed", error.message
        assert_equal false, @delivery_completed
        assert @authorization_observations.any? { |entry| entry.fetch("exact") && entry.fetch("rejected") }
      end

      def delivery_authority_client
        @delivery_client || super
      end

      def observe_pending_delivery!
        return unless @delivery_executor
        state = @delivery_executor.status.fetch(:state)
        refute state.subtree_complete?("010")
        assert state.active_steps.any?, "pending canonical delivery keeps original child active"
        @pending_delivery_observations += 1
      end

      def with_original_delivery_worker(&delivery)
        @delivery_client = start_service_server
        @kernel.peer_identity = @worker
        identity = @worker
        kernel = EndcapResultOwnerFixture::Kernel.new
        kernel.define_singleton_method(:capture) { |_| identity }
        kernel.peer_identity = @service.slice("uid", "gid", "groups")
        worker_client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
        @provider_calls = 0
        query = Object.new
        query.define_singleton_method(:query) do |provider, prompt, **parameters|
          execute_delivery_provider(worker_client, delivery, prompt)
          {text: "Original protected delivery completed.", provider: provider, model: "controlled", metadata: {}}
        end
        fixture_owner = self
        query.define_singleton_method(:execute_delivery_provider) { |*args| fixture_owner.execute_delivery_provider(*args) }
        launcher = Molecules::ForkSessionLauncher.new(query_interface: query, config: {}, runner: Object.new, interactive_builder: Object.new)
        launcher.define_singleton_method(:detect_provider_session) { |*| raise "native discovery forbidden" }
        worker = Authority::PreparedWorker.new(kernel: kernel, client_factory: ->(_) { worker_client }, launcher: launcher,
          env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping", "ACE_ASSIGN_ASSIGNMENT_ID" => "assignment", "ACE_ASSIGN_ATTEMPT_ID" => @attempt})
        assert_equal "Original protected delivery completed.", worker.run.fetch(:text)
      end

      def execute_delivery_provider(client, delivery, prompt)
        @provider_calls += 1
        assert_includes prompt, "ace-lab service request"
        admitted = Authority::PreparedInput.fetch(client: client, assignment_id: "assignment", attempt_id: @attempt)
        queue = Authority::PreparedQueue.new(work: admitted.work, descriptor: admitted.descriptor)
        queue.with_executor do |executor|
          executor.start_step(fork_root: "010")
          @delivery_executor = executor
          refute executor.status.fetch(:state).subtree_complete?("010")
          delivery.call
          @kernel.peer_identity = @worker
          record = @journal.service_request("service-request")
          unless record && record.fetch("state") == "succeeded"
            @delivery_completed = false
            refute executor.status.fetch(:state).subtree_complete?("010")
            assert executor.status.fetch(:state).active_steps.any?
            return
          end
          assert_equal "succeeded", record.fetch("state")
          executor.finish_step(report_content: "Consumed original canonical protected delivery.", fork_root: "010")
          8.times do
            break if executor.status.fetch(:state).subtree_complete?("010")
            executor.start_step(fork_root: "010")
            executor.finish_step(report_content: "Original selected delivery subtree completed.", fork_root: "010")
          end
          assert executor.status.fetch(:state).subtree_complete?("010")
          @delivery_completed = true
        ensure
          @delivery_executor = nil
        end
      end

      def test_managed_preparation_captures_shipped_merge_child_before_registration
        @managed_flow = @managed_delivery = true
        fixture do
          work = @prepared_registration.work
          assert_equal "010", work.manifest.fetch("scope")
          children = work.manifest.fetch("steps").reject { |entry| entry.fetch("number") == "010" }
          assert_equal 1, children.size
          child = children.first
          body = work.parse_queue_step!(work.files.fetch("steps/" + child.fetch("filename")))
          assert_includes body.fetch(:body), "For an original protected PreparedWorker"
          assert_includes body.fetch(:body), "Refusal, unavailable evidence or uncertainty leaves it unfinished"
          assert_equal @managed_input.fetch("selection_sha256"), work.selection_sha256
        end
      end
    end
  end
end
