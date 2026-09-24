# frozen_string_literal: true

require "test_helper"
require "socket"
require "json"

# Test successors of lab-config tests/test_hitl.py binding rows (M1
# audit brief 8wm.t.y21 §1): the provider=lab binding client speaks the
# daemon's read-only `hitl_binding` op over a REAL AF_UNIX socket served
# through the exact newline-JSON framing, and applies the narrow
# fail-closed interpretation of the daemon projection. The daemon-side
# W647 authority itself stays lab-config.
class LabDaemonBindingTest < AceHitlTestCase
  WORK = "W500"
  ATTEMPT = "A-#{"a" * 24}"

  def setup
    @path = File.join(Dir.mktmpdir("ace-hitl-labd"), "labd.sock")
    @queries = []
    @reply = ->(_query) { ok_reply }
    @listener = UNIXServer.new(@path)
    @thread = Thread.new { serve }
  end

  def teardown
    @thread.exit
    @listener.close
    File.unlink(@path) if File.exist?(path)
  end

  attr_reader :path

  def serve
    loop do
      conn = @listener.accept
      Thread.new(conn) do |socket|
        line = socket.gets("\n")
        query = JSON.parse(line) if line
        @queries << query
        reply = @reply.call(query)
        socket.write(JSON.generate(reply) + "\n")
        socket.close
      end
    end
  rescue
    nil
  end

  def binding
    Ace::Hitl::Providers::Lab::DaemonBinding.new(socket_path: path)
  end

  def attempt_record(overrides = {})
    {
      "id" => ATTEMPT,
      "work" => WORK,
      "project" => "ace",
      "state" => "working",
      "unix_user" => "lab-builder",
      "owner" => "",
      "execution" => "container",
      "herdr" => {"session" => "lab", "pane_id" => "s2:pC", "terminal_id" => "t-2"},
      "process" => {"kind" => "", "boot_id" => ""}
    }.merge(overrides)
  end

  def ok_reply(overrides = {})
    work_overrides = overrides.delete("work") || {}
    {
      "ok" => true,
      "result" => {
        "work" => {
          "id" => WORK,
          "project" => "ace",
          "active_attempt" => ATTEMPT,
          "assignment" => {
            "dispatch_id" => ATTEMPT.delete_prefix("A-"),
            "agent" => "builder-pi",
            "pane_id" => "s2:pC",
            "herdr_session" => "lab",
            "started_at" => 1234
          }
        }.merge(work_overrides),
        "attempt" => attempt_record.merge(overrides)
      }
    }
  end

  def error_reply(message)
    {"ok" => false, "error" => message}
  end

  def test_validate_request_records_exactly_one_narrow_query_and_passes
    @reply = ->(query) { ok_reply if query == {"op" => "hitl_binding", "work" => WORK, "attempt" => ATTEMPT} }

    binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "lab-builder")

    assert_equal(
      [{"op" => "hitl_binding", "work" => WORK, "attempt" => ATTEMPT}],
      @queries
    )
  end

  def test_validate_request_rejects_stale_active_attempt
    @reply = ->(_query) do
      reply = ok_reply
      reply["result"]["work"]["active_attempt"] = "A-#{"b" * 24}"
      reply
    end

    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "lab-builder")
    end
    assert_match(/exact active Work Attempt/, error.message)
  end

  def test_validate_request_rejects_wrong_owner
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "mo")
    end
    assert_match(/not owned by one exact live Attempt/, error.message)
  end

  def test_validate_request_rejects_missing_pane_evidence
    @reply = ->(_query) { ok_reply("herdr" => {"session" => "lab", "pane_id" => "s9:pQ", "terminal_id" => "t-2"}) }

    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "lab-builder")
    end
    assert_match(/pane\/terminal binding evidence/, error.message)
  end

  def test_validate_request_accepts_daemon_owned_release_attempt
    @reply = ->(_query) do
      ok_reply(
        "owner" => "labd",
        "execution" => "host",
        "herdr" => {},
        "process" => {"kind" => "labd-release", "boot_id" => "b-1"}
      )
    end

    binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "lab-builder")
  end

  def test_validate_request_rejects_daemon_attempt_without_process_identity
    [
      {"owner" => "labd", "execution" => "container", "herdr" => {},
       "process" => {"kind" => "labd-release", "boot_id" => "b-1"}},
      {"owner" => "labd", "execution" => "host", "herdr" => {}, "process" => {}}
    ].each do |overrides|
      @reply = ->(_query) { ok_reply(overrides) }
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        binding.validate_request(work: WORK, attempt: ATTEMPT, project: "ace", requester: "lab-builder")
      end
      assert_match(/ownership and process identity/, error.message)
    end
  end

  def test_unreachable_daemon_fails_closed
    absent = File.join(File.dirname(path), "absent.sock")
    unreachable = Ace::Hitl::Providers::Lab::DaemonBinding.new(socket_path: absent)
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      unreachable.require_active(work: WORK, attempt: ATTEMPT)
    end
    assert_match(/HITL Attempt records are unavailable/, error.message)
  end

  def test_error_reply_passes_the_daemon_message_through
    @reply = ->(_query) { error_reply("HITL request requires a valid active Work") }

    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.require_active(work: WORK, attempt: ATTEMPT)
    end
    assert_match(/requires a valid active Work/, error.message)
  end

  def test_malformed_reply_fails_closed
    @reply = ->(_query) { {"ok" => true, "result" => {"work" => "not-an-object"}} }
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.require_active(work: WORK, attempt: ATTEMPT)
    end
    assert_match(/unavailable/, error.message)

    @reply = ->(_query) { "just a string" }
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.require_active(work: WORK, attempt: ATTEMPT)
    end
    assert_match(/unavailable/, error.message)
  end

  def test_require_active_rejects_terminal_attempt
    @reply = ->(_query) { ok_reply("state" => "failed") }

    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.require_active(work: WORK, attempt: ATTEMPT)
    end
    assert_match(/no longer active/, error.message)
  end

  def test_invalid_ids_fail_closed_before_any_socket_use
    error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
      binding.require_active(work: "BAD", attempt: ATTEMPT)
    end
    assert_match(/valid active Work/, error.message)
    assert_empty @queries
  end
end
