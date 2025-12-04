# frozen_string_literal: true

require_relative "../test_helper"

class CachePathResolverTest < ModelsDevTestCase
  def test_resolve_returns_string
    result = Ace::LLM::ModelsDev::Atoms::CachePathResolver.resolve
    assert_kind_of String, result
  end

  def test_resolve_includes_gem_name
    result = Ace::LLM::ModelsDev::Atoms::CachePathResolver.resolve
    assert_includes result, "ace-llm-models-dev"
  end

  def test_resolve_uses_xdg_cache_home_when_set
    original = ENV["XDG_CACHE_HOME"]
    ENV["XDG_CACHE_HOME"] = "/custom/cache"

    result = Ace::LLM::ModelsDev::Atoms::CachePathResolver.resolve
    assert_equal "/custom/cache/ace-llm-models-dev", result
  ensure
    if original
      ENV["XDG_CACHE_HOME"] = original
    else
      ENV.delete("XDG_CACHE_HOME")
    end
  end

  def test_resolve_uses_home_cache_when_xdg_not_set
    original = ENV["XDG_CACHE_HOME"]
    ENV.delete("XDG_CACHE_HOME")

    result = Ace::LLM::ModelsDev::Atoms::CachePathResolver.resolve
    expected = File.join(Dir.home, ".cache", "ace-llm-models-dev")
    assert_equal expected, result
  ensure
    ENV["XDG_CACHE_HOME"] = original if original
  end
end
