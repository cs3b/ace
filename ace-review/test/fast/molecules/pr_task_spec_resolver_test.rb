# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_resolver"

class PrTaskSpecResolverTest < AceReviewTest
  def test_extract_task_reference_prefers_branch_prefix
    metadata = {
      "headRefName" => "q3r-review-spec-context",
      "title" => "task 999",
      "body" => "task 888"
    }

    result = Ace::Review::Molecules::PrTaskSpecResolver.extract_task_reference(metadata)
    assert_equal "q3r", result
  end

  def test_extract_task_reference_falls_back_to_body_text
    metadata = {
      "headRefName" => "feature/review-spec-context",
      "title" => "Improvement",
      "body" => "Implements task 281.05."
    }

    result = Ace::Review::Molecules::PrTaskSpecResolver.extract_task_reference(metadata)
    assert_equal "281.05", result
  end

  def test_extract_task_reference_supports_full_task_id_in_text
    metadata = {
      "headRefName" => "feature/review-spec-context",
      "body" => "References v.0.9.0+task.281.05"
    }

    result = Ace::Review::Molecules::PrTaskSpecResolver.extract_task_reference(metadata)
    assert_equal "v.0.9.0+task.281.05", result
  end

  def test_extract_task_reference_returns_nil_when_no_match
    metadata = {
      "headRefName" => "feature/no-task-ref",
      "title" => "Improvement without task",
      "body" => "No task reference here."
    }

    result = Ace::Review::Molecules::PrTaskSpecResolver.extract_task_reference(metadata)
    assert_nil result
  end

  def test_resolve_spec_path_returns_nil_when_spec_missing
    metadata = {"headRefName" => "281.05-review-spec-context"}
    task_info = {spec_path: "/tmp/does-not-exist.s.md"}

    Ace::Review::Molecules::TaskResolver.stub(:resolve, task_info) do
      result = Ace::Review::Molecules::PrTaskSpecResolver.resolve_spec_path(metadata)
      assert_nil result
    end
  end

  def test_resolve_spec_path_returns_resolved_spec
    metadata = {"headRefName" => "281.05-review-spec-context"}
    spec_path = File.join(@test_dir, "281.05-review-spec-context.s.md")
    File.write(spec_path, "# spec")
    task_info = {spec_path: spec_path}

    Ace::Review::Molecules::TaskResolver.stub(:resolve, task_info) do
      result = Ace::Review::Molecules::PrTaskSpecResolver.resolve_spec_path(metadata)
      assert_equal spec_path, result
    end
  end
end
