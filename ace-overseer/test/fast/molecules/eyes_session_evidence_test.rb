# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/overseer/molecules/eyes_session_evidence"
require "fileutils"
require "timeout"

class EyesSessionEvidenceTest < Minitest::Test
  Result = Struct.new(:parsed_json)
  Executor = Struct.new(:pane, :processes) do
    def pane_get(_id) = Result.new({"result" => {"pane" => pane}})
    def pane_process_info(_id) = Result.new({"result" => {"process_info" => {"foreground_processes" => processes}}})
  end
  Identity = Struct.new(:value) do
    def capture(_pid) = value
  end

  def setup
    @dir = Dir.mktmpdir
    @uuid = "01234567-89ab-cdef-0123-456789abcdef"
    @path = File.join(@dir, "2026-01-01_#{@uuid}.jsonl")
    @process = {"pid" => 123, "uid" => Process.uid, "started_at" => "linux:#{@uuid}:12345"}
    @executor = Executor.new({"pane_id" => "w1:p1", "terminal_id" => "term", "agent" => "pi",
      "agent_session" => {"agent" => "pi", "kind" => "path", "value" => @path}}, [{"pid" => 123}])
    @identity = Identity.new(@process)
    @reader = Ace::Overseer::Molecules::EyesSessionEvidence.new(executor: @executor, identity: @identity, clock: -> { 20_000 })
    @records = [
      {"type" => "session", "version" => 3, "id" => @uuid, "cwd" => "/lab/ace"},
      {"id" => "bind", "parentId" => nil, "type" => "custom", "customType" => "ace-wake-eyes-binding", "data" => {
        "ownerCwd" => "/lab/ace", "process" => {"pid" => 123, "startedAt" => @process["started_at"]}}},
      {"id" => "one", "parentId" => "bind", "type" => "message", "timestamp" => "1970-01-01T00:00:10.000Z", "message" => {"role" => "user", "content" => "first"}},
      {"id" => "two", "parentId" => "one", "type" => "message", "message" => {"role" => "assistant", "stopReason" => "stop"}},
      {"id" => "three", "parentId" => "two", "type" => "custom", "customType" => "ace-wake-eyes", "data" => {
        "ownerCwd" => "/lab/ace", "enabled" => true, "retired" => false, "breaker" => nil, "errors" => 0,
        "config" => {"intervalSeconds" => 30, "timeoutMs" => 60_000},
        "observerEvidence" => {"process" => {"pid" => 123, "startedAt" => @process["started_at"]},
                               "observedAt" => 19_000, "sources" => {"tasks" => "ok"}}
      }}
    ]
    write_session
  end

  def teardown = FileUtils.remove_entry(@dir)

  def write_session
    File.write(@path, @records.map { |record| JSON.generate(record) }.join("\n") + "\n")
  end

  def ready?
    @reader.ready?(pane: "w1:p1", root: "/lab/ace", prompt: "first", required_sources: ["tasks"])
  end

  def test_live_bound_process_and_current_branch_prove_observation
    assert ready?
  end

  def test_injected_descriptor_keeps_validation_and_never_falls_back_to_path_open
    opened = File.open(@path, File::RDONLY)
    requested = []
    @reader = Ace::Overseer::Molecules::EyesSessionEvidence.new(executor: @executor,
      identity: @identity, clock: -> { 20_000 }, file_opener: ->(path) { requested << path; opened.dup })
    assert ready?
    assert_equal [@path], requested
    refute opened.closed?
    @identity.value = @process.merge("started_at" => "linux:#{@uuid}:999")
    refute ready?
    @identity.value = @process
    @reader = Ace::Overseer::Molecules::EyesSessionEvidence.new(executor: @executor,
      identity: @identity, file_opener: ->(_) { raise Errno::EACCES })
    refute ready?
  ensure
    opened&.close
  end

  def test_rejects_replaced_process_or_missing_foreground_agent
    @identity.value = @process.merge("started_at" => "linux:#{@uuid}:999")
    refute ready?
    @identity.value = @process
    @executor.processes = []
    refute ready?
  end

  def test_ignores_evidence_on_a_previous_branch
    @records << {"id" => "other", "parentId" => "one", "type" => "message", "message" => {"role" => "assistant", "stopReason" => "stop"}}
    write_session
    refute ready?
  end

  def test_rejects_invalid_session_or_foreign_terminal
    @records[0]["id"] = "different"
    write_session
    refute ready?
    @records[0]["id"] = @uuid
    write_session
    @executor.pane["agent"] = "codex"
    refute ready?
  end

  def test_rejects_symlinks_and_fifos_without_waiting_for_a_writer
    original = @path + ".real"
    File.rename(@path, original)
    File.symlink(original, @path)
    refute ready?
    File.unlink(@path)
    assert system("mkfifo", @path)
    Timeout.timeout(2) { refute ready? }
  end
end
