# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
load File.expand_path("../../bin/lab-vm-lab-start", __dir__)

class LabVmStartResultTest < AceMonorepoE2eTestCase
  def partial
    {"status" => "partial", "scope" => "lab", "root" => "/lab", "prompt_failed" => false, "pane" => "w2:p8"}
  end

  def parse(code, value, allow: true)
    stub(:guest_mo, [code, JSON.generate(value)]) do
      guest_json("fixture", "ace-overseer", "start", allow_partial_lab_start: allow)
    end
  end

  def test_accepts_started_coordinator_with_unready_project_without_hiding_exit_status
    assert_equal partial, parse(1, partial)
    assert_raises(RuntimeError) { parse(2, partial) }
    assert_raises(RuntimeError) { parse(1, partial, allow: false) }
  end

  def test_rejects_blocked_unconfirmed_and_unidentified_coordinators
    [{"status" => "blocked"}, {"prompt_failed" => true}, {"pane" => nil},
      {"scope" => "project"}, {"root" => "/other"}].each do |change|
      assert_raises(RuntimeError) { parse(1, partial.merge(change)) }
    end
  end

  def test_successful_ready_result_remains_accepted
    assert_equal "ready", parse(0, partial.merge("status" => "ready")).fetch("status")
  end
  def test_guest_capture_keeps_cli_error_out_of_json_stdout
    child = "STDOUT.write(#{JSON.generate({"status" => "partial"}).dump}); STDERR.write('project unready'); exit 1"
    capture = lambda do |_uuid, _program, _flag, wrapper, *_, **_options|
      out, err, status = Open3.capture3("python3", "-c", wrapper, RbConfig.ruby, "-e", child)
      [status.exitstatus, out + err]
    end
    code = output = nil
    _, error = capture_io do
      LabVm.stub(:guest_exec, capture) { code, output = guest_mo("fixture", "ace-overseer", "start") }
    end
    assert_equal 1, code
    assert_equal({"status" => "partial"}, JSON.parse(output))
    assert_includes error, "project unready"
  end

end
