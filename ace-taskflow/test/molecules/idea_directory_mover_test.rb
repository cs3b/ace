# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_directory_mover"

class IdeaDirectoryMoverTest < AceTaskflowTestCase
  def setup
    @mover = Ace::Taskflow::Molecules::IdeaDirectoryMover.new
  end

  def test_move_to_done_with_folder_path
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea folder structure
        ideas_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        idea_folder = File.join(ideas_dir, "20250101-120000-test-idea")
        FileUtils.mkdir_p(idea_folder)
        File.write(File.join(idea_folder, "idea.md"), "---\nstatus: pending\n---\n# Test Idea")

        # Move to done using folder path
        result = @mover.move_to_done(idea_folder)

        assert result[:success], "Should succeed: #{result[:message]}"
        assert_equal File.join(ideas_dir, "done", "20250101-120000-test-idea"), result[:new_path]
        assert Dir.exist?(result[:new_path]), "Done folder should exist"
        refute Dir.exist?(idea_folder), "Original folder should not exist"
      end
    end
  end

  def test_move_to_done_with_file_path_moves_entire_folder
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea folder structure
        ideas_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        idea_folder = File.join(ideas_dir, "20250101-120000-test-idea")
        FileUtils.mkdir_p(idea_folder)
        idea_file = File.join(idea_folder, "my-idea.s.md")
        File.write(idea_file, "---\nstatus: pending\n---\n# My Idea")

        # Move to done using FILE path (should move entire folder)
        result = @mover.move_to_done(idea_file)

        assert result[:success], "Should succeed: #{result[:message]}"
        # Should move the FOLDER, not just the file
        expected_folder = File.join(ideas_dir, "done", "20250101-120000-test-idea")
        assert_equal expected_folder, result[:new_path]
        assert Dir.exist?(expected_folder), "Done folder should exist at ideas/done/"
        assert File.exist?(File.join(expected_folder, "my-idea.s.md")), "File should be inside moved folder"
        refute Dir.exist?(idea_folder), "Original folder should not exist"
        # Ensure no incorrect done/ subfolder was created
        refute Dir.exist?(File.join(ideas_dir, "20250101-120000-test-idea", "done")),
               "Should NOT create done/ inside idea folder"
      end
    end
  end

  def test_move_to_done_updates_frontmatter
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea folder structure
        ideas_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        idea_folder = File.join(ideas_dir, "20250101-120000-test-idea")
        FileUtils.mkdir_p(idea_folder)
        File.write(File.join(idea_folder, "idea.md"), "---\nstatus: pending\n---\n# Test Idea")

        # Move to done
        result = @mover.move_to_done(idea_folder)

        assert result[:success]
        # Check frontmatter was updated
        content = File.read(File.join(result[:new_path], "idea.md"))
        assert_match(/status: done/, content)
        assert_match(/completed_at:/, content)
      end
    end
  end

  def test_move_to_done_with_nonexistent_path
    result = @mover.move_to_done("/nonexistent/path")
    refute result[:success]
    assert_match(/not found/i, result[:message])
  end

  def test_move_to_done_with_nil_path
    result = @mover.move_to_done(nil)
    refute result[:success]
    assert_match(/not provided/i, result[:message])
  end

  def test_restore_from_done
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create done idea folder
        ideas_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        done_dir = File.join(ideas_dir, "done")
        idea_folder = File.join(done_dir, "20250101-120000-test-idea")
        FileUtils.mkdir_p(idea_folder)
        File.write(File.join(idea_folder, "idea.md"), "---\nstatus: done\ncompleted_at: 2025-01-01\n---\n# Test Idea")

        # Restore from done
        result = @mover.restore_from_done(idea_folder)

        assert result[:success], "Should succeed: #{result[:message]}"
        expected_path = File.join(ideas_dir, "20250101-120000-test-idea")
        assert_equal expected_path, result[:new_path]
        assert Dir.exist?(expected_path), "Restored folder should exist"
        refute Dir.exist?(idea_folder), "Done folder should not exist"
      end
    end
  end
end
