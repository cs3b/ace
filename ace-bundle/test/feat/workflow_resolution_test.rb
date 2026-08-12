# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../test_helper"

class WorkflowResolutionTest < AceTestCase
  WORKFLOW_URIS = {
    "wfi://bundle" => "ace-bundle/handbook/workflow-instructions/bundle.wf.md",
    "wfi://onboard" => "ace-bundle/handbook/workflow-instructions/onboard.wf.md"
  }.freeze

  RELEASE_WORKFLOW_URIS = %w[
    wfi://release/local
    wfi://release/bump-version
    wfi://release/update-changelog
    wfi://release/publish
    wfi://release/rubygems-publish
  ].freeze

  def test_workflow_backed_skills_resolve_and_load_via_wfi
    require "ace/support/nav"

    engine = Ace::Support::Nav::Organisms::NavigationEngine.new

    WORKFLOW_URIS.each do |uri, relative_path|
      resolved_path = engine.resolve(uri)

      refute_nil resolved_path, "Expected #{uri} to resolve to a real path"
      assert File.exist?(resolved_path), "Expected resolved path to exist: #{resolved_path}"
      assert resolved_path.end_with?(relative_path),
             "Expected #{uri} to resolve to a path ending with #{relative_path}, got #{resolved_path}"

      result = Ace::Bundle.load_auto(uri, compressor_source_scope: "per-source", compressor_mode: "exact")

      refute result.metadata[:error], "Expected #{uri} to load without errors"
      assert result.metadata[:compressed], "Expected #{uri} bundle output to be compressed"
      assert_includes result.content, "FILE|", "Expected #{uri} to return compressed workflow content"
    end
  end

  def test_release_workflows_resolve_from_ace_handbook_gem_without_project_overlay
    require "ace/support/nav"

    engine = build_gem_only_nav_engine
    RELEASE_WORKFLOW_URIS.each do |uri|
      slug = uri.delete_prefix("wfi://release/")
      resolved_path = engine.resolve(uri)

      refute_nil resolved_path, "Expected #{uri} to resolve from gem defaults"
      assert File.exist?(resolved_path), "Expected resolved path to exist: #{resolved_path}"
      refute_match(
        %r{(^|/)\.ace-handbook/},
        resolved_path,
        "Expected #{uri} to resolve from gem handbook, not monorepo overlay: #{resolved_path}"
      )
      assert_match(
        %r{ace-handbook(?:-[^/]+)?/handbook/workflow-instructions/release/#{Regexp.escape(slug)}\.wf\.md\z},
        resolved_path
      )

      content = File.read(resolved_path)
      assert_match(/Prep vs publication/i, content)
      assert_match(/Override/i, content)
      assert(
        content.match?(/non-publishing|does not publish|does \*\*not\*\* publish|No registry publish|Do not publish|no `gem push`/i),
        "Expected #{uri} baseline to default to non-publishing guidance"
      )
    end
  ensure
    cleanup_gem_only_nav_engine
  end

  def test_missing_release_workflow_uri_fails_clearly_without_project_overlay
    require "ace/support/nav"

    engine = build_gem_only_nav_engine
    missing_uri = "wfi://release/does-not-exist"

    resolved_path = engine.resolve(missing_uri)
    assert_nil resolved_path, "Expected #{missing_uri} not to resolve"

    result = Ace::Bundle.load_auto(missing_uri, compressor_source_scope: "per-source", compressor_mode: "exact")
    assert result.metadata[:error], "Expected unresolved error metadata for #{missing_uri}"
    assert_match(
      /does-not-exist|unresolved|not found|unable to resolve|failed to resolve/i,
      result.metadata[:error].to_s
    )
  ensure
    cleanup_gem_only_nav_engine
  end

  private

  def build_gem_only_nav_engine
    @isolated_nav_root = Dir.mktmpdir("ace-bundle-wfi-gem-only")
    registry = Ace::Support::Nav::Molecules::SourceRegistry.new(start_path: @isolated_nav_root)
    config_loader = Ace::Support::Nav::Molecules::ConfigLoader.new(nil, source_registry: registry)
    scanner = Ace::Support::Nav::Molecules::ProtocolScanner.new(config_loader: config_loader)
    Ace::Support::Nav::Organisms::NavigationEngine.new(protocol_scanner: scanner)
  end

  def cleanup_gem_only_nav_engine
    FileUtils.rm_rf(@isolated_nav_root) if @isolated_nav_root && Dir.exist?(@isolated_nav_root)
    @isolated_nav_root = nil
  end
end
