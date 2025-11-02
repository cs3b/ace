# frozen_string_literal: true

require "test_helper"
require "ace/core/atoms/path_expander"
require "tmpdir"
require "fileutils"

class PathExpanderProtocolTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @project_root = File.join(@tmpdir, "project")
    @source_dir = File.join(@project_root, ".ace")

    FileUtils.mkdir_p(@source_dir)
    FileUtils.mkdir_p(File.join(@project_root, ".git"))

    # Clear any registered protocol resolver
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)
  end

  # === Protocol Detection Tests ===

  def test_protocol_detects_standard_protocols
    assert Ace::Core::Atoms::PathExpander.protocol?("wfi://setup")
    assert Ace::Core::Atoms::PathExpander.protocol?("guide://testing")
    assert Ace::Core::Atoms::PathExpander.protocol?("tmpl://task-draft")
    assert Ace::Core::Atoms::PathExpander.protocol?("task://083")
    assert Ace::Core::Atoms::PathExpander.protocol?("prompt://context")
  end

  def test_protocol_detects_http_protocols
    assert Ace::Core::Atoms::PathExpander.protocol?("http://example.com")
    assert Ace::Core::Atoms::PathExpander.protocol?("https://example.com")
    assert Ace::Core::Atoms::PathExpander.protocol?("ftp://server.com")
  end

  def test_protocol_detects_complex_protocol_names
    assert Ace::Core::Atoms::PathExpander.protocol?("custom-proto://resource")
    assert Ace::Core::Atoms::PathExpander.protocol?("proto+ext://resource")
    assert Ace::Core::Atoms::PathExpander.protocol?("proto.v2://resource")
  end

  def test_protocol_rejects_non_protocols
    refute Ace::Core::Atoms::PathExpander.protocol?("./relative/path")
    refute Ace::Core::Atoms::PathExpander.protocol?("../parent/path")
    refute Ace::Core::Atoms::PathExpander.protocol?("docs/file.md")
    refute Ace::Core::Atoms::PathExpander.protocol?("/absolute/path")
    refute Ace::Core::Atoms::PathExpander.protocol?("$HOME/path")
  end

  def test_protocol_handles_edge_cases
    refute Ace::Core::Atoms::PathExpander.protocol?(nil)
    refute Ace::Core::Atoms::PathExpander.protocol?("")
    refute Ace::Core::Atoms::PathExpander.protocol?("   ")
    refute Ace::Core::Atoms::PathExpander.protocol?("no-colon-slash")
    refute Ace::Core::Atoms::PathExpander.protocol?("://no-protocol")
  end

  def test_protocol_case_sensitive
    assert Ace::Core::Atoms::PathExpander.protocol?("wfi://test")
    refute Ace::Core::Atoms::PathExpander.protocol?("WFI://test")
    refute Ace::Core::Atoms::PathExpander.protocol?("Wfi://test")
  end

  # === Protocol Resolver Registration Tests ===

  def test_register_protocol_resolver
    resolver = Object.new

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    # We can't directly test the class variable, but we can test behavior
    # This is verified in resolve tests below
    assert true  # If we get here, registration didn't error
  end

  def test_register_nil_resolver_clears_registration
    resolver = Object.new
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    # Clear it
    Ace::Core::Atoms::PathExpander.register_protocol_resolver(nil)

    # Verify by testing resolve behavior (should return error hash)
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://test")
    assert_kind_of Hash, result
    assert result.key?(:error)
  end

  # === Protocol Resolution Tests ===

  def test_resolve_returns_error_hash_when_no_resolver_registered
    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://workflow")

    assert_kind_of Hash, result
    assert_equal "Protocol resolver not available", result[:error]
    assert_equal "wfi://workflow", result[:uri]
    assert_match(/Protocol 'wfi:\/\/workflow' could not be resolved/, result[:message])
    assert_match(/PathExpander.register_protocol_resolver/, result[:message])
  end

  def test_resolve_delegates_to_registered_resolver
    # Create a mock resolver
    resolved_path = "/resolved/path/to/workflow.wf.md"
    mock_resource = Struct.new(:path).new(resolved_path)
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, mock_resource, ["wfi://workflow"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://workflow")

    assert_equal resolved_path, result
    resolver.verify
  end

  def test_resolve_handles_resolver_returning_plain_string
    # Some resolvers might return plain strings
    resolved_path = "/resolved/path.md"
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, resolved_path, ["guide://testing"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("guide://testing")

    assert_equal resolved_path, result
    resolver.verify
  end

  def test_resolve_handles_resolver_returning_nil
    # Resolver might return nil if resource not found
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, nil, ["wfi://missing"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://missing")

    assert_nil result
    resolver.verify
  end

  def test_resolve_skips_resolver_if_not_respond_to_resolve
    # Register something that doesn't respond to :resolve
    invalid_resolver = Object.new

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(invalid_resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://test")

    # Should return error hash since resolver doesn't respond to :resolve
    assert_kind_of Hash, result
    assert_equal "Protocol resolver not available", result[:error]
  end

  # === Mixed Resolution Tests ===

  def test_resolve_regular_paths_unaffected_by_resolver_registration
    # Register a resolver
    mock_resource = Struct.new(:path).new("/resolved/protocol.md")
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, mock_resource, ["wfi://test"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    # Regular paths should still work normally
    assert_equal File.join(@source_dir, "local.yml"), expander.resolve("./local.yml")
    assert_equal File.join(@project_root, "docs/file.md"), expander.resolve("docs/file.md")
    assert_equal "/absolute/path", expander.resolve("/absolute/path")

    # Protocol should use resolver
    result = expander.resolve("wfi://test")
    assert_equal "/resolved/protocol.md", result

    resolver.verify
  end

  def test_protocol_resolution_prioritized_over_regular_paths
    # Even if there's a file literally named "wfi://something",
    # it should be treated as protocol first
    resolver = Minitest::Mock.new
    resolver.expect(:resolve, "/protocol/result.md", ["wfi://file"])

    Ace::Core::Atoms::PathExpander.register_protocol_resolver(resolver)

    expander = Ace::Core::Atoms::PathExpander.new(
      source_dir: @source_dir,
      project_root: @project_root
    )

    result = expander.resolve("wfi://file")

    # Should use protocol resolver, not treat as filename
    assert_equal "/protocol/result.md", result
    resolver.verify
  end
end
