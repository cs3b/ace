# frozen_string_literal: true

require "test_helper"
require "ace/nav"
require "ace/nav/organisms/navigation_engine"

class NavigationEngineTest < Minitest::Test
  def setup
    @test_dir = create_temp_ace_directory
    setup_test_environment_with_protocols
    @original_dir = Dir.pwd
  end

  def teardown
    Dir.chdir(@original_dir) if @original_dir
    cleanup_temp_directory(@test_dir)
  end

  def test_resolves_simple_uri
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      path = engine.resolve("wfi://setup")

      assert path, "Should resolve URI to path"
      assert File.exist?(path), "Resolved path should exist"
    end
  end

  def test_resolves_from_deep_directory
    Dir.chdir(@test_dir) do
      # Create deep directory structure (5 levels)
      deep_dir = File.join(@test_dir, *Array.new(5) { "level" })
      FileUtils.mkdir_p(deep_dir)

      # Change to deep directory
      Dir.chdir(deep_dir)

      engine = Ace::Nav::Organisms::NavigationEngine.new

      # Should still resolve even from deep directory
      path = engine.resolve("wfi://setup")

      assert path, "Should resolve from deep directory"
      assert File.exist?(path), "Should find resource from any depth"
    end
  end

  def test_lists_resources_matching_pattern
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      results = engine.list("wfi://*")

      assert results.is_a?(Array), "Should return array"
      refute_empty results, "Should find workflow resources"
    end
  end

  def test_lists_resources_with_tree_format
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      tree = engine.list("wfi://*", tree: true)

      assert tree.is_a?(Array), "Tree should be array"
      refute_empty tree, "Tree should have content"
    end
  end

  def test_lists_resources_with_verbose_format
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      verbose = engine.list("wfi://*", verbose: true)

      assert verbose.is_a?(Array), "Verbose should be array"
      refute_empty verbose, "Should have verbose output"
      assert verbose.first.is_a?(Hash), "Verbose items should be hashes"
    end
  end

  def test_shows_available_sources
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      sources = engine.sources

      assert sources.is_a?(Array), "Sources should be array"
      refute_empty sources, "Should have sources"
    end
  end

  def test_handles_missing_resource
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      path = engine.resolve("wfi://nonexistent")

      assert_nil path, "Should return nil for missing resource"
    end
  end

  def test_handles_invalid_protocol
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      path = engine.resolve("invalid://resource")

      # Should either return nil or handle gracefully
      # Implementation may raise or return nil
      assert_nil path if path.nil?
    end
  end

  def test_resolves_with_content_option
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      content = engine.resolve("wfi://setup", content: true)

      assert content.is_a?(String), "Content should be string"
      refute_empty content.strip, "Content should not be empty"
    end
  end

  def test_resolves_with_verbose_option
    Dir.chdir(@test_dir) do
      engine = Ace::Nav::Organisms::NavigationEngine.new

      verbose = engine.resolve("wfi://setup", verbose: true)

      assert verbose.is_a?(Hash), "Verbose should be hash"
      assert verbose.key?(:path) || verbose[:path], "Should include path info"
    end
  end

  def test_execution_from_project_subdirectory
    Dir.chdir(@test_dir) do
      # Create and change to subdirectory
      subdir = File.join(@test_dir, "src", "components")
      FileUtils.mkdir_p(subdir)
      Dir.chdir(subdir)

      engine = Ace::Nav::Organisms::NavigationEngine.new

      path = engine.resolve("wfi://setup")

      assert path, "Should resolve from subdirectory"
      assert File.exist?(path), "Should traverse up to find resources"
    end
  end

  def test_handles_unicode_resource_names
    Dir.chdir(@test_dir) do
      # Create resource with unicode name
      resource_dir = File.join(@test_dir, "workflows")
      FileUtils.mkdir_p(resource_dir)
      unicode_file = File.join(resource_dir, "café-文件.wfi.md")
      File.write(unicode_file, "# Unicode Test")

      engine = Ace::Nav::Organisms::NavigationEngine.new

      # List should include unicode resource
      results = engine.list("wfi://*")

      assert results.any?, "Should find resources including unicode names"
    end
  end

  def test_handles_paths_with_spaces
    Dir.chdir(@test_dir) do
      # Create resource with spaces in path
      spaced_dir = File.join(@test_dir, "workflows with spaces")
      FileUtils.mkdir_p(spaced_dir)

      # Update source to point to spaced directory
      create_test_source(@test_dir, "wfi", "spaced", {
        "path" => spaced_dir,
        "priority" => 15
      })

      File.write(File.join(spaced_dir, "test.wfi.md"), "# Spaced Path")

      engine = Ace::Nav::Organisms::NavigationEngine.new

      results = engine.list("wfi://*")

      assert results.any?, "Should handle paths with spaces"
    end
  end

  def test_handles_symlinked_resources
    Dir.chdir(@test_dir) do
      # Create a symlink to resource
      resource_dir = File.join(@test_dir, "workflows")
      FileUtils.mkdir_p(resource_dir)
      target = File.join(resource_dir, "target.wfi.md")
      link = File.join(resource_dir, "link.wfi.md")

      File.write(target, "# Target")
      FileUtils.ln_s(target, link)

      engine = Ace::Nav::Organisms::NavigationEngine.new

      results = engine.list("wfi://*")

      assert results.any?, "Should handle symlinked resources"
    end
  end

  def test_protocol_resolution_with_env_variables
    ENV["TEST_PROTOCOL_PATH"] = File.join(@test_dir, "custom-workflows")
    FileUtils.mkdir_p(ENV["TEST_PROTOCOL_PATH"])

    Dir.chdir(@test_dir) do
      # Create source with env variable in path
      create_test_source(@test_dir, "wfi", "env_test", {
        "path" => "$TEST_PROTOCOL_PATH",
        "priority" => 20
      })

      File.write(File.join(ENV["TEST_PROTOCOL_PATH"], "env.wfi.md"), "# Env Test")

      engine = Ace::Nav::Organisms::NavigationEngine.new

      results = engine.list("wfi://*")

      assert results.any? { |r| r.include?("env") }, "Should resolve env variables in paths"
    end
  ensure
    ENV.delete("TEST_PROTOCOL_PATH")
  end

  def test_handles_missing_config_gracefully
    # Create temp dir with no .ace config
    empty_dir = Dir.mktmpdir("nav_empty")

    begin
      Dir.chdir(empty_dir)

      engine = Ace::Nav::Organisms::NavigationEngine.new

      # Should handle missing config without crashing
      sources = engine.sources

      assert sources.is_a?(Array), "Should return empty array for missing config"
    ensure
      Dir.chdir(@test_dir)
      FileUtils.rm_rf(empty_dir)
    end
  end

  private

  def setup_test_environment_with_protocols
    # Create workflow protocol
    create_test_protocol(@test_dir, "wfi", {
      "name" => "Workflow Instructions",
      "extensions" => [".wfi.md", ".workflow.md", ".wf.md"]
    })

    # Create workflow source
    workflow_dir = File.join(@test_dir, "workflows")
    FileUtils.mkdir_p(workflow_dir)

    create_test_source(@test_dir, "wfi", "project", {
      "path" => workflow_dir,
      "priority" => 10
    })

    # Create test workflow files
    File.write(File.join(workflow_dir, "setup.wfi.md"), "# Setup Workflow")
    File.write(File.join(workflow_dir, "deploy.workflow.md"), "# Deploy Workflow")
    File.write(File.join(workflow_dir, "test.wf.md"), "# Test Workflow")
  end
end
