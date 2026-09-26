# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# Test successors of lab-config tests/test_hitl.py TransportTest
# (lifecycle rows, M1 audit brief 8wm.t.y21): the generic request
# lifecycle — create/pending/states/deliver/consume/cancel — exercised
# against the REAL filesystem with real flock and real file modes.
class LifecycleStoreTest < AceHitlTestCase
  include LifecycleFixtures

  def unprivileged_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: false)
  end

  def root_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: true)
  end

  def test_create_requires_exact_attempt_id
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(attempt: ""))
      end
      assert_match(/exact active Attempt id/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_secret_kind_is_rejected_before_persistence
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "secret"))
      end
      assert_match(/approved otp kind/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_create_validates_binding_for_otp_and_non_admin_and_persists_requester
    with_lifecycle_root do |root|
      binding = LifecycleFixtures::TestBinding.new
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      # Admin otp requests always validate.
      store.create(**request_args(kind: "otp"))
      assert_equal 1, binding.validations.length

      # Admin non-otp requests skip the binding, as migrated.
      store.create(**request_args(id: "hitl002"))
      assert_equal 1, binding.validations.length

      # Non-admin requesters validate even for plain kinds.
      mo_store = make_store(root: root, identity: unprivileged_identity("mo"), binding: binding)
      mo_store.create(**request_args(id: "hitl003", kind: "text", harness: "overseer-codex"))
      assert_equal 2, binding.validations.length

      persisted = JSON.parse(File.read(File.join(root, "requests", "hitl003.json")))
      assert_equal "mo", persisted["requester"]
    end
  end

  def test_binding_rejection_fails_closed_without_creating_a_request
    with_lifecycle_root do |root|
      binding = LifecycleFixtures::TestBinding.new(
        on_validate: ->(work:, attempt:, project:, requester:) {
          raise Ace::Hitl::Lifecycle::BindingError,
            "HITL request is not bound to the exact active Work Attempt"
        }
      )
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        store.create(**request_args(kind: "otp"))
      end
      assert_match(/exact active Work Attempt/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
      assert_empty Dir.children(File.join(root, "public"))
    end
  end

  def test_otp_request_rejects_choices_and_records_sensitive_shape
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "otp", options: ["approve"]))
      end
      assert_match(/must not offer choices/, error.message)

      store.create(**request_args(kind: "otp"))
      persisted = JSON.parse(File.read(File.join(root, "requests", "hitl001.json")))
      assert_equal "otp", persisted["kind"]
      assert_equal true, persisted["sensitive"]
      assert_empty persisted["options"]
      assert_equal "lab-admin", persisted["requester"]
    end
  end

  def test_no_time_based_expiry_is_ever_recorded
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      created = store.create(**request_args(kind: "otp"))
      refute_includes created.keys, "expires_at"
      refute_includes JSON.parse(File.read(File.join(root, "requests", "hitl001.json")).then { |s| s }).keys, "expires_at"
      public = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      refute_includes public.keys, "expires_at"
      assert_equal "created", public["state"]
    end
  end

  def test_lifecycle_preserves_attempt_without_exposing_answer
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      created = store.create(**request_args)
      attempt = created["attempt"]

      root_store = make_store(root: root, identity: root_identity)
      delivered = root_store.deliver("hitl001", stdin_reader("approved"))
      assert_equal attempt, delivered["attempt"]
      refute_includes JSON.generate(delivered), "answer"
      assert_equal "answer-delivered", public_state(root)

      consumed = store.consume("hitl001", timeout: 1)
      assert_equal "approved", consumed["answer"]
      public = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal attempt, public["attempt"]
      assert_equal "consumed", public["state"]
      refute_includes JSON.generate(public), "answer"
    end
  end

  def test_deliver_rejects_terminal_attempt_cancels_and_fails_closed
    with_lifecycle_root do |root|
      binding = LifecycleFixtures::TestBinding.new(
        on_active: ->(work:, attempt:) {
          raise Ace::Hitl::Lifecycle::BindingError, "HITL Attempt is no longer active"
        }
      )
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      store.create(**request_args)

      root_store = make_store(root: root, identity: root_identity, binding: binding)
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        root_store.deliver("hitl001", stdin_reader("approved"))
      end
      assert_match(/no longer active/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
      assert_equal "cancelled", public_state(root)
    end
  end

  def test_deliver_rejects_mismatched_attempt
    with_lifecycle_root do |root|
      binding = LifecycleFixtures::TestBinding.new(
        on_active: ->(work:, attempt:) {
          raise Ace::Hitl::Lifecycle::BindingError,
            "HITL request is not bound to the exact active Work Attempt"
        }
      )
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      store.create(**request_args)

      root_store = make_store(root: root, identity: root_identity, binding: binding)
      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        root_store.deliver("hitl001", stdin_reader("approved"))
      end
      assert_match(/does not match|not bound/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_otp_deliver_requires_exactly_six_ascii_digits
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      root_store = make_store(root: root, identity: root_identity)

      ["12345", "1234567", "12a456", "otp: 123456"].each do |bad|
        error = assert_raises(Ace::Hitl::Lifecycle::AnswerError) do
          root_store.deliver("hitl001", stdin_reader(bad))
        end
        assert_match(/exactly six ASCII digits/, error.message)
      end
      assert_empty Dir.children(File.join(root, "secrets"))

      delivered = root_store.deliver("hitl001", stdin_reader("123456"))
      assert_equal true, delivered["sensitive"]
      refute_includes JSON.generate(delivered), "answer"
      assert_equal "123456", File.read(File.join(root, "secrets", "hitl001.answer"))
      refute_includes File.read(File.join(root, "public", "hitl001.json")), "123456"

      consumed = store.consume("hitl001", timeout: 1)
      assert_equal "123456", consumed["answer"]
    end
  end

  def test_non_otp_deliver_rejects_secret_shaped_answers_including_bare_digits
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args)
      root_store = make_store(root: root, identity: root_identity)

      ["123456", "otp: 123456", "github_pat_AbC1234567890", "sk-proj-abcdefghij0123456789"].each do |forbidden|
        error = assert_raises(Ace::Hitl::Lifecycle::AnswerError) do
          root_store.deliver("hitl001", stdin_reader(forbidden))
        end
        assert_match(/secret-shaped/, error.message)
      end
      assert_empty Dir.children(File.join(root, "answers"))
    end
  end

  def test_deliver_holds_the_per_request_lock_inside_its_critical_section
    with_lifecycle_root do |root|
      request_path = File.join(root, "requests", "hitl001.json")
      gated = nil
      binding = LifecycleFixtures::TestBinding.new(
        on_active: ->(work:, attempt:) {
          File.open(request_path, "r") do |probe|
            # The stop-side cancellation protocol must be excluded:
            # a non-blocking exclusive acquisition fails.
            gated = probe.flock(File::LOCK_EX | File::LOCK_NB)
            probe.flock(File::LOCK_UN)
          end
        }
      )
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      store.create(**request_args)

      root_store = make_store(root: root, identity: root_identity, binding: binding)
      root_store.deliver("hitl001", stdin_reader("approved"))
      refute gated, "deliver must hold the request flock inside its critical section"
    end
  end

  def test_consume_rejects_attempt_terminalized_before_answer
    with_lifecycle_root do |root|
      binding = LifecycleFixtures::TestBinding.new(
        on_active: ->(work:, attempt:) {
          raise Ace::Hitl::Lifecycle::BindingError, "HITL Attempt is no longer active"
        }
      )
      store = make_store(root: root, identity: unprivileged_identity, binding: binding)
      store.create(**request_args)

      error = assert_raises(Ace::Hitl::Lifecycle::BindingError) do
        store.consume("hitl001", timeout: 1)
      end
      assert_match(/no longer active/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
      assert_equal "cancelled", public_state(root)
    end
  end

  def test_consume_commits_the_terminal_transition_under_the_request_lock
    with_lifecycle_root do |root|
      request_path = File.join(root, "requests", "hitl001.json")
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args)
      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("approved"))

      # Probe the per-request flock inside the terminal transition: a
      # non-blocking exclusive acquisition must FAIL while consume holds
      # the lock (review F5 on W696).
      lock_held = []
      consumer = make_store(root: root, identity: unprivileged_identity)
      consumer.define_singleton_method(:update_public) do |value, state, audit: nil|
        File.open(request_path, "r") do |probe|
          denied = probe.flock(File::LOCK_EX | File::LOCK_NB) == false
          probe.flock(File::LOCK_UN) unless denied
          lock_held << denied
        end
        super(value, state, audit: audit)
      end
      consumer.define_singleton_method(:remove_request) do |value, keep_public: false|
        File.open(request_path, "r") do |probe|
          denied = probe.flock(File::LOCK_EX | File::LOCK_NB) == false
          probe.flock(File::LOCK_UN) unless denied
          lock_held << denied
        end
        super(value, keep_public: keep_public)
      end

      consumed = consumer.consume("hitl001", timeout: 1)

      assert_equal "approved", consumed["answer"]
      assert_equal [true, true], lock_held,
        "the consumed transition and the removal must commit under the flock"
      assert_equal "consumed", JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["state"]
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_lock_on_vanished_record_fails_closed_as_state_error
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.send(:with_request_lock, "absent1") {}
      end
      assert_match(/unknown or invalid HITL request/, error.message)
    end
  end

  def test_create_provisions_the_store_layout_with_pinned_modes
    Dir.mktmpdir("ace-hitl-provision") do |tmp|
      root = File.join(tmp, "store")
      previous = File.umask(0o000)
      begin
        store = make_store(root: root, identity: unprivileged_identity)
        store.create(**request_args)
      ensure
        File.umask(previous)
      end

      # The modes are pinned by spec §2 regardless of the creating
      # process umask (review F6 on W696).
      assert_equal 0o700, File.stat(root).mode & 0o777
      assert_equal 0o755, File.stat(File.join(root, "public")).mode & 0o777
      %w[requests secrets answers effects].each do |name|
        assert_equal 0o700, File.stat(File.join(root, name)).mode & 0o777, name
      end
      assert_path_exists File.join(root, "requests", "hitl001.json")
    end
  end

  def test_cancel_preserves_exact_attempt_reference
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args)
      cancelled = store.cancel("hitl001")
      assert_equal true, cancelled["cancelled"]
      public = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "cancelled", public["state"]
      assert_equal "A-#{"a" * 24}", public["attempt"]
    end
  end

  def test_request_stays_pending_far_beyond_a_legacy_expiry_and_is_still_answered
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      # A backdated pre-W651 record still carrying a long-past expiry.
      request_path = File.join(root, "requests", "hitl001.json")
      record = JSON.parse(File.read(request_path))
      record["created_at"] = Time.now.to_i - 3600
      record["expires_at"] = Time.now.to_i - 3000
      File.write(request_path, JSON.generate(record))

      root_store = make_store(root: root, identity: root_identity)
      assert_equal ["hitl001"], root_store.pending.map { |item| item["id"] }
      assert_path_exists request_path

      delivered = root_store.deliver("hitl001", stdin_reader("654321"))
      assert_equal true, delivered["delivered"]
      consumed = store.consume("hitl001", timeout: 1)
      assert_equal "654321", consumed["answer"]
      assert_equal "consumed", public_state(root)
    end
  end

  def test_consume_waits_indefinitely_and_resumes_on_a_late_answer
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity, poll_seconds: 0.05)
      store.create(**request_args(kind: "otp"))
      request_path = File.join(root, "requests", "hitl001.json")
      record = JSON.parse(File.read(request_path))
      record["created_at"] = Time.now.to_i - 3600
      record["expires_at"] = Time.now.to_i - 3000
      File.write(request_path, JSON.generate(record))

      root_store = make_store(root: root, identity: root_identity)
      answerer = Thread.new do
        sleep 0.3
        root_store.deliver("hitl001", stdin_reader("654321"))
      end
      consumed = store.consume("hitl001", timeout: 0)
      answerer.join(30)
      refute answerer.alive?
      assert_equal "654321", consumed["answer"]
      refute_path_exists request_path
      refute_path_exists File.join(root, "secrets", "hitl001.answer")
      public = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "consumed", public["state"]
      refute_includes JSON.generate(public), "654321"
    end
  end

  def test_consume_timeout_bounds_only_the_local_wait
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity, poll_seconds: 0.05)
      store.create(**request_args)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1)
      end
      assert_match(/request remains pending/, error.message)
      assert_path_exists File.join(root, "requests", "hitl001.json")
    end
  end

  def test_explicit_cancel_is_audited_and_a_late_answer_fails_closed
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      cancelled = store.cancel("hitl001", reason: "operator stopped the publication")
      assert_equal "lab-admin", cancelled["cancelled_by"]
      assert_equal "operator stopped the publication", cancelled["reason"]

      public = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "cancelled", public["state"]
      assert_equal "lab-admin", public["cancelled_by"]
      assert_equal "operator stopped the publication", public["reason"]
      assert_equal "A-#{"a" * 24}", public["attempt"]

      root_store = make_store(root: root, identity: root_identity)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        root_store.deliver("hitl001", stdin_reader("654321"))
      end
      assert_match(/unknown or invalid HITL request/, error.message)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1)
      end
      assert_match(/unknown or invalid HITL request/, error.message)

      states = make_store(root: root, identity: root_identity).states
      assert_equal ["hitl001"], states.map { |item| item["id"] }
      assert_equal "cancelled", states[0]["state"]
    end
  end

  def test_answers_fail_closed_for_duplicates_and_foreign_requesters
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      root_store = make_store(root: root, identity: root_identity)
      root_store.deliver("hitl001", stdin_reader("654321"))

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        root_store.deliver("hitl001", stdin_reader("654321"))
      end
      assert_match(/already has an answer/, error.message)

      foreign = make_store(root: root, identity: unprivileged_identity("mo"))
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        foreign.consume("hitl001", timeout: 1)
      end
      assert_match(/only the requesting role/, error.message)

      consumed = store.consume("hitl001", timeout: 1)
      assert_equal "654321", consumed["answer"]
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1)
      end
      assert_match(/unknown or invalid HITL request/, error.message)
      refute_path_exists File.join(root, "secrets", "hitl001.answer")
      assert_equal "consumed", public_state(root)
    end
  end

  def test_root_delivery_preserves_requester_ownership
    with_lifecycle_root do |root|
      ownership = LifecycleFixtures::RecordingOwnership.new
      identity = root_identity
      store = make_store(root: root, identity: identity, ownership: ownership)
      # A request whose requester is a foreign identity with distinct ids.
      foreign = LifecycleFixtures::TestIdentity.new(username: "mo", root: true)
      creator = make_store(root: root, identity: foreign, ownership: ownership)
      creator.create(**request_args)

      store.deliver("hitl001", stdin_reader("approved"))
      # The answer file transition carries the requester's exact ids.
      answer_transition = find_transition(ownership, "answers")
      refute_nil answer_transition
      assert_equal [1234, 1234], [answer_transition[1], answer_transition[2]]
      # The public projection carries the requester uid with the
      # control group gid (port of the chown(1234, 966) contract).
      public_transition = find_transition(ownership, "public")
      refute_nil public_transition
      assert_equal 1234, public_transition[1]
      assert_equal 966, public_transition[2]
    end
  end

  def test_public_projection_file_mode_is_0440_and_answer_0400
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("654321"))
      assert_equal 0o440, File.stat(File.join(root, "public", "hitl001.json")).mode & 0o777
      assert_equal 0o400, File.stat(File.join(root, "secrets", "hitl001.answer")).mode & 0o777
    end
  end

  def test_duplicate_request_id_fails_closed_keeping_the_original
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(kind: "otp"))
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "otp"))
      end
      assert_match(/already exists/, error.message)
      assert_equal ["hitl001.json"], Dir.children(File.join(root, "requests")).sort
    end
  end

  def test_reused_request_id_starts_clean_from_the_previous_incarnation
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      root_store = make_store(root: root, identity: root_identity)

      # First incarnation: its callback escalates, then the request is
      # consumed (terminal, artifacts kept by design).
      store.create(**request_args(effect: {
        match: nil, effect_args: ["/bin/false"], effect_cwd: root, effect_timeout: 30
      }))
      root_store.deliver("hitl001", stdin_reader("first"))
      store.consume("hitl001", timeout: 1)
      assert_equal "escalated", effects_log(root)["attempts"][0]["outcome"]

      # Reuse the exact same id: the new incarnation must not inherit
      # the stale public projection or the stale effects log (review
      # F-B on W696).
      store.create(**request_args(effect: {
        match: nil, effect_args: ["/bin/true"], effect_cwd: root, effect_timeout: 30
      }))
      refute_path_exists File.join(root, "effects", "hitl001.json")
      public_record = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "created", public_record["state"]
      refute public_record.key?("effect_state")

      # The second incarnation runs on a genuinely fresh log: exactly
      # one new attempt, no inherited escalation marker.
      root_store.deliver("hitl001", stdin_reader("second"))
      log = effects_log(root)
      assert_equal 1, log["attempts"].length
      assert_equal "ok", log["attempts"][0]["outcome"]
      assert_nil log["escalated"]
      assert_equal "callback-ok", public_effect_state(root)
    end
  end

  def test_root_only_operations_reject_unprivileged_callers
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      ["pending", "states"].each do |operation|
        error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
          store.public_send(operation)
        end
        assert_match(/host-broker operation/, error.message)
      end
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        store.deliver("hitl001", stdin_reader("approved"))
      end
      assert_match(/host-broker operation/, error.message)
    end
  end

  private

  def public_state(root)
    JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["state"]
  end

  def public_effect_state(root)
    JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["effect_state"]
  end

  def effects_log(root)
    JSON.parse(File.read(File.join(root, "effects", "hitl001.json")))
  end

  def find_transition(ownership, dir_suffix)
    ownership.transitions.reverse.find do |(path, _uid, _gid)|
      Pathname.new(path).dirname.to_s.end_with?(dir_suffix)
    end
  end
end
