# frozen_string_literal: true

require_relative "../../test_helper"
require "yaml"

class IterativeReviewPresetTest < AceAssignTestCase
  ROOT = File.expand_path("../../../.ace-defaults/assign", __dir__)

  def test_pr_delivery_presets_use_one_iterative_review_step_after_code_changes
    %w[work-on-task work-on-task-auto-merge work-on-task-ace-development fix-bug].each do |name|
      preset = YAML.safe_load_file(File.join(ROOT, "presets", "#{name}.yml"))
      steps = preset.fetch("steps")
      create_pr = steps.find { |step| step["name"] == "create-pr" }
      assert_includes Array(create_pr.fetch("instructions")).join(" "), "--draft", name
      reviews = steps.select { |step| step["workflow"] == "wfi://review/pr" }
      assert_equal 1, reviews.length, name
      assert_operator steps.index(reviews.first), :>, steps.index { |step| step["name"] == "create-pr" }, name
      ready_index = steps.index { |step| step["name"] == "mark-pr-ready" }
      assert_operator ready_index, :>, steps.index(reviews.first), name
      update_index = steps.index { |step| step["name"] == "update-pr-desc" }
      assert_operator update_index, :>, steps.index(reviews.first), name
      assert_operator ready_index, :>, update_index, name
      task_done = steps.index { |step| %w[mark-tasks-done mark-task-done].include?(step["name"]) }
      refute_nil task_done, name
      assert_operator steps.index(reviews.first), :>, task_done, name
      retro = steps.index { |step| step["name"] == "create-retro" }
      assert_operator steps.index(reviews.first), :>, retro, name if retro
      merge = steps.index { |step| step["name"] == "auto-merge" }
      assert_operator merge, :>, steps.index(reviews.first), name if merge
      refute steps.any? { |step| step["name"].to_s.match?(/review-(valid|fit|shine)-/) }, name
      refute steps.drop(steps.index(reviews.first) + 1).any? { |step| step["name"].to_s.start_with?("apply-feedback") }, name
    end
  end

  def test_pr_recipes_delegate_rounds_to_one_shared_workflow
    %w[implement-with-pr batch-tasks fix-and-review].each do |name|
      recipe = YAML.safe_load_file(File.join(ROOT, "catalog", "recipes", "#{name}.recipe.yml"))
      review = recipe.fetch("steps").find { |step| step["name"] == "review-pr" }
      assert_equal "wfi://review/pr", review.fetch("workflow"), name
      create = recipe.fetch("steps").find { |step| step["name"] == "create-pr" }
      assert_includes create.fetch("instructions_template"), "--draft", name
      ready = recipe.fetch("steps").find { |step| step["name"] == "mark-pr-ready" }
      assert ready.fetch("required"), name
      assert_operator recipe.fetch("steps").index(ready), :>, recipe.fetch("steps").index(review), name
      update = recipe.fetch("steps").find { |step| step["name"] == "update-pr-desc" }
      assert update.fetch("required"), name
      assert_operator recipe.fetch("steps").index(update), :>, recipe.fetch("steps").index(review), name
      assert_operator recipe.fetch("steps").index(ready), :>, recipe.fetch("steps").index(update), name
      if name == "implement-with-pr"
        demo = recipe.fetch("steps").find { |step| step["name"] == "record-demo" }
        assert_operator recipe.fetch("steps").index(review), :>, recipe.fetch("steps").index(demo)
      end
      refute recipe.fetch("steps").any? { |step| step["name"] == "review-cycle" }, name
    end
  end

  def test_work_on_task_refreshes_pr_description_after_final_review
    preset = YAML.safe_load_file(File.join(ROOT, "presets", "work-on-task.yml"))
    steps = preset.fetch("steps")
    review_index = steps.index { |step| step["workflow"] == "wfi://review/pr" }
    update_index = steps.index { |step| step["name"] == "update-pr-desc" }
    assert_operator update_index, :>, review_index
    assert_operator steps[update_index].fetch("number").to_i, :>, steps[review_index].fetch("number").to_i
  end

  def test_auto_merge_preset_marks_pr_ready_after_review_and_before_merge
    preset = YAML.safe_load_file(File.join(ROOT, "presets", "work-on-task-auto-merge.yml"))
    steps = preset.fetch("steps")
    review_index = steps.index { |step| step["workflow"] == "wfi://review/pr" }
    ready_index = steps.index { |step| step["name"] == "mark-pr-ready" }
    merge_index = steps.index { |step| step["name"] == "auto-merge" }

    assert_operator ready_index, :>, review_index
    assert_operator merge_index, :>, ready_index
    assert_includes Array(steps[ready_index]["instructions"]).join(" "), "gh pr ready"
  end
end
