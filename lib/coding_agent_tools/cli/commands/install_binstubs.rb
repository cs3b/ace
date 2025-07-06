# frozen_string_literal: true

require "dry/cli"
require "fileutils"
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
        option :setup_path, type: :boolean, default: false, desc: "Generate shell PATH setup scripts"

        example [
          "                                # Install all binstubs in current directory",
          "--config config/custom.yml     # Use custom configuration file",
          "--alias tn                     # Install only the 'tn' binstub",
          "--force                        # Overwrite existing files",
          "--verbose                      # Show detailed output",
          "--list                         # List available binstub aliases",
          "--setup-path                   # Generate shell PATH setup scripts"
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
          elsif options[:setup_path]
            setup_path_scripts(target_directory, options)
          elsif options[:alias]
            install_specific_alias(installer, options[:alias], options)
          else
            install_all_aliases(installer, options)
            
            # Optionally suggest PATH setup after installing binstubs
            suggest_path_setup(target_directory, options) unless options[:alias]
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

        def setup_path_scripts(target_directory, options)
          puts "Setting up PATH scripts..." if options[:verbose]
          
          # Copy PATH setup scripts from config to target directory
          config_source_dir = File.expand_path("../../../../config/bin-setup-env", __dir__)
          target_setup_dir = File.join(target_directory, "bin-setup-env")
          
          unless File.directory?(config_source_dir)
            puts "Error: PATH setup templates not found at #{config_source_dir}"
            exit 1
          end
          
          # Create target directory
          FileUtils.mkdir_p(target_setup_dir)
          
          # Copy all setup files
          setup_files = %w[setup.sh setup.fish setup-env]
          copied_files = []
          
          setup_files.each do |file|
            source_file = File.join(config_source_dir, file)
            target_file = File.join(target_setup_dir, file)
            
            if File.exist?(source_file)
              if !File.exist?(target_file) || options[:force]
                FileUtils.cp(source_file, target_file)
                FileUtils.chmod(0755, target_file) if file == "setup-env"
                copied_files << file
                puts "  ✓ #{file}" if options[:verbose]
              else
                puts "  - #{file} (already exists)" if options[:verbose]
              end
            end
          end
          
          if copied_files.any?
            puts "Successfully created PATH setup scripts in: #{target_setup_dir}"
            puts ""
            puts "To add tools to your PATH, run:"
            puts "  source #{target_setup_dir}/setup-env"
            puts ""
            puts "Or for your specific shell:"
            puts "  # Bash/Zsh: source #{target_setup_dir}/setup.sh"
            puts "  # Fish:     source #{target_setup_dir}/setup.fish"
          else
            puts "PATH setup scripts already exist in: #{target_setup_dir}"
            puts "Use --force to overwrite them."
          end
        end

        def suggest_path_setup(target_directory, options)
          return if options[:verbose] # Don't show suggestions in verbose mode
          
          puts ""
          puts "💡 Tip: To add tools to your PATH, run:"
          puts "   coding_agent_tools install-binstubs --setup-path"
        end
      end
    end
  end
end