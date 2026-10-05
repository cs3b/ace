# frozen_string_literal: true
require_relative "../../test_helper"

class DeliveryParametersTest < AceAssignTestCase
  def parameters
    {"forge_server" => "forge", "pr_provenance" => {"mode" => "canonical",
      "head_repository_url" => "https://forge.example/team/repo", "head_ref" => "feature",
      "base_repository_url" => "https://forge.example/team/repo", "base_ref" => "main"}}
  end

  def validate(input = parameters)
    Ace::Assign::Atoms::DeliveryParameters.validate(input)
  end

  def test_explicit_canonical_and_fork_modes
    assert_equal "canonical", validate.dig("pr_provenance", "mode")
    p = parameters
    p["pr_provenance"].merge!("mode" => "fork", "head_repository_url" => "git@forge.example:team/fork.git")
    assert_equal "fork", validate(p).dig("pr_provenance", "mode")
  end

  def test_missing_mode_and_canonical_mismatch_fail
    p = parameters
    p["pr_provenance"].delete("mode")
    assert_raises(ArgumentError) { validate(p) }
    p = parameters
    p["pr_provenance"]["head_repository_url"] = "https://forge.example/team/fork"
    assert_raises(ArgumentError) { validate(p) }
  end

  def test_conflicting_selection_and_invalid_boolean_fail
    assert_raises(ArgumentError) { validate(parameters.merge("forge_default" => true)) }
    assert_raises(ArgumentError) { validate(parameters.merge("forge_default" => "true")) }
  end

  def test_unrecognized_fields_cannot_carry_credentials
    assert_raises(ArgumentError) { validate(parameters.merge("token" => "forbidden")) }
  end

  def test_credentials_queries_and_unsafe_refs_fail
    ["https://user:secret@forge.example/team/repo", "https://forge.example/team/repo?token=value"].each do |url|
      p = parameters
      p["pr_provenance"]["head_repository_url"] = url
      assert_raises(ArgumentError) { validate(p) }
    end
    ["--help", "refs/heads/foo..bar", "feature\nother", "@{upstream}"].each do |ref|
      p = parameters
      p["pr_provenance"]["head_ref"] = ref
      assert_raises(ArgumentError) { validate(p) }
    end
  end
end
