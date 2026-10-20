# frozen_string_literal: true

require "ace/assign"
# Explicit (not transitive) requires for the ace-assign surface used below.
require "ace/assign/molecules/assignment_manager"
require "ace/assign/molecules/step_writer"
require "ace/assign/atoms/number_generator"

module Ace
  module Coworker
    module Molecules
      # Composes the planner's role-sequence assignments (L4.2): ONE
      # ace-assign assignment per role, in dependency order, stored by
      # ace-assign in the prepared worktree's .ace-local/assign/ — the plan
      # is the only place steps live (ADR-034; no second queue, no sequence
      # copy in coworker config). Each role's process comes from its
      # per-role sequence definition (shipped
      # .ace-defaults/coworker/sequences/<role>.yml, project override
      # .ace/coworker/sequences/<role>.yml), so worker and reviewer get
      # different processes matched to the same task. A role without a
      # preset or without its own process definition is reported and
      # NOTHING is written: another role's process is never substituted.
      # Composition is idempotent: an existing assignment named
      # "<task>-<role>" with a matching task_id is reused without writes.
      # dry_run resolves the same sequence with ZERO writes: existing
      # assignments are read-only reused, missing legs are "planned".
      class RoleSequenceComposer
        GEM_SEQUENCES_DIR = File.join(".ace-defaults", "coworker", "sequences")
        PROJECT_SEQUENCES_DIR = File.join(".ace", "coworker", "sequences")
        ASSIGN_DIR = File.join(".ace-local", "assign")
        # Step keys the composer itself owns: lifecycle-reserved frontmatter
        # (status/added_by/parent) must never be overridable from definition
        # data, and name/instructions are passed as explicit arguments.
        RESERVED_STEP_KEYS = %w[name instructions status added_by parent].freeze

        # @param project_root [String] absolute root the roles work in (the
        #   prepared worktree)
        # @param preset_loader [RolePresetLoader, #fetch] role preset source
        # @param gem_sequences_dir [String, nil] explicit gem sequences dir
        def initialize(project_root:, preset_loader: nil, gem_sequences_dir: nil)
          @project_root = project_root
          @preset_loader = preset_loader || RolePresetLoader.new(project_root: project_root)
          @gem_sequences_dir = gem_sequences_dir || File.join(gem_root, GEM_SEQUENCES_DIR)
        end

        # @param task [String] canonical task id
        # @param roles [Array<String>] role sequence in dependency order
        # @param dry_run [Boolean] resolve the whole sequence without any
        #   writes: existing assignments are reported as "existing" (a
        #   read-only lookup), missing legs as "planned" with a nil
        #   assignment id
        # @return [Array<Hash>] ordered entries:
        #   {"role", "position", "of", "assignment", "disposition"
        #    ("created"|"existing"|"planned"), "steps", "outcome"}
        # @raise [Error] when any role has no preset or no process
        #   definition; raised BEFORE any assignment is written
        def call(task:, roles:, dry_run: false)
          role_list = Array(roles).map(&:to_s).map(&:strip).reject(&:empty?)
          raise Error, "role sequence requires at least one role" if role_list.empty?

          # Resolve every role's process first: a missing process aborts
          # the whole composition instead of leaving a partial sequence.
          definitions = role_list.map { |role| load_definition(role) }

          previous = nil
          role_list.each_with_index.map do |role, index|
            definition = definitions[index]
            existing = find_existing(task, role)
            entry = if existing
              entry_for(task: task, role: role, index: index, total: role_list.length,
                assignment_id: existing, definition: definition, disposition: "existing")
            elsif dry_run
              entry_for(task: task, role: role, index: index, total: role_list.length,
                assignment_id: nil, definition: definition, disposition: "planned")
            else
              assignment_id = create_assignment(task: task, role: role,
                definition: definition, index: index, total: role_list.length,
                previous: previous)
              entry_for(task: task, role: role, index: index, total: role_list.length,
                assignment_id: assignment_id, definition: definition, disposition: "created")
            end
            previous = {"role" => role, "assignment" => entry["assignment"]}
            entry
          end
        end

        private

        def entry_for(task:, role:, index:, total:, assignment_id:, definition:, disposition:)
          {
            "role" => role,
            "position" => index + 1,
            "of" => total,
            "assignment" => assignment_id,
            "disposition" => disposition,
            "steps" => definition["steps"].length,
            "outcome" => render(definition["outcome"], {"task" => task, "role" => role})
          }
        end

        def create_assignment(task:, role:, definition:, index:, total:, previous:)
          context = {"task" => task, "role" => role}
          description = render(definition["description"], context)
          outcome = render(definition["outcome"], context)
          description = "#{description} (sequence #{index + 1}/#{total}); expected outcome: #{outcome}"

          manager = Ace::Assign::Molecules::AssignmentManager.new(
            cache_base: File.join(@project_root, ASSIGN_DIR))
          assignment = manager.create(
            name: "#{task}-#{role}",
            description: description,
            source_config: definition["path"],
            task_id: task)

          writer = Ace::Assign::Molecules::StepWriter.new
          entry_condition = previous ? entry_condition_line(previous) : nil
          definition["steps"].each_with_index do |step, step_index|
            instructions = step_instructions(step, context: context,
              entry_condition: step_index.zero? ? entry_condition : nil)
            extra = step.reject { |key, _| RESERVED_STEP_KEYS.include?(key) }
            writer.create(
              steps_dir: assignment.steps_dir,
              number: Ace::Assign::Atoms::NumberGenerator.from_index(step_index),
              name: step["name"],
              instructions: instructions,
              status: :pending,
              extra: extra)
          end

          assignment.id
        end

        def entry_condition_line(previous)
          "Entry condition: assignment #{previous['assignment']} (role #{previous['role']}) " \
            "finished successfully before this role starts."
        end

        def step_instructions(step, context:, entry_condition: nil)
          body = Array(step["instructions"])
            .map { |line| render(line, context) }
            .reject(&:empty?)
            .join("\n")
          lines = []
          lines << entry_condition if entry_condition
          lines << body
          lines.reject(&:empty?).join("\n\n")
        end

        def render(template, context)
          Atoms::PromptTemplate.render(template.to_s, context)
        end

        # Finds an existing sequence assignment for the task+role pair:
        # exact name "<task>-<role>" with a matching recorded task_id.
        # Read-only over ace-assign-owned files (like AssignmentMetadata).
        def find_existing(task, role)
          name = "#{task}-#{role}"
          Dir.glob(File.join(@project_root, ASSIGN_DIR, "*", "assignment.yaml")).sort.each do |path|
            data = YAML.safe_load_file(path, permitted_classes: [Time, Date], aliases: true) || {}
            return File.basename(File.dirname(path)) if data["name"] == name && data["task_id"].to_s == task
          end
          nil
        end

        # Resolves the role's process definition: the preset must exist and
        # the role must have its own sequence definition (project override
        # first, then the shipped default). Never substitutes.
        def load_definition(role)
          @preset_loader.fetch(role) # raises Error for an unknown role
          path = sequence_path(role)
          if path.nil?
            raise Error,
              "role '#{role}' has no assignment process: no " \
                "#{File.join(PROJECT_SEQUENCES_DIR, "#{role}.yml")} project override and no " \
                "shipped default; refusing to substitute another role's process"
          end

          raw = begin
            YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
          rescue Psych::Exception => e
            raise Error, "invalid assignment process '#{relative(path)}': #{e.message}"
          end
          errors = definition_errors(role, raw)
          unless errors.empty?
            raise Error, "invalid assignment process '#{relative(path)}': #{errors.join('; ')}"
          end

          raw.merge("path" => path)
        end

        def sequence_path(role)
          project = File.join(@project_root, PROJECT_SEQUENCES_DIR, "#{role}.yml")
          return project if File.file?(project)

          shipped = File.join(@gem_sequences_dir, "#{role}.yml")
          File.file?(shipped) ? shipped : nil
        end

        def definition_errors(role, raw)
          # Mirror the RolePresetSchema raw-YAML guard: an empty file or a
          # non-mapping document is an actionable process error, never a
          # NoMethodError/TypeError on raw["role"].
          return ["process is empty"] if raw.nil?
          return ["process must be a mapping, got #{raw.class}"] unless raw.is_a?(Hash)

          errors = []
          errors << "required 'role' field is missing" if raw["role"].to_s.strip.empty?
          if raw["role"].to_s != role
            errors << "role field '#{raw["role"]}' must match the requested role '#{role}'"
          end
          errors << "required 'description' field is missing" if raw["description"].to_s.strip.empty?
          errors << "required 'outcome' field is missing" if raw["outcome"].to_s.strip.empty?
          steps = raw["steps"]
          if !steps.is_a?(Array) || steps.empty?
            errors << "at least one step is required"
          else
            steps.each_with_index do |step, index|
              # A scalar/null step (steps: [42], steps: [null]) must be an
              # actionable process error, never a TypeError from indexing a
              # non-mapping — malformed user process data stays inside the
              # role_sequence gap path.
              unless step.is_a?(Hash)
                errors << "step #{index + 1}: must be a mapping with 'name' and 'instructions', got #{step.class}"
                next
              end
              errors << "step #{index + 1}: 'name' is required" if step["name"].to_s.strip.empty?
              if Array(step["instructions"]).map(&:to_s).reject(&:empty?).empty?
                errors << "step #{index + 1}: 'instructions' are required"
              end
            end
          end
          errors.uniq
        end

        def relative(path)
          path.start_with?(@project_root) ? path.delete_prefix("#{@project_root}/") : path
        end

        def gem_root
          ::Gem.loaded_specs["ace-coworker"]&.gem_dir || File.expand_path("../../../..", __dir__)
        end
      end
    end
  end
end
