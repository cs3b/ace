# frozen_string_literal: true

require "open3"
require "json"

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
            config_file: ".standard.yml"
          }.merge(options)
        end

        def validate(paths = ["."])
          ensure_standard_available!

          command = build_command(paths)
          output, status = execute_command(command)

          parse_results(output, status)
        end

        def autofix(paths = ["."])
          @options[:fix] = true
          validate(paths)
        end

        private

        def ensure_standard_available!
          unless system("which standardrb > /dev/null 2>&1")
            raise "StandardRB is not installed. Please add it to your Gemfile."
          end
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
          end

          # Expand paths to absolute paths
          expanded_paths = Array(paths).map do |path|
            File.expand_path(path)
          end

          cmd.concat(expanded_paths)
          cmd
        end

        def execute_command(command)
          # Find the dev-tools directory
          current_file = File.expand_path(__FILE__)
          dev_tools_dir = current_file.split("/dev-tools/").first + "/dev-tools"

          Dir.chdir(dev_tools_dir) do
            stdout, stderr, status = Open3.capture3(*command)
            output = stdout.empty? ? stderr : stdout

            [output, status.exitstatus]
          end
        end

        def parse_results(output, exit_code)
          findings = []

          begin
            if options[:format] == "json" && !output.empty?
              data = JSON.parse(output)
              findings = extract_offenses(data)
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

        def extract_offenses(data)
          offenses = []

          data["files"]&.each do |file_data|
            file_path = file_data["path"]
            
            # Adjust path to be relative to project root (not dev-tools)
            # Since we're running from dev-tools, prepend "dev-tools/" to make it project-relative
            adjusted_path = File.join("dev-tools", file_path)

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

        def parse_text_output(output)
          # Basic text parsing fallback
          findings = []

          output.each_line do |line|
            # Match StandardRB output format
            if line =~ /^(.+):(\d+):(\d+):\s+([A-Z]):\s+(.+)$/
              findings << {
                file: $1,
                line: $2.to_i,
                column: $3.to_i,
                severity: $4,
                message: $5
              }
            end
          end

          findings
        end
      end
    end
  end
end
