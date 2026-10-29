# frozen_string_literal: true

require_relative "../../test_helper"

module Atoms
  # Task 8xs.t.pu0.1: the start contract is explicit — scope, profile
  # reference, instructions source — and nothing is guessed.
  class StartContractTest < Minitest::Test
    def config(start_section = {"scope" => "project", "profile" => "overseer-default",
      "instructions" => "wfi://overseer/start"})
      {"start" => start_section,
       "profiles" => {"overseer-default" => {"harness" => "pi",
         "model" => "zai/glm-5.3-flash", "thinking" => "high"}}}
    end

    def test_valid_project_start_normalizes
      plan = Ace::Overseer::Atoms::StartContract.normalize(config)

      assert_equal "project", plan["scope"]
      assert_equal "overseer-default", plan["profile_name"]
      assert_equal({"harness" => "pi", "model" => "zai/glm-5.3-flash", "thinking" => "high"},
        plan["profile"])
      assert_equal "wfi://overseer/start", plan["instructions"]
    end

    def test_missing_start_section_is_an_error_before_any_session
      error = assert_raises(Ace::Overseer::Error) do
        Ace::Overseer::Atoms::StartContract.normalize({})
      end
      assert_match(/requires an explicit 'start' section/, error.message)
    end

    def test_missing_scope_profile_or_instructions_is_an_error
      [["scope", {}], ["profile", {}], ["instructions", {}]].each do |key, _|
        section = {"scope" => "project", "profile" => "overseer-default",
          "instructions" => "wfi://overseer/start"}
        section.delete(key)
        error = assert_raises(Ace::Overseer::Error) do
          Ace::Overseer::Atoms::StartContract.normalize(config(section))
        end
        assert_match(/'#{key}' is required/, error.message)
      end
    end

    def test_lab_scope_reports_the_unimplemented_capability
      error = assert_raises(Ace::Overseer::Error) do
        Ace::Overseer::Atoms::StartContract.normalize(
          config("scope" => "lab", "profile" => "overseer-default",
            "instructions" => "wfi://overseer/start")
        )
      end
      assert_match(/scope 'lab' is not implemented yet/, error.message)
    end

    def test_unknown_profile_reference_is_an_error
      error = assert_raises(Ace::Overseer::Error) do
        Ace::Overseer::Atoms::StartContract.normalize(
          config("scope" => "project", "profile" => "ghost",
            "instructions" => "wfi://overseer/start")
        )
      end
      assert_match(/profile 'ghost' is not configured/, error.message)
    end

    def test_profile_requires_harness_and_model_without_defaults
      error = assert_raises(Ace::Overseer::Error) do
        Ace::Overseer::Atoms::StartContract.normalize(
          {"start" => {"scope" => "project", "profile" => "p", "instructions" => "/abs/guide.md"},
           "profiles" => {"p" => {"thinking" => "high"}}}
        )
      end
      assert_match(/profile 'p' key 'harness' is required/, error.message)
    end

    def test_session_label_derives_from_the_project_root
      assert_equal "overseer-ace", Ace::Overseer::Atoms::StartContract.session_label("/lab/projects/ace")
    end
  end
end
