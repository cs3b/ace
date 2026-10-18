# frozen_string_literal: true

require "yaml"

module Ace
  module Coworker
    module Molecules
      # Loads and validates .ace-local/coworker/config.yml.
      #
      # Missing or invalid input produces specific errors; the loader never
      # guesses a substitute commission.
      class ConfigLoader
        DEFAULT_CONFIG_PATH = File.join(".ace-local", "coworker", "config.yml")

        # @param project_root [String] absolute project root
        # @param path [String, nil] explicit config path (absolute or root-relative)
        # @param defaults [Hash] cascade defaults (config_path override)
        def initialize(project_root:, defaults: {})
          @project_root = project_root
          @defaults = defaults || {}
        end

        def config_path
          configured = @defaults["config_path"].to_s.strip
          relative = configured.empty? ? DEFAULT_CONFIG_PATH : configured
          File.expand_path(relative, @project_root)
        end

        # @return [Models::Config]
        def load(path: nil)
          target = path ? File.expand_path(path, @project_root) : config_path
          raise Error, "not ready: #{relativize(target)} not found" unless File.file?(target)

          raw = YAML.safe_load_file(target, permitted_classes: [Date], aliases: true)
          raw = {} if raw.nil?
          unless raw.is_a?(Hash)
            raise Error, "invalid config #{relativize(target)}: expected a mapping, got #{raw.class}"
          end

          errors = Atoms::ConfigSchema.errors(raw)
          unless errors.empty?
            raise Error, "invalid config #{relativize(target)}: #{errors.join('; ')}"
          end

          build_config(Atoms::ConfigSchema.normalize(raw), target)
        end

        def ready?(path: nil)
          target = path ? File.expand_path(path, @project_root) : config_path
          File.file?(target)
        end

        private

        def build_config(normalized, target)
          Models::Config.new(
            role: normalized["role"],
            instructions: normalized["instructions"],
            start_prompt: normalized["start_prompt"],
            start_prompt_file: normalized["start_prompt_file"].to_s.empty? ? nil : normalized["start_prompt_file"],
            task: normalized["task"],
            assignment: normalized["assignment"],
            overseer: normalized["overseer"],
            reporting_channel: normalized.dig("reporting", "channel"),
            on_failure: normalized.dig("errors", "on_failure"),
            source_path: target
          )
        end

        def relativize(path)
          path.start_with?(@project_root) ? path.delete_prefix("#{@project_root}/") : path
        end
      end
    end
  end
end
