# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../molecules/config_loader"
require_relative "../../organisms/navigation_engine"
require_relative "../../organisms/command_delegator"

module Ace
  module Support
    module Nav
      module CLI
        module Commands
          # ace-support-cli Command class for the resolve command
          class Resolve < Ace::Support::Cli::Command
            include Ace::Core::CLI::Base

            desc <<~DESC.strip
              Resolve resource path or content

              SYNTAX:
                ace-nav resolve [URI] [OPTIONS]

              Automatically detects list mode for wildcards, patterns ending with /,
              and protocol-only URIs (e.g., wfi://, tmpl://).

              Magic Wildcard Routing:
                Wildcard patterns are auto-routed to 'list' command:
                  ace-nav resolve wfi://*              → ace-nav list wfi://*
                  ace-nav resolve tmpl://@ace-*/*     → ace-nav list tmpl://@ace-*
                  ace-nav resolve wfi://              → ace-nav list wfi:// (protocol-only)
                Recognized patterns: *, ?, trailing /, protocol-only

              EXAMPLES:

                # Resolve URI to path
                $ ace-nav resolve wfi://setup

                # Display content
                $ ace-nav resolve wfi://setup --content

                # Wildcard patterns auto-route to list
                $ ace-nav resolve wfi://*

                # Protocol-only URIs auto-route to list
                $ ace-nav resolve tmpl:///

              CONFIGURATION:

                Global config:  ~/.ace/nav/config.yml
                Project config: .ace/nav/config.yml
                Example:        ace-support-nav/.ace-defaults/nav/config.yml

                Sources configured via nav.sources in config

              OUTPUT:

                By default, displays resolved path
                Use --content to display resource content
                Exit codes: 0 (success), 1 (error)
            DESC

            example [
              "wfi://setup                # Resolve workflow",
              "wfi://*                    # List workflows (auto-routing)",
              "tmpl://                    # List templates (auto-routing)",
              "wfi://setup --content      # Display resource content"
            ]

            argument :uri, required: true, desc: "Resource URI to resolve"

            option :path, type: :boolean, desc: "Display resource path"
            option :content, type: :boolean, desc: "Display resource content"
            option :tree, type: :boolean, desc: "Display resources in tree format (passed through to cmd protocols)"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(uri:, **options)
              # Normalize bare protocol names to protocol:// format for listing
              uri = normalize_protocol_shorthand(uri)

              # Handle magic patterns (wildcards → list)
              if magic_wildcard_pattern?(uri)
                # Delegate to list command
                require_relative "list"
                list_cmd = List.new
                return list_cmd.call(pattern: uri, **options)
              end

              # Initialize instance variables for use in private methods
              @uri = uri
              @options = options
              @engine = Organisms::NavigationEngine.new

              execute
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
                raise Ace::Core::CLI::Error.new("Resource not found: #{@uri}")
              end

              if @options[:verbose] && result.is_a?(Hash)
                require "json"
                puts JSON.pretty_generate(result)
              elsif @options[:path]
                # Show path only
                puts result.is_a?(Hash) ? result[:path] || result : result
              else
                puts result
              end
            end

            private

            # Normalize bare protocol names (e.g., "wfi") to protocol:// format
            # This allows users to type "ace-nav wfi" instead of "ace-nav wfi://"
            def normalize_protocol_shorthand(uri)
              return uri if uri.include?("://")

              # Check if input is a known protocol name
              config_loader = Molecules::ConfigLoader.new
              if config_loader.valid_protocol?(uri)
                "#{uri}://"
              else
                uri
              end
            end

            # Check if URI pattern should trigger list mode
            def magic_wildcard_pattern?(uri)
              return true if uri.include?("*") || uri.include?("?")
              return true if uri.match?(%r{/$})
              return true if uri.match?(/^\w+:\/\/$/)
              false
            end

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
