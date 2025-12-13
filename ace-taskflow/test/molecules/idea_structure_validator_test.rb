# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/idea_structure_validator"
require "fileutils"
require "tmpdir"

module Ace
  module Taskflow
    module Molecules
      class IdeaStructureValidatorTest < Minitest::Test
        def setup
          @test_dir = Dir.mktmpdir("taskflow_test")
          @validator = IdeaStructureValidator.new(@test_dir)
        end

        def teardown
          FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
        end

        def test_validate_all_with_no_ideas
          result = @validator.validate_all

          assert_equal 0, result[:total]
          assert_equal 0, result[:valid].size
          assert_equal 0, result[:misplaced].size
        end

        def test_properly_placed_idea_in_backlog
          # Create properly placed idea in backlog/ideas/folder/
          backlog_idea_folder = File.join(@test_dir, "backlog", "ideas", "test-idea-folder")
          FileUtils.mkdir_p(backlog_idea_folder)
          idea_file = File.join(backlog_idea_folder, "test-idea.s.md")
          File.write(idea_file, "# Test Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:total]
          assert_equal 1, result[:valid].size
          assert_equal 0, result[:misplaced].size
        end

        def test_properly_placed_idea_in_release
          # Create properly placed idea in v.0.1.0/ideas/folder/
          release_idea_folder = File.join(@test_dir, "v.0.1.0", "ideas", "20251115-1200-test")
          FileUtils.mkdir_p(release_idea_folder)
          idea_file = File.join(release_idea_folder, "20251115-1200-test.s.md")
          File.write(idea_file, "# Test Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:total]
          assert_equal 1, result[:valid].size
          assert_equal 0, result[:misplaced].size
        end

        def test_properly_placed_idea_in_done_release
          # Create properly placed idea in _archive/v.0.1.0/ideas/folder/
          done_idea_folder = File.join(@test_dir, "_archive", "v.0.1.0", "ideas", "archived-idea-folder")
          FileUtils.mkdir_p(done_idea_folder)
          idea_file = File.join(done_idea_folder, "archived-idea.s.md")
          File.write(idea_file, "# Archived Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:total]
          assert_equal 1, result[:valid].size
          assert_equal 0, result[:misplaced].size
        end

        def test_misplaced_idea_at_release_root
          # Create misplaced idea at release root
          release_dir = File.join(@test_dir, "v.0.1.0")
          FileUtils.mkdir_p(release_dir)
          idea_file = File.join(release_dir, "misplaced-idea.s.md")
          File.write(idea_file, "# Misplaced Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:total]
          assert_equal 0, result[:valid].size
          assert_equal 1, result[:misplaced].size

          misplaced = result[:misplaced].first
          assert_includes misplaced[:path], "misplaced-idea.s.md"
          assert_match(/release root level.*ideas/, misplaced[:reason])
        end

        def test_ignores_docs_files_outside_ideas
          # Files in docs/ that aren't in ideas/ subdirectory are filtered out
          # (they're not considered idea files at all)
          docs_dir = File.join(@test_dir, "v.0.1.0", "docs")
          FileUtils.mkdir_p(docs_dir)
          doc_file = File.join(docs_dir, "doc-file.s.md")
          File.write(doc_file, "# Doc File\n\nContent")

          result = @validator.validate_all

          # Should be ignored completely (not counted as ideas)
          assert_equal 0, result[:total], "Docs files outside ideas/ should be ignored"
          assert_equal 0, result[:valid].size
          assert_equal 0, result[:misplaced].size
        end

        def test_properly_placed_checks_path_correctly
          # Test the properly_placed? method directly
          # Proper: file in folder within ideas/
          proper_path = File.join(@test_dir, "v.0.1.0", "ideas", "test-folder", "test.s.md")
          assert @validator.properly_placed?(proper_path)

          # Misplaced: file at release root
          misplaced_path = File.join(@test_dir, "v.0.1.0", "test.s.md")
          refute @validator.properly_placed?(misplaced_path)

          # Misplaced: flat file directly in ideas/ (no folder)
          flat_file_path = File.join(@test_dir, "v.0.1.0", "ideas", "test.s.md")
          refute @validator.properly_placed?(flat_file_path)
        end

        def test_ignores_task_files
          # Task files should be ignored even if they match .s.md pattern
          tasks_dir = File.join(@test_dir, "v.0.1.0", "tasks")
          FileUtils.mkdir_p(tasks_dir)
          task_file = File.join(tasks_dir, "task.001.s.md")
          File.write(task_file, "# Task\n\nContent")

          result = @validator.validate_all

          assert_equal 0, result[:total], "Task files should be ignored"
        end

        def test_ignores_retro_files
          # Retro files should be ignored
          retro_dir = File.join(@test_dir, "v.0.1.0", "retros")
          FileUtils.mkdir_p(retro_dir)
          retro_file = File.join(retro_dir, "reflection.s.md")
          File.write(retro_file, "# Retro\n\nContent")

          result = @validator.validate_all

          assert_equal 0, result[:total], "Retro files should be ignored"
        end

        def test_suggested_location_for_misplaced_idea
          # Create misplaced idea
          release_dir = File.join(@test_dir, "v.0.1.0")
          FileUtils.mkdir_p(release_dir)
          idea_file = File.join(release_dir, "misplaced.s.md")
          File.write(idea_file, "# Misplaced\n\nContent")

          result = @validator.validate_all

          misplaced = result[:misplaced].first
          assert misplaced[:suggested_location]
          # Suggestion should include folder: .../ideas/misplaced/misplaced.s.md
          assert_includes misplaced[:suggested_location], "/ideas/misplaced/misplaced.s.md"
        end

        def test_flat_file_in_ideas_is_misplaced
          # Flat files directly in ideas/ should be misplaced
          ideas_dir = File.join(@test_dir, "v.0.1.0", "ideas")
          FileUtils.mkdir_p(ideas_dir)
          flat_file = File.join(ideas_dir, "flat-idea.s.md")
          File.write(flat_file, "# Flat Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:total]
          assert_equal 0, result[:valid].size
          assert_equal 1, result[:misplaced].size

          misplaced = result[:misplaced].first
          assert_match(/flat file in ideas/, misplaced[:reason])
        end

        def test_misplaced_idea_in_done_release
          # Test nested path suggestion for _archive/v.X.Y.Z structure
          done_release_dir = File.join(@test_dir, "_archive", "v.0.1.0")
          FileUtils.mkdir_p(done_release_dir)
          idea_file = File.join(done_release_dir, "misplaced-in-done.s.md")
          File.write(idea_file, "# Misplaced Idea\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:misplaced].size
          misplaced = result[:misplaced].first
          # Should suggest: _archive/v.0.1.0/ideas/folder/file.md
          assert_includes misplaced[:suggested_location], "_archive/v.0.1.0/ideas/misplaced-in-done/misplaced-in-done.s.md"
        end

        def test_misplaced_idea_in_other_subdirectory
          # Test suggestion for ideas in wrong subdirectory
          other_dir = File.join(@test_dir, "v.0.1.0", "other_files")
          FileUtils.mkdir_p(other_dir)
          idea_file = File.join(other_dir, "misplaced-deep.s.md")
          File.write(idea_file, "# Misplaced Deep\n\nContent")

          result = @validator.validate_all

          assert_equal 1, result[:misplaced].size
          misplaced = result[:misplaced].first
          # Should suggest: v.0.1.0/other_files/ideas/folder/file.md
          assert_match %r{/v\.0\.1\.0/other_files/ideas/misplaced-deep/misplaced-deep\.s\.md$}, misplaced[:suggested_location]
        end

        def test_generate_folder_name_removes_extension
          # Test folder name generation from filename
          assert_equal "my-idea", @validator.send(:generate_folder_name, "my-idea.s.md")
          assert_equal "draft", @validator.send(:generate_folder_name, "draft.i.md")
        end

        def test_generate_folder_name_removes_timestamp
          # Test folder name generation removes timestamp prefix
          assert_equal "test-idea", @validator.send(:generate_folder_name, "20251115-1200-test-idea.s.md")
          assert_equal "feature", @validator.send(:generate_folder_name, "20250101-000000-feature.i.md")
        end

        def test_generate_folder_name_handles_plain_filenames
          # Test folder name generation without timestamps
          assert_equal "simple", @validator.send(:generate_folder_name, "simple.s.md")
        end

        def test_generate_folder_name_defaults_to_idea
          # Test folder name generation with only timestamp
          assert_equal "idea", @validator.send(:generate_folder_name, "20251115-1200.s.md")
        end

        def test_idea_file_detection_with_s_md_extension
          # Test that .s.md files are recognized as idea files
          file_path = File.join(@test_dir, "v.0.1.0", "ideas", "test.s.md")
          assert @validator.send(:idea_file?, file_path)
        end

        def test_idea_file_detection_with_i_md_extension
          # Test that .i.md files are recognized as idea files
          file_path = File.join(@test_dir, "v.0.1.0", "ideas", "draft.i.md")
          assert @validator.send(:idea_file?, file_path)
        end

        def test_task_file_detection_by_path
          # Task files in /tasks/ should be filtered out
          task_path = File.join(@test_dir, "v.0.1.0", "tasks", "something.s.md")
          assert @validator.send(:task_file?, task_path)
        end

        def test_task_file_detection_by_pattern
          # Files matching task.NNN pattern should be filtered out
          task_path = File.join(@test_dir, "v.0.1.0", "task.042.s.md")
          assert @validator.send(:task_file?, task_path)
        end

        def test_retro_file_detection_by_path
          # Retro files in /retro/ should be filtered out
          retro_path = File.join(@test_dir, "v.0.1.0", "retro", "notes.s.md")
          assert @validator.send(:retro_file?, retro_path)
        end

        def test_retro_file_detection_by_pattern
          # Reflection files should be filtered out
          reflection_path = File.join(@test_dir, "v.0.1.0", "reflection.s.md")
          assert @validator.send(:retro_file?, reflection_path)
        end

        def test_release_file_detection
          # Release markdown files should be filtered out
          release_path = File.join(@test_dir, "v.0.1.0", "release-notes.md")
          assert @validator.send(:release_file?, release_path)
        end

        def test_docs_file_outside_ideas_detection
          # Files in docs/ but not in ideas/ should be filtered out
          docs_path = File.join(@test_dir, "v.0.1.0", "docs", "guide.s.md")
          assert @validator.send(:docs_file_outside_ideas?, docs_path)
        end

        def test_docs_file_inside_ideas_not_filtered
          # Files in docs/ideas/ should NOT be filtered out
          docs_ideas_path = File.join(@test_dir, "v.0.1.0", "docs", "ideas", "guide.s.md")
          refute @validator.send(:docs_file_outside_ideas?, docs_ideas_path)
        end
      end
    end
  end
end
