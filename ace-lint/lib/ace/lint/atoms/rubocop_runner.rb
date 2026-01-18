# frozen_string_literal: true

require 'json'
require 'open3'

module Ace
  module Lint
    module Atoms
      # Executes RuboCop linter and parses results
      # Used as fallback when StandardRB is not available
      class RuboCopRunner
        # Thread-safe availability check using ||= pattern
        @available_mutex = Mutex.new

        class << self
          private

          # Check availability with caching (thread-safe)
          def check_availability
            @available_mutex.synchronize do
              @available ||= Open3.capture3('which', 'rubocop')[2].success?
            end
          end
        end

        # Check if RuboCop is available (cached per process, thread-safe)
        # @return [Boolean] True if rubocop command is available
        def self.available?
          check_availability
        end

        # Reset availability cache (for testing purposes)
        # @internal
        def self.reset_availability_cache!
          @available_mutex.synchronize do
            @available = nil
          end
        end

        # Run RuboCop on file(s)
        # @param file_paths [String, Array<String>] Path(s) to lint
        # @param fix [Boolean] Apply autofix
        # @return [Hash] Result with :success, :errors, :warnings
        def self.run(file_paths, fix: false)
          paths = Array(file_paths)
          return unavailable_result unless available?

          cmd = build_command(paths, fix: fix)

          stdout, stderr, status = Open3.capture3(*cmd)

          if status.success?
            parse_success_output(stdout)
          else
            parse_error_output(stdout, stderr, exit_status: status.exitstatus)
          end
        rescue StandardError => e
          {
            success: false,
            errors: [{ message: "RuboCop execution failed for #{Array(file_paths).join(', ')}: #{e.message}" }],
            warnings: []
          }
        end

        # Build RuboCop command
        # @param paths [Array<String>] File paths
        # @param fix [Boolean] Apply fixes
        # @return [Array<String>] Command and arguments
        # Flag mapping: --fix → --auto-correct, --fix-unsafely → --auto-correct-all
        def self.build_command(paths, fix:)
          # Map ace-lint flags to RuboCop flags
          # fix: false → no autofix
          # fix: true → --auto-correct (safe fixes only)
          autofix_flags = fix ? ['--auto-correct'] : []

          # Find project root to locate bundled config
          # Start from current file and go up to find .ace-defaults directory
          config_path = find_bundled_config

          # Add --config flag if bundled config exists, otherwise let RuboCop use its defaults
          config_flags = config_path ? ['--config', config_path] : []

          ['rubocop', *config_flags, *autofix_flags, '--format', 'json', *paths].compact
        end

        # Find the bundled RuboCop configuration
        # Searches upward from the gem directory to find .ace-defaults/lint/.rubocop.yml
        # @return [String, nil] Path to bundled config, or nil if not found
        def self.find_bundled_config
          # Get the gem root directory
          gem_root = ::Gem.loaded_specs["ace-lint"]&.gem_dir
          return nil unless gem_root

          config_path = File.join(gem_root, '.ace-defaults', 'lint', '.rubocop.yml')
          File.exist?(config_path) ? config_path : nil
        end
        private_class_method :find_bundled_config

        # Parse successful RuboCop output (no issues)
        # @param stdout [String] RuboCop output
        # @return [Hash] Parsed result
        def self.parse_success_output(stdout)
          # RuboCop with JSON format outputs empty or specific structure
          # If stdout is empty or contains "no offenses", no issues found
          if stdout.strip.empty? || stdout.include?('no offenses')
            return { success: true, errors: [], warnings: [] }
          end

          parse_json_output(stdout)
        rescue JSON::ParserError
          { success: true, errors: [], warnings: [] }
        end

        # Parse RuboCop error output (issues found)
        # @param stdout [String] RuboCop stdout
        # @param stderr [String] RuboCop stderr
        # @param exit_status [Integer] Process exit status
        # @return [Hash] Parsed result
        def self.parse_error_output(stdout, stderr, exit_status:)
          # RuboCop with JSON format outputs to stdout even on failure
          unless stdout.strip.empty?
            # Try to parse JSON output
            # If parsing fails, fall back to text parsing
            begin
              return parse_json_output(stdout, exit_status: exit_status)
            rescue JSON::ParserError
              return parse_text_output(stderr, exit_status: exit_status)
            end
          end

          # Fallback: parse stderr if stdout is empty
          parse_text_output(stderr, exit_status: exit_status)
        end

        # Parse JSON output from RuboCop
        # @param output [String] JSON string
        # @param exit_status [Integer, nil] Process exit status (nil for success case)
        # @return [Hash] Parsed result
        # @raise [JSON::ParserError] if output is not valid JSON
        def self.parse_json_output(output, exit_status: nil)
          data = JSON.parse(output)

          errors = []
          warnings = []

          # RuboCop JSON format: {files: [{path, offenses: [...)}]}
          if data.is_a?(Hash) && data.key?('files')
            data['files'].each do |file_data|
              file_path = file_data['path'] || 'unknown'
              offenses = file_data['offenses'] || []

              offenses.each do |offense|
                item = build_offense_item(offense, file_path)
                if offense['severity'] == 'error' || offense['severity'] == 'fatal'
                  errors << item
                else
                  warnings << item
                end
              end
            end
          # Fallback: direct array format (some tools may use this)
          elsif data.is_a?(Array)
            data.each do |offense|
              item = build_offense_item(offense)
              if offense['severity'] == 'error' || offense['severity'] == 'fatal'
                errors << item
              else
                warnings << item
              end
            end
          end

          # Determine success based on exit status when available
          # If process exited non-zero, consider it a failure even for warnings
          success = if exit_status
                      exit_status.zero?
                    else
                      errors.empty?
                    end

          {
            success: success,
            errors: errors,
            warnings: warnings
          }
        end

        # Parse text output from RuboCop (fallback)
        # @param output [String] Text output
        # @param exit_status [Integer, nil] Process exit status (nil for success case)
        # @return [Hash] Parsed result
        def self.parse_text_output(output, exit_status: nil)
          errors = []
          warnings = []

          output.each_line do |line|
            # RuboCop format: file:line:column: severity: message
            next unless line.match?(/^.+:\d+:\d+:/)

            parts = line.split(':', 5)
            next if parts.size < 5

            item = {
              file: parts[0],
              line: parts[1].to_i,
              column: parts[2].to_i,
              message: parts[4].strip
            }

            # Parse severity from parts[3] (e.g., " E", " F", " C", " W")
            # E/F = error, C/W = warning
            severity = parts[3].strip.upcase
            if severity == 'E' || severity == 'F'
              errors << item
            else
              warnings << item
            end
          end

          # Determine success based on exit status when available
          success = if exit_status
                      exit_status.zero?
                    else
                      errors.empty?
                    end

          # Add fallback error message if non-zero exit but no offenses parsed
          if !success && errors.empty? && warnings.empty? && !output.strip.empty?
            errors << { message: "RuboCop failed: #{output.strip.lines.first&.strip || output.strip}" }
          end

          {
            success: success,
            errors: errors,
            warnings: warnings
          }
        end

        # Build offense item from RuboCop offense
        # @param offense [Hash] Offense data
        # @param file_path [String] File path (for RuboCop format where path is at file level)
        # @return [Hash] Offense item
        def self.build_offense_item(offense, file_path = nil)
          # Use provided file_path or try to extract from location (legacy format)
          path = file_path || offense.dig('location', 'path') || 'unknown'
          location = offense['location'] || {}

          {
            file: path,
            line: location['line'] || 0,
            column: location['column'] || 0,
            message: "#{offense['cop_name']}: #{offense['message']}"
          }
        end

        # Result when neither StandardRB nor RuboCop is available
        # @return [Hash] Error result mentioning both tools
        def self.unavailable_result
          {
            success: false,
            errors: [{
              message: 'No Ruby linter available. Install StandardRB (preferred): gem install standardrb' \
                       ' - or RuboCop: gem install rubocop'
            }],
            warnings: []
          }
        end
      end
    end
  end
end
