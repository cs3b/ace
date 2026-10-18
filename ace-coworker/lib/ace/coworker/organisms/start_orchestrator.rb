# frozen_string_literal: true

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker start`: load+validate config, resolve the
      # task in this worktree, verify the assignment exists and matches the
      # config task, resolve the instruction source, and render the executor
      # brief. Writes nothing; never creates a substitute assignment/worktree.
      class StartOrchestrator
        def initialize(project_root: nil, config_loader: nil, task_probe: nil, assignment_metadata: nil,
          assignment_probe: nil, instruction_resolver: nil, config: nil)
          @config = config || Ace::Coworker.config
          @project_root = project_root || Molecules::ProjectRoot.new.resolve
          @config_loader = config_loader || Molecules::ConfigLoader.new(project_root: @project_root, defaults: @config)
          @task_probe = task_probe || Molecules::TaskProbe.new(project_root: @project_root)
          @assignment_metadata = assignment_metadata || Molecules::AssignmentMetadata.new(project_root: @project_root)
          @assignment_probe = assignment_probe || Molecules::AssignmentProbe.new(project_root: @project_root)
          @instruction_resolver = instruction_resolver || Molecules::InstructionResolver.new(project_root: @project_root)
        end

        attr_reader :project_root

        # @return [Models::Brief]
        # @raise [Error] with a specific "not ready"/invalid/mismatch message
        def call(config_path: nil)
          cfg = @config_loader.load(path: config_path)

          task_path = @task_probe.resolve!(cfg.task)
          @assignment_metadata.verify_task_match!(cfg.assignment, cfg.task)
          snapshot = @assignment_probe.snapshot(cfg.assignment)
          instructions_source = @instruction_resolver.resolve!(cfg.instructions)

          Models::Brief.new(
            config: cfg,
            instructions_source: instructions_source,
            task_path: task_path,
            assignment_snapshot: snapshot,
            project_root: @project_root
          )
        end
      end
    end
  end
end
