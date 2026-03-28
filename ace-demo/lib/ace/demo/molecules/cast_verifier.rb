# frozen_string_literal: true

require "shellwords"

module Ace
  module Demo
    module Molecules
      class CastVerifier
        def initialize(parser: Atoms::CastFileParser)
          @parser = parser
        end

        def verify(cast_path:, tape_spec:)
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

          commands_found = expected.select { |command| include_command?(recorded_commands, command) }
          commands_missing = expected - commands_found

          status = commands_missing.empty? ? "pass" : "warn"
          Models::VerificationResult.new(
            success: commands_missing.empty?,
            status: status,
            commands_found: commands_found,
            commands_missing: commands_missing,
            details: {
              cast_path: cast_path,
              inputs_recorded: recorded_inputs.length,
              echoed_commands_recorded: echoed_commands.length,
              script_commands_recorded: script_commands.length,
              commands_expected: expected.length
            }
          )
        rescue CastParseError => e
          Models::VerificationResult.new(
            success: false,
            status: "fail-details",
            commands_found: [],
            commands_missing: expected_commands(tape_spec),
            details: {error: e.message, cast_path: cast_path}
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

        def normalized(command)
          command.to_s.strip.gsub(/\s+/, " ")
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
