# frozen_string_literal: true

require "test_helper"
require "ace/core/atoms/path_expander"
require "tmpdir"
require "fileutils"

class PathExpanderNavIntegrationTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @project_root = File.join(@tmpdir, "project")
    @source_dir = File.join(@project_root, ".ace")
    @workflows_dir = File.join(@project_root, "handbook", "workflow-instructions")

    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(@workflows_dir)
    FileUtils.mkdir_p(File.join(@project_root, ".git"))

    # Create a test workflow file
    @workflow_file = File.join(@workflows_dir, "test-workflow.wf.md")
    File.write(@workflow_file, "# Test Workflow\nContent here")

    # Clear any registered protocol resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
  end

  # === Integration Tests ===

  def test_integration_with_ace_nav_resolver
    # Skip if ace-nav is not available
    begin
      require 'ace/nav'
    rescue LoadError
      skip "ace-nav not available for integration test"
    end

    # Create a simple mock that simulates ace-nav behavior
    mock_resolver = create_mock_nav_resolver

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://test-workflow")

    assert_equal @workflow_file, result
  end

  def test_integration_mixed_path_types_with_resolver
    mock_resolver = create_mock_nav_resolver

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    # Protocol resolution
    protocol_result = expander.resolve("wfi://test-workflow")
    assert_equal @workflow_file, protocol_result

    # Source-relative still works
    source_result = expander.resolve("./config.yml")
    assert_equal File.join(@source_dir, "config.yml"), source_result

    # Project-relative still works
    project_result = expander.resolve("docs/readme.md")
    assert_equal File.join(@project_root, "docs/readme.md"), project_result
  end

  def test_integration_resolver_returns_nil_for_missing_resource
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect(:resolve, nil, ["wfi://missing"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://missing")

    assert_nil result
    mock_resolver.verify
  end

  def test_integration_resolver_registration_affects_all_instances
    # Create a mock that expects two calls
    mock_resource = Struct.new(:path).new(@workflow_file)
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])
    mock_resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    # Create multiple instances
    expander1 = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    expander2 = Ace::Core::Atoms::PathExpander.new(
      source_dir: @workflows_dir,
      project_root: @project_root
    )

    # Both should use the registered resolver
    result1 = expander1.resolve("wfi://test-workflow")
    result2 = expander2.resolve("wfi://test-workflow")

    assert_equal @workflow_file, result1
    assert_equal @workflow_file, result2

    mock_resolver.verify
  end

  def test_integration_unregister_resolver_stops_protocol_resolution
    mock_resolver = create_mock_nav_resolver

    # Register resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    # Should work with resolver
    result = expander.resolve("wfi://test-workflow")
    assert_equal @workflow_file, result

    # Unregister resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)

    # Should return error hash now
    result = expander.resolve("wfi://test-workflow")
    assert_kind_of Hash, result
    assert_equal "Protocol resolver not available", result[:error]
  end

  def test_integration_realistic_config_file_scenario
    # Simulate a real config file scenario
    config_file = File.join(@source_dir, "nav", "config.yml")
    FileUtils.mkdir_p(File.dirname(config_file))
    File.write(config_file, <<~YAML)
      sources:
        - path: wfi://test-workflow
        - path: ./local/workflows
        - path: handbook/shared
    YAML

    mock_resolver = create_mock_nav_resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    # Create expander for this config file
    expander = Ace::Core::Atoms::PathExpander.for_file(config_file)

    # Resolve the three different path types
    result1 = expander.resolve("wfi://test-workflow")
    result2 = expander.resolve("./local/workflows")
    result3 = expander.resolve("handbook/shared")

    # Protocol should resolve via ace-nav
    assert_equal @workflow_file, result1

    # Source-relative should resolve from config file directory
    assert result2.end_with?(".ace/nav/local/workflows"), "Expected #{result2} to end with .ace/nav/local/workflows"

    # Project-relative should resolve from project root
    assert result3.end_with?("handbook/shared"), "Expected #{result3} to end with handbook/shared"
  end

  def test_integration_factory_method_with_protocol_resolution
    mock_resolver = create_mock_nav_resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(mock_resolver)

    # Use factory method
    Dir.chdir(@project_root) do
      expander = Ace::Core::Atoms::PathExpander.for_cli

      result = expander.resolve("wfi://test-workflow")
      assert_equal @workflow_file, result
    end
  end

  private

  # Create a simple mock that simulates ace-nav ResourceResolver behavior
  def create_mock_nav_resolver
    mock_resource = Struct.new(:path).new(@workflow_file)
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, mock_resource, ["wfi://test-workflow"])
    resolver
  end
end
