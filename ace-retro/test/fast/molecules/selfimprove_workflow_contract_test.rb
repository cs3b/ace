# frozen_string_literal: true

require "test_helper"

class SelfimproveWorkflowContractTest < AceRetroTestCase
  def test_selfimprove_recognizes_wrong_layer_root_cause
    content = File.read(
      File.expand_path("../../../handbook/workflow-instructions/retro/selfimprove.wf.md", __dir__)
    )

    assert_includes content, "Wrong layer / owner not identified"
    assert_includes content, "ace-assign"
    assert_includes content, "ace-tmux"
    assert_includes content, "window creation, naming, and navigation"
  end
end
