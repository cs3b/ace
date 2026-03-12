# frozen_string_literal: true

require_relative "../test_helper"

class WorkflowResolutionTest < AceTestCase
  WORKFLOW_URIS = {
    "wfi://demo/create" => "ace-demo/handbook/workflow-instructions/demo/create.wf.md",
    "wfi://demo/record" => "ace-demo/handbook/workflow-instructions/demo/record.wf.md",
    "wfi://overseer" => "ace-overseer/handbook/workflow-instructions/overseer.wf.md",
    "wfi://prompt-prep" => "ace-prompt-prep/handbook/workflow-instructions/prompt-prep.wf.md"
  }.freeze

  def test_workflow_backed_skills_resolve_and_load_via_wfi
    require "ace/support/nav"

    engine = Ace::Support::Nav::Organisms::NavigationEngine.new

    WORKFLOW_URIS.each do |uri, relative_path|
      expected_path = File.expand_path("../../../#{relative_path}", __dir__)
      resolved_path = engine.resolve(uri)

      assert_equal expected_path, resolved_path, "Expected #{uri} to resolve to #{relative_path}"

      result = Ace::Bundle.load_auto(uri, compressor_source_scope: "per-source", compressor_mode: "exact")

      refute result.metadata[:error], "Expected #{uri} to load without errors"
      assert result.metadata[:compressed], "Expected #{uri} bundle output to be compressed"
      assert_includes result.content, "FILE|", "Expected #{uri} to return compressed workflow content"
    end
  end
end
