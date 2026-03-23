# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "minitest/pride"

# Load the gem
require_relative "../lib/ace/support/markdown"

# Test helpers
module TestHelpers
  def sample_markdown
    <<~MARKDOWN
      ---
      id: test.001
      status: pending
      priority: high
      dependencies: []
      ---

      # Test Document

      This is a test document.

      ## Section 1

      Content of section 1.

      ### Subsection 1.1

      Content of subsection 1.1.

      ## References

      - Reference 1
      - Reference 2
    MARKDOWN
  end

  def sample_frontmatter
    {
      "id" => "test.001",
      "status" => "pending",
      "priority" => "high",
      "dependencies" => []
    }
  end

  def create_temp_file(content)
    require "tempfile"
    temp = Tempfile.new(["test", ".md"])
    temp.write(content)
    temp.close
    temp
  end
end
