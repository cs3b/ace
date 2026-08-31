# frozen_string_literal: true

require "json"
require "open3"

module Ace
  module Overseer
    module Molecules
      class LabClient
        BINARY = "/usr/local/bin/lab"

        def initialize(runner: Open3)
          @runner = runner
        end

        def call(*arguments, stdin_data: nil, json: true)
          stdout, stderr, status = @runner.capture3(
            BINARY,
            *arguments.map(&:to_s),
            stdin_data: stdin_data.to_s
          )
          raise Error, stderr.to_s.strip.empty? ? "Lab command failed" : stderr.to_s.strip unless status.success?

          return stdout unless json

          JSON.parse(stdout)
        rescue Errno::ENOENT
          raise Error, "Lab runtime unavailable: #{BINARY} is not installed"
        rescue JSON::ParserError => error
          raise Error, "Lab returned invalid JSON: #{error.message}"
        end
      end
    end
  end
end
