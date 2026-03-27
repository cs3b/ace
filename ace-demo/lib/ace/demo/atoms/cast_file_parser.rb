# frozen_string_literal: true

require "json"

module Ace
  module Demo
    module Atoms
      module CastFileParser
        module_function

        def parse(path)
          raise CastParseError, "Cast file not found: #{path}" unless File.exist?(path)

          header = nil
          events = []

          File.foreach(path).with_index(1) do |line, line_number|
            stripped = line.strip
            next if stripped.empty?

            json = JSON.parse(stripped)
            if header.nil?
              header = parse_header(json, path: path)
            else
              events << parse_event(json, path: path, line_number: line_number)
            end
          rescue JSON::ParserError => e
            raise CastParseError, "Invalid JSON in #{path}:#{line_number}: #{e.message}"
          end

          raise CastParseError, "Missing cast header in #{path}" if header.nil?

          Models::CastRecording.new(header: header, events: events)
        end

        def parse_header(json, path:)
          unless json.is_a?(Hash)
            raise CastParseError, "Invalid cast header in #{path}: expected JSON object"
          end

          json
        end
        private_class_method :parse_header

        def parse_event(json, path:, line_number:)
          unless json.is_a?(Array) && json.length == 3
            raise CastParseError,
              "Invalid cast event in #{path}:#{line_number}: expected [timestamp, type, data]"
          end

          time, type, data = json
          unless type.is_a?(String) && !type.empty?
            raise CastParseError, "Invalid cast event type in #{path}:#{line_number}"
          end

          Models::CastEvent.new(time: time, type: type, data: data)
        end
        private_class_method :parse_event
      end
    end
  end
end
