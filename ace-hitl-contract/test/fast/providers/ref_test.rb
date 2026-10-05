# frozen_string_literal: true

require "test_helper"
require "ace/hitl/contract"

class RefTest < AceHitlContractTestCase
  Ref = Ace::Hitl::Providers::Ref
  Invalid = Ace::Hitl::Providers::InvalidRefError

  def test_native_pairs_are_exact_and_normalized_at_direct_and_environment_boundaries
    [["$0", "%0"], ["$12", "%345"], ["$#{'1' * 127}", "%#{'2' * 127}"]].each do |session, pane|
      direct = Ref.new(session: " #{session} ", pane: " #{pane} ")
      assert_equal [session, pane], [direct.session, direct.pane]
      environmental = Ref.from_env("HERDR_SESSION" => " #{session} ", "HERDR_PANE" => " #{pane} ")
      assert_equal direct.to_h, environmental.to_h
    end
    assert_equal({schema: Ref::SCHEMA, session: "s1", pane: "p1"}, Ref.new(session: " s1 ", pane: " p1 ").to_h)
  end

  def test_all_pair_entrypoints_refuse_malformed_and_mixed_fields
    pairs = [["$0", "p1"], ["s1", "%0"], ["%0", "$0"], ["$", "%0"], ["$0", "%"],
      ["$01", "%0"], ["$0", "%01"], ["$-1", "%0"], ["$0", "%-1"], ["$0", "@0"],
      ["$0;cmd", "%0"], ["$0", "%0/foo"], ["$#{'1' * 128}", "%0"], ["$0", "%#{'1' * 128}"],
      [1, "p1"], ["s1", 2], [nil, "p1"], ["s1", nil], ["$0", "% 0"], ["s1", "p$ane"],
      ["s1".encode(Encoding::UTF_16LE), "p1"], ["s1", "p1".encode(Encoding::UTF_16BE)]]
    pairs.each do |session, pane|
      assert_raises(Invalid, "direct #{[session, pane].inspect}") { Ref.new(session: session, pane: pane) }
      assert_raises(Invalid, "environment #{[session, pane].inspect}") do
        Ref.from_env("HERDR_SESSION" => session, "HERDR_PANE" => pane)
      end
    end
  end

  def test_diagnostic_labels_never_select_field_semantics
    assert_raises(Invalid) do
      Ref.new(session: "%0", pane: "$0", session_source: "pane", pane_source: "session")
    end
    ref = Ref.new(session: "$0", pane: "%0", session_source: "anything", pane_source: "unrelated")
    assert_equal ["$0", "%0"], [ref.session, ref.pane]
  end

  def test_from_env_returns_stripped_ref
    ref = with_env("HERDR_SESSION" => " w692-lab ", "HERDR_PANE" => "agent-3") do
      Ace::Hitl::Providers::Ref.from_env
    end

    assert_equal "w692-lab", ref.session
    assert_equal "agent-3", ref.pane
  end

  def test_to_h_is_versioned_schema_shape
    ref = Ace::Hitl::Providers::Ref.new(session: "s1", pane: "p2")

    assert_equal(
      {schema: "ace.hitl.ref/v1", session: "s1", pane: "p2"},
      ref.to_h
    )
  end

  def test_missing_session_fails_closed_naming_the_variable
    error = assert_raises(Ace::Hitl::Providers::InvalidRefError) do
      with_env("HERDR_SESSION" => nil, "HERDR_PANE" => "p2") do
        Ace::Hitl::Providers::Ref.from_env
      end
    end

    assert_match(/HERDR_SESSION is required/, error.message)
  end

  def test_missing_pane_fails_closed_naming_the_variable
    error = assert_raises(Ace::Hitl::Providers::InvalidRefError) do
      with_env("HERDR_SESSION" => "s1", "HERDR_PANE" => nil) do
        Ace::Hitl::Providers::Ref.from_env
      end
    end

    assert_match(/HERDR_PANE is required/, error.message)
  end

  def test_whitespace_only_values_fail_closed
    error = assert_raises(Ace::Hitl::Providers::InvalidRefError) do
      with_env("HERDR_SESSION" => "   ", "HERDR_PANE" => "p2") do
        Ace::Hitl::Providers::Ref.from_env
      end
    end

    assert_match(/HERDR_SESSION is required/, error.message)
  end

  def test_overlong_value_fails_closed
    error = assert_raises(Ace::Hitl::Providers::InvalidRefError) do
      with_env("HERDR_SESSION" => "a" * 129, "HERDR_PANE" => "p2") do
        Ace::Hitl::Providers::Ref.from_env
      end
    end

    assert_match(/HERDR_SESSION exceeds 128 characters/, error.message)
  end

  def test_invalid_characters_fail_closed
    ["bad token", "sess;ion", "p$ane", "pa/ne"].each do |bad|
      error = assert_raises(Ace::Hitl::Providers::InvalidRefError) do
        with_env("HERDR_SESSION" => "s1", "HERDR_PANE" => bad) do
          Ace::Hitl::Providers::Ref.from_env
        end
      end

      assert_match(/HERDR_PANE contains invalid characters/, error.message)
    end
  end

  def test_max_length_boundary_value_is_accepted
    ref = with_env("HERDR_SESSION" => "a" * 128, "HERDR_PANE" => ":" * 128) do
      Ace::Hitl::Providers::Ref.from_env
    end

    assert_equal "a" * 128, ref.session
    assert_equal ":" * 128, ref.pane
  end

  def test_all_token_punctuation_is_accepted
    ref = with_env("HERDR_SESSION" => "W692.lab_1", "HERDR_PANE" => "agent:3-x_9.y") do
      Ace::Hitl::Providers::Ref.from_env
    end

    assert_equal "W692.lab_1", ref.session
    assert_equal "agent:3-x_9.y", ref.pane
  end
end
