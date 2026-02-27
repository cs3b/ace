# frozen_string_literal: true

module Ace
  module Sim
    module CLI
      module Commands
        class Run < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Run preset simulation"

          option :preset, type: :string, desc: "Preset name (configured in .ace/sim/presets/*.yml)"
          option :source, type: :string, desc: "Source reference (task/idea reference)"
          option :steps, type: :string, desc: "Comma-separated step names"
          option :provider, type: :array, desc: "Provider:model (repeatable, e.g. --provider codex:mini)"
          option :repeat, type: :integer, desc: "Repeat count for each provider"
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

            raise Ace::Core::CLI::Error.new(result[:error] || "Simulation failed")
          end

          private

          def build_session(options)
            preset_name = value_from(options[:preset], Ace::Sim.default_preset_name)
            preset_data = Ace::Sim.load_preset(preset_name)
            if preset_data.nil? && Ace::Sim.preset_names.include?(preset_name)
              preset_data = {
                "name" => preset_name,
                "steps" => Array(Ace::Sim.get("sim", "default_steps")).map(&:to_s)
              }
            end
            if preset_data.nil?
              raise Ace::Core::CLI::Error.new("Unknown preset '#{preset_name}'. Known presets: #{Ace::Sim.preset_names.join(', ')}")
            end

            source = value_from(options[:source], preset_data["source"])
            raise Ace::Core::CLI::Error.new("--source is required") if source.to_s.strip.empty?

            expanded_source = File.expand_path(source.to_s)
            unless File.file?(expanded_source)
              raise Ace::Core::CLI::Error.new("--source must be a readable file path: #{source}")
            end
            unless File.readable?(expanded_source)
              raise Ace::Core::CLI::Error.new("--source file is not readable: #{source}")
            end

            source = expanded_source

            steps = if present?(options[:steps])
              parse_steps(options[:steps])
            else
              Array(preset_data["steps"] || Ace::Sim.get("sim", "default_steps")).map(&:to_s)
            end
            raise Ace::Core::CLI::Error.new("At least one step is required") if steps.empty?

            providers = if options[:provider].nil?
              normalized_providers(preset_data["provider"] || preset_data["providers"] || Ace::Sim.get("sim", "default_providers"))
            else
              normalized_providers(options[:provider])
            end
            raise Ace::Core::CLI::Error.new("At least one --provider is required") if providers.empty?

            repeat = pick_value(options[:repeat], preset_data["repeat"], Ace::Sim.get("sim", "default_repeat") || 1)
            repeat = Integer(repeat)
            raise Ace::Core::CLI::Error.new("--repeat must be >= 1") if repeat < 1

            dry_run = pick_value(options[:dry_run], preset_data["dry_run"], false)
            writeback = pick_value(options[:writeback], preset_data["writeback"], Ace::Sim.get("sim", "writeback") || false)

            step_bundles = resolve_step_bundles(steps)

            Models::SimulationSession.new(
              preset: preset_name,
              source: source,
              steps: steps,
              providers: providers,
              repeat: repeat,
              dry_run: dry_run,
              writeback: writeback,
              verbose: options[:verbose],
              step_bundles: step_bundles
            )
          rescue ArgumentError => e
            raise Ace::Core::CLI::Error.new(e.message)
          rescue Ace::Sim::ValidationError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def parse_steps(raw_steps)
            raw_steps.to_s.split(",").map(&:strip).reject(&:empty?)
          end

          def resolve_step_bundles(steps)
            steps.each_with_object({}) do |step, configs|
              config_path = Ace::Sim.step_bundle_path(step)
              if config_path.nil?
                raise Ace::Core::CLI::Error.new("Missing step config for '#{step}' in .ace/sim/steps or defaults")
              end

              configs[step] = config_path
            end
          end

          def normalized_providers(raw)
            Array(raw).flatten.compact.map(&:to_s).map(&:strip).reject(&:empty?)
          end

          def present?(value)
            !value.nil? && !value.to_s.strip.empty?
          end

          def value_from(primary, fallback)
            present?(primary) ? primary : fallback
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
