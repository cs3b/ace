# frozen_string_literal: true

require "ace/support/cli"
require_relative "shared_helpers"
require_relative "../../commands/config_command"

module Ace
  module Git
    module Worktree
      module CLI
        module Commands
          class Config < Ace::Support::Cli::Command
            include SharedHelpers

            desc "Show and manage worktree configuration"

            example [
              "                # Show current configuration",
              "--show          # Show current configuration",
              "--validate      # Validate configuration",
              "--files         # Show config file locations"
            ]

            # Accept extra positional arguments for backward compatibility
            # (e.g., "show", "validate" as positional args instead of flags)
            argument :subcommand, required: false, desc: "Subcommand (init, set-bootstrap, show, validate, files)"

            option :show, desc: "Show current configuration", type: :boolean, aliases: []
            option :validate, desc: "Validate configuration", type: :boolean, aliases: []
            option :files, desc: "Show configuration file locations", type: :boolean, aliases: []
            option :json, desc: "Format output as JSON", type: :boolean, aliases: []
            option :bootstrap, desc: "Validate bootstrap policy", type: :boolean, aliases: []
            option :command, desc: "Bootstrap command to execute", type: :string, aliases: []
            option :working_dir, desc: "Working directory for bootstrap command", type: :string, aliases: []
            option :timeout, desc: "Timeout in seconds for bootstrap command", type: :string, aliases: []
            option :required, desc: "Require bootstrap execution to succeed", type: :boolean, aliases: []
            option :advisory, desc: "Allow worktree creation when bootstrap fails", type: :boolean, aliases: []
            option :env, desc: "Environment variables KEY=VALUE", type: :array, aliases: []
            option :verbose, desc: "Show verbose output", type: :boolean, aliases: ["-v"]
            option :quiet, type: :boolean, aliases: ["-q"], desc: "Suppress non-essential output"
            option :debug, type: :boolean, aliases: ["-d"], desc: "Show debug output"

            def call(subcommand: nil, **options)
              display_config_summary("config", options)

              args = []
              args << subcommand if subcommand
              args << "init" if options[:init]
              args << "set-bootstrap" if options[:set_bootstrap]
              args << "--show" if options[:show]
              args << "--validate" if options[:validate]
              args << "--files" if options[:files]
              args << "--json" if options[:json]
              args << "--bootstrap" if options[:bootstrap]
              args << "--command" << options[:command] if options[:command]
              args << "--working-dir" << options[:working_dir] if options[:working_dir]
              args << "--timeout" << options[:timeout].to_s if options[:timeout]
              args << "--required" if options[:required]
              args << "--advisory" if options[:advisory]
              if options[:env]
                Array(options[:env]).each do |e|
                  args << "--env" << e
                end
              end

              Ace::Git::Worktree::Commands::ConfigCommand.new.run(args)
            end
          end
        end
      end
    end
  end
end
