# frozen_string_literal: true

require "open3"
require "json"
require "pathname"
require_relative "../project_root_detector"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for running StandardRB Ruby linter
      class StandardRbValidator
        attr_reader :options

        def initialize(options = {})
          @options = {
            fix: false,
            format: "json",
            config_file: ".standard.yml",
            project_root: nil
          }.merge(options)
        end

        def validate(paths = ["."])
          ensure_standard_available!

          project_root = detect_project_root
          command = build_command(paths)
          output, status = execute_command(command, project_root)

          parse_results(output, status, project_root)
        end

        def autofix(paths = ["."])
          @options[:fix] = true
          validate(paths)
        end

        private

        def detect_project_root
          return options[:project_root] if options[:project_root]

          ProjectRootDetector.find_project_root
        end

        def ensure_standard_available!
          return if system("which standardrb > /dev/null 2>&1")

          raise "StandardRB is not installed. Please add it to your Gemfile."
        end

        def build_command(paths)
          cmd = ["bundle", "exec", "standardrb"]

          if options[:fix]
            # Use fix-unsafely to actually apply all available fixes
            cmd << "--fix-unsafely"
          end
          cmd << "--format" << options[:format]

          if options[:config_file] && File.exist?(options[:config_file])
            cmd << "--config" << options[:config_file]
            puts "  Using StandardRB config: #{options[:config_file]}" if ENV["DEBUG"]
          elsif ENV["DEBUG"]
            puts "  Using StandardRB default config (no .standard.yml found)"
          end

          # Expand paths to absolute paths
          expanded_paths = Array(paths).map do |path|
            File.expand_path(path)
          end

          cmd.concat(expanded_paths)
          cmd
        end

        def execute_command(command, project_root)
          # Determine the working directory - prefer dev-tools subdirectory if it exists
          working_dir = File.join(project_root, "dev-tools")
          working_dir = project_root unless File.directory?(working_dir)

          stdout, stderr, status = Open3.capture3(*command, chdir: working_dir)
          output = stdout.empty? ? stderr : stdout

          [output, status.exitstatus]
        end

        def parse_results(output, exit_code, project_root)
          findings = []

          begin
            if options[:format] == "json" && !output.empty?
              data = JSON.parse(output)
              findings = extract_offenses(data, project_root)
            end
          rescue JSON::ParserError => e
            # Fall back to text parsing if JSON fails
            puts "StandardRB JSON parse error: #{e.message}" if ENV["DEBUG"]
            findings = parse_text_output(output)
          end

          {
            success: exit_code == 0,
            findings: findings,
            exit_code: exit_code,
            output: output,
            fixed: options[:fix]
          }
        end

        def extract_offenses(data, project_root)
          offenses = []

          data["files"]&.each do |file_data|
            file_path = file_data["path"]

            # Convert to project-relative path
            adjusted_path = resolve_project_relative_path(file_path, project_root)

            file_data["offenses"].each do |offense|
              offenses << {
                file: adjusted_path,
                line: offense["location"]["line"],
                column: offense["location"]["column"],
                severity: offense["severity"],
                message: offense["message"],
                cop: offense["cop_name"],
                correctable: offense["correctable"]
              }
            end
          end

          offenses
        end

        def resolve_project_relative_path(file_path, project_root)
          # If the path is already absolute, make it relative to project root
          if File.absolute_path?(file_path)
            begin
              return Pathname.new(file_path).relative_path_from(Pathname.new(project_root)).to_s
            rescue ArgumentError
              # If we can't make it relative, return as-is
              return file_path
            end
          end

          # If we're running from a subdirectory (like dev-tools), adjust the path
          working_dir = File.join(project_root, "dev-tools")
          return File.join("dev-tools", file_path) if File.directory?(working_dir)

          # Default: return the path as-is
          file_path
        end

        def parse_text_output(output)
          # Basic text parsing fallback
          findings = []

          output.each_line do |line|
            # Match StandardRB output format
            next unless line =~ /^(.+):(\d+):(\d+):\s+([A-Z]):\s+(.+)$/

            findings << {
              file: ::Regexp.last_match(1),
              line: ::Regexp.last_match(2).to_i,
              column: ::Regexp.last_match(3).to_i,
              severity: ::Regexp.last_match(4),
              message: ::Regexp.last_match(5)
            }
          end

          findings
        end
      end
    end
  end
end
