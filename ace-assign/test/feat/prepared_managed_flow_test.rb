# frozen_string_literal: true
require_relative "prepared_work_fetch_test"
require "ace/assign/organisms/prepared_work_builder"
require "ace/assign/authority/prepared_worker"

module Ace
  module Assign
    class PreparedManagedFlowTest < PreparedWorkFetchTest
      def configure_result_owner_fixture
        super
        return unless @managed_flow
        task_root = File.join(@root, "tasks")
        directory = File.join(task_root, "8wr.t.abc-managed")
        FileUtils.mkdir_p(directory)
        @managed_spec = File.join(directory, "8wr.t.abc-managed.s.md")
        File.write(@managed_spec, "---\nid: 8wr.t.abc\ntitle: Managed input\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nOriginal managed task instructions.\n")
        tasks = Ace::Task::Organisms::TaskManager.new(root_dir: task_root, config: {})
        cache = File.join(@root, "managed-source")
        executor = Organisms::AssignmentExecutor.new(cache_base: cache)
        # Only the fresh local assignment ID generator is fixed to the shared
        # authority fixture identity. Graph/materialization/definition stay real.
        executor.assignment_manager.define_singleton_method(:generate_assignment_id) { "assignment" }
        builder = Organisms::PreparedWorkBuilder.new(export_root: @root, task_manager: tasks,
          executor: executor, bundle_loader: Ace::Bundle::Organisms::BundleLoader.new(base_dir: @root))
        @managed_input = Ace::Assign.stub(:cache_dir, cache) do
          builder.call(task_ref: "8wr.t.abc", project_id: "project", dependency_reports: [])
        end
      end

      def call(operation, params, **options)
        return super unless @managed_input
        if operation == "register_assignment"
          input = @managed_input
          work = Authority::PreparedWork.admit(root: @root, bytes: input.fetch("bundle"), size: input.fetch("bytes"),
            sha256: input.fetch("sha256"), head: input.fetch("head"), tree: input.fetch("tree"))
          @prepared_registration = PreparedRegistrationFixture::Artifact.new(definition_bytes: input.fetch("definition_bytes"),
            bundle: input.fetch("bundle"), work: work, head: input.fetch("head"), tree: input.fetch("tree"))
          @prepared_registration.with_input(root: @root) do |transfer, descriptor|
            request = {"version" => 1, "operation" => operation, "mutation_id" => options.fetch(:id), "project_id" => "project",
              "params" => @prepared_registration.header(expected_generation: params.fetch("expected_generation"))
                .merge("mapping_id" => "mapping", "transfer" => descriptor)}
            @router.dispatch(request: request, peer: options.fetch(:peer), role: options.fetch(:role), transfer: transfer)
          end
        else
          params = params.merge("scope" => @managed_input.fetch("scope")) if operation == "reserve_attempt"
          super(operation, params, **options)
        end
      end

      def test_actual_managed_preparation_register_release_fetch_and_worker_consume_original_selection
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
            end
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
          assert_equal before, @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_equal 1, captured.size
        end
      ensure
        @managed_flow = @managed_input = nil
      end
    end
  end
end
