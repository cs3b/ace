# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/task"

# Base test case for ace-task
class AceTaskTestCase < AceTestCase
  # Helper to create a temporary tasks directory
  def with_tasks_dir
    Dir.mktmpdir("ace-task-test") do |tmpdir|
      yield tmpdir
    end
  end

  # Helper to create a minimal task in a directory
  def create_task_fixture(root_dir, id:, slug:, status: "pending", tags: [], special_folder: nil)
    parent = special_folder ? File.join(root_dir, special_folder) : root_dir
    FileUtils.mkdir_p(parent)
    folder_name = "#{id}-#{slug}"
    task_dir = File.join(parent, folder_name)
    FileUtils.mkdir_p(task_dir)

    content = <<~CONTENT
      ---
      id: #{id}
      status: #{status}
      title: #{slug.tr("-", " ").capitalize}
      tags: [#{tags.join(", ")}]
      created_at: 2026-02-28 12:00:00
      ---

      # #{slug.tr("-", " ").capitalize}

      Test task content.
    CONTENT

    spec_file = File.join(task_dir, "#{folder_name}.s.md")
    File.write(spec_file, content)
    task_dir
  end
end
