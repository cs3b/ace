# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../organisms/navigation_engine"

module Ace
  module Nav
    module Commands
      # dry-cli Command class for the sources command
      class Sources < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Show available sources

          Show all available sources for resources.

          EXAMPLES:

            # Show all sources
            $ ace-nav sources

            # Verbose JSON output
            $ ace-nav sources --verbose

            # Backward compat: using --sources flag
            $ ace-nav --sources

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
          "--verbose                 # Show detailed information (JSON)",
          "                          # Backward compat: --sources flag"
        ]

        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show detailed information (JSON)"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

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
