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

        # Whether this surface can make the no-writer state check and the
        # destruction one atomic operation. The raw CLI cannot: between
        # `work status` and `work destroy` another writer may start. Prune
        # treats the path as unsupported (preserve) unless the adapter
        # guarantees atomicity.
        def supports_atomic_destroy?
          false
        end

        # The authoritative status entry for one Work, or nil when the Work
        # is absent from the surface. Missing state is a blocking condition
        # for prune — never treated as safe.
        #
        # @param work_id [String] Exact Lab Work ID
        # @return [Hash, nil] Status entry or nil
        def work_entry(work_id)
          data = call("work", "status", "--json")
          works = data.is_a?(Hash) ? Array(data["works"]) : []
          works.find { |entry| entry.is_a?(Hash) && entry["id"].to_s == work_id.to_s }
        end
      end
    end
  end
end
