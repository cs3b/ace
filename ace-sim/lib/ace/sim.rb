# frozen_string_literal: true

require "yaml"
require "date"
require "ace/support/config"
require "ace/core"
require "ace/b36ts"

require_relative "sim/version"
require_relative "sim/models/simulation_session"
require_relative "sim/molecules/source_resolver"
require_relative "sim/molecules/stage_executor"
require_relative "sim/molecules/session_store"
require_relative "sim/molecules/synthesis_builder"
require_relative "sim/organisms/simulation_runner"
require_relative "sim/cli"

module Ace
  module Sim
    class Error < StandardError; end
    class ValidationError < Error; end

    module_function

    def normalize_list(raw)
      Array(raw).flatten.compact.map(&:to_s).map(&:strip).reject(&:empty?)
    end

    def config
      @config ||= begin
        defaults = load_defaults
        user_config = config_resolver.resolve_namespace("sim").to_h
        Ace::Support::Config::Models::Config.wrap(defaults, user_config, source: "sim")
      end
    end

    def get(*keys)
      config.dig(*keys)
    end

    def reset_config!
      @config = nil
      @config_resolver = nil
      @preset_names = nil
    end

    def preset_names
      @preset_names ||= begin
        dirs = [
          File.join(gem_root, ".ace-defaults", "sim", "presets"),
          File.join(Dir.home, ".ace", "sim", "presets"),
          File.join(Dir.pwd, ".ace", "sim", "presets")
        ]

        dirs.filter_map do |dir|
          next unless Dir.exist?(dir)

          files = Dir.glob(File.join(dir, "*.yml")) + Dir.glob(File.join(dir, "*.yaml"))
          files.map { |path| File.basename(path, ".*") }
        end.flatten.uniq.sort
      end
    end

    def load_preset(name)
      preset_name = name.to_s.strip
      return nil if preset_name.empty?

      data = config_resolver.resolve_file([
        "sim/presets/#{preset_name}.yml",
        "sim/presets/#{preset_name}.yaml"
      ]).data

      preset = if data.nil? || data.empty?
        return nil unless preset_names.include?(preset_name)

        {"steps" => normalize_list(get("sim", "default_steps"))}
      else
        data["preset"] || data
      end

      steps = normalize_list(preset["steps"])
      raise ValidationError, "Preset '#{preset_name}' has no steps" if steps.empty?

      normalized = preset.to_h.each_with_object({}) { |(k, v), acc| acc[k.to_s] = v }
      normalized["name"] = preset_name
      normalized["steps"] = steps
      normalized
    end

    def step_bundle_path(step)
      step_name = step.to_s.strip
      return nil if step_name.empty?

      candidates = [
        File.join(Dir.pwd, ".ace", "sim", "steps", "#{step_name}.md"),
        File.join(Dir.home, ".ace", "sim", "steps", "#{step_name}.md"),
        File.join(gem_root, ".ace-defaults", "sim", "steps", "#{step_name}.md")
      ]

      candidates.find { |path| File.exist?(path) }
    end

    def default_preset_name
      get("sim", "default_preset") || "validate-idea"
    end

    def next_run_id
      Ace::B36ts.now
    rescue StandardError
      timestamp = Time.now.utc.to_i.to_s(36)
      entropy = rand(36**2).to_s(36).rjust(2, "0")
      "#{timestamp}#{entropy}"
    end

    def config_resolver
      @config_resolver ||= Ace::Support::Config.create(gem_path: gem_root)
    end

    def gem_root
      Gem.loaded_specs["ace-sim"]&.gem_dir || File.expand_path("../..", __dir__)
    end

    def load_defaults
      defaults_path = File.join(gem_root, ".ace-defaults", "sim", "config.yml")
      raise "Default config not found: #{defaults_path}" unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    end
    private_class_method :load_defaults
  end
end
