# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/navigation_engine"

module Ace
  module Support
    module Nav
      module CLI
        module Commands
          # ace-support-cli Command class for the create command
          class Create < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc <<~DESC.strip
              Create resource from template

              SYNTAX:
                ace-nav create [URI] [TARGET] [OPTIONS]

              EXAMPLES:

                # Create from workflow template
                $ ace-nav create wfi://my-workflow

                # Create from template to specific file
                $ ace-nav create tmpl://custom ./output.md

              CONFIGURATION:

                Global config:  ~/.ace/nav/config.yml
                Project config: .ace/nav/config.yml
                Example:        ace-support-nav/.ace-defaults/nav/config.yml

              OUTPUT:

                Creates resource at specified path or default location
                Exit codes: 0 (success), 1 (error)
            DESC

            example [
              "wfi://my-workflow           # Create from workflow template",
              "tmpl://custom ./output.md   # Create from template to file"
            ]

            argument :uri, required: true, desc: "Template URI"
            argument :target, required: false, desc: "Target file path"

            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(uri:, target: nil, **options)
              # Initialize instance variables for use in private methods
              @uri = uri
              @target = target
              @options = options
              @engine = Organisms::NavigationEngine.new

              execute
            end

            def execute
              display_config_summary

              result = @engine.create(@uri, @target)

              if result[:error]
                raise Ace::Support::Cli::Error.new(result[:error])
              end

              puts "Created: #{result[:created]}"
              puts "From: #{result[:from]}" if @options[:verbose]
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
              # Use Ace::Support::Nav.config which already handles the cascade
              require_relative "../../../nav"
              Ace::Support::Nav.config
            end

            def default_config
              # Use centralized gem_root from Nav module (avoids path depth duplication)
              defaults_path = File.join(Ace::Support::Nav.gem_root, ".ace-defaults", "nav", "config.yml")

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
  end
end
