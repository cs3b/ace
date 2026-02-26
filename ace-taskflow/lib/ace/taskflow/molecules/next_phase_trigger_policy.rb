# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Resolves auto/manual trigger state and mode precedence for next-phase simulation.
      class NextPhaseTriggerPolicy
        VALID_MODES = %w[draft plan work].freeze

        def initialize(config: nil)
          @config = config || Ace::Taskflow.configuration.config
        end

        def resolve(source_type:, manual:, cli_enable: false, cli_disable: false, cli_modes: nil)
          if cli_enable && cli_disable
            raise ArgumentError, "Cannot use --next-phase-review and --no-next-phase-review together"
          end

          source_kind = normalize_source_type(source_type)
          explicit_modes = parse_modes(cli_modes)
          enabled = resolve_enabled(source_kind: source_kind, manual: manual, cli_enable: cli_enable, cli_disable: cli_disable)
          modes = explicit_modes || default_modes_for(source_kind)

          {
            enabled: enabled,
            modes: modes,
            source_type: source_kind,
            reason: enabled ? "enabled" : "disabled"
          }
        end

        private

        def resolve_enabled(source_kind:, manual:, cli_enable:, cli_disable:)
          return true if cli_enable
          return false if cli_disable
          return true if manual

          review_cfg = review_config
          review_enabled = review_cfg.fetch("enabled", true)
          auto_enabled = review_cfg.dig("auto", source_kind) != false
          review_enabled && auto_enabled
        end

        def parse_modes(raw_modes)
          parsed = Array(raw_modes).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:empty?).uniq
          return nil if parsed.empty?

          invalid = parsed - VALID_MODES
          unless invalid.empty?
            raise ArgumentError, "Unsupported mode(s): #{invalid.join(', ')}. Valid modes: #{VALID_MODES.join(', ')}"
          end

          parsed
        end

        def default_modes_for(source_kind)
          return %w[draft plan] if source_kind == "idea"
          return %w[plan work] if include_work_simulation_enabled?

          %w[plan]
        end

        def normalize_source_type(source_type)
          normalized = source_type.to_s.strip.downcase
          return "idea" if normalized == "idea"
          return "task" if normalized == "task"

          raise ArgumentError, "Unsupported source type '#{source_type}'. Expected 'idea' or 'task'."
        end

        def review_config
          raw = @config.dig("review", "next_phase") || @config.dig("taskflow", "review", "next_phase") || {}
          stringify_keys(raw)
        end

        def include_work_simulation_enabled?
          review_config["include_work_simulation"] == true
        end

        def stringify_keys(value)
          case value
          when Hash
            value.each_with_object({}) do |(k, v), out|
              out[k.to_s] = stringify_keys(v)
            end
          when Array
            value.map { |item| stringify_keys(item) }
          else
            value
          end
        end
      end
    end
  end
end
