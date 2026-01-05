# frozen_string_literal: true

require "ace/core/cli/base"
require_relative "commands/scan_command"
require_relative "commands/rewrite_command"
require_relative "commands/revoke_command"
require_relative "commands/check_release_command"
require_relative "version"

module Ace
  module Git
    module Secrets
      # CLI interface using Thor
      # Commands return exit codes; exe/ace-git-secrets handles exit()
      #
      # Requires gitleaks to be installed: brew install gitleaks
      class CLI < Ace::Core::CLI::Base
        # class_options :quiet, :verbose, :debug inherited from Base

        # Load config early before any command runs to ensure thread safety.
        # This preloading is CRITICAL for thread safety. The config method uses
        # mutex synchronization, but has a potential TOCTOU (time-of-check-to-time-of-use)
        # issue if config is first accessed during parallel operations. By loading
        # config here before Thor dispatches commands, we guarantee config is fully
        # initialized before any threads are spawned.
        def self.start(args = ARGV, config = {})
          # Preload config before Thor dispatches to commands
          Ace::Git::Secrets.config
          super
        end

        desc "scan", "Scan Git history for authentication tokens"
        method_option :since, type: :string, desc: "Start scanning from commit or date"
        method_option :format, type: :string, aliases: "-f", default: "table",
                      desc: "Stdout format when --verbose is used (table, json, yaml)"
        method_option :report_format, type: :string, aliases: "-r", default: "json",
                      desc: "Format for saved report file (json, markdown)"
        method_option :confidence, type: :string, aliases: "-c", default: "low",
                      desc: "Minimum confidence (high, medium, low)"
        method_option :verbose, type: :boolean,
                      desc: "Enable verbose output with full report to stdout"
        method_option :quiet, type: :boolean, aliases: "-q",
                      desc: "Suppress non-essential output (for CI)"
        def scan(first_arg = nil)
          # Handle --help/-h for subcommand
          if first_arg == "--help" || first_arg == "-h"
            invoke :help, ["scan"]
            return 0
          end
          Commands::ScanCommand.execute(options)
        end

        desc "rewrite-history", "Remove detected tokens from Git history"
        method_option :dry_run, type: :boolean, aliases: "-n",
                      desc: "Show what would be rewritten"
        method_option :backup, type: :boolean, default: true,
                      desc: "Create backup before rewrite"
        method_option :force, type: :boolean,
                      desc: "Skip confirmation prompt"
        method_option :scan_file, type: :string,
                      desc: "Use previous scan results file"
        def rewrite_history(first_arg = nil)
          # Handle --help/-h for subcommand
          if first_arg == "--help" || first_arg == "-h"
            invoke :help, ["rewrite-history"]
            return 0
          end
          Commands::RewriteCommand.execute(options)
        end

        desc "revoke", "Revoke detected tokens via provider APIs"
        method_option :service, type: :string, aliases: "-s",
                      desc: "Revoke for specific service"
        method_option :token, type: :string, aliases: "-t",
                      desc: "Revoke specific token"
        method_option :scan_file, type: :string,
                      desc: "Use previous scan results file"
        def revoke(first_arg = nil)
          # Handle --help/-h for subcommand
          if first_arg == "--help" || first_arg == "-h"
            invoke :help, ["revoke"]
            return 0
          end
          Commands::RevokeCommand.execute(options)
        end

        desc "check-release", "Pre-release security validation check"
        method_option :strict, type: :boolean,
                      desc: "Fail on medium confidence matches"
        method_option :format, type: :string, aliases: "-f", default: "table",
                      desc: "Output format (table, json)"
        def check_release(first_arg = nil)
          # Handle --help/-h for subcommand
          if first_arg == "--help" || first_arg == "-h"
            invoke :help, ["check-release"]
            return 0
          end
          Commands::CheckReleaseCommand.execute(options)
        end

        desc "version", "Show version"
        def version
          puts "ace-git-secrets version #{Ace::Git::Secrets::VERSION}"
          0
        end
        map "--version" => :version
      end
    end
  end
end
