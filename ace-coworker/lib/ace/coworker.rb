# frozen_string_literal: true

require "yaml"
require "ace/support/config"
require_relative "coworker/version"
require_relative "coworker/errors"

module Ace
  module Coworker
    require_relative "coworker/models/config"
    require_relative "coworker/models/brief"
    require_relative "coworker/models/assignment_snapshot"

    autoload :CLI, "ace/coworker/cli"

    module Atoms
      autoload :ConfigSchema, "ace/coworker/atoms/config_schema"
      autoload :BriefFormatter, "ace/coworker/atoms/brief_formatter"
    end

    module Molecules
      autoload :ProjectRoot, "ace/coworker/molecules/project_root"
      autoload :ConfigLoader, "ace/coworker/molecules/config_loader"
      autoload :TaskProbe, "ace/coworker/molecules/task_probe"
      autoload :AssignmentMetadata, "ace/coworker/molecules/assignment_metadata"
      autoload :AssignmentProbe, "ace/coworker/molecules/assignment_probe"
      autoload :InstructionResolver, "ace/coworker/molecules/instruction_resolver"
    end

    module Organisms
      autoload :StartOrchestrator, "ace/coworker/organisms/start_orchestrator"
      autoload :StatusOrchestrator, "ace/coworker/organisms/status_orchestrator"
    end

    def self.config
      @config ||= begin
        defaults = load_gem_defaults
        user_config = Ace::Support::Config.create.resolve_namespace("coworker").to_h
        Ace::Support::Config::Models::Config.wrap(defaults, user_config, source: "coworker")
      end
    end

    def self.load_gem_defaults
      gem_root = ::Gem.loaded_specs["ace-coworker"]&.gem_dir || File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace-defaults", "coworker", "config.yml")
      raise Error, "Default config not found: #{defaults_path}" unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

    def self.reset_config!
      @config = nil
    end
  end
end
