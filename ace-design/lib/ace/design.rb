# frozen_string_literal: true
require "json"
require "yaml"
require "date"
require "ace/support/config"
require "ace/support/cli"
require "ace/b36ts"
require_relative "design/version"
module Ace
  module Design
    class Error < StandardError; end
    def self.gem_root
      File.expand_path("../..", __dir__)
    end
    def self.config
      defaults = YAML.safe_load_file(File.join(gem_root, ".ace-defaults/design/config.yml"))
      overrides = Ace::Support::Config.create(gem_path: gem_root).resolve_namespace("design").to_h
      Ace::Support::Config::Models::Config.wrap(defaults, overrides).fetch("design")
    end
  end
end
require_relative "design/atoms/contracts"
require_relative "design/molecules/preset"
require_relative "design/molecules/artifacts"
require_relative "design/molecules/agent_executor"
require_relative "design/molecules/context_document"
require_relative "design/molecules/context_repository"
require_relative "design/molecules/design_context"
require_relative "design/molecules/adjust_prompts"
require_relative "design/organisms/adjuster"
require_relative "design/molecules/design_source"
require_relative "design/molecules/skill_sources"
require_relative "design/molecules/design_prompts"
require_relative "design/molecules/session"
require_relative "design/organisms/design_run"
require_relative "design/organisms/generator"
require_relative "design/molecules/catalog"
require_relative "design/molecules/runtime"
require_relative "design/organisms/inspector"
require_relative "design/cli"
