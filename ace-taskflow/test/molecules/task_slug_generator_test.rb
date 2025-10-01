# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/task_slug_generator"

class TaskSlugGeneratorTest < AceTaskflowTestCase
  def setup
    @generator = Ace::Taskflow::Molecules::TaskSlugGenerator
  end

  def test_generate_with_feature_type
    slug = @generator.generate(25, "Implement dark mode for ace-taskflow")

    assert_match(/^025-feat-taskflow/, slug)
  end

  def test_generate_with_fix_type
    slug = @generator.generate(42, "Fix bug in authentication system")

    assert_match(/^042-fix/, slug)
  end

  def test_generate_with_docs_type
    slug = @generator.generate(10, "Document API endpoints")

    assert_match(/^010-docs/, slug)
  end

  def test_generate_extracts_ace_component
    slug = @generator.generate(15, "Add feature to ace-core module")

    assert_match(/core/, slug)
  end

  def test_generate_with_metadata_type
    slug = @generator.generate(30, "Some task title", { type: "refactor" })

    assert_match(/^030-refactor/, slug)
  end

  def test_generate_with_metadata_context
    slug = @generator.generate(20, "Task title", { component: "nav" })

    assert_match(/nav/, slug)
  end

  def test_generate_removes_noise_words
    slug = @generator.generate(5, "Add the feature for ace-llm integration")

    # Should not contain noise words like "the", "for"
    refute_match(/the/, slug)
    refute_match(/for/, slug)
  end

  def test_generate_descriptive_part_without_number
    slug = @generator.generate_descriptive_part("Fix bug in ace-context")

    assert_match(/^fix-context/, slug)
    refute_match(/^\d+/, slug)
  end

  def test_parse_slug_extracts_components
    slug = "025-feat-taskflow-idea-management"
    result = @generator.parse_slug(slug)

    assert_equal "025", result[:number]
    assert_equal "feat", result[:type]
    assert_equal "taskflow", result[:context]
    assert_equal "idea-management", result[:keywords]
  end

  def test_parse_slug_handles_minimal_slug
    slug = "042-fix"
    result = @generator.parse_slug(slug)

    assert_equal "042", result[:number]
    assert_equal "fix", result[:type]
    assert_equal "", result[:context]
  end

  def test_generate_pads_task_number
    slug = @generator.generate(5, "Feature title")

    assert_match(/^005/, slug)
  end

  def test_generate_truncates_long_keywords
    long_title = "Implement very long task title with many words that should be truncated properly"
    slug = @generator.generate(1, long_title)

    # Total slug length should be reasonable
    assert slug.length < 80
  end

  def test_generate_handles_special_characters
    slug = @generator.generate(10, "Fix: Bug #123 (urgent!)")

    # Should sanitize special characters
    refute_match(/[:#()!]/, slug)
  end

  def test_type_inference_from_keywords
    assert_match(/feat/, @generator.generate(1, "Create new component"))
    assert_match(/feat/, @generator.generate(1, "Add functionality"))
    assert_match(/fix/, @generator.generate(1, "Resolve issue"))
    assert_match(/test/, @generator.generate(1, "Add test coverage"))
  end

  def test_default_type_when_no_match
    slug = @generator.generate(1, "Random task title")

    assert_match(/task/, slug)
  end
end
