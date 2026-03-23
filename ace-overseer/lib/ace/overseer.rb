# frozen_string_literal: true

require "yaml"
require "ace/support/config"
require "ace/assign"
require "ace/git"
require "ace/git/worktree"
require "ace/task"
require "ace/tmux"

require_relative "overseer/version"
require_relative "overseer/models/work_context"
require_relative "overseer/models/prune_candidate"
require_relative "overseer/models/assignment_prune_candidate"
require_relative "overseer/atoms/preset_resolver"
require_relative "overseer/atoms/status_formatter"
require_relative "overseer/molecules/worktree_provisioner"
require_relative "overseer/molecules/tmux_window_opener"
require_relative "overseer/molecules/assignment_launcher"
require_relative "overseer/molecules/worktree_context_collector"
require_relative "overseer/molecules/prune_safety_checker"
require_relative "overseer/molecules/assignment_prune_safety_checker"
require_relative "overseer/organisms/work_on_orchestrator"
require_relative "overseer/organisms/status_collector"
require_relative "overseer/organisms/prune_orchestrator"
require_relative "overseer/cli"

module Ace
  module Overseer
    class Error < StandardError; end

    @config_mutex = Mutex.new
    @gem_root_mutex = Mutex.new

    def self.gem_root
      return @gem_root if defined?(@gem_root) && @gem_root

      @gem_root_mutex.synchronize do
        @gem_root ||= Gem.loaded_specs["ace-overseer"]&.gem_dir || File.expand_path("../..", __dir__)
      end
    end

    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    def self.config
      return @config if defined?(@config) && @config

      @config_mutex.synchronize do
        @config ||= load_config
      end
    end

    def self.reset_config!
      @config_mutex.synchronize do
        @config = nil
      end
    end

    def self.load_config
      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      config = resolver.resolve_namespace("overseer")
      config.data
    rescue => e
      warn "ace-overseer: Could not load config: #{e.class} - #{e.message}" if debug?
      load_gem_defaults_fallback
    end
    private_class_method :load_config

    def self.load_gem_defaults_fallback
      defaults_path = File.join(gem_root, ".ace-defaults", "overseer", "config.yml")
      return {} unless File.exist?(defaults_path)

      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end
