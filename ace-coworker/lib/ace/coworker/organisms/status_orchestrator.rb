# frozen_string_literal: true

module Ace
  module Coworker
    module Organisms
      # Orchestrates `ace-coworker status`: readiness, resolved identity,
      # assignment progress, completion verdict. A query — renders any state,
      # including not-ready, without guessing.
      class StatusOrchestrator
        NotReady = Struct.new(:message, keyword_init: true)
        Ready = Struct.new(:config, :snapshot, :project_root, :probe_error, :assignment, keyword_init: true)

        def initialize(project_root: nil, config_loader: nil, assignment_metadata: nil,
          assignment_probe: nil, config: nil)
          @config = config || Ace::Coworker.config
          @project_root = project_root || Molecules::ProjectRoot.new.resolve
          @config_loader = config_loader || Molecules::ConfigLoader.new(project_root: @project_root, defaults: @config)
          @assignment_metadata = assignment_metadata || Molecules::AssignmentMetadata.new(project_root: @project_root)
          @assignment_probe = assignment_probe || Molecules::AssignmentProbe.new(project_root: @project_root)
        end

        attr_reader :project_root

        # @return [NotReady, Ready]
        def call(config_path: nil, assignment: nil)
          # Same resolution rule as ConfigLoader: explicit paths are expanded
          # against the project root, not the process working directory.
          target = config_path ? File.expand_path(config_path, @project_root) : default_config_path
          relative = relativize(target)
          return NotReady.new(message: "not ready: #{relative} not found") unless File.file?(target)

          begin
            cfg = @config_loader.load(path: target)
          rescue Error => e
            return NotReady.new(message: e.message)
          end

          assignment_id = assignment.to_s.strip.empty? ? cfg.assignment : assignment.to_s.strip
          begin
            @assignment_metadata.verify_task_match!(assignment_id, cfg.task)
            snapshot = @assignment_probe.snapshot(assignment_id)
          rescue Error => e
            return Ready.new(config: cfg, snapshot: nil, project_root: @project_root,
              probe_error: e.message, assignment: assignment_id)
          end

          Ready.new(config: cfg, snapshot: snapshot, project_root: @project_root, assignment: assignment_id)
        end

        private

        def default_config_path
          @config_loader.config_path
        end

        def relativize(path)
          path.start_with?(@project_root) ? path.delete_prefix("#{@project_root}/") : path
        end
      end
    end
  end
end
