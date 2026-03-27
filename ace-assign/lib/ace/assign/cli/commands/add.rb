# frozen_string_literal: true

require "yaml"
require "set"

module Ace
  module Assign
    module CLI
      module Commands
        # Add step trees dynamically to a running assignment.
        class Add < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include AssignmentTarget

          desc "Add step(s) to the queue dynamically"

          option :yaml, desc: "Path to YAML file with a top-level steps: array"
          option :step, desc: "Preset step name(s), comma-separated"
          option :task, desc: "Task reference to expand from preset child-template"
          option :preset, desc: "Preset name (required only for --step/--task overrides)"
          option :after, aliases: ["-a"], desc: "Insert after this step number (e.g., 010)"
          option :child, aliases: ["-c"], type: :boolean, default: false, desc: "Insert as child of --after step"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(**options)
            validate_mode_options!(options)
            validate_child_requires_after!(options)

            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)

            mode = selected_mode(options)
            case mode
            when :yaml
              handle_yaml_mode(executor, options)
            when :step
              handle_step_mode(executor, options)
            when :task
              handle_task_mode(executor, options)
            else
              raise Ace::Support::Cli::Error, "Exactly one of --yaml, --step, or --task is required"
            end
          end

          private

          def validate_mode_options!(options)
            selected = insertion_modes(options).count { |_, value| !value.to_s.strip.empty? }
            raise Ace::Support::Cli::Error, "Exactly one of --yaml, --step, or --task is required" if selected.zero?
            raise Ace::Support::Cli::Error, "--yaml, --step, and --task are mutually exclusive" if selected > 1

            preset = options[:preset].to_s.strip
            return if preset.empty?
            return if !options[:step].to_s.strip.empty? || !options[:task].to_s.strip.empty?

            raise Ace::Support::Cli::Error, "--preset requires --step or --task"
          end

          def validate_child_requires_after!(options)
            if options[:child] && options[:after].to_s.strip.empty? && options[:task].to_s.strip.empty?
              raise Ace::Support::Cli::Error, "--child requires --after to specify the parent step"
            end
          end

          def insertion_modes(options)
            {
              yaml: options[:yaml],
              step: options[:step],
              task: options[:task]
            }
          end

          def selected_mode(options)
            insertion_modes(options).find { |_, value| !value.to_s.strip.empty? }&.first
          end

          def handle_yaml_mode(executor, options)
            yaml_path = options[:yaml].to_s.strip
            steps = load_steps_from_file(yaml_path)
            result = executor.add_batch(
              steps: steps,
              after: options[:after],
              as_child: options[:child],
              source_file: yaml_path
            )
            print_yaml_result(result, yaml_path) unless options[:quiet]
            nil
          end

          def handle_step_mode(executor, options)
            preset_name = resolve_preset_name(executor, options)
            preset = Atoms::PresetLoader.load(preset_name)
            requested = parse_step_names(options[:step])
            templates = Atoms::PresetStepResolver.find_steps(preset, requested)

            steps = []
            added_steps = []
            renumbered = []
            sibling_cursor = options[:after]

            templates.each do |template|
              state = executor.status[:state]
              existing_names = state.steps.map(&:name)
              step = build_preset_step(template, existing_names: existing_names)
              steps << step

              inserted = executor.add_batch(
                steps: [step],
                after: options[:child] ? options[:after] : sibling_cursor,
                as_child: options[:child],
                source_file: "preset:#{preset_name}"
              )

              inserted_added = Array(inserted[:added])
              added_steps.concat(inserted_added)
              renumbered.concat(Array(inserted[:renumbered]))
              sibling_cursor = inserted_added.first&.number unless options[:child]
            end

            result = {added: added_steps, renumbered: renumbered.uniq}

            print_step_result(result, steps, after: options[:after]) unless options[:quiet]
            nil
          end

          def handle_task_mode(executor, options)
            preset_name = resolve_preset_name(executor, options)
            preset = Atoms::PresetLoader.load(preset_name)
            task_ref = options[:task].to_s.strip
            raise Ace::Support::Cli::Error, "--task requires a task reference" if task_ref.empty?

            child_template = preset.dig("expansion", "child-template")
            unless child_template.is_a?(Hash)
              raise Ace::Support::Cli::Error, "Preset '#{preset_name}' has no expansion.child-template"
            end

            parent_step = options[:after].to_s.strip
            parent_step = detect_batch_parent(executor) if parent_step.empty?
            if parent_step.to_s.strip.empty?
              raise Ace::Support::Cli::Error, "No batch parent found. Pass --after <step> to specify."
            end

            task_step = build_task_step(child_template, task_ref, debug: options[:debug])
            result = executor.add_batch(
              steps: [task_step],
              after: parent_step,
              as_child: true,
              source_file: "preset:#{preset_name}:task:#{task_ref}"
            )

            print_task_result(result, task_ref, parent_step) unless options[:quiet]
            nil
          end

          def resolve_preset_name(executor, options)
            explicit = options[:preset].to_s.strip
            return explicit unless explicit.empty?

            assignment = executor.status[:assignment]
            Molecules::PresetInferrer.infer_from_assignment(assignment)
          end

          def parse_step_names(raw)
            names = raw.to_s.split(",").map(&:strip).reject(&:empty?)
            raise Ace::Support::Cli::Error, "--step requires at least one step name" if names.empty?

            names
          end

          def build_preset_step(template, existing_names:)
            step = deep_dup_hash(template)
            step_name = step["name"].to_s
            if Atoms::PresetStepResolver.iteration_name?(step_name)
              next_name = Atoms::PresetStepResolver.next_iteration_name(
                Atoms::PresetStepResolver.base_name(step_name),
                existing_names
              )
              step["name"] = next_name
              existing_names << next_name
            else
              existing_names << step_name
            end
            step
          end

          def build_task_step(template, task_ref, debug: false)
            normalized = template.each_with_object({}) { |(key, value), memo| memo[key.to_s] = value }
            step = substitute_tokens(normalized, "item" => task_ref)
            warn_unexpanded_template_tokens(step) if debug
            step
          end

          def substitute_tokens(value, replacements)
            case value
            when Hash
              value.each_with_object({}) do |(key, nested), memo|
                memo[key] = substitute_tokens(nested, replacements)
              end
            when Array
              value.map { |item| substitute_tokens(item, replacements) }
            when String
              value.gsub(/\{\{([a-zA-Z0-9_]+)\}\}/) do
                replacements.fetch(Regexp.last_match(1), Regexp.last_match(0))
              end
            else
              value
            end
          end

          def warn_unexpanded_template_tokens(value)
            tokens = collect_template_tokens(value)
            return if tokens.empty?

            warn "[ace-assign] Warning: Unexpanded preset template token(s): " \
                 "#{tokens.join(', ')}. Supported tokens for --task mode: {{item}}"
          end

          def collect_template_tokens(value, tokens = Set.new)
            case value
            when Hash
              value.each_value { |nested| collect_template_tokens(nested, tokens) }
            when Array
              value.each { |item| collect_template_tokens(item, tokens) }
            when String
              value.scan(/\{\{([a-zA-Z0-9_]+)\}\}/) do |match|
                tokens << "{{#{match.first}}}"
              end
            end

            tokens.to_a.sort
          end

          def detect_batch_parent(executor)
            state = executor.status[:state]

            batch_parent = state.top_level.find { |step| step.name == "batch-tasks" }
            return batch_parent.number if batch_parent

            fallback = state.top_level.find do |step|
              state.children_of(step.number).any? { |child| child.name.start_with?("work-on-") }
            end
            fallback&.number
          end

          def load_steps_from_file(path)
            raise Ace::Support::Cli::Error, "File not found: #{path}" unless File.exist?(path)

            begin
              data = YAML.safe_load_file(path, aliases: true)
            rescue Psych::SyntaxError => e
              raise Ace::Support::Cli::Error, "Invalid YAML in #{path}: #{e.message}"
            end

            steps = data.is_a?(Hash) ? data["steps"] : nil
            unless steps.is_a?(Array) && steps.any?
              raise Ace::Support::Cli::Error, "No steps defined in #{path}"
            end

            steps
          end

          def deep_dup_hash(value)
            Marshal.load(Marshal.dump(value))
          end

          def print_yaml_result(result, source_path)
            added_steps = Array(result[:added])
            puts "Added #{added_steps.size} step(s) from #{File.basename(source_path)}"
            print_added_steps(added_steps)
          end

          def print_step_result(result, requested_steps, after: nil)
            added_steps = Array(result[:added])
            root_name = requested_steps.first["name"]
            relation = after.to_s.strip.empty? ? "" : " after #{after}"
            puts "Added #{root_name} (#{added_steps.size} step(s))#{relation}".strip
            print_added_steps(added_steps)
          end

          def print_task_result(result, task_ref, parent_step)
            added_steps = Array(result[:added])
            puts "Added task #{task_ref} under #{parent_step}"
            print_added_steps(added_steps)
          end

          def print_added_steps(steps)
            steps.each do |step|
              fork_suffix = step.context == "fork" ? " (fork)" : ""
              puts "  #{step.number}: #{step.name} [#{step.status}]#{fork_suffix}"
            end
          end
        end
      end
    end
  end
end
