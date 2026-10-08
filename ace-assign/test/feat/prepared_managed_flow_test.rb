# frozen_string_literal: true
require_relative "prepared_work_fetch_test"
require "ace/assign/organisms/prepared_work_builder"
require "ace/assign/authority/prepared_worker"
require "ace/assign/authority/launch_driver"
require_relative "../support/managed_prepared_registration_fixture"

module Ace
  module Assign
    class PreparedManagedFlowTest < PreparedWorkFetchTest
      include ManagedPreparedRegistrationFixture

      def original_cli(args, kernel:)
        project = @project.merge("worker_uids" => [@worker.fetch("uid")], "launcher_uids" => [@launcher.fetch("uid")])
        map, service = @map, @service
        @deployment.define_singleton_method(:data) { {"projects" => {"project" => project}, "launch_mappings" => {"mapping" => map}, "authorities" => {"authority" => service}} }
        history = Object.new
        history.define_singleton_method(:descriptors) { [] }
        context = Authority::ProtectedAssignmentContext.new(deployment: @deployment, history: history,
          uid: @worker.fetch("uid"), kernel: kernel, env: {})
        client = @client
        output, error = capture_io do
          Authority::ProtectedAssignmentContext.stub(:load, context) do
            Authority::Client.stub(:new, ->(**_) { client }) { assert_equal 0, CLI.start(args) }
          end
        end
        assert_empty error
        JSON.parse(output)
      end

      def submit_worker_result(kernel:)
        common = ["--mapping", "mapping", "--assignment", "assignment", "--attempt", @attempt]
        observed = original_cli(["authority", "status", *common], kernel: kernel)
        bundle = File.join(@root, "worker.bundle")
        git(@journal.repo_root, "bundle", "create", bundle, "HEAD")
        admitted = original_cli(["submit-candidate", *common, "--head", @head, "--candidate-generation",
          observed.fetch("result_candidate_generation").to_s, "--expected-generation", observed.fetch("authority_generation").to_s,
          "--mutation", "worker-public-candidate", "--bundle", bundle], kernel: kernel)
        assert_equal @head, admitted.fetch("head")
        candidate_generation = admitted.fetch("candidate_generation")
        accepted = original_public_review(admitted)
        @kernel.peer_identity = @worker
        observed = original_cli(["authority", "status", *common], kernel: kernel)
        assert_equal accepted.fetch("generation"), observed.fetch("authority_generation")
        assert_equal candidate_generation, observed.fetch("result_candidate_generation")
        report_path = File.join(@root, "executed-queue.txt")
        report = "Original admitted queue executed to completion through maintained Executor."
        File.binwrite(report_path, report)
        result = Models::ExecutionReceipt.new(assignment_id: "assignment", attempt_id: @attempt, project_id: "project",
          scope: @managed_input.fetch("scope"), operation: "work", head: @head,
          producer: {"actor" => "worker", "role" => "worker", "runtime" => "herdr"}, verdict: "succeeded",
          artifacts: [{"path" => "executed-queue.txt", "sha256" => Digest::SHA256.hexdigest(report)}],
          checks: [{"name" => "original queue execution", "verdict" => "passed"}], recorded_at: Time.now.utc)
        path = File.join(@root, "result.json")
        File.binwrite(path, JSON.generate(result.to_h))
        args = ["submit-result", *common, "--head", @head, "--candidate-generation", candidate_generation.to_s,
          "--expected-generation", observed.fetch("authority_generation").to_s, "--mutation", "worker-public-result",
          "--receipt", path, "--artifact", report_path]
        @produced_result = original_cli(args, kernel: kernel)
        selected = @journal.ref_value
        assert_equal @produced_result, original_cli(args, kernel: kernel)
        assert_equal selected, @journal.ref_value
      end

      def original_public_review(candidate)
        require "ace/overseer/cli"
        require "ace/review"
        original = @journal.read_events("assignment").find { |event| event.dig("payload", "operation") == "record_launch" }
        left, right = UNIXSocket.pair
        channel = Authority::LaunchControlChannel.new(socket: left, codec: Object.new,
          outcome: ->(*) { flunk "review cannot invoke native prompt outcome" })
        @launch.instance_variable_get(:@control_channels)[["project", "mapping", "assignment", @attempt]] = channel
        channel_thread = Thread.new { channel.serve }
        owner = self
        bridge = Object.new
        bridge.define_singleton_method(:call) do |operation, params, mutation_id:, **_|
          reply = owner.call(operation, params, id: mutation_id, peer: owner.instance_variable_get(:@launcher), role: :launcher)
          Authority::Client::Reply.new(data: reply.fetch(:data), replayed: reply.fetch(:replayed))
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
        rescue IOError
          raise unless right.closed?
        end
        @kernel.peer_identity = @reviewer
        kernel = Kernel.new
        kernel.peer_identity = @service.slice("uid", "gid", "groups")
        reviewer = @reviewer
        kernel.define_singleton_method(:capture) { |_| reviewer }
        client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
        provider = Object.new
        provider.define_singleton_method(:execute) do |system_prompt:, user_prompt:, model:, session_dir:, output_file: nil, **_|
          if model == "role:review-default"
            packet = JSON.parse(user_prompt)
            response = JSON.generate("schema" => "ace.review.candidate-verdict/v1", "head" => packet.dig("candidate", "head"),
              "tree" => packet.dig("candidate", "tree"), "subject_sha256" => packet.fetch("subject_sha256"),
              "verdict" => "approved", "summary" => "Controlled executed review of original tested snapshot", "findings" => [])
            output_file ||= File.join(session_dir, "review-report-controlled.md")
          else
            response = '{"findings":[]}'
          end
          FileUtils.mkdir_p(session_dir)
          File.write(output_file, response)
          {success: true, response: response, output_file: output_file,
            execution: {"status" => "succeeded", "provider" => "controlled", "model" => "fixture"}}
        end
        consumer = Ace::Overseer::Organisms::ProtectedReview.new(deployment_loader: -> { @deployment }, kernel: kernel,
          client_factory: ->(*_) { client })
        limits = Struct.new(:context_limit, :output_limit).new(200_000, 8192)
        output, error = capture_io do
          Ace::Review::Molecules::LlmExecutor.stub(:new, provider) do
            Ace::Review::Atoms::ContextLimitResolver.stub(:resolve_details, limits) do
              Ace::Overseer::Organisms::ProtectedReview.stub(:new, ->(**_) { consumer }) do
                Ace::Support::Cli::Runner.new(Ace::Overseer::CLI).call(args: ["review", "--project", "project", "--agent", "mapping",
                  "--assignment", "assignment", "--attempt", @attempt, "--head", @head,
                  "--candidate-generation", candidate.fetch("candidate_generation").to_s,
                  "--expected-generation", candidate.fetch("generation").to_s,
                  "--mutation", "worker-review-request", "--accept-mutation", "worker-review-accept"])
              end
            end
          end
        end
        assert_includes error, "Synthesis complete"
        result = JSON.parse(output)
        assert_equal "accepted", result.fetch("state"), result.fetch("error", "review did not accept")
        assert driver_thread.join(3)
        driver_thread.value
        result.fetch("acceptance")
      ensure
        channel&.close
        left&.close unless left&.closed?
        right&.close unless right&.closed?
        channel_thread&.join(3)
        driver_thread&.join(3)
        refute channel_thread&.alive?, "original review channel remains live"
        refute driver_thread&.alive?, "original review Driver remains live"
      end

      def test_actual_managed_preparation_register_release_fetch_and_worker_consume_original_selection
        managed_worker_flow
      end

      def test_actual_original_worker_produces_public_candidate_and_result_after_queue_execution
        managed_worker_flow(produce_result: true)
      end

      def managed_worker_flow(produce_result: false)
        @managed_flow = true
        fixture do
          issued = issue_original.fetch(:data)
          assert_equal @managed_input.fetch("selection_sha256"), issued.dig("prepared_input", "prepared_work", "selection_sha256")
          assert_equal @managed_input.fetch("bundle"), @journal.blob(issued.dig("prepared_input", "bundle_ref"),
            commit: issued.dig("prepared_input", "registration_commit"))
          File.write(@managed_spec, "Current task changed after registration.\n")
          start_server
          fetched = client_fetch
          assert_equal [@managed_input.fetch("bundle")], fetched.parts
          identity = @worker
          kernel = Kernel.new
          kernel.define_singleton_method(:capture) { |_| identity }
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          captured = []
          client, attempt = @client, @attempt
          producer = -> { submit_worker_result(kernel: kernel) }
          query = Object.new
          query.define_singleton_method(:query) do |provider, prompt, **parameters|
            captured << [provider, prompt, parameters]
            admitted = Authority::PreparedInput.fetch(client: client, assignment_id: "assignment", attempt_id: attempt)
            queue = Authority::PreparedQueue.new(work: admitted.work, descriptor: admitted.descriptor)
            scope = admitted.descriptor.fetch("scope")
            queue.with_executor do |executor|
              # Controlled provider performs actual maintained queue transitions;
              # a response string alone must never satisfy worker completion.
              256.times do
                break if executor.status.fetch(:state).subtree_complete?(scope)
                executor.start_step(fork_root: scope)
                executor.finish_step(report_content: "Controlled step result.", fork_root: scope)
              end
              raise "Controlled queue did not complete" unless executor.status.fetch(:state).subtree_complete?(scope)
            end
            producer.call if produce_result
            {text: "Controlled provider received original work.", provider: provider, model: "controlled", metadata: {}}
          end
          launcher = Molecules::ForkSessionLauncher.new(config: {}, query_interface: query,
            runner: Object.new, interactive_builder: Object.new)
          launcher.define_singleton_method(:detect_provider_session) { |*| raise "native session discovery forbidden" }
          worker = Authority::PreparedWorker.new(kernel: kernel,
            env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping", "ACE_ASSIGN_ASSIGNMENT_ID" => "assignment", "ACE_ASSIGN_ATTEMPT_ID" => @attempt},
            client_factory: ->(_) { @client }, launcher: launcher)
          before = @journal.ref_value
          assert_equal "Controlled provider received original work.", worker.run.fetch(:text)
          assert_equal 1, captured.size
          assert_includes captured.first[1], "Original managed task instructions."
          refute_includes captured.first[1], "Current task changed"
          assert_includes captured.first[1], "assignment@#{@managed_input.fetch('scope')}"
          if produce_result
            refute_equal before, @journal.ref_value
            assert_includes captured.first[1], "ace-assign submit-candidate"
            assert_includes captured.first[1], "--candidate-generation CURRENT_CANDIDATE"
            assert_includes captured.first[1], "--candidate-generation REVIEWED_CANDIDATE"
            assert_includes captured.first[1], "using 0 when null"
            assert_includes captured.first[1], "ace-lab service request"
            assert_includes captured.first[1], "ace-lab service status"
            assert_includes captured.first[1], "Refusal, unavailable or uncertain leaves the active delivery step unfinished"
            assert_includes captured.first[1], "ace-assign submit-result"
            assert_includes captured.first[1], "ace-overseer review"
            assert_equal "succeeded", @produced_result.fetch("verdict")
          else
            assert_equal before, @journal.ref_value
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_equal 1, captured.size
        end
      ensure
        @managed_flow = @managed_input = nil
      end
    end
  end
end
