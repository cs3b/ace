# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/idea"

# Base test case for ace-idea
class AceIdeaTestCase < AceTestCase
  # Helper to create a temporary ideas directory
  def with_ideas_dir
    Dir.mktmpdir("ace-idea-test") do |tmpdir|
      yield tmpdir
    end
  end

  # Helper to create a minimal idea in a directory
  def create_idea_fixture(root_dir, id:, slug:, status: "pending", tags: [], special_folder: nil)
    parent = special_folder ? File.join(root_dir, special_folder) : root_dir
    FileUtils.mkdir_p(parent)
    folder_name = "#{id}-#{slug}"
    idea_dir = File.join(parent, folder_name)
    FileUtils.mkdir_p(idea_dir)

    content = <<~CONTENT
      ---
      id: #{id}
      status: #{status}
      title: #{slug.tr("-", " ").capitalize}
      tags: [#{tags.join(", ")}]
      created_at: 2026-02-28 12:00:00
      ---

      # #{slug.tr("-", " ").capitalize}

      Test idea content.
    CONTENT

    spec_file = File.join(idea_dir, "#{folder_name}.idea.s.md")
    File.write(spec_file, content)
    idea_dir
  end
end
