# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "../models/config_templates"

module Ace
  module Core
    class ConfigInitializer
      def initialize(force: false, dry_run: false, global: false, verbose: false)
        @force = force
        @dry_run = dry_run
        @global = global
        @verbose = verbose
        @copied_files = []
        @skipped_files = []
      end

      def init_all
        puts "Initializing all ace-* gem configurations..." if @verbose

        ConfigTemplates.all_gems.each do |gem_name|
          init_gem(gem_name)
        end

        print_summary
      end

      def init_gem(gem_name)
        gem_name = normalize_gem_name(gem_name)

        unless ConfigTemplates.gem_exists?(gem_name)
          puts "Warning: No configuration found for #{gem_name}"
          return
        end

        puts "\nInitializing #{gem_name}..." if @verbose

        source_dir = ConfigTemplates.example_dir_for(gem_name)
        target_dir = target_directory

        unless File.exist?(source_dir)
          puts "Warning: No ace.example directory found for #{gem_name}"
          return
        end

        # Show config docs on first run if config is missing
        show_config_docs_if_needed(gem_name, target_dir)

        # Copy files from ace.example to .ace
        copy_config_files(source_dir, target_dir, gem_name)
      end

      private

      def normalize_gem_name(name)
        # Handle both "ace-core" and "core" formats
        name.start_with?("ace-") ? name : "ace-#{name}"
      end

      def target_directory
        @global ? File.expand_path("~/.ace") : ".ace"
      end

      def show_config_docs_if_needed(gem_name, target_dir)
        # Check if any config files exist for this gem
        config_subdir = gem_name.sub("ace-", "")

        # Look for any existing config files in the expected location
        existing_configs = Dir.glob("#{target_dir}/#{config_subdir}/**/*").reject { |f| File.directory?(f) }

        # Only show docs if this is the first time (no existing config)
        if existing_configs.empty? && !@dry_run
          docs_file = ConfigTemplates.docs_file_for(gem_name)
          if File.exist?(docs_file)
            puts "\n#{File.read(docs_file)}\n"
          end
        end
      end

      def copy_config_files(source_dir, target_dir, gem_name)
        Dir.glob("#{source_dir}/**/*").each do |source_file|
          next if File.directory?(source_file)

          # Calculate relative path from source_dir
          relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_dir))

          # Build target path - files already include their subdirectory
          target_file = File.join(target_dir, relative_path.to_s)

          copy_file(source_file, target_file)
        end
      end

      def copy_file(source, target)
        if File.exist?(target) && !@force
          @skipped_files << target
          puts "  Skipped: #{target} (already exists)" if @verbose
          return
        end

        if @dry_run
          puts "  Would copy: #{source} -> #{target}"
        else
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(source, target)
          @copied_files << target
          puts "  Copied: #{target}" if @verbose
        end
      end

      def print_summary
        return if @dry_run

        puts "\nConfiguration initialization complete:"
        puts "  Files copied: #{@copied_files.size}"
        puts "  Files skipped: #{@skipped_files.size}"

        if @skipped_files.any? && !@force
          puts "\nUse --force to overwrite existing files"
        end
      end
    end
  end
end