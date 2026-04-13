# frozen_string_literal: true

require_relative "../test_helper"

class WorkflowResolutionTest < AceTestCase
  WORKFLOW_URIS = {
    "wfi://bundle" => "ace-bundle/handbook/workflow-instructions/bundle.wf.md",
    "wfi://onboard" => "ace-bundle/handbook/workflow-instructions/onboard.wf.md"
  }.freeze

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
end
