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
    require_relative "coworker/models/outcome"
    require_relative "coworker/models/resume_plan"
    require_relative "coworker/models/preparation"

    autoload :CLI, "ace/coworker/cli"

    module Atoms
      autoload :ConfigSchema, "ace/coworker/atoms/config_schema"
      autoload :BriefFormatter, "ace/coworker/atoms/brief_formatter"
      autoload :OutcomePlanner, "ace/coworker/atoms/outcome_planner"
      autoload :ReportRecordFormatter, "ace/coworker/atoms/report_record_formatter"
      autoload :ResumePlanner, "ace/coworker/atoms/resume_planner"
      autoload :ResumeBriefFormatter, "ace/coworker/atoms/resume_brief_formatter"
      autoload :PrepareDecision, "ace/coworker/atoms/prepare_decision"
      autoload :ActiveExecutorRule, "ace/coworker/atoms/active_executor_rule"
      autoload :RolePresetSchema, "ace/coworker/atoms/role_preset_schema"
      autoload :PromptTemplate, "ace/coworker/atoms/prompt_template"
      autoload :RoundRule, "ace/coworker/atoms/round_rule"
      autoload :RoundRecordSchema, "ace/coworker/atoms/round_record_schema"
      autoload :IntegrationGate, "ace/coworker/atoms/integration_gate"
    end

    module Molecules
      autoload :ProjectRoot, "ace/coworker/molecules/project_root"
      autoload :ConfigLoader, "ace/coworker/molecules/config_loader"
      autoload :TaskProbe, "ace/coworker/molecules/task_probe"
      autoload :AssignmentMetadata, "ace/coworker/molecules/assignment_metadata"
      autoload :AssignmentProbe, "ace/coworker/molecules/assignment_probe"
      autoload :InstructionResolver, "ace/coworker/molecules/instruction_resolver"
      autoload :StepEvidenceReader, "ace/coworker/molecules/step_evidence_reader"
      autoload :HitlReporter, "ace/coworker/molecules/hitl_reporter"
      autoload :TaskRecordWriter, "ace/coworker/molecules/task_record_writer"
      autoload :ReportStateStore, "ace/coworker/molecules/report_state_store"
      autoload :StepReportReader, "ace/coworker/molecules/step_report_reader"
      autoload :GitStateProbe, "ace/coworker/molecules/git_state_probe"
      autoload :WorktreeProvisionProbe, "ace/coworker/molecules/worktree_provision_probe"
      autoload :WorktreeExecutorProbe, "ace/coworker/molecules/worktree_executor_probe"
      autoload :RolePresetLoader, "ace/coworker/molecules/role_preset_loader"
      autoload :ReviewRoundStore, "ace/coworker/molecules/review_round_store"
    end

    module Organisms
      autoload :StartOrchestrator, "ace/coworker/organisms/start_orchestrator"
      autoload :StatusOrchestrator, "ace/coworker/organisms/status_orchestrator"
      autoload :ReportOrchestrator, "ace/coworker/organisms/report_orchestrator"
      autoload :ResumeOrchestrator, "ace/coworker/organisms/resume_orchestrator"
      autoload :PrepareOrchestrator, "ace/coworker/organisms/prepare_orchestrator"
      autoload :CommissionOrchestrator, "ace/coworker/organisms/commission_orchestrator"
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
