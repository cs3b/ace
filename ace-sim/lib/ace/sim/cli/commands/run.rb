# frozen_string_literal: true

module Ace
  module Sim
    module CLI
      module Commands
        class Run < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Run preset simulation"

          option :preset, type: :string, desc: "Preset name (configured in .ace/sim/presets/*.yml)"
          option :source, type: :array, desc: "Source file(s) - repeatable, supports globs"
          option :steps, type: :string, desc: "Comma-separated step names"
          option :provider, type: :array, desc: "Provider:model (repeatable, e.g. --provider codex:mini)"
          option :repeat, type: :integer, desc: "Repeat count for each provider"
          option :synthesis_workflow, type: :string, desc: "Workflow/file reference for final synthesis (e.g. wfi://task/review, wfi://idea/review)"
          option :synthesis_provider, type: :string, desc: "Provider:model for final suggestions synthesis"
          option :dry_run, type: :boolean, desc: "Enable non-mutating run"
          option :writeback, type: :boolean, desc: "Enable writeback"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :verbose, aliases: ["-v"], type: :boolean, default: false, desc: "Verbose output"

          def initialize(runner: nil)
            super()
            @runner = runner
          end

          def call(**options)
            session = build_session(options)
            result = runner.run(session)

            unless options[:quiet]
              puts "Run ID: #{result[:run_id]}"
              puts "Run Dir: #{result[:run_dir]}"
              puts "Status: #{result[:status]}"
            end

            return if result[:success]

            raise Ace::Support::Cli::Error.new(result[:error] || "Simulation failed")
          end

          private

          def build_session(options)
            preset_name = pick_value(options[:preset], Ace::Sim.default_preset_name)
            preset_data = Ace::Sim.load_preset(preset_name)
            if preset_data.nil?
              raise Ace::Support::Cli::Error.new("Unknown preset '#{preset_name}'. Known presets: #{Ace::Sim.preset_names.join(', ')}")
            end

            if !options[:synthesis_provider].to_s.strip.empty? && options[:synthesis_workflow].nil?
              raise Ace::Support::Cli::Error.new("synthesis_provider requires synthesis_workflow")
            end

            sources = options[:source] || Array(preset_data["source"])
            raise Ace::Support::Cli::Error.new("--source is required") if sources.empty?

            steps = if options[:steps] && !options[:steps].to_s.strip.empty?
              parse_steps(options[:steps])
            else
              Ace::Sim.normalize_list(preset_data["steps"] || Ace::Sim.get("sim", "default_steps"))
            end
            raise Ace::Support::Cli::Error.new("At least one step is required") if steps.empty?

            providers = if options[:provider].nil?
              Ace::Sim.normalize_list(preset_data["provider"] || preset_data["providers"] || Ace::Sim.get("sim", "default_providers"))
            else
              Ace::Sim.normalize_list(options[:provider])
            end
            raise Ace::Support::Cli::Error.new("At least one --provider is required") if providers.empty?

            repeat = pick_value(options[:repeat], preset_data["repeat"], Ace::Sim.get("sim", "default_repeat") || 1)
            repeat = Integer(repeat)
            raise Ace::Support::Cli::Error.new("--repeat must be >= 1") if repeat < 1

            synthesis_workflow = pick_value(
              options[:synthesis_workflow],
              preset_data["synthesis_workflow"],
              Ace::Sim.get("sim", "synthesis_workflow")
            ).to_s.strip
            synthesis_provider = pick_value(
              options[:synthesis_provider],
              preset_data["synthesis_provider"],
              Ace::Sim.get("sim", "synthesis_provider")
            ).to_s.strip

            dry_run = pick_value(options[:dry_run], preset_data["dry_run"], false)
            writeback = pick_value(options[:writeback], preset_data["writeback"], Ace::Sim.get("sim", "writeback") || false)

            step_bundles = resolve_step_bundles(steps)

            Models::SimulationSession.new(
              preset: preset_name,
              source: sources,
              steps: steps,
              providers: providers,
              repeat: repeat,
              dry_run: dry_run,
              writeback: writeback,
              verbose: options[:verbose],
              step_bundles: step_bundles,
              synthesis_workflow: synthesis_workflow,
              synthesis_provider: synthesis_provider
            )
          rescue ArgumentError => e
            raise Ace::Support::Cli::Error.new(e.message)
          rescue Ace::Sim::ValidationError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          def parse_steps(raw_steps)
            raw_steps.to_s.split(",").map(&:strip).reject(&:empty?)
          end

          def resolve_step_bundles(steps)
            steps.each_with_object({}) do |step, configs|
              config_path = Ace::Sim.step_bundle_path(step)
              if config_path.nil?
                raise Ace::Support::Cli::Error.new("Missing step config for '#{step}' in .ace/sim/steps or defaults")
              end

              configs[step] = config_path
            end
          end

          def pick_value(*values)
            values.find { |value| !value.nil? }
          end

          def runner
            @runner ||= Organisms::SimulationRunner.new
          end
        end
      end
    end
  end
end
