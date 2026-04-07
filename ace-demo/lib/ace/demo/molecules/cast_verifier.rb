# frozen_string_literal: true

require "open3"
require "shellwords"

module Ace
  module Demo
    module Molecules
      class CastVerifier
        def initialize(parser: Atoms::CastFileParser, command_runner: nil)
          @parser = parser
          @command_runner = command_runner || method(:default_command_runner)
        end

        def verify(cast_path:, tape_spec:, sandbox_path: nil, env: {})
          recording = @parser.parse(cast_path)
          expected = expected_commands(tape_spec)
          recorded_inputs = recording.events
            .select { |event| event.type == "i" }
            .map { |event| event.data.to_s.strip }
            .reject(&:empty?)
          echoed_commands = recording.events
            .select { |event| event.type == "o" }
            .flat_map { |event| echoed_output_lines(event.data) }
          script_commands = script_commands(recording: recording)
          recorded_commands = (recorded_inputs + echoed_commands + script_commands).uniq
          verification_spec = tape_spec.fetch("verify", {})
          captured_vars = extract_output_vars(echoed_commands)

          commands_found = expected.select { |command| include_command?(recorded_commands, command) }
          commands_missing = expected - commands_found
          required_vars = verification_spec.fetch("require_vars", [])
          missing_vars = required_vars.reject { |name| present?(captured_vars[name]) || present?(env[name]) }
          forbidden_hits = forbidden_output_hits(echoed_commands, verification_spec.fetch("forbid_output", []))
          assertion_failures = run_assertions(
            verification_spec.fetch("assert_commands", []),
            sandbox_path: sandbox_path,
            env: env.merge(captured_vars)
          )

          success = commands_missing.empty? && missing_vars.empty? && forbidden_hits.empty? && assertion_failures.empty?
          classification, status, summary, retryable = classify(
            commands_missing: commands_missing,
            missing_vars: missing_vars,
            forbidden_hits: forbidden_hits,
            assertion_failures: assertion_failures
          )

          Models::VerificationResult.new(
            success: success,
            status: status,
            commands_found: commands_found,
            commands_missing: commands_missing,
            classification: classification,
            summary: summary,
            retryable: retryable,
            details: {
              cast_path: cast_path,
              inputs_recorded: recorded_inputs.length,
              echoed_commands_recorded: echoed_commands.length,
              script_commands_recorded: script_commands.length,
              commands_expected: expected.length,
              captured_vars: captured_vars,
              missing_vars: missing_vars,
              forbidden_hits: forbidden_hits,
              assertion_failures: assertion_failures
            }
          )
        rescue CastParseError => e
          Models::VerificationResult.new(
            success: false,
            status: "verification-error",
            commands_found: [],
            commands_missing: expected_commands(tape_spec),
            classification: "verification_error",
            summary: "Failed to parse the recorded cast",
            details: {error: e.message, cast_path: cast_path}
          )
        rescue StandardError => e
          Models::VerificationResult.new(
            success: false,
            status: "verification-error",
            commands_found: [],
            commands_missing: expected_commands(tape_spec),
            classification: "verification_error",
            summary: "Demo verification failed unexpectedly",
            details: {error: "#{e.class}: #{e.message}", cast_path: cast_path}
          )
        end

        private

        def expected_commands(tape_spec)
          scenes = tape_spec.fetch("scenes", [])
          scenes.flat_map do |scene|
            commands = scene.fetch("commands", [])
            commands.filter_map do |command|
              command_text = command["type"].to_s.strip
              command_text unless command_text.empty?
            end
          end
        end

        def include_command?(recorded_inputs, expected_command)
          recorded_inputs.any? do |input|
            normalized(input).include?(normalized(expected_command))
          end
        end

        def classify(commands_missing:, missing_vars:, forbidden_hits:, assertion_failures:)
          return ["pass", "pass", "Verification passed", false] if commands_missing.empty? && missing_vars.empty? &&
            forbidden_hits.empty? && assertion_failures.empty?
          return ["instruction_defect", "instruction-defect", "Recording instructions failed verification", true] unless commands_missing.empty? && missing_vars.empty?

          ["product_bug", "product-bug", "Recorded product behavior failed verification", false]
        end

        def normalized(command)
          command.to_s.strip.gsub(/\s+/, " ")
        end

        def extract_output_vars(lines)
          lines.each_with_object({}) do |line, vars|
            match = line.match(/\A([A-Z][A-Z0-9_]*)=(.+)\z/)
            next unless match

            vars[match[1]] = match[2].strip
          end
        end

        def present?(value)
          !value.to_s.strip.empty?
        end

        def forbidden_output_hits(lines, patterns)
          patterns.flat_map do |pattern|
            regexp = pattern_to_regexp(pattern)
            lines.filter_map do |line|
              next unless line.match?(regexp)

              {pattern: pattern, line: line}
            end
          end
        end

        def pattern_to_regexp(pattern)
          text = pattern.to_s
          if text.start_with?("/") && text.end_with?("/") && text.length > 2
            Regexp.new(text[1..-2])
          else
            /#{Regexp.escape(text)}/
          end
        end

        def run_assertions(commands, sandbox_path:, env:)
          return [] if commands.empty?

          commands.filter_map do |command|
            stdout, stderr, status = @command_runner.call(command, sandbox_path, env)
            next if status.to_i.zero?

            {
              command: command,
              exit_code: status.to_i,
              stdout: stdout.to_s.strip,
              stderr: stderr.to_s.strip
            }
          end
        end

        def default_command_runner(command, sandbox_path, env)
          stdout, stderr, status = Open3.capture3(env, "bash", "-lc", command, chdir: sandbox_path)
          [stdout, stderr, status.exitstatus]
        end

        def script_commands(recording:)
          script_path = script_path_from_header(recording.header)
          return [] unless script_path && File.file?(script_path)

          File.readlines(script_path, chomp: true).filter_map do |line|
            command = line.strip
            next if command.empty? || command.start_with?("#")
            next if command.start_with?("set ", "sleep ", "export ")

            command
          end
        rescue StandardError
          []
        end

        ANSI_ESCAPE_PATTERN = /\e\[[0-9;?]*[A-Za-z]/.freeze
        private_constant :ANSI_ESCAPE_PATTERN

        def echoed_output_lines(data)
          data.to_s
            .gsub(ANSI_ESCAPE_PATTERN, "")
            .split(/[\r\n]+/)
            .map(&:strip)
            .reject(&:empty?)
        end

        def script_path_from_header(header)
          command = header.fetch("command", nil)
          return nil if command.to_s.strip.empty?

          parts = Shellwords.split(command.to_s)
          return nil if parts.empty?

          first = File.basename(parts[0])
          return parts[1] if first == "bash" || first == "sh"

          parts[0]
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
