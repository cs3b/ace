# frozen_string_literal: true

require "open3"
require "date"

module Ace
  module Docs
    module Molecules
      # Resolves last commit date for a file path.
      class GitDateResolver
        def self.last_updated_for(path)
          return nil if path.nil? || path.to_s.empty?

          args = [
            "git", "log", "-1", "--format=%cs", "--", path.to_s
          ]
          stdout, _stderr, status = Open3.capture3(*args)
          return nil unless status.success?

          value = stdout.strip
          return nil if value.empty?

          Date.parse(value)
        rescue StandardError
          nil
        end
      end
    end
  end
end
