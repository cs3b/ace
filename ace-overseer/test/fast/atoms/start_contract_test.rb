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

    def test_missing_start_section_bootstraps_the_lab_with_the_approved_profile
      plan = Ace::Overseer::Atoms::StartContract.normalize({})
      assert_equal "lab", plan["scope"]
      assert_equal "wfi://overseer/lab-start", plan["instructions"]
      assert_equal({"harness" => "pi", "model" => "zai/glm-5.3-flash", "thinking" => "high"}, plan["profile"])
    end

    def test_bootstrap_for_a_child_project_has_project_scope
      config = Ace::Overseer::Atoms::StartContract.bootstrap({}, scope: "project")
      plan = Ace::Overseer::Atoms::StartContract.normalize(config)
      assert_equal "project", plan["scope"]
      assert_equal "wfi://overseer/start", plan["instructions"]
    end

    def test_explicit_invalid_configuration_never_falls_back_to_bootstrap
      assert_raises(Ace::Overseer::Error) { Ace::Overseer::Atoms::StartContract.normalize({"start" => nil}) }
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

    def test_lab_scope_is_a_valid_scope_for_the_lab_start
      plan = Ace::Overseer::Atoms::StartContract.normalize(
        config("scope" => "lab", "profile" => "overseer-default",
          "instructions" => "wfi://overseer/lab-start")
      )

      assert_equal "lab", plan["scope"]
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
