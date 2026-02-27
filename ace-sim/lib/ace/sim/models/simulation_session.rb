# frozen_string_literal: true

module Ace
  module Sim
    module Models
      class SimulationSession
        attr_reader :preset, :source, :steps, :providers, :repeat, :dry_run, :writeback, :run_id, :verbose,
                    :step_bundles

        def initialize(preset:, source:, steps:, providers:, repeat:, dry_run:, writeback:, verbose: false,
                       run_id: nil, step_bundles: {})
          @preset = preset.to_s.strip
          @source = source.to_s.strip
          @steps = Array(steps).map(&:to_s).map(&:strip).reject(&:empty?)
          @providers = Array(providers).map(&:to_s).map(&:strip).reject(&:empty?)
          @repeat = Integer(repeat)
          @dry_run = !!dry_run
          @writeback = !!writeback
          @verbose = !!verbose
          @step_bundles = stringify_step_bundles(step_bundles)
          @run_id = run_id || Ace::Sim.next_run_id

          validate!
        end

        def dry_run?
          dry_run
        end

        def writeback?
          writeback
        end

        def regenerate_run_id!
          @run_id = Ace::Sim.next_run_id
        end

        def bundle_path_for(step)
          step_bundles[step.to_s]
        end

        def to_h
          {
            "run_id" => run_id,
            "preset" => preset,
            "source" => source,
            "steps" => steps,
            "providers" => providers,
            "repeat" => repeat,
            "dry_run" => dry_run,
            "writeback" => writeback
          }
        end

        private

        def validate!
          raise Ace::Sim::ValidationError, "source cannot be empty" if source.empty?
          raise Ace::Sim::ValidationError, "steps cannot be empty" if steps.empty?
          raise Ace::Sim::ValidationError, "providers cannot be empty" if providers.empty?
          raise Ace::Sim::ValidationError, "repeat must be >= 1" if repeat < 1
          raise Ace::Sim::ValidationError, "writeback cannot be enabled with --dry-run" if dry_run? && writeback?

          missing_bundles = steps.reject { |step| step_bundles.key?(step) && !step_bundles[step].to_s.strip.empty? }
          return if missing_bundles.empty?

          raise Ace::Sim::ValidationError, "Missing step configs for: #{missing_bundles.join(', ')}"
        end

        def stringify_step_bundles(raw)
          raw.to_h.each_with_object({}) do |(step, path), acc|
            acc[step.to_s] = path.to_s
          end
        end
      end
    end
  end
end
