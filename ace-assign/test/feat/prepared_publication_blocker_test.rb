# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-git/test/support/protected_merge_flow_fixture"
require_relative "../support/managed_prepared_registration_fixture"
require_relative "../support/prepared_workspace_resource_fixture"
require_relative "../../../ace-handbook/test/support/rubygems_publish_fixture"
require "ace/assign/cli"

module Ace
  module Assign
    class PreparedPublicationBlockerTest < AceAssignTestCase
      include ProtectedMergeFlowFixture
      include ManagedPreparedRegistrationFixture
      include PreparedWorkspaceResourceFixture
      include RubygemsPublishFixture

      def test_missing_publisher_retains_policy_denial_and_failed_original_step
        fixture do
          issue_original
          submission, bytes = prepared_submission
          original = @policy.method(:authorize!)
          denied, effects = [], []
          @policy.define_singleton_method(:authorize!) do |binding|
            original.call(binding)
          rescue SecurityError => error
            denied << [binding.fetch("operation"), binding.fetch("request_id"), error.message]
            raise
          end
          handler = Object.new
          handler.define_singleton_method(:execute) { |**args| effects << args; raise "unconfigured publisher executed" }
          client = start_service_server
          before = @journal.ref_value
          run_publication_worker do
            @kernel.peer_identity = @executor
            result = receiver(client, handler).execute(submission: submission, peer: @worker, input_bytes: bytes,
              mutation_id: "publication-unavailable")
            assert_equal "uncertain", result.fetch("state")
            assert_equal [["publish", "service-request", "operation is not configured"]], denied
            route_failed_publication("publication blocked: configured publisher unavailable")
          end
          stop_listener!
          assert_equal before, @journal.ref_value
          assert_nil @journal.service_request("service-request")
          assert_empty effects
          assert_equal 1, denied.size
        end
      end

      def test_ordinary_publisher_otp_precondition_routes_original_failure_without_push
        fixture do
          issue_original
          before = @journal.ref_value
          start_service_server
          run_publication_worker do
            with_fake_rubygems(credentials: true) do |env, context|
              stdout, stderr, status = run_script(env, context, "ace-support-core")
              refute status.success?
              assert_includes stderr, "No valid OTP."
              refute File.exist?(context.push_log)
              refute_includes File.read(context.command_log), "push"
              assert_secret_absent(stdout, stderr)
            end
            route_failed_publication("publication blocked: ordinary publisher OTP prerequisite unavailable")
          end
          stop_listener!
          assert_equal before, @journal.ref_value
          assert_empty @journal.service_requests("assignment")
        end
      end

      def configure_result_owner_fixture
        super
        configure_original_workspace_resource
        task_root = File.join(@root, "publication-tasks")
        directory = File.join(task_root, "8wr.t.abc-publication")
        FileUtils.mkdir_p(directory)
        File.write(File.join(directory, "8wr.t.abc-publication.s.md"), "---\nid: 8wr.t.abc\ntitle: Publication handoff\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nRequested publication handoff.\n")
        catalog = File.expand_path("../../../ace-handbook/handbook/workflow-instructions/handbook/perform-delivery.wf.md", __dir__)
        workflow = Ace::Bundle::Organisms::BundleLoader.new(base_dir: @root).load_file(catalog).content
        instructions = workflow.split("## Unavailable publication prerequisite\n", 2).fetch(1).split("\n## ", 2).first
        instructions = "## Unavailable publication prerequisite\n" + instructions
        assert_includes instructions, "Unavailable publication prerequisite"
        preset_root = File.join(@root, ".ace", "assign", "presets")
        FileUtils.mkdir_p(preset_root)
        File.write(File.join(preset_root, "work-on-task.yml"), YAML.dump({"name" => "work-on-task",
          "parameters" => {"taskref" => {"required" => true}}, "steps" => [{"number" => "010",
            "name" => "publication-handoff", "context" => "fork", "taskref" => "{{taskref}}", "instructions" => instructions}]}))
        cache = File.join(@root, "publication-source")
        executor = Organisms::AssignmentExecutor.new(cache_base: cache)
        executor.assignment_manager.define_singleton_method(:generate_assignment_id) { "assignment" }
        builder = Organisms::PreparedWorkBuilder.new(export_root: @root,
          task_manager: Ace::Task::Organisms::TaskManager.new(root_dir: task_root, config: {}), executor: executor,
          bundle_loader: Ace::Bundle::Organisms::BundleLoader.new(base_dir: @root))
        @managed_input = Ace::Assign.stub(:cache_dir, cache) do
          Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, @root) do
            builder.call(task_ref: "8wr.t.abc", project_id: "project", dependency_reports: [])
          end
        end
      end

      def run_publication_worker(&operation)
        @kernel.peer_identity = @worker
        identity = @worker
        @worker_kernel = EndcapResultOwnerFixture::Kernel.new
        @worker_kernel.define_singleton_method(:capture) { |_| identity }
        @worker_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @worker_client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: @worker_kernel)
        query = Object.new
        query.define_singleton_method(:query) do |provider, prompt, **parameters|
          raise "captured publication instructions missing" unless prompt.include?("Unavailable publication prerequisite")
          operation.call
          {text: "Publication blocker retained.", provider: provider, model: "controlled", metadata: {}}
        end
        launcher = Molecules::ForkSessionLauncher.new(query_interface: query, config: {}, runner: Object.new, interactive_builder: Object.new)
        launcher.define_singleton_method(:detect_provider_session) { |*| raise "native discovery forbidden" }
        adapter = Authority::PreparedWorker.new(kernel: @worker_kernel, client_factory: ->(_) { @worker_client }, launcher: launcher,
          workspace_reader_factory: method(:controlled_workspace_reader), env: {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping",
            "ACE_ASSIGN_ASSIGNMENT_ID" => "assignment", "ACE_ASSIGN_ATTEMPT_ID" => @attempt})
        error = assert_raises(AttemptErrors::EvidenceUnavailable) { adapter.run }
        assert_equal "prepared provider exited before selected queue completed", error.message
      end

      def route_failed_publication(message)
        @kernel.peer_identity = @worker
        data = {"projects" => {"project" => @project}, "authorities" => {"authority" => @service},
          "launch_mappings" => {"mapping" => @map}}
        @deployment.define_singleton_method(:data) { data }
        history = Object.new
        history.define_singleton_method(:descriptors) { [] }
        context = Authority::ProtectedAssignmentContext.new(deployment: @deployment, history: history,
          uid: @worker.fetch("uid"), kernel: @worker_kernel, env: {})
        stdout, stderr = capture_io do
          Authority::ProtectedAssignmentContext.stub(:load, context) do
            assert_equal 0, CLI.start(["fail", "--assignment", "assignment@010", "--attempt", @attempt,
              "--mapping", "mapping", "--message", message])
            assert_equal 0, CLI.start(["status", "--assignment", "assignment@010", "--attempt", @attempt, "--mapping", "mapping"])
          end
        end
        assert_includes stdout, "marked as failed"
        assert_includes stdout, message
        assert_empty stderr
        admitted = Authority::PreparedInput.fetch(client: @worker_client, assignment_id: "assignment", attempt_id: @attempt)
        Authority::PreparedQueue.new(work: admitted.work, descriptor: admitted.descriptor).with_executor do |executor|
          state = executor.status.fetch(:state)
          assert state.subtree_failed?("010")
          refute state.subtree_steps("010").all? { |step| step.status == :done }
          assert_equal 1, state.failed.size
          assert_equal message, state.failed.first.error
        end
      end

      def stop_listener!
        @server.stop
        @owner.join(10)
        refute @owner.alive?
        @owner.value
      end
    end
  end
end
