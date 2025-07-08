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
          cmd = ["standardrb"]
          
          cmd << "--fix" if options[:fix]
          cmd << "--format" << options[:format]
          
          if options[:config_file] && File.exist?(options[:config_file])
            cmd << "--config" << options[:config_file]
          end
          
          cmd.concat(Array(paths))
          cmd.join(" ")
        end

        def execute_command(command)
          stdout, stderr, status = Open3.capture3(command)
          output = stdout.empty? ? stderr : stdout
          
          [output, status.exitstatus]
        end

        def parse_results(output, exit_code)
          findings = []
          
          begin
            if options[:format] == "json" && !output.empty?
              data = JSON.parse(output)
              findings = extract_offenses(data)
            end
          rescue JSON::ParserError
            # Fall back to text parsing if JSON fails
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
          
          if data["files"]
            data["files"].each do |file_data|
              file_path = file_data["path"]
              
              file_data["offenses"].each do |offense|
                offenses << {
                  file: file_path,
                  line: offense["location"]["line"],
                  column: offense["location"]["column"],
                  severity: offense["severity"],
                  message: offense["message"],
                  cop: offense["cop_name"],
                  correctable: offense["correctable"]
                }
              end
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