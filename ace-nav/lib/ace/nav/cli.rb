# frozen_string_literal: true

require "ace/core/cli/base"
require "fileutils"
require_relative "organisms/navigation_engine"
require_relative "organisms/command_delegator"

module Ace
  module Nav
    class CLI < Ace::Core::CLI::Base
      default_task :resolve

      # Override help to add wildcard routing section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Magic Wildcard Routing:"
        shell.say "  Wildcard patterns are auto-routed to 'list' command - no need to type 'list':"
        shell.say "    ace-nav wfi://*              → ace-nav list wfi://*"
        shell.say "    ace-nav tmpl://@ace-*/*     → ace-nav list tmpl://@ace-*/*"
        shell.say "    ace-nav wfi://              → ace-nav list wfi:// (protocol-only)"
        shell.say "  Recognized patterns: *, ?, trailing /, protocol-only"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-nav wfi://setup                # Resolve workflow"
        shell.say "  ace-nav wfi://*                    # List workflows (auto-routing)"
        shell.say "  ace-nav tmpl://custom ./output.md  # Create from template"
      end

      desc "resolve URI", "Resolve resource path or content"
      long_desc <<~DESC
        Resolve a resource URI to its path or content.

        SYNTAX:
          ace-nav [URI] [OPTIONS]
          ace-nav resolve [URI] [OPTIONS]

        Automatically detects list mode for wildcards, patterns ending with /,
        and protocol-only URIs (e.g., wfi://, tmpl://).

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
      option :path, type: :boolean, desc: "Display resource path"
      option :content, type: :boolean, desc: "Display resource content"
      option :verbose, type: :boolean, aliases: "-v", desc: "Show detailed information"
      option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
      def resolve(uri)
        # Handle --help/-h passed as URI argument
        if uri == "--help" || uri == "-h"
          invoke :help, ["resolve"]
          return 0
        end

        # Handle magic patterns (wildcards → list)
        if magic_wildcard_pattern?(uri)
          invoke :list, [uri]
          return
        end

        require_relative "commands/resolve_command"
        Commands::ResolveCommand.new(uri, options).execute
      end

      desc "list PATTERN", "List matching resources"
      long_desc <<~DESC
        List all resources matching the given pattern.

        SYNTAX:
          ace-nav list [PATTERN] [OPTIONS]

        EXAMPLES:

          # List all workflows
          $ ace-nav list 'wfi://*'

          # List templates with pattern
          $ ace-nav list 'tmpl://@ace-*/*'

          # Tree format
          $ ace-nav list wfi:// --tree

          # Can also use wildcard directly (auto-routed)
          $ ace-nav wfi://*

        CONFIGURATION:

          Global config:  ~/.ace/nav/config.yml
          Project config: .ace/nav/config.yml
          Example:        ace-nav/.ace-defaults/nav/config.yml

        OUTPUT:

          Table format with columns: URI, path, type
          Use --tree for hierarchical format
          Exit codes: 0 (success), 1 (error)
      DESC
      option :tree, type: :boolean, desc: "Display resources in tree format"
      option :verbose, type: :boolean, aliases: "-v", desc: "Show detailed information"
      option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
      def list(pattern)
        require_relative "commands/list_command"
        Commands::ListCommand.new(pattern, options).execute
      end

      desc "create URI [TARGET]", "Create resource from template"
      long_desc <<~DESC
        Create a new resource from a template.

        SYNTAX:
          ace-nav create [URI] [TARGET] [OPTIONS]

        EXAMPLES:

          # Create from workflow template
          $ ace-nav create wfi://my-workflow

          # Create from template to specific file
          $ ace-nav create tmpl://custom ./output.md

          # Backward compat: using --create flag
          $ ace-nav --create wfi://my-workflow

        CONFIGURATION:

          Global config:  ~/.ace/nav/config.yml
          Project config: .ace/nav/config.yml
          Example:        ace-nav/.ace-defaults/nav/config.yml

        OUTPUT:

          Creates resource at specified path or default location
          Exit codes: 0 (success), 1 (error)
      DESC
      option :verbose, type: :boolean, aliases: "-v", desc: "Show detailed information"
      option :quiet, type: :boolean, aliases: "-q", desc: "Suppress config summary"
      def create(uri, target = nil)
        require_relative "commands/create_command"
        Commands::CreateCommand.new(uri, target, options).execute
      end

      desc "sources", "Show available sources"
      long_desc <<~DESC
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
      option :verbose, type: :boolean, aliases: "-v", desc: "Show detailed information (JSON)"
      def sources
        require_relative "commands/sources_command"
        Commands::SourcesCommand.new(options).execute
      end

      # Backward compatibility: --sources flag still works
      map "--sources" => :sources

      # Backward compatibility for --create URI flag
      desc "create_from_flag URI", "Create resource (backward compat)", hide: true
      def create_from_flag(uri = nil)
        if uri && uri != "" && uri != "--sources"
          invoke :create, [uri]
        else
          puts "Usage: ace-nav create URI [TARGET]"
          puts "       ace-nav --create URI"
        end
      end
      map "--create" => :create_from_flag

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-nav.

        EXAMPLES:

          $ ace-nav version
          $ ace-nav --version
      DESC
      def version
        puts "ace-nav #{VERSION}"
        0
      end
      map "--version" => :version

      no_commands do
        # Check if URI pattern should trigger list mode
        def magic_wildcard_pattern?(uri)
          return true if uri.include?("*") || uri.include?("?")
          return true if uri.match?(/\/$/)
          return true if uri.match?(/^\w+:\/\/$/)
          false
        end
      end

      # Handle unknown commands as arguments to the default 'resolve' command
      # This allows: ace-nav wfi://update-pr-description without requiring 'resolve'
      def method_missing(command, *args)
        invoke :resolve, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end
