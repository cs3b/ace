# frozen_string_literal: true

require_relative "../organisms/navigation_engine"
require_relative "../organisms/command_delegator"

module Ace
  module Nav
    module Commands
      class ResolveCommand
        def initialize(uri, options = {})
          @uri = uri
          @options = options
          @engine = Organisms::NavigationEngine.new
        end

        def execute
          display_config_summary

          # Check for cmd:// protocol delegation
          if @uri.include?("://")
            protocol = @uri.split("://").first
            if @engine.cmd_protocol?(protocol)
              delegator = Organisms::CommandDelegator.new
              return delegator.delegate(@uri, @options)
            end
          end

          result = @engine.resolve(@uri, content: @options[:content], verbose: @options[:verbose])

          if result.nil?
            puts "Resource not found: #{@uri}"
            return 1
          elsif @options[:verbose] && result.is_a?(Hash)
            require "json"
            puts JSON.pretty_generate(result)
          elsif @options[:path]
            # Show path only
            puts result.is_a?(Hash) ? result[:path] || result : result
          else
            puts result
          end

          0
        end

        private

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "resolve",
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
