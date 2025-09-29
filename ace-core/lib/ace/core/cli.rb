# frozen_string_literal: true

require "thor"
require_relative "organisms/config_initializer"
require_relative "organisms/config_diff"

module Ace
  module Core
    class CLI < Thor
      desc "init [GEM]", "Initialize configuration for specific gem or all"
      option :force, type: :boolean, desc: "Overwrite existing files"
      option :dry_run, type: :boolean, desc: "Show what would be done"
      option :global, type: :boolean, desc: "Use ~/.ace instead of ./.ace"
      option :verbose, type: :boolean, desc: "Show detailed output"
      def init(gem = nil)
        initializer = ConfigInitializer.new(
          force: options[:force],
          dry_run: options[:dry_run],
          global: options[:global],
          verbose: options[:verbose]
        )

        if gem
          initializer.init_gem(gem)
        else
          initializer.init_all
        end
      end

      desc "diff", "Compare configs with examples"
      option :global, type: :boolean, desc: "Compare global configs"
      option :local, type: :boolean, desc: "Compare local configs (default)"
      option :file, type: :string, desc: "Compare specific file"
      option :one_line, type: :boolean, desc: "One-line summary per file"
      def diff
        differ = ConfigDiff.new(
          global: options[:global],
          file: options[:file],
          one_line: options[:one_line]
        )

        differ.run
      end

      desc "list", "List available ace-* gems with example configs"
      option :verbose, type: :boolean, desc: "Show detailed information"
      def list
        require_relative "models/config_templates"

        puts "Available ace-* gems with example configurations:\n\n"

        if ConfigTemplates.all_gems.empty?
          puts "No ace-* gems with example configurations found."
          return
        end

        ConfigTemplates.all_gems.each do |gem_name|
          info = ConfigTemplates.gem_info[gem_name]
          source_label = case info[:source]
                         when :local then "[local]"
                         when :gem then "[gem]"
                         when :both then "[local+gem]"
                         end

          puts "  #{gem_name} #{source_label}"

          if options[:verbose]
            puts "    Path: #{info[:path]}"
            puts "    Gem: #{info[:gem_path]}" if info[:gem_path]
            example_dir = ConfigTemplates.example_dir_for(gem_name)
            if File.exist?(example_dir)
              example_files = Dir.glob("#{example_dir}/**/*").reject { |f| File.directory?(f) }
              puts "    Example files: #{example_files.size}"
            end
          end
        end

        puts "\nUse 'ace-framework init [GEM]' to initialize a specific gem's configuration"
        puts "Use 'ace-framework init' to initialize all configurations"
      end

      desc "version", "Show version"
      def version
        puts "ace-framework #{Ace::Core::VERSION}"
      end
    end
  end
end