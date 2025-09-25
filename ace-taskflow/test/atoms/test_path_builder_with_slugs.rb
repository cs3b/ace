# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/atoms/path_builder"

module Ace
  module Taskflow
    module Atoms
      class TestPathBuilderWithSlugs < Minitest::Test
        def test_build_task_path_with_slug
          path = PathBuilder.build_task_path("/root", "v.0.9.0", "025", "feat-taskflow-idea")
          assert_equal "/root/v.0.9.0/t/025-feat-taskflow-idea", path
        end

        def test_build_task_path_without_slug
          path = PathBuilder.build_task_path("/root", "v.0.9.0", "025")
          assert_equal "/root/v.0.9.0/t/025", path
        end

        def test_build_task_file_path_with_slug
          path = PathBuilder.build_task_file_path("/root", "v.0.9.0", "025", nil, "feat-taskflow")
          assert_equal "/root/v.0.9.0/t/025-feat-taskflow/task.025.md", path
        end

        def test_build_task_file_path_without_slug
          path = PathBuilder.build_task_file_path("/root", "v.0.9.0", "025")
          assert_equal "/root/v.0.9.0/t/025/task.md", path
        end

        def test_extract_task_number_old_format
          # Old format: /t/019/
          number = PathBuilder.extract_task_number("/ace-taskflow/v.0.9.0/t/019/task.md")
          assert_equal "019", number
        end

        def test_extract_task_number_new_format
          # New format: /t/019-feat-taskflow/
          number = PathBuilder.extract_task_number("/ace-taskflow/v.0.9.0/t/019-feat-taskflow/task.019.md")
          assert_equal "019", number
        end

        def test_extract_task_number_from_directory
          number = PathBuilder.extract_task_number("/ace-taskflow/v.0.9.0/t/025-feat-taskflow-idea/")
          assert_equal "025", number
        end

        def test_extract_slug_from_dir
          slug = PathBuilder.extract_slug_from_dir("025-feat-taskflow-idea")
          assert_equal "feat-taskflow-idea", slug
        end

        def test_extract_slug_from_old_format
          slug = PathBuilder.extract_slug_from_dir("025")
          assert_nil slug
        end

        def test_task_number_padding
          path = PathBuilder.build_task_path("/root", "v.0.9.0", 5, "feat-test")
          assert_equal "/root/v.0.9.0/t/005-feat-test", path
        end

        def test_backward_compatibility
          # Ensure old format paths still work
          old_path = PathBuilder.build_task_path("/root", "backlog", "042")
          assert_equal "/root/backlog/t/042", old_path

          old_file = PathBuilder.build_task_file_path("/root", "backlog", "042", "custom-name.md")
          assert_equal "/root/backlog/t/042/custom-name.md", old_file
        end
      end
    end
  end
end