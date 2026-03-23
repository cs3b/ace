# frozen_string_literal: true

require "open3"
require "pathname"
require_relative "../models/config_templates"

module Ace
  module Core
    class ConfigDiff
      def initialize(global: false, file: nil, one_line: false)
        @global = global
        @file = file
        @one_line = one_line
        @diffs = []
      end

      def run
        if @file
          diff_file(@file)
        else
          diff_all_configs
        end

        print_results
      end

      def diff_gem(gem_name)
        # Normalize gem name (support both "ace-bundle" and "bundle")
        gem_name = gem_name.start_with?("ace-") ? gem_name : "ace-#{gem_name}"

        unless ConfigTemplates.gem_exists?(gem_name)
          puts "Error: Gem '#{gem_name}' not found or has no example configurations"
          exit 1
        end

        diff_gem_configs(gem_name)
        print_results
      end

      private

      def config_directory
        @global ? File.expand_path("~/.ace") : ".ace"
      end

      def diff_all_configs
        ConfigTemplates.all_gems.each do |gem_name|
          diff_gem_configs(gem_name)
        end
      end

      def diff_gem_configs(gem_name)
        source_dir = ConfigTemplates.example_dir_for(gem_name)

        return unless source_dir && File.exist?(source_dir)

        Dir.glob("#{source_dir}/**/*").each do |source_file|
          next if File.directory?(source_file)

          relative_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_dir))
          target_file = File.join(config_directory, relative_path.to_s)

          compare_files(source_file, target_file, gem_name)
        end
      end

      def diff_file(file_path)
        # Determine which gem this file belongs to
        if file_path.start_with?(config_directory)
          relative_path = Pathname.new(file_path).relative_path_from(Pathname.new(config_directory))
          parts = relative_path.to_s.split(File::SEPARATOR)

          if parts.any?
            config_subdir = parts.first
            gem_name = "ace-#{config_subdir}"

            if ConfigTemplates.gem_exists?(gem_name)
              source_dir = ConfigTemplates.example_dir_for(gem_name)
              relative_file = parts[1..-1].join(File::SEPARATOR)
              source_file = File.join(source_dir, relative_file)

              if File.exist?(source_file)
                compare_files(source_file, file_path, gem_name)
              else
                puts "No example file found for #{file_path}"
              end
            end
          end
        else
          puts "File #{file_path} is not in a configuration directory"
        end
      end

      def compare_files(source_file, target_file, gem_name)
        @diffs << if !File.exist?(target_file)
          {
            gem: gem_name,
            file: target_file,
            status: :missing,
            source: source_file
          }
        elsif files_differ?(source_file, target_file)
          {
            gem: gem_name,
            file: target_file,
            status: :different,
            source: source_file,
            diff_output: get_diff_output(source_file, target_file)
          }
        else
          {
            gem: gem_name,
            file: target_file,
            status: :same,
            source: source_file
          }
        end
      end

      def files_differ?(file1, file2)
        File.read(file1) != File.read(file2)
      rescue
        true
      end

      def get_diff_output(source_file, target_file)
        # Use system diff command
        output, _status = Open3.capture2("diff", "-u", target_file, source_file)
        output
      rescue
        "Unable to generate diff"
      end

      def print_results
        if @one_line
          print_one_line_summary
        else
          print_detailed_diffs
        end
      end

      def print_one_line_summary
        @diffs.each do |diff|
          case diff[:status]
          when :missing
            puts "MISSING: #{diff[:file]}"
          when :different
            puts "CHANGED: #{diff[:file]}"
          when :same
            puts "SAME:    #{diff[:file]}" if @verbose
          end
        end

        puts "\nSummary:"
        puts "  Missing: #{@diffs.count { |d| d[:status] == :missing }}"
        puts "  Changed: #{@diffs.count { |d| d[:status] == :different }}"
        puts "  Same: #{@diffs.count { |d| d[:status] == :same }}"
      end

      def print_detailed_diffs
        missing = @diffs.select { |d| d[:status] == :missing }
        changed = @diffs.select { |d| d[:status] == :different }

        if missing.any?
          puts "Missing configuration files:"
          missing.each do |diff|
            puts "  #{diff[:file]}"
            puts "  -> Example: #{diff[:source]}"
          end
          puts
        end

        if changed.any?
          puts "Changed configuration files:"
          changed.each do |diff|
            puts "\n#{diff[:file]}:"
            puts diff[:diff_output]
          end
        end

        if missing.empty? && changed.empty?
          puts "All configuration files match the examples."
        end
      end
    end
  end
end
