# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/navigation_engine"

module Ace
  module Support
    module Nav
      module CLI
        module Commands
          # ace-support-cli Command class for the sources command
          class Sources < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base

            desc <<~DESC.strip
              Show available sources

              Show all available sources for resources.

              EXAMPLES:

                # Show all sources
                $ ace-nav sources

                # Verbose JSON output
                $ ace-nav sources --verbose

              CONFIGURATION:

                Sources configured in: .ace/nav/config.yml
                Global config:  ~/.ace/nav/config.yml
                Project config: .ace/nav/config.yml

              OUTPUT:

                Table format with source details
                Use --verbose for JSON output
                Exit codes: 0 (success), 1 (error)
            DESC

            example [
              "                          # Show all sources",
              "--verbose                 # Show detailed information (JSON)"
            ]

            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(**options)
              # Initialize instance variables for use in private methods
              @options = options
              @engine = Organisms::NavigationEngine.new

              execute
            end

            def execute
              display_config_summary

              sources = @engine.sources(verbose: @options[:verbose])

              if @options[:verbose]
                require "json"
                puts JSON.pretty_generate(sources)
              else
                puts "Available sources:"
                sources.each { |source| puts "  #{source}" }
              end

              0
            end

            private

            def display_config_summary
              return if @options[:quiet]

              require "ace/core"
              Ace::Core::Atoms::ConfigSummary.display(
                command: "sources",
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
