# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "resolve_command"

module Ace
  module Nav
    module Commands
      # dry-cli Command class for the resolve command
      #
      # This wraps the existing ResolveCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Resolve < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Resolve resource path or content

          SYNTAX:
            ace-nav [URI] [OPTIONS]
            ace-nav resolve [URI] [OPTIONS]

          Automatically detects list mode for wildcards, patterns ending with /,
          and protocol-only URIs (e.g., wfi://, tmpl://).

          Magic Wildcard Routing:
            Wildcard patterns are auto-routed to 'list' command:
              ace-nav wfi://*              → ace-nav list wfi://*
              ace-nav tmpl://@ace-*/*     → ace-nav list tmpl://@ace-*/*
              ace-nav wfi://              → ace-nav list wfi:// (protocol-only)
            Recognized patterns: *, ?, trailing /, protocol-only

          EXAMPLES:

            # Resolve URI to path
            $ ace-nav wfi://setup

            # Display content
            $ ace-nav wfi://setup --content

            # Wildcard patterns auto-route to list
            $ ace-nav wfi://*

            # Protocol-only URIs auto-route to list
            $ ace-nav tmpl:///

          CONFIGURATION:

            Global config:  ~/.ace/nav/config.yml
            Project config: .ace/nav/config.yml
            Example:        ace-nav/.ace-defaults/nav/config.yml

            Sources configured via nav.sources in config

          OUTPUT:

            By default, displays resolved path
            Use --content to display resource content
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "wfi://setup                # Resolve workflow",
          "wfi://*                    # List workflows (auto-routing)",
          "tmpl://custom ./output.md  # Create from template",
          "wfi://setup --content      # Display resource content"
        ]

        argument :uri, required: true, desc: "Resource URI to resolve"

        option :path, type: :boolean, desc: "Display resource path"
        option :content, type: :boolean, desc: "Display resource content"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show detailed information"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(uri:, **options)
          # Handle magic patterns (wildcards → list)
          if magic_wildcard_pattern?(uri)
            # Delegate to list command
            require_relative "list"
            list_cmd = List.new
            return list_cmd.call(pattern: uri, **options)
          end

          # Use the existing ResolveCommand logic
          command = ResolveCommand.new(uri, options)
          command.execute
        end

        private

        # Check if URI pattern should trigger list mode
        def magic_wildcard_pattern?(uri)
          return true if uri.include?("*") || uri.include?("?")
          return true if uri.match?(%r{/$})
          return true if uri.match?(/^\w+:\/\/$/)
          false
        end
      end
    end
  end
end
