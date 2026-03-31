# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "../models/config_templates"

module Ace
  module Support
    module Config
      module Organisms
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

            Models::ConfigTemplates.all_gems.each do |gem_name|
              init_gem(gem_name)
            end

            print_summary
          end

          def init_gem(gem_name)
            gem_name = normalize_gem_name(gem_name)

            unless Models::ConfigTemplates.gem_exists?(gem_name)
              puts "Warning: No configuration found for #{gem_name}"
              return
            end

            puts "\nInitializing #{gem_name}..." if @verbose

            source_dir = Models::ConfigTemplates.example_dir_for(gem_name)
            target_dir = target_directory

            unless File.exist?(source_dir)
              puts "Warning: No .ace-defaults directory found for #{gem_name}"
              return
            end

            show_config_docs_if_needed(gem_name, target_dir)
            copy_config_files(source_dir, target_dir)
          end

          private

          def normalize_gem_name(name)
            name.start_with?("ace-") ? name : "ace-#{name}"
          end

          def target_directory
            @global ? File.expand_path("~/.ace") : ".ace"
          end

          def show_config_docs_if_needed(gem_name, target_dir)
            config_subdir = gem_name.sub("ace-", "")
            existing_configs = Dir.glob("#{target_dir}/#{config_subdir}/**/*").reject { |f| File.directory?(f) }

            return if existing_configs.any? || @dry_run

            docs_file = Models::ConfigTemplates.docs_file_for(gem_name)
            puts "\n#{File.read(docs_file)}\n" if docs_file && File.exist?(docs_file)
          end

          def copy_config_files(source_dir, target_dir)
            Dir.glob("#{source_dir}/**/*").each do |source_file|
              next if File.directory?(source_file)

              relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_dir))
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
  end
end
