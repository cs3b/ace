# frozen_string_literal: true

require_relative "../organisms/navigation_engine"

module Ace
  module Nav
    module Commands
      class CreateCommand
        def initialize(uri, target, options = {})
          @uri = uri
          @target = target
          @options = options
          @engine = Organisms::NavigationEngine.new
        end

        def execute
          display_config_summary

          result = @engine.create(@uri, @target)

          if result[:error]
            puts "Error: #{result[:error]}"
            return 1
          else
            puts "Created: #{result[:created]}"
            puts "From: #{result[:from]}" if @options[:verbose]
            return 0
          end
        end

        private

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "create",
            config: load_effective_config,
            defaults: default_config,
            options: @options,
            quiet: false
          )
        end

        def load_effective_config
          # Use Ace::Nav.config which already handles the cascade
          require_relative "../../nav"
          Ace::Nav.config
        end

        def default_config
          gem_root = Gem.loaded_specs["ace-nav"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)
          defaults_path = File.join(gem_root, ".ace-defaults", "nav", "config.yml")

          if File.exist?(defaults_path)
            require "yaml"
            YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
          else
            {}
          end
        end
      end
    end
  end
end
