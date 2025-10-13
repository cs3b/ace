# frozen_string_literal: true

require_relative "docs/version"

module Ace
  module Docs
    class Error < StandardError; end

    # Main entry point for ace-docs gem
    # Provides documentation management with frontmatter,
    # change analysis, and intelligent updates
    def self.root
      File.expand_path("../..", __dir__)
    end
  end
end
