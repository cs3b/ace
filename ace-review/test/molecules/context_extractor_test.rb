# frozen_string_literal: true

require "test_helper"

class ContextExtractorTest < AceReviewTest
  def setup
    @extractor = Ace::Review::Molecules::ContextExtractor.new
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  # Helper to create mock ace-bundle result
  def mock_bundle_result(content = "Mock context content")
    mock = Minitest::Mock.new
    mock.expect(:content, content)
    mock
  end

  # Helper to stub ContextComposer.load_context_via_ace_bundle for cache_dir tests
  def with_mocked_ace_bundle_loading(content = "Mocked bundle content")
    Ace::Review::Molecules::ContextComposer.stub(:load_context_via_ace_bundle, content) do
      yield
    end
  end

  # Helper to stub Ace::Bundle.load_auto for non-cache tests
  def with_mocked_ace_bundle_auto(content = "Mocked bundle content")
    mock = mock_bundle_result(content)
    Ace::Bundle.stub(:load_auto, mock) do
      yield
    end
  end

  def test_extract_none_returns_empty_string
    result = @extractor.extract(nil)
    assert_equal "", result

    result = @extractor.extract("none")
    assert_equal "", result

    result = @extractor.extract(false)
    assert_equal "", result
  end

  def test_extract_project_context_without_cache_dir
    # Create some mock project docs
    readme_path = File.join(@temp_dir, "README.md")
    File.write(readme_path, "# Test Project")

    Dir.chdir(@temp_dir) do
      result = @extractor.extract("project")
      # ace-bundle loads from actual project root, not test dir
      # Just verify we got some content
      refute_empty result
      assert_match(/Context|Metadata|ACE/, result)
    end
  end

  def test_extract_project_context_with_cache_dir
    # Create some mock project docs
    readme_path = File.join(@temp_dir, "README.md")
    File.write(readme_path, "# Test Project")

    cache_dir = File.join(@temp_dir, "cache")
    FileUtils.mkdir_p(cache_dir)

    Dir.chdir(@temp_dir) do
      result = @extractor.extract("project", cache_dir)
      # ace-bundle loads from actual project root, not test dir
      # Just verify we got some content
      refute_empty result
      assert_match(/Context|ACE|files/, result)

      # Verify context.md was created
      context_file = File.join(cache_dir, "context.md")
      assert File.exist?(context_file)

      context_content = File.read(context_file)
      assert_match(/^---\nbundle:/, context_content)
    end
  end

  def test_extract_from_string_yaml_config
    yaml_config = {
      "files" => ["test.rb"],
      "presets" => ["project"]
    }.to_yaml

    result = @extractor.extract(yaml_config)
    refute_empty result
  end

  def test_extract_from_string_yaml_config_with_cache
    yaml_config = {
      "files" => ["test.rb"],
      "presets" => ["project"]
    }.to_yaml

    cache_dir = File.join(@temp_dir, "cache")
    FileUtils.mkdir_p(cache_dir)

    # Mock ace-bundle loading to avoid slow real project context loading
    with_mocked_ace_bundle_loading("Mocked YAML config context") do
      result = @extractor.extract(yaml_config, cache_dir)
      assert_equal "Mocked YAML config context", result

      # Verify context.md was created (file creation is not mocked)
      context_file = File.join(cache_dir, "context.md")
      assert File.exist?(context_file)
    end
  end

  def test_extract_from_string_file_path
    # Create a test file
    test_file = File.join(@temp_dir, "test.rb")
    File.write(test_file, "class Test; end")

    Dir.chdir(@temp_dir) do
      result = @extractor.extract("test.rb")
      refute_empty result
    end
  end

  def test_extract_from_string_file_path_with_cache
    # Create a test file
    test_file = File.join(@temp_dir, "test.rb")
    File.write(test_file, "class Test; end")

    cache_dir = File.join(@temp_dir, "cache")
    FileUtils.mkdir_p(cache_dir)

    Dir.chdir(@temp_dir) do
      result = @extractor.extract("test.rb", cache_dir)
      refute_empty result

      # Verify context.md was created
      context_file = File.join(cache_dir, "context.md")
      assert File.exist?(context_file)
    end
  end

  def test_extract_from_hash_config
    config = {
      "files" => ["test.rb"],
      "presets" => ["project"]
    }

    result = @extractor.extract(config)
    refute_empty result
  end

  def test_extract_from_hash_config_with_cache
    config = {
      "files" => ["test.rb"],
      "presets" => ["project"]
    }

    cache_dir = File.join(@temp_dir, "cache")
    FileUtils.mkdir_p(cache_dir)

    # Mock ace-bundle loading to avoid slow real project context loading
    with_mocked_ace_bundle_loading("Mocked hash config context") do
      result = @extractor.extract(config, cache_dir)
      assert_equal "Mocked hash config context", result

      # Verify context.md was created (file creation is not mocked)
      context_file = File.join(cache_dir, "context.md")
      assert File.exist?(context_file)

      # Verify context.md content structure (ContextComposer still runs)
      context_content = File.read(context_file)
      assert_match(/^---\nbundle:/, context_content)
      assert_match(/files:\s*\n\s*- test\.rb/, context_content)
      assert_match(/presets:\s*\n\s*- project/, context_content)
    end
  end

  def test_extract_with_preset_context
    # Mock preset manager to return context
    preset_manager_mock = Minitest::Mock.new
    preset_manager_mock.expect(:load_preset, { "bundle" => { "files" => ["test.rb"] } }, ["test-preset"])

    @extractor.instance_variable_set(:@preset_manager, preset_manager_mock)

    result = @extractor.extract("test-preset")
    refute_empty result

    preset_manager_mock.verify
  end

  def test_extract_with_preset_reference_in_hash
    # Mock preset manager to return context
    preset_manager_mock = Minitest::Mock.new
    preset_manager_mock.expect(:load_preset, { "bundle" => { "files" => ["test.rb"] } }, ["test-preset"])

    @extractor.instance_variable_set(:@preset_manager, preset_manager_mock)

    config = { "preset" => "test-preset" }
    result = @extractor.extract(config)
    refute_empty result

    preset_manager_mock.verify
  end

  def test_extract_raises_error_on_context_composer_failure
    # Mock ContextComposer to raise an error
    Ace::Review::Molecules::ContextComposer.stub(:create_context_md, ->(*) {
      raise Ace::Review::Errors::ContextComposerError, "Mock error"
    }) do
      config = { "files" => ["test.rb"] }

      error = assert_raises(Ace::Review::Molecules::ContextExtractor::ContextExtractorError) do
        @extractor.extract(config, @temp_dir)
      end

      assert_match(/Context extraction failed: Mock error/, error.message)
    end
  end

  def test_extract_with_ace_bundle_preset
    # Mock ace-bundle preset check
    @extractor.stub(:ace_bundle_preset_exists?, true) do
      # Mock ace-bundle loading
      ace_bundle_result_mock = Minitest::Mock.new
      ace_bundle_result_mock.expect(:content, "Mock context content")

      Ace::Bundle.stub(:load_auto, ace_bundle_result_mock) do
        result = @extractor.extract("mock-preset")
        assert_equal "Mock context content", result
      end
    end
  end

  def test_extract_with_empty_config
    result = @extractor.extract({})
    refute_empty result
  end

  def test_extract_with_falsey_values
    result = @extractor.extract(false)
    assert_equal "", result

    result = @extractor.extract(nil)
    assert_equal "", result

    result = @extractor.extract("none")
    assert_equal "", result
  end

  def test_backward_compatibility_without_cache_dir
    # Test that existing code works without cache_dir parameter
    config = { "files" => ["test.rb"] }

    result = @extractor.extract(config)
    refute_empty result
  end

  # Tests for default_project_docs and config loading (ADR-022 compliance)
  def test_default_project_docs_matches_config_file
    # Load the actual config file to verify fallback matches
    # __dir__ is test/molecules, so ../.. gets to ace-review gem root
    gem_root = File.expand_path("../..", __dir__)
    config_path = File.join(gem_root, ".ace-defaults/review/config.yml")
    config = YAML.safe_load_file(config_path)
    config_docs = config["project_docs"]

    # Get the fallback defaults via the private method
    fallback_docs = @extractor.send(:default_project_docs)

    assert_equal config_docs, fallback_docs,
      "Fallback default_project_docs should match .ace-defaults/review/config.yml project_docs"
  end

  def test_extract_project_context_uses_config_when_available
    # Verify the config-based loading path (success path)
    Ace::Review.stub(:get, ->(key) { %w[README.md docs/vision.md] if key == "project_docs" }) do
      Dir.chdir(@temp_dir) do
        # Create files that match config
        File.write(File.join(@temp_dir, "README.md"), "# Test")
        FileUtils.mkdir_p(File.join(@temp_dir, "docs"))
        File.write(File.join(@temp_dir, "docs/vision.md"), "# Vision")

        result = @extractor.extract("project")
        refute_empty result
      end
    end
  end

  def test_extract_project_context_uses_fallback_when_config_unavailable
    # Verify the fallback path (failure path)
    Ace::Review.stub(:get, ->(_key) { nil }) do
      Dir.chdir(@temp_dir) do
        # Create README.md which is in fallback defaults
        File.write(File.join(@temp_dir, "README.md"), "# Test Project")

        result = @extractor.extract("project")
        refute_empty result
      end
    end
  end

  def test_default_project_docs_includes_vision_md
    # Specific check that vision.md is included (after consolidation)
    fallback_docs = @extractor.send(:default_project_docs)
    assert_includes fallback_docs, "docs/vision.md",
      "Fallback should include docs/vision.md (consolidated from philosophy + what-do-we-build)"
  end
end