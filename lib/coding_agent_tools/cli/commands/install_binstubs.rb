# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/binstub_installer"

module CodingAgentTools
  module Cli
    module Commands
      # InstallBinstubs - CLI command for installing shell binstubs
      #
      # Generates and installs shell binstubs based on configuration.
      # Supports installing all binstubs or specific ones by name.
      class InstallBinstubs < Dry::CLI::Command
        desc "Install shell binstubs from configuration"

        argument :target_dir, type: :string, required: false, desc: "Target directory for binstubs (default: current directory)"
        option :config, type: :string, desc: "Path to binstub configuration file"
        option :alias, type: :string, desc: "Install specific alias only"
        option :force, type: :boolean, default: false, desc: "Overwrite existing files without confirmation"
        option :verbose, type: :boolean, default: false, desc: "Verbose output"
        option :list, type: :boolean, default: false, desc: "List available aliases"

        example [
          "                                # Install all binstubs in current directory",
          "--config config/custom.yml     # Use custom configuration file",
          "--alias tn                     # Install only the 'tn' binstub",
          "--force                        # Overwrite existing files",
          "--verbose                      # Show detailed output",
          "--list                         # List available binstub aliases"
        ]

        def call(target_dir: nil, **options)
          target_directory = target_dir || Dir.pwd
          config_path = options[:config] || default_config_path
          
          unless File.exist?(config_path)
            puts "Error: Configuration file not found: #{config_path}"
            puts "Use --config to specify a different configuration file."
            exit 1
          end

          installer = CodingAgentTools::Organisms::BinstubInstaller.new(
            config_path,
            target_directory
          )

          if options[:list]
            list_aliases(installer)
          elsif options[:alias]
            install_specific_alias(installer, options[:alias], options)
          else
            install_all_aliases(installer, options)
          end
        rescue CodingAgentTools::Error => e
          puts "Error: #{e.message}"
          exit 1
        rescue => e
          puts "Unexpected error: #{e.message}"
          puts e.backtrace if options[:verbose]
          exit 1
        end

        private

        def default_config_path
          File.expand_path("../../../../config/binstub-aliases.yml", __dir__)
        end

        def list_aliases(installer)
          aliases = installer.list_available_aliases
          if aliases.empty?
            puts "No binstub aliases found in configuration."
          else
            puts "Available binstub aliases:"
            aliases.each { |alias_name| puts "  #{alias_name}" }
          end
        end

        def install_specific_alias(installer, alias_name, options)
          if installer.install_specific(alias_name, options)
            puts "Successfully installed binstub: #{alias_name}"
          else
            puts "Binstub installation skipped: #{alias_name}"
          end
        end

        def install_all_aliases(installer, options)
          puts "Installing binstubs..." if options[:verbose]
          
          results = installer.install_all(options)

          # Report results
          if results[:installed].any?
            puts "Successfully installed binstubs:"
            results[:installed].each { |name| puts "  ✓ #{name}" }
          end

          if results[:skipped].any?
            puts "Skipped existing binstubs:"
            results[:skipped].each { |name| puts "  - #{name}" }
          end

          if results[:errors].any?
            puts "Errors occurred:"
            results[:errors].each { |error| puts "  ✗ #{error[:alias]}: #{error[:error]}" }
            exit 1
          end

          total = results[:installed].size + results[:skipped].size
          puts "\nInstallation complete: #{results[:installed].size}/#{total} binstubs installed."
        end
      end
    end
  end
end