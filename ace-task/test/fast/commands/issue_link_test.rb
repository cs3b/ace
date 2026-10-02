# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"

class IssueLinkCommandTest < AceTaskTestCase
  def test_clear_cannot_combine_with_server_selection
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Task::TaskCLI.start(["issue-link", "q7w", "--clear", "--server", "lab"])
    end
    assert_match(/--clear cannot combine/, error.message)
  end

  def test_link_passes_exact_selection_to_manager
    captured = nil
    task = Struct.new(:id, :metadata).new("8pp.t.q7w",
      {"remote_issue" => {"url" => "https://forge.example/owner/repo/issues/42"}})
    manager = Object.new
    manager.define_singleton_method(:issue_link) { |*args, **options| captured = [args, options]; task }
    Ace::Task::Organisms::TaskManager.stub(:new, manager) do
      output = capture_io do
        Ace::Task::TaskCLI.start(["issue-link", "q7w", "--issue", "42", "--server", "lab"])
      end.first
      assert_match(/Linked 8pp.t.q7w/, output)
    end
    assert_equal ["q7w"], captured[0]
    assert_equal "lab", captured[1][:server_name]
    assert_equal "42", captured[1][:issue]
  end
end
