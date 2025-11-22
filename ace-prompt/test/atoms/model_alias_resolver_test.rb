# frozen_string_literal: true

require "test_helper"
require "ace/prompt/atoms/model_alias_resolver"

class ModelAliasResolverTest < Ace::Prompt::TestCase
  def test_resolve_known_alias
    result = Ace::Prompt::Atoms::ModelAliasResolver.resolve("glite")

    assert_equal "google:gemini-2.0-flash-lite", result
  end

  def test_resolve_full_name_unchanged
    result = Ace::Prompt::Atoms::ModelAliasResolver.resolve("anthropic:claude-3-opus")

    assert_equal "anthropic:claude-3-opus", result
  end

  def test_alias_returns_true_for_known_alias
    assert Ace::Prompt::Atoms::ModelAliasResolver.alias?("glite")
  end

  def test_alias_returns_false_for_unknown
    refute Ace::Prompt::Atoms::ModelAliasResolver.alias?("unknown")
  end
end
