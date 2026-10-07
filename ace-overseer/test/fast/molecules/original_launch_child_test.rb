# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/original_launch_child"

class OriginalLaunchChildTest < AceOverseerTestCase
  class Boundary
    attr_reader :calls
    attr_accessor :frame, :waiting, :supported, :readable
    def initialize(frame)
      @frame, @calls, @supported, @readable = frame, [], true, true
    end
    def supported? = supported
    def pipe
      @reader, @writer = IO.pipe
      [@reader, @writer]
    end
    def fork_loaded(**args)
      @calls << args.fetch(:argv)
      @writer.write(frame) if frame
      123
    end
    def readable?(_reader, _timeout) = readable
    def wait(_pid) = waiting
    def close
      @reader.close if @reader && !@reader.closed?
      @writer.close if @writer && !@writer.closed?
    end
  end

  def setup
    super
    @request = {"project_id" => "project", "mapping_id" => "mapping", "assignment_id" => "assignment",
      "scope" => "010", "base_head" => "a" * 40, "mutation_id" => "invocation", "task_id" => "task",
      "definition_sha256" => "d" * 64, "definition_bytes" => JSON.generate("prepared_work" => {"selection_sha256" => "e" * 64}),
      "prepared_bundle" => {"bytes" => 100, "sha256" => "f" * 64}}
    @canonical_row = {"assignment_id" => "assignment", "task_id" => "task", "scope" => "010", "base_head" => "a" * 40,
      "reservation_mutation_id" => "invocation-reserve", "definition_digest" => "d" * 64, "selection_sha256" => "e" * 64,
      "prepared_bundle_bytes" => 100, "prepared_bundle_sha256" => "f" * 64,
      "prepared_bundle_ref" => "execution/prepared/assignment-#{'f' * 64}.bundle"}
    @ready = {"version" => 1, "type" => "launch_ready", "mapping_id" => "mapping", "assignment_id" => "assignment",
      "attempt_id" => "attempt", "generation" => 4, "journal_commit" => "b" * 40, "original_binding_digest" => "c" * 64}
    @identity = {"pid" => 123, "started_at" => "controlled-birth"}
    test = self
    @kernel = Object.new
    @kernel.define_singleton_method(:capture) { |_pid| test.instance_variable_get(:@identity) }
    @joins = []
    joins = @joins
    @status = Object.new
    @status.define_singleton_method(:join_ready!) { |**args| joins << args; {"item" => test.instance_variable_get(:@canonical_row)} }
    @boundaries = []
  end

  def teardown
    @boundaries.each(&:close)
    super
  end

  def child(frame = JSON.generate(@ready) + "\n", **injections)
    boundary = Boundary.new(frame)
    @boundaries << boundary
    value = Ace::Overseer::Molecules::OriginalLaunchChild.new(process: boundary, kernel: @kernel,
      threads: -> { [Thread.current] }, quiescent: -> { true }, **injections)
    [value, boundary]
  end

  def start(value)
    value.start(request: @request, definition_path: "/private/invocation.definition.json", bundle_path: "/private/invocation.prepared.bundle")
  end

  def test_fixed_loaded_argv_ready_join_and_original_nonblocking_lifetime
    value, boundary = child
    start(value).await_ready(status: @status)
    assert_equal "ready", value.state
    assert_equal 123, value.pid
    assert_equal @identity, value.identity
    assert_equal ["authority", "launch", "--mapping", "mapping", "--assignment", "assignment", "--definition", "/private/invocation.definition.json",
      "--prepared-bundle", "/private/invocation.prepared.bundle", "--step", "010", "--base-head", "a" * 40, "--mutation", "invocation"], boundary.calls.first
    assert_equal @ready, @joins.first.fetch(:ready)
    value.observe
    assert_equal "ready", value.state
    boundary.waiting = [123, :controlled_exit]
    value.observe
    assert_equal "exited", value.state
    assert_equal :controlled_exit, value.exit_status
    assert_equal 1, boundary.calls.size
  end

  def test_unsafe_boundary_and_unsupported_fork_refuse_before_child
    unrelated = Object.new
    unrelated.define_singleton_method(:alive?) { true }
    [ {threads: -> { [Thread.current, unrelated] }}, {quiescent: -> { false }} ].each do |injection|
      value, boundary = child(**injection)
      assert_raises(Ace::Overseer::Error) { start(value) }
      assert_empty boundary.calls
    end
    value, boundary = child
    boundary.supported = false
    assert_raises(Ace::Overseer::Error) { start(value) }
    assert_empty boundary.calls
  end

  def test_actual_tick_marker_and_held_owned_lock_refuse_before_fork
    tick = Ace::Overseer::Molecules::ProposalTick
    key = ["controlled", "socket", "project"]
    assert tick.acquire(key)
    value, boundary = child(quiescent: -> { tick.quiescent? })
    assert_raises(Ace::Overseer::Error) { start(value) }
    assert_empty boundary.calls
    tick.release(key)
    mutex = tick.instance_variable_get(:@mutex)
    mutex.synchronize do
      value, boundary = child(quiescent: -> { tick.quiescent? })
      assert_raises(Ace::Overseer::Error) { start(value) }
      assert_empty boundary.calls
    end
  ensure
    tick.release(key)
  end

  def test_unobservable_original_birth_is_uncertain_without_replacement
    @identity = nil
    value, boundary = child
    start(value)
    assert_equal "uncertain", value.state
    assert_equal 123, value.pid
    assert_equal 1, boundary.calls.size
    assert_raises(Ace::Overseer::Error) { start(value) }
  end

  def test_malformed_foreign_duplicate_and_oversized_ready_retain_same_child
    ["bad\n", JSON.generate(@ready.merge("mapping_id" => "foreign")) + "\n",
      JSON.generate(@ready) + "\nextra\n", "x" * 16_385, '{"version":1,"version":1}' + "\n"].each do |frame|
      value, boundary = child(frame)
      start(value).await_ready(status: @status)
      assert_equal "uncertain", value.state
      assert_equal 123, value.pid
      assert_equal 1, boundary.calls.size
      assert_raises(Ace::Overseer::Error) { start(value) }
    end
    assert_empty @joins
  end

  def test_valid_ready_for_different_canonical_inputs_is_uncertain
    %w[reservation_mutation_id scope base_head definition_digest selection_sha256 prepared_bundle_sha256 prepared_bundle_ref].each do |key|
      original = @canonical_row
      @canonical_row = original.merge(key => "different")
      value, boundary = child
      start(value).await_ready(status: @status)
      assert_equal "uncertain", value.state
      assert_equal 123, value.pid
      assert_equal 1, boundary.calls.size
      @canonical_row = original
    end
    @canonical_row = @canonical_row.merge("prepared_bundle_bytes" => 100.0)
    value, = child
    start(value).await_ready(status: @status)
    assert_equal "uncertain", value.state
  end

  def test_delayed_await_cannot_refresh_original_readiness_deadline
    now = 0
    value, boundary = child(clock: -> { now })
    start(value)
    now = 31
    value.await_ready(status: @status)
    assert_equal "uncertain", value.state
    assert_empty @joins
    assert_equal 1, boundary.calls.size
  end

  def test_timeout_eof_and_birth_change_retain_original_handle
    value, boundary = child
    boundary.readable = false
    start(value).await_ready(status: @status)
    assert_equal "uncertain", value.state
    assert_equal 123, value.pid
    value, boundary = child(nil)
    start(value).await_ready(status: @status)
    assert_equal "uncertain", value.state
    value, = child
    start(value)
    @identity = {"pid" => 123, "started_at" => "other-birth"}
    value.await_ready(status: @status)
    assert_equal "uncertain", value.state
    assert_empty @joins
  end
end
