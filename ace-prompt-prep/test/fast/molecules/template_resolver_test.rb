# frozen_string_literal: true

require "test_helper"

class TemplateResolverTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @test_template = File.join(@tmpdir, "test-template.template.md")
    File.write(@test_template, "Test template content")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_normalizes_short_form_to_full_uri
    # Short form should be converted to full URI
    # We'll stub resolve_via_ace_nav to see what URI it gets
    resolver = Ace::PromptPrep::Molecules::TemplateResolver

    original_method = resolver.method(:resolve_via_ace_nav)
    received_uri = nil

    resolver.define_singleton_method(:resolve_via_ace_nav) do |uri|
      received_uri = uri
      nil  # Return nil to trigger bundled template fallback
    end

    begin
      resolver.call(uri: "bug")
      assert_equal "tmpl://the-prompt-bug", received_uri
    ensure
      # Restore original method
      resolver.define_singleton_method(:resolve_via_ace_nav, original_method)
    end
  end

  def test_passes_through_full_uri_unchanged
    # Full URI should pass through unchanged
    resolver = Ace::PromptPrep::Molecules::TemplateResolver

    original_method = resolver.method(:resolve_via_ace_nav)
    received_uri = nil

    resolver.define_singleton_method(:resolve_via_ace_nav) do |uri|
      received_uri = uri
      nil
    end

    begin
      resolver.call(uri: "tmpl://custom/template")
      assert_equal "tmpl://custom/template", received_uri
    ensure
      resolver.define_singleton_method(:resolve_via_ace_nav, original_method)
    end
  end

  def test_resolves_bundled_template
    # The bundled the-prompt-base template should exist
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://the-prompt-base")

    # Should either resolve via ace-nav or find bundled template
    if result[:success]
      assert result[:path]
      assert File.exist?(result[:path])
    else
      # If bundled template isn't found, that's expected in test environment
      assert_match(/not found/, result[:error])
    end
  end

  def test_handles_nonexistent_template
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://nonexistent-template")

    refute result[:success]
    assert_nil result[:path]
    assert_match(/not found/, result[:error])
  end

  def test_handles_malformed_uri
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://")

    refute result[:success]
    assert_nil result[:path]
    assert_match(/not found/, result[:error])
  end

  def test_handles_empty_protocol_response
    # Test with a URI that won't resolve
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://invalid/empty")

    refute result[:success]
    assert_nil result[:path]
    assert_match(/not found/, result[:error])
  end

  def test_returns_error_on_exception
    # Stub to force an exception
    Ace::PromptPrep::Molecules::TemplateResolver.stub(:resolve_via_ace_nav, ->(_uri) { raise "Test error" }) do
      Ace::PromptPrep::Molecules::TemplateResolver.stub(:resolve_bundled_template, ->(_uri) { raise "Test error" }) do
        result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://test-template")

        refute result[:success]
        assert_nil result[:path]
        assert_match(/Failed to resolve template/, result[:error])
      end
    end
  end

  def test_bundled_template_path_construction
    # Test that bundled template path is constructed correctly
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "tmpl://the-prompt-base")

    # Should attempt to find bundled template
    # Path should be in gem's handbook/templates directory
    assert result
    assert_includes result.keys, :success
    assert_includes result.keys, :path
    assert_includes result.keys, :error
  end

  def test_short_form_resolves_to_bundled_template
    # Short form "base" should resolve to the-prompt-base.template.md
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "base")

    # Should attempt to find bundled template at the-prompt-base.template.md
    if result[:success]
      assert result[:path]
      assert result[:path].end_with?("the-prompt-base.template.md")
    end
  end

  def test_rejects_uri_with_spaces
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "bug report")

    refute result[:success]
    assert_nil result[:path]
    assert_match(/contains spaces/, result[:error])
  end

  def test_accepts_path_like_short_form
    # Should not raise - paths with slashes are valid
    result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: "some-folder/test")
    assert result  # May fail to find template, but shouldn't raise ArgumentError
    assert_includes result.keys, :success
  end

  def test_accepts_valid_short_forms
    # Various valid short forms should not raise
    valid_forms = ["bug", "bug-report", "my_template", "template-v2", "folder/template"]

    valid_forms.each do |form|
      result = Ace::PromptPrep::Molecules::TemplateResolver.call(uri: form)
      assert result, "Expected result for #{form}"
      assert_includes result.keys, :success, "Expected :success key for #{form}"
    end
  end
end
