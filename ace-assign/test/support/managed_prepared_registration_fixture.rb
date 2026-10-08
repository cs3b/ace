# frozen_string_literal: true
require "ace/assign/organisms/prepared_work_builder"

module Ace
  module Assign
    module ManagedPreparedRegistrationFixture
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
        capture = -> { builder.call(task_ref: "8wr.t.abc", project_id: "project", dependency_reports: []) }
        @managed_input = Ace::Assign.stub(:cache_dir, cache) do
          if @managed_delivery
            preset_root = File.join(@root, ".ace", "assign", "presets")
            FileUtils.mkdir_p(preset_root)
            preset = {"name" => "work-on-task", "parameters" => {"taskref" => {"required" => true}},
              "steps" => [{"number" => "010", "name" => "protected-delivery", "context" => "fork",
                "taskref" => "{{taskref}}", "sub_steps" => ["auto-merge"],
                "instructions" => "Execute only the captured authorized delivery child."}]}
            File.write(File.join(preset_root, "work-on-task.yml"), YAML.dump(preset))
            Ace::Support::Fs::Molecules::ProjectRootFinder.stub(:find_or_current, @root) { capture.call }
          else
            capture.call
          end
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

    end
  end
end
