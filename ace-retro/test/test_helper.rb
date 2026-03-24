# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/retro"

# Base test case for ace-retro
class AceRetroTestCase < AceTestCase
  # Helper to create a temporary retros directory
  def with_retros_dir
    Dir.mktmpdir("ace-retro-test") do |tmpdir|
      yield tmpdir
    end
  end

  # Helper to create a minimal retro in a directory
  def create_retro_fixture(root_dir, id:, slug:, status: "active", type: "standard",
    tags: [], special_folder: nil)
    parent = special_folder ? File.join(root_dir, special_folder) : root_dir
    FileUtils.mkdir_p(parent)
    folder_name = "#{id}-#{slug}"
    retro_dir = File.join(parent, folder_name)
    FileUtils.mkdir_p(retro_dir)

    content = <<~CONTENT
      ---
      id: #{id}
      title: #{slug.tr("-", " ").capitalize}
      type: #{type}
      tags: [#{tags.join(", ")}]
      created_at: 2026-02-28 12:00:00
      status: #{status}
      ---

      # #{slug.tr("-", " ").capitalize}

      ## What Went Well

      Test retro content.
    CONTENT

    retro_file = File.join(retro_dir, "#{folder_name}.retro.md")
    File.write(retro_file, content)
    retro_dir
  end
end
