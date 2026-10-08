# frozen_string_literal: true

require "test_helper"
require "openssl"
require_relative "../../support/codex_inbox_observation_fixture"

class InboxNativeObservationTest < Minitest::Test
  include CodexInboxObservationFixture
  Inbox = Ace::Herdr::Organisms::Inbox
  Store = Ace::Herdr::Molecules::DeliveryRecordStore
  KEY = OpenSSL::PKey::RSA.generate(2048)
  ERROR = Ace::Herdr::ValidationError

  def setup
    @dir = Dir.mktmpdir("inbox-observation")
    @native = Native.new
    @box = Inbox.new(executor: Pane.new, native: @native, deliveries_dir: @dir, receipt_public_key: KEY.public_key)
    @box.enqueue(event: "event1", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "private answer")
  end

  def teardown = FileUtils.remove_entry(@dir)

  def read(**overrides)
    @box.observe_consumption(event: "event1", expected_attempt: "attempt1", expected_claim_generation: 1,
      deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2, **overrides)
  end

  def test_exact_retained_submission_is_read_without_signing_saving_or_sending_again
    @box.deliver(event: "event1")
    before = File.binread(File.join(@dir, "event1.json"))
    result = read
    assert_equal "consumed", result.dig("observation", "outcome")
    assert_equal QUEUE, result.dig("observation", "native_reference", "queued_submission_id")
    assert_equal "attempt1", result.fetch("attempt_id")
    assert_equal 1, result.fetch("claim_generation")
    assert_equal before, File.binread(File.join(@dir, "event1.json"))
    assert_equal 1, @native.sends.size
    assert_equal 1, @native.reads.size
    refute_includes JSON.generate(result), "private answer"
    assert_equal "delivered", @box.retained_status(event: "event1").fetch("state")
  end

  def test_lost_add_reply_reads_retained_client_id_without_manufacturing_queue_identity
    @native.accepted = false
    @box.deliver(event: "event1")
    result = read
    assert_equal "consumed", result.dig("observation", "outcome")
    assert_nil result.dig("observation", "native_reference", "queued_submission_id")
    assert_equal "uncertain", @box.retained_status(event: "event1").fetch("state")
    assert_equal 1, @native.sends.size
  end

  def test_stale_generation_attempt_key_and_expired_budget_never_read_native_history
    @box.deliver(event: "event1")
    [{expected_claim_generation: 2}, {expected_attempt: "other"}, {expected_claim_generation: 0},
      {deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1}].each do |arguments|
      assert_raises(ERROR) { read(**arguments) }
    end
    other = Inbox.new(executor: Pane.new, native: @native, deliveries_dir: @dir,
      receipt_public_key: OpenSSL::PKey::RSA.generate(2048).public_key)
    assert_raises(ERROR) do
      other.observe_consumption(event: "event1", expected_attempt: "attempt1", expected_claim_generation: 1,
        deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2)
    end
    assert_empty @native.reads
  end

  def test_query_is_outside_event_lock_and_changed_record_discards_positive_result
    @box.deliver(event: "event1")
    @native.on_read = lambda do
      Store.with_lock(@dir, "event1") do
        record = Store.load(@dir, "event1")
        Store.save(record.advance_inbox(state: "uncertain", inbox: record.inbox,
          detail: {"action" => "controlled concurrent change"}, timestamp: Time.now.utc.iso8601), @dir)
      end
    end
    assert_raises(ERROR) { read }
    assert_equal "uncertain", @box.retained_status(event: "event1").fetch("state")
    assert_equal 1, @native.sends.size
  end

  def test_matching_text_wrong_ids_process_or_endpoint_never_becomes_positive_observation
    @box.deliver(event: "event1")
    baseline = read.fetch("observation")
    %w[thread_id client_user_message_id payload_sha256 queued_submission_id turn_id item_id version].each do |field|
      @native.result = Marshal.load(Marshal.dump(baseline))
      @native.result.fetch("native_reference")[field] = field == "item_id" ? "" : "unrelated"
      assert_raises(ERROR) { read }
    end
    %w[endpoint_reference_sha256 server_process_binding].each do |field|
      @native.result = baseline.merge(field => "substituted")
      assert_raises(ERROR) { read }
    end
    @native.result = baseline.merge("body" => "private answer")
    assert_raises(ERROR) { read }
    assert_equal "delivered", @box.retained_status(event: "event1").fetch("state")
  end

  def test_uncertain_reply_drops_native_error_text_and_does_not_mutate_event
    @box.deliver(event: "event1")
    @native.result = {"outcome" => "uncertain", "error" => "private answer"}
    assert_equal({"outcome" => "uncertain"}, read.fetch("observation"))
    assert_equal "delivered", @box.retained_status(event: "event1").fetch("state")
  end

  def test_original_deadline_bounds_event_lock_wait_before_any_native_query
    @box.deliver(event: "event1")
    entered, release = Queue.new, Queue.new
    holder = Thread.new do
      Store.with_lock(@dir, "event1") { entered << true; release.pop }
    end
    entered.pop
    assert_raises(ERROR) do
      read(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 0.03)
    end
    assert_empty @native.reads
  ensure
    release << true if release
    assert holder.join(1) if holder
    holder&.value
  end
end
