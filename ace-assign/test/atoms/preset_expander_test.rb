# frozen_string_literal: true

require_relative "../test_helper"

class PresetExpanderTest < AceAssignTestCase
  # parse_array_parameter tests

  def test_parse_array_parameter_comma_separated
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("148,149,150")

    assert_equal ["148", "149", "150"], result
  end

  def test_parse_array_parameter_comma_with_spaces
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("148, 149, 150")

    assert_equal ["148", "149", "150"], result
  end

  def test_parse_array_parameter_range
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("148-152")

    assert_equal ["148", "149", "150", "151", "152"], result
  end

  def test_parse_array_parameter_single_value
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("148")

    assert_equal ["148"], result
  end

  def test_parse_array_parameter_pattern_with_asterisk
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("240.*")

    assert_equal ["240.*"], result
  end

  def test_parse_array_parameter_pattern_with_question_mark
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("24?")

    assert_equal ["24?"], result
  end

  def test_parse_array_parameter_already_array
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter(["148", "149"])

    assert_equal ["148", "149"], result
  end

  def test_parse_array_parameter_integer_array
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter([148, 149])

    assert_equal ["148", "149"], result
  end

  def test_parse_array_parameter_nil
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter(nil)

    assert_equal [], result
  end

  def test_parse_array_parameter_empty_string
    result = Ace::Assign::Atoms::PresetExpander.parse_array_parameter("")

    assert_equal [], result
  end

  # has_expansion? tests

  def test_has_expansion_true
    preset = { "expansion" => { "foreach" => "taskrefs" } }

    assert Ace::Assign::Atoms::PresetExpander.has_expansion?(preset)
  end

  def test_has_expansion_false
    preset = { "steps" => [] }

    refute Ace::Assign::Atoms::PresetExpander.has_expansion?(preset)
  end

  # foreach_parameter tests

  def test_foreach_parameter_present
    preset = { "expansion" => { "foreach" => "taskrefs" } }

    assert_equal "taskrefs", Ace::Assign::Atoms::PresetExpander.foreach_parameter(preset)
  end

  def test_foreach_parameter_absent
    preset = { "steps" => [] }

    assert_nil Ace::Assign::Atoms::PresetExpander.foreach_parameter(preset)
  end

  # validate_parameters tests

  def test_validate_parameters_all_present
    preset = {
      "parameters" => {
        "taskrefs" => { "required" => true },
        "review_preset" => { "required" => false }
      }
    }
    params = { "taskrefs" => ["148", "149"] }

    errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)

    assert_empty errors
  end

  def test_validate_parameters_missing_required
    preset = {
      "parameters" => {
        "taskrefs" => { "required" => true }
      }
    }
    params = {}

    errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)

    assert_equal 1, errors.length
    assert_match(/taskrefs/, errors.first)
  end

  def test_validate_parameters_taskref_satisfies_required_taskrefs
    preset = {
      "parameters" => {
        "taskrefs" => { "required" => true, "type" => "array" }
      }
    }
    params = { "taskref" => "148" }

    errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)

    assert_empty errors
  end

  def test_validate_parameters_empty_array_is_missing
    preset = {
      "parameters" => {
        "taskrefs" => { "required" => true }
      }
    }
    params = { "taskrefs" => [] }

    errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)

    assert_equal 1, errors.length
  end

  def test_validate_parameters_no_parameters_section
    preset = { "steps" => [] }
    params = { "anything" => "value" }

    errors = Ace::Assign::Atoms::PresetExpander.validate_parameters(preset, params)

    assert_empty errors
  end

  # expand tests - no expansion section

  def test_expand_without_expansion_section
    preset = {
      "steps" => [
        { "name" => "step1", "instructions" => "Do {{taskref}}" },
        { "name" => "step2", "instructions" => "More work" }
      ]
    }
    params = { "taskref" => "123" }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 2, result.length
    assert_equal "Do 123", result[0]["instructions"]
    assert_equal "More work", result[1]["instructions"]
  end

  def test_expand_without_expansion_preserves_other_fields
    preset = {
      "steps" => [
        { "name" => "step1", "skill" => "as-git-commit", "instructions" => "Commit" }
      ]
    }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, {})

    assert_equal "as-git-commit", result[0]["skill"]
  end

  # expand tests - with expansion section

  def test_expand_batch_parent_only
    preset = {
      "expansion" => {
        "batch-parent" => {
          "name" => "batch-tasks",
          "number" => "010",
          "instructions" => "Container for batch work."
        }
      },
      "steps" => []
    }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, {})

    assert_equal 1, result.length
    assert_equal "010", result[0]["number"]
    assert_equal "batch-tasks", result[0]["name"]
    assert_equal "Container for batch work.", result[0]["instructions"]
  end

  def test_expand_foreach_children
    preset = {
      "expansion" => {
        "batch-parent" => {
          "name" => "batch-tasks",
          "number" => "010",
          "instructions" => "Batch container."
        },
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "context" => "fork",
          "instructions" => "Implement task {{item}}"
        }
      },
      "steps" => []
    }
    params = { "taskrefs" => ["148", "149", "150"] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 4, result.length

    # Parent step
    assert_equal "010", result[0]["number"]
    assert_equal "batch-tasks", result[0]["name"]

    # Child steps
    assert_equal "010.01", result[1]["number"]
    assert_equal "work-on-148", result[1]["name"]
    assert_equal "010", result[1]["parent"]
    assert_equal "fork", result[1]["context"]
    assert_equal "Implement task 148", result[1]["instructions"]

    assert_equal "010.02", result[2]["number"]
    assert_equal "work-on-149", result[2]["name"]

    assert_equal "010.03", result[3]["number"]
    assert_equal "work-on-150", result[3]["name"]
  end

  def test_expand_foreach_children_with_taskref_alias
    preset = {
      "expansion" => {
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "instructions" => "Implement task {{item}}"
        }
      },
      "steps" => []
    }
    params = { "taskref" => "148" }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 1, result.length
    assert_equal "work-on-148", result[0]["name"]
    assert_equal "Implement task 148", result[0]["instructions"]
  end

  def test_expand_with_base_steps_after_expansion
    preset = {
      "expansion" => {
        "batch-parent" => {
          "name" => "batch-tasks",
          "number" => "010",
          "instructions" => "Batch container."
        },
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "instructions" => "Implement task {{item}}"
        }
      },
      "steps" => [
        { "name" => "review", "number" => "020", "instructions" => "Review all: {{taskrefs}}" },
        { "name" => "finalize", "number" => "030", "instructions" => "Commit changes" }
      ]
    }
    params = { "taskrefs" => ["148", "149"] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    # 1 parent + 2 children + 2 base steps = 5
    assert_equal 5, result.length

    # Verify base steps are included with substitution
    review_step = result.find { |s| s["name"] == "review" }
    refute_nil review_step
    assert_equal "020", review_step["number"]
    assert_equal "Review all: 148, 149", review_step["instructions"]

    finalize_step = result.find { |s| s["name"] == "finalize" }
    refute_nil finalize_step
    assert_equal "030", finalize_step["number"]
  end

  def test_expand_empty_foreach_parameter
    preset = {
      "expansion" => {
        "batch-parent" => {
          "name" => "batch-tasks",
          "number" => "010",
          "instructions" => "Batch container."
        },
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "instructions" => "Implement task {{item}}"
        }
      },
      "steps" => []
    }
    params = { "taskrefs" => [] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    # Only parent step, no children
    assert_equal 1, result.length
    assert_equal "batch-tasks", result[0]["name"]
  end

  def test_expand_with_skill_in_child_template
    preset = {
      "expansion" => {
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "skill" => "as-task-work",
          "instructions" => "Work on {{item}}"
        }
      },
      "steps" => []
    }
    params = { "taskrefs" => ["148"] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 1, result.length
    assert_equal "as-task-work", result[0]["skill"]
  end

  def test_expand_substitutes_placeholders_in_non_instruction_fields
    preset = {
      "expansion" => {
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "work-on-{{item}}",
          "parent" => "010",
          "skill" => "as-task-work",
          "taskref" => "{{item}}",
          "metadata" => {
            "label" => "task-{{item}}"
          },
          "instructions" => [
            "Implement task {{item}}",
            "Report taskref {{item}}"
          ]
        }
      },
      "steps" => []
    }
    params = { "taskrefs" => ["235.01"] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 1, result.length
    assert_equal "235.01", result[0]["taskref"]
    assert_equal "task-235.01", result[0].dig("metadata", "label")
    assert_equal ["Implement task 235.01", "Report taskref 235.01"], result[0]["instructions"]
  end

  def test_expand_array_instructions
    preset = {
      "steps" => [
        {
          "name" => "step1",
          "instructions" => [
            "Load task {{taskref}}",
            "Review requirements"
          ]
        }
      ]
    }
    params = { "taskref" => "123" }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal ["Load task 123", "Review requirements"], result[0]["instructions"]
  end

  def test_expand_child_numbering_sequence
    preset = {
      "expansion" => {
        "foreach" => "items",
        "child-template" => {
          "name" => "item-{{item}}",
          "parent" => "020",
          "instructions" => "Process {{item}}"
        }
      },
      "steps" => []
    }
    # Test with many items to verify numbering format
    params = { "items" => (1..12).map(&:to_s) }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal 12, result.length
    assert_equal "020.01", result[0]["number"]
    assert_equal "020.09", result[8]["number"]
    assert_equal "020.10", result[9]["number"]
    assert_equal "020.12", result[11]["number"]
  end

  def test_expand_parameter_substitution_in_batch_parent
    preset = {
      "expansion" => {
        "batch-parent" => {
          "name" => "work-on-{{project}}",
          "number" => "010",
          "instructions" => "Working on project {{project}} tasks: {{taskrefs}}"
        },
        "foreach" => "taskrefs",
        "child-template" => {
          "name" => "task-{{item}}",
          "parent" => "010",
          "instructions" => "Task {{item}}"
        }
      },
      "steps" => []
    }
    params = { "project" => "ace", "taskrefs" => ["1", "2"] }

    result = Ace::Assign::Atoms::PresetExpander.expand(preset, params)

    assert_equal "work-on-ace", result[0]["name"]
    assert_equal "Working on project ace tasks: 1, 2", result[0]["instructions"]
  end
end
