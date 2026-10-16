# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"

class RootCLITest < AceTaskTestCase
  def test_exact_overseer_root_round_trip_and_project_root_isolation
    Dir.mktmpdir("task-root") do |dir|
      Dir.chdir(dir) do
        root = ".ace-tasks/overseer"
        created = invoke("create", "Deliver current objective", "--root", root)
        id = created[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
        refute_nil id
        path = invoke("show", id, "--root", File.expand_path(root), "--path").strip
        assert path.start_with?(File.realpath(root) + File::SEPARATOR)
        refute Dir.exist?(".ace-tasks/_overseer")
        assert_includes invoke("list", "--root", root), id
        invoke("update", id, "--root", root, "--set", "status=in-progress,next_action=integrate")
        shown = invoke("show", id, "--root", root, "--content")
        assert_includes shown, "status: in-progress"
        assert_includes shown, "next_action: integrate"

        # An identical ref in a separate queue must not receive the update.
        other_root = File.join(dir, "other-queue")
        FileUtils.mkdir_p(other_root)
        FileUtils.cp_r(File.dirname(path), other_root)
        original = File.binread(path)
        invoke("update", id, "--root", other_root, "--set", "status=blocked")
        assert_equal original, File.binread(path)
        assert_includes invoke("show", id, "--root", other_root, "--content"), "status: blocked"
      end
    end
  end

  def test_root_dry_run_does_not_create_directories
    Dir.mktmpdir("task-root-preview") do |dir|
      root = File.join(dir, "queue")
      invoke("create", "Preview", "--root", root, "--dry-run")
      refute Dir.exist?(root)
    end
  end

  private

  def invoke(*args)
    capture_io { Ace::Task::TaskCLI.start(args) }.first
  end
end
