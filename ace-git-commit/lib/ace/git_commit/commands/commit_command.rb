# frozen_string_literal: true

module Ace
  module GitCommit
    module Commands
      class CommitCommand
        def initialize(files, options = {})
          @files = files
          @options = options
        end

        def execute
          display_config_summary

          orchestrator = Organisms::CommitOrchestrator.new
          success = orchestrator.execute(commit_options)

          success ? 0 : 1
        rescue GitError => e
          $stderr.puts "Error: #{e.message}"
          1
        rescue Interrupt
          $stderr.puts "\nCommit cancelled"
          130
        end

        private

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          Ace::Core::Atoms::ConfigSummary.display(
            command: "commit",
            config: load_effective_config,
            defaults: default_config,
            options: @options,
            quiet: false  # Don't suppress ConfigSummary itself
          )
        end

        def commit_options
          options = Models::CommitOptions.new(
            intention: @options[:intention],
            message: @options[:message],
            model: @options[:model],
            files: @files,
            only_staged: @options[:only_staged] || false,
            dry_run: @options[:dry_run] || false,
            debug: @options[:debug] || false,
            force: @options[:force] || false,
            verbose: @options[:verbose] != false,  # Default true
            quiet: @options[:quiet] || false
          )
        end

        def load_effective_config
          gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)

          resolver = Ace::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          config = resolver.resolve_namespace("git", filename: "commit")
          config.data["git"] || config.data
        end

        def default_config
          gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
                     File.expand_path("../../../../../..", __dir__)

          defaults_path = File.join(gem_root, ".ace-defaults", "git", "commit.yml")

          if File.exist?(defaults_path)
            require "yaml"
            YAML.safe_load_file(defaults_path, permitted_classes: [Symbol], aliases: true) || {}
          else
            {}
          end
        end
      end
    end
  end
end
