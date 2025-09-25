# frozen_string_literal: true

require "test_helper"
require "ace/taskflow/molecules/task_slug_generator"

module Ace
  module Taskflow
    module Molecules
      class TestTaskSlugGenerator < Minitest::Test
        def test_generate_basic_slug
          slug = TaskSlugGenerator.generate("025", "Add git commit flag to idea command")
          assert_equal "025-feat-git-commit-flag-idea-command", slug
        end

        def test_generate_with_type_detection
          # Feature detection
          slug = TaskSlugGenerator.generate("001", "Implement new search functionality")
          assert slug.start_with?("001-feat-")

          # Fix detection
          slug = TaskSlugGenerator.generate("002", "Fix context loader crash")
          assert slug.start_with?("002-fix-")

          # Docs detection
          slug = TaskSlugGenerator.generate("003", "Update README documentation")
          assert slug.start_with?("003-docs-")

          # Test detection
          slug = TaskSlugGenerator.generate("004", "Add test coverage for nav module")
          assert slug.start_with?("004-test-")

          # Refactor detection
          slug = TaskSlugGenerator.generate("005", "Refactor config resolver logic")
          assert slug.start_with?("005-refactor-")
        end

        def test_generate_with_metadata
          metadata = { type: "feature", component: "taskflow" }
          slug = TaskSlugGenerator.generate("030", "Add LLM enhancement", metadata)
          assert_equal "030-feat-taskflow-llm-enhancement", slug
        end

        def test_context_extraction
          # ACE component detection
          slug = TaskSlugGenerator.generate("010", "Update ace-taskflow module")
          assert slug.include?("-taskflow-")

          slug = TaskSlugGenerator.generate("011", "Fix ace-context loading")
          assert slug.include?("-context-")
        end

        def test_keywords_extraction
          slug = TaskSlugGenerator.generate("015", "Add GitHub issues import support")
          assert slug.include?("github")
          assert slug.include?("issues")
          assert slug.include?("import")
        end

        def test_slug_length_limits
          long_title = "Add support for " + ("very " * 20) + "long task titles"
          slug = TaskSlugGenerator.generate("020", long_title)

          # Verify slug isn't too long (reasonable limit)
          assert slug.length < 100
        end

        def test_generate_descriptive_part_only
          desc = TaskSlugGenerator.generate_descriptive_part("Fix critical bug")
          assert_equal "fix-critical", desc
        end

        def test_parse_slug
          result = TaskSlugGenerator.parse_slug("025-feat-taskflow-idea-gc-llm")
          assert_equal "025", result[:number]
          assert_equal "feat", result[:type]
          assert_equal "taskflow", result[:context]
          assert_equal "idea-gc-llm", result[:keywords]
        end

        def test_parse_old_format_slug
          result = TaskSlugGenerator.parse_slug("025")
          assert_equal "025", result[:number]
          assert_equal "task", result[:type]
          assert_equal "", result[:context]
          assert_equal "", result[:keywords]
        end

        def test_sanitization
          slug = TaskSlugGenerator.generate("040", "Fix issue #123: Special chars & symbols!")
          # Should remove special characters
          refute slug.include?("#")
          refute slug.include?(":")
          refute slug.include?("&")
          refute slug.include?("!")
        end

        def test_number_padding
          slug = TaskSlugGenerator.generate("5", "Short task number")
          assert slug.start_with?("005-")

          slug = TaskSlugGenerator.generate(7, "Integer task number")
          assert slug.start_with?("007-")
        end

        def test_default_type_fallback
          slug = TaskSlugGenerator.generate("050", "Generic task title")
          assert slug.start_with?("050-task-")
        end
      end
    end
  end
end