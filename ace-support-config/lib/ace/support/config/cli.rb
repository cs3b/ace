# frozen_string_literal: true

require "optparse"
require_relative "organisms/config_initializer"
require_relative "organisms/config_diff"
require_relative "models/config_templates"

module Ace
  module Support
    module Config
      class CLI
        def self.start(argv)
          new.run(argv)
        end

        def run(argv)
          return show_help if argv.empty?

          command = argv.shift

          case command
          when "init"
            run_init(argv)
          when "diff"
            run_diff(argv)
          when "list"
            run_list(argv)
          when "version", "--version"
            show_version
          when "help", "--help", "-h"
            show_help
          else
            puts "Unknown command: #{command}"
            puts ""
            show_help
            exit 1
          end
        end

        private

        def run_init(argv)
          options = {}

          parser = OptionParser.new do |opts|
            opts.banner = <<~BANNER.chomp
              NAME
                ace-config init - Initialize configuration for ace-* gems

              USAGE
                ace-config init [GEM] [OPTIONS]

              OPTIONS
            BANNER
            opts.on("--force", "Overwrite existing files") { options[:force] = true }
            opts.on("--dry-run", "Show what would be done") { options[:dry_run] = true }
            opts.on("--global", "Use ~/.ace instead of ./.ace") { options[:global] = true }
            opts.on("--verbose", "Show verbose output") { options[:verbose] = true }
            opts.on("-h", "--help", "Show this help") do
              puts opts
              exit
            end
          end

          parser.parse!(argv)
          gem_name = argv.shift

          initializer = Organisms::ConfigInitializer.new(**options)

          if gem_name
            initializer.init_gem(gem_name)
          else
            initializer.init_all
          end
        end

        def run_diff(argv)
          options = {}

          parser = OptionParser.new do |opts|
            opts.banner = <<~BANNER.chomp
              NAME
                ace-config diff - Compare configs with examples

              USAGE
                ace-config diff [GEM] [OPTIONS]

              OPTIONS
            BANNER
            opts.on("--global", "Compare global configs") { options[:global] = true }
            opts.on("--local", "Compare local configs (default)") { options[:local] = true }
            opts.on("--file PATH", "Compare specific file") { |f| options[:file] = f }
            opts.on("--one-line", "One-line summary per file") { options[:one_line] = true }
            opts.on("--verbose", "Include unchanged files in one-line summary") { options[:verbose] = true }
            opts.on("-h", "--help", "Show this help") do
              puts opts
              exit
            end
          end

          parser.parse!(argv)
          gem_name = argv.shift

          differ = Organisms::ConfigDiff.new(**options)

          if gem_name
            differ.diff_gem(gem_name)
          else
            differ.run
          end
        end

        def run_list(argv)
          verbose = false

          parser = OptionParser.new do |opts|
            opts.banner = <<~BANNER.chomp
              NAME
                ace-config list - List available ace-* gems with example configs

              USAGE
                ace-config list [OPTIONS]

              OPTIONS
            BANNER
            opts.on("--verbose", "Show detailed information") { verbose = true }
            opts.on("-h", "--help", "Show this help") do
              puts opts
              exit
            end
          end

          parser.parse!(argv)

          puts "Available ace-* gems with example configurations:\n\n"

          if Models::ConfigTemplates.all_gems.empty?
            puts "No ace-* gems with example configurations found."
            return
          end

          Models::ConfigTemplates.all_gems.each do |gem_name|
            info = Models::ConfigTemplates.gem_info[gem_name]
            source_label = case info[:source]
            when :local then "[local]"
            when :gem then "[gem]"
            when :both then "[local+gem]"
            end

            puts "  #{gem_name} #{source_label}"

            next unless verbose

            puts "    Path: #{info[:path]}"
            puts "    Gem: #{info[:gem_path]}" if info[:gem_path]
            example_dir = Models::ConfigTemplates.example_dir_for(gem_name)
            if example_dir && File.exist?(example_dir)
              example_files = Dir.glob("#{example_dir}/**/*").reject { |f| File.directory?(f) }
              puts "    Example files: #{example_files.size}"
            end
          end

          puts "\nUse 'ace-config init [GEM]' to initialize a specific gem's configuration"
          puts "Use 'ace-config init' to initialize all configurations"
        end

        def show_version
          puts "ace-config #{Ace::Support::Config::VERSION}"
        end

        def show_help
          puts <<~HELP
            NAME
              ace-config - Configuration management for ace-* gems

            USAGE
              ace-config COMMAND [OPTIONS]

            COMMANDS
              init [GEM]                        Initialize configuration for specific gem or all
              diff [GEM]                        Compare configs with examples
              list                              List available ace-* gems with example configs
              version                           Show version
              help                              Show this help

            Run 'ace-config COMMAND --help' for more information on a command.
          HELP
        end
      end
    end
  end
end
