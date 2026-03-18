# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/navigation_engine"

module Ace
  module Support
    module Nav
      module CLI
        module Commands
          # ace-support-cli Command class for the list command
          class List < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc <<~DESC.strip
              List matching resources

              SYNTAX:
                ace-nav list [PATTERN] [OPTIONS]

              EXAMPLES:

                # List all workflows
                $ ace-nav list 'wfi://*'

                # List templates with pattern
                $ ace-nav list 'tmpl://@ace-*/*'

                # Tree format
                $ ace-nav list wfi:// --tree

              CONFIGURATION:

                Global config:  ~/.ace/nav/config.yml
                Project config: .ace/nav/config.yml
                Example:        ace-support-nav/.ace-defaults/nav/config.yml

              OUTPUT:

                Table format with columns: URI, path, type
                Use --tree for hierarchical format
                Exit codes: 0 (success), 1 (error)
            DESC

            example [
              "'wfi://*'                 # List all workflows",
              "'tmpl://@ace-*/*'         # List templates with pattern",
              "wfi:// --tree             # Tree format"
            ]

            argument :pattern, required: true, desc: "Pattern to match resources"

            option :tree, type: :boolean, desc: "Display resources in tree format"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(pattern:, **options)
              # Initialize instance variables for use in private methods
              @pattern = pattern
              @options = options
              @engine = Organisms::NavigationEngine.new

              execute
            end

            def execute
              display_config_summary

              resources = @engine.list(@pattern, tree: @options[:tree], verbose: @options[:verbose])

              if resources.empty?
                raise Ace::Support::Cli::Error.new("No resources found matching: #{@pattern}")
              end

              if @options[:verbose]
                require "json"
                puts JSON.pretty_generate(resources)
              else
                resources.each { |resource| puts resource }
              end
            end

            private

            def display_config_summary
              return if @options[:quiet]

              require "ace/core"
              Ace::Core::Atoms::ConfigSummary.display(
                command: "list",
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
