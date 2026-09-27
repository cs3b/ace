# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Organisms
      class DelivererTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir("ace_herdr_deliverer_test")
          @slept = []
          @executor = HerdrTestHelper::FakeExecutor.new
          @deliverer = build_deliverer
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def build_deliverer(executor: @executor, max_attempts: 3)
          Deliverer.new(
            executor: executor, deliveries_dir: @dir,
            max_attempts: max_attempts, backoff_seconds: [1, 2, 4],
            default_agent_kind: "pi", agent_start_timeout_ms: 60_000,
            readiness_timeout_ms: 30_000,
            clock: ->(seconds) { @slept << seconds }
          )
        end

        def error_class(name)
          Ace::Herdr.const_get(name)
        end

        # --- Mandated scenario 1: existing-agent delivery -----------------

        def test_delivers_to_existing_agent_without_bootstrap
          result = @deliverer.deliver(make_ref, "the answer", event_id: "evt-1")

          assert_equal :delivered, result.state
          assert_equal "p5", result.ref.pane
          assert_empty @executor.calls_of(:agent_start)
          assert_empty @executor.calls_of(:pane_run)
          prompt = @executor.calls_of(:agent_prompt).first
          assert_equal "the answer", prompt[:args][:text]
          assert_equal "delivered", Molecules::DeliveryRecordStore.load(@dir, "evt-1").state
        end

        # --- Mandated scenario 2: bootstrap delivery ----------------------

        def test_bootstraps_missing_agent_then_delivers
          @executor = HerdrTestHelper::FakeExecutor.new(
            outcomes: {agent_get: error_class("AgentNotFoundError").new("no agent")}
          )
          deliverer = build_deliverer

          result = deliverer.deliver(make_ref("ws-1", "p7"), "answer", event_id: "evt-2", label: "8wm.t.vs0")

          assert_equal :delivered, result.state
          run_export = @executor.calls_of(:pane_run).first
          assert_equal "export HERDR_SESSION=ws-1 HERDR_PANE=p7", run_export[:args][:command]
          start = @executor.calls_of(:agent_start).first
          assert_equal "8wm.t.vs0", start[:args][:name]
          assert_equal "pi", start[:args][:kind]
          assert_equal "p7", start[:args][:pane]
          assert_equal 1, @executor.calls_of(:agent_wait).length # readiness gate before prompt
          assert_equal 1, @executor.calls_of(:agent_prompt).length
          assert_equal "delivered", Molecules::DeliveryRecordStore.load(@dir, "evt-2").state
        end

        # --- Mandated scenario 3: startup failure -------------------------

        def test_reports_bootstrap_startup_failure_as_terminal
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: error_class("AgentNotFoundError").new("no agent"),
            agent_start: error_class("PaneNotFoundError").new("pane vanished")
          })
          deliverer = build_deliverer

          result = deliverer.deliver(make_ref, "answer", event_id: "evt-3")

          assert_equal :failed, result.state
          assert_empty @executor.calls_of(:agent_prompt)
          record = Molecules::DeliveryRecordStore.load(@dir, "evt-3")
          assert_equal "failed", record.state
          assert_match(/pane vanished/, record.history.last["error"])
        end

        # --- Mandated scenario 4: duplicate delivery ----------------------

        def test_duplicate_delivery_of_identical_content_short_circuits
          @deliverer.deliver(make_ref, "answer", event_id: "evt-4")
          @executor = HerdrTestHelper::FakeExecutor.new # fresh: any contact would be a dup
          deliverer = build_deliverer

          result = deliverer.deliver(make_ref, "answer", event_id: "evt-4")

          assert_equal :delivered, result.state
          assert_empty @executor.calls
        end

        # --- Idempotency / fail-closed ------------------------------------

        def test_conflicting_content_for_same_event_fails_closed
          @deliverer.deliver(make_ref, "answer", event_id: "evt-5")

          error = assert_raises(ValidationError) do
            @deliverer.deliver(make_ref, "DIFFERENT", event_id: "evt-5")
          end

          assert_match(/different answer or destination/, error.message)
        end

        def test_conflicting_destination_for_same_event_fails_closed
          @deliverer.deliver(make_ref("ws-1", "p5"), "answer", event_id: "evt-5b")

          assert_raises(ValidationError) do
            @deliverer.deliver(make_ref("ws-1", "p9"), "answer", event_id: "evt-5b")
          end
          assert_equal 1, @executor.calls_of(:agent_prompt).length # only the first, valid delivery
        end

        def test_invalid_ref_fails_closed_before_any_state
          @executor = HerdrTestHelper::FakeExecutor.new

          assert_raises(Ace::Hitl::Providers::InvalidRefError) do
            @deliverer.deliver(make_ref("ws bad chars!", "p5"), "answer")
          end

          assert_empty @executor.calls
          assert_empty Dir.children(@dir)
        end

        def test_invalid_explicit_event_id_fails_closed
          assert_raises(ValidationError) do
            @deliverer.deliver(make_ref, "answer", event_id: "bad id with spaces")
          end
        end

        def test_derived_event_id_is_deterministic
          first = @deliverer.deliver(make_ref, "answer")
          second = build_deliverer.deliver(make_ref, "answer")

          assert_equal :delivered, second.state
          assert_equal first.ref.session, second.ref.session
          assert_equal first.ref.pane, second.ref.pane
          records = Dir.children(@dir).count { |f| f.end_with?(".json") }
          assert_equal 1, records # same record reused
        end

        # --- Terminal outcomes ----------------------------------------------

        def test_blocked_agent_is_terminal_failure
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_prompt: error_class("AgentBlockedError").new("blocked")
          })

          result = build_deliverer.deliver(make_ref, "answer", event_id: "evt-6")

          assert_equal :failed, result.state
          record = Molecules::DeliveryRecordStore.load(@dir, "evt-6")
          assert_equal "failed", record.state
          assert_equal 1, record.attempts
        end

        def test_missing_pane_is_terminal_failure
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: error_class("PaneNotFoundError").new("gone")
          })

          result = build_deliverer.deliver(make_ref, "answer", event_id: "evt-7")

          assert_equal :failed, result.state
          assert_empty @executor.calls_of(:agent_prompt)
        end

        # --- Retry limits and backoff ---------------------------------------

        def test_transient_failures_retry_with_backoff_then_report_retryable
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_prompt: error_class("AgentNotReadyError").new("stalled")
          })

          result = build_deliverer(max_attempts: 3).deliver(make_ref, "answer", event_id: "evt-8")

          assert_equal :retryable, result.state
          assert_equal 3, @executor.calls_of(:agent_prompt).length
          assert_equal [1, 2], @slept # backoff between attempts, none after last
          record = Molecules::DeliveryRecordStore.load(@dir, "evt-8")
          assert_equal "retryable", record.state
          assert_equal 3, record.attempts
        end

        def test_transient_then_success_delivers
          calls = 0
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_prompt: lambda { |args|
              calls += 1
              next true if calls >= 2

              raise error_class("AgentNotReadyError"), "stalled"
            }
          })

          result = build_deliverer.deliver(make_ref, "answer", event_id: "evt-9")

          assert_equal :delivered, result.state
          assert_equal [1], @slept
        end

        # --- Readiness gate ---------------------------------------------------

        def test_readiness_timeout_after_bootstrap_does_not_prompt
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: error_class("AgentNotFoundError").new("no agent"),
            agent_wait: error_class("AgentNotReadyError").new("timeout")
          })

          result = build_deliverer.deliver(make_ref, "answer", event_id: "evt-10")

          assert_equal :retryable, result.state
          assert_empty @executor.calls_of(:agent_prompt)
          assert_equal "retryable", Molecules::DeliveryRecordStore.load(@dir, "evt-10").state
        end

        # --- Contract input forms ---------------------------------------------

        def test_accepts_hash_ref_from_persisted_event_fields
          result = @deliverer.deliver({"session" => "ws-1", "pane" => "p5"}, "answer", event_id: "evt-11")

          assert_equal :delivered, result.state
          assert_instance_of Ace::Hitl::Providers::Ref, result.ref
        end

        def test_from_config_applies_cascade_defaults
          deliverer = Deliverer.from_config(
            executor: @executor, deliveries_dir: @dir,
            config: {"default_agent_kind" => "codex", "delivery" => {"max_attempts" => 5}}
          )

          assert_equal 5, deliverer.instance_variable_get(:@max_attempts)
          assert_equal "codex", deliverer.instance_variable_get(:@default_agent_kind)
          assert_equal 60_000, deliverer.instance_variable_get(:@agent_start_timeout_ms)
        end

        # --- Review-driven regressions --------------------------------------

        def test_answer_is_persisted_write_ahead_with_restricted_permissions
          @deliverer.deliver(make_ref, "secret answer", event_id: "evt-12")

          record = Molecules::DeliveryRecordStore.load(@dir, "evt-12")
          assert_equal "secret answer", record.answer
          mode = File.stat(Molecules::DeliveryRecordStore.path_for(@dir, "evt-12")).mode & 0o777
          assert_equal 0o600, mode
        end

        def test_resume_redelivers_stored_answer_after_crash
          @executor = HerdrTestHelper::FakeExecutor.new
          build_deliverer.deliver(make_ref, "stored answer", event_id: "evt-13")

          result = build_deliverer.resume("evt-13")

          assert_equal :delivered, result.state
          prompt = @executor.calls_of(:agent_prompt).first
          assert_equal "stored answer", prompt[:args][:text]
        end

        def test_resume_without_stored_answer_fails
          error = assert_raises(ValidationError) { @deliverer.resume("no-such-event") }

          assert_match(/no recoverable answer/, error.message)
        end

        def test_ambiguous_crash_window_is_reported_not_resent
          record = Models::DeliveryRecord.new(
            event_id: "evt-14", session: "ws-1", pane: "p5",
            answer_digest: Ace::Herdr::Atoms::AnswerDigest.call("a"), answer: "a"
          )
          record = record.record_attempt(
            state: "pending", detail: {action: "prompt", outcome: "submitting"},
            timestamp: "t0"
          )
          Molecules::DeliveryRecordStore.save(record, @dir)

          result = @deliverer.deliver(make_ref, "a", event_id: "evt-14")

          assert_equal :failed, result.state
          assert_empty @executor.calls_of(:agent_prompt)
          loaded = Molecules::DeliveryRecordStore.load(@dir, "evt-14")
          assert_equal "failed", loaded.state
          assert_match(/crashed after submitting/, loaded.history.last["error"])
        end

        def test_concurrent_deliveries_of_one_event_prompt_once
          @executor = HerdrTestHelper::FakeExecutor.new
          deliverer = build_deliverer

          threads = 2.times.map do
            Thread.new { deliverer.deliver(make_ref, "answer", event_id: "evt-15") }
          end
          results = threads.map(&:value)

          assert_equal %i[delivered delivered], results.map(&:state)
          assert_equal 1, @executor.calls_of(:agent_prompt).length
        end

        def test_transient_probe_failure_returns_retryable
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            agent_get: Ace::Herdr::ExecutorUnavailableError.new("socket down")
          })

          result = build_deliverer.deliver(make_ref, "answer", event_id: "evt-16")

          assert_equal :retryable, result.state
          loaded = Molecules::DeliveryRecordStore.load(@dir, "evt-16")
          assert_equal "retryable", loaded.state
          assert_equal "probe", loaded.history.last["action"]
        end
      end
    end
  end
end
