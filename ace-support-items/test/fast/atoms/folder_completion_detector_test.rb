# frozen_string_literal: true

require "test_helper"

class FolderCompletionDetectorTest < AceSupportItemsTestCase
  def setup
    @tmpdir = Dir.mktmpdir("folder-completion-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_all_terminal_when_all_done
    write_spec(@tmpdir, "task-a.s.md", status: "done")
    write_spec(@tmpdir, "task-b.s.md", status: "done")

    assert Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(@tmpdir)
  end

  def test_all_terminal_with_mixed_terminal_statuses
    write_spec(@tmpdir, "task-a.s.md", status: "done")
    write_spec(@tmpdir, "task-b.s.md", status: "skipped")
    write_spec(@tmpdir, "task-c.s.md", status: "blocked")

    assert Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(@tmpdir)
  end

  def test_not_terminal_when_one_pending
    write_spec(@tmpdir, "task-a.s.md", status: "done")
    write_spec(@tmpdir, "task-b.s.md", status: "pending")

    refute Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(@tmpdir)
  end

  def test_not_terminal_when_in_progress
    write_spec(@tmpdir, "task-a.s.md", status: "in-progress")

    refute Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(@tmpdir)
  end

  def test_false_when_no_files_found
    refute Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(@tmpdir)
  end

  def test_custom_spec_pattern
    write_spec(@tmpdir, "idea.idea.s.md", status: "done")

    assert Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(
      @tmpdir, spec_pattern: "*.idea.s.md"
    )
  end

  def test_recursive_checks_subdirectories
    sub_a = File.join(@tmpdir, "subtask-a")
    sub_b = File.join(@tmpdir, "subtask-b")
    FileUtils.mkdir_p(sub_a)
    FileUtils.mkdir_p(sub_b)

    write_spec(sub_a, "subtask-a.s.md", status: "done")
    write_spec(sub_b, "subtask-b.s.md", status: "done")

    assert Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(
      @tmpdir, recursive: true
    )
  end

  def test_recursive_false_when_subdirectory_not_terminal
    sub_a = File.join(@tmpdir, "subtask-a")
    sub_b = File.join(@tmpdir, "subtask-b")
    FileUtils.mkdir_p(sub_a)
    FileUtils.mkdir_p(sub_b)

    write_spec(sub_a, "subtask-a.s.md", status: "done")
    write_spec(sub_b, "subtask-b.s.md", status: "pending")

    refute Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(
      @tmpdir, recursive: true
    )
  end

  def test_custom_terminal_statuses
    write_spec(@tmpdir, "task-a.s.md", status: "cancelled")

    assert Ace::Support::Items::Atoms::FolderCompletionDetector.all_terminal?(
      @tmpdir, terminal_statuses: %w[done cancelled]
    )
  end

  private

  def write_spec(dir, filename, status:)
    File.write(File.join(dir, filename), <<~CONTENT)
      ---
      status: #{status}
      ---

      # Test
    CONTENT
  end
end
