# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# The OTP contract (spec 8wq.t.34i): a challenge exists ONLY with its
# OTP-required publisher evidence, binds exactly ONE authorized
# operation, and its bytes never persist — the service vault holds them
# in memory, transfers once over the authenticated boundary, and a
# consumed retry replays the receipt without the secret.
class OtpChallengeTest < AceHitlTestCase
  include LifecycleFixtures

  def test_create_rejects_otp_without_the_authorized_operation_challenge
    with_lifecycle_root do |root|
      store = make_store(root: root)
      ["absent", 42, "", {}].each do |bad|
        error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
          store.create(**request_args(kind: "otp", otp: bad))
        end
        assert_match(/OTP challenge|authorized-operation challenge/, error.message)
      end
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_challenge_fields_are_validated_structurally_and_fail_closed
    with_lifecycle_root do |root|
      store = make_store(root: root)
      bad_contexts = [
        otp_context(operation: "GEM PUSH"),     # name charset
        otp_context(result_ref: "multi\nline"), # newline injection
        otp_context(input_digest: "short"),     # not a sha256 hex
        otp_context(expires_in: -10),           # already expired
        otp_context(expires_in: 25 * 60 * 60)   # beyond the 24h bound
      ]
      bad_contexts.each do |context|
        error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
          store.create(**request_args(kind: "otp", otp: context))
        end
        assert_match(/OTP challenge|OTP requests/, error.message)
      end
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_otp_requests_must_not_declare_effect_callbacks
    with_lifecycle_root do |root|
      store = make_store(root: root)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "otp", otp: otp_context,
          effect: {match: nil, effect_args: ["/bin/true"], effect_cwd: Dir.tmpdir, effect_timeout: 30}))
      end
      assert_match(/must not declare an effect callback/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_consume_requires_the_exact_authorized_operation
    with_lifecycle_root do |root|
      store = make_store(root: root)
      root_store = make_store(root: root, identity: root_identity)
      store.create(**request_args(kind: "otp", otp: otp_context(operation: "gem-push")))
      root_store.deliver("hitl001", stdin_reader("654321"))

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1)
      end
      assert_match(/requires the authorized operation/, error.message)

      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        store.consume("hitl001", timeout: 1, operation: "other-op")
      end
      assert_match(/authorized only for operation "gem-push"/, error.message)

      # The exact operation transfers the bytes.
      consumed = store.consume("hitl001", timeout: 1, operation: "gem-push")
      assert_equal "654321", consumed["answer"]
    end
  end

  def test_memory_vault_transfers_once_and_persists_nothing
    with_lifecycle_root do |root|
      vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
      store = make_store(root: root, vault: vault)
      root_store = make_store(root: root, identity: root_identity, vault: vault)
      store.create(**request_args(kind: "otp", otp: otp_context))
      root_store.deliver("hitl001", stdin_reader("654321"))

      # Secret bytes exist nowhere on disk.
      assert_empty Dir.children(File.join(root, "secrets"))
      refute_includes File.read(File.join(root, "public", "hitl001.json")), "654321"

      consumed = store.consume("hitl001", timeout: 1, operation: "gem-push")
      assert_equal "654321", consumed["answer"]

      # The consumed retry replays the receipt — never the bytes.
      replay = store.consume("hitl001", timeout: 1, operation: "gem-push")
      assert_equal true, replay["replay"]
      refute_includes JSON.generate(replay), "654321"
    end
  end

  def test_memory_vault_loses_the_otp_on_service_restart_and_prompts_again
    with_lifecycle_root do |root|
      first_vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
      store = make_store(root: root, vault: first_vault)
      root_store = make_store(root: root, identity: root_identity, vault: first_vault)
      store.create(**request_args(kind: "otp", otp: otp_context))
      root_store.deliver("hitl001", stdin_reader("654321"))

      # The service restarts: a fresh vault knows nothing. The consume
      # WAITS for a delivery that can never come (the answer is gone)
      # and the timeout bounds the wait — the requester prompts again;
      # no persisted verifier exists (review 8x327bue).
      restarted = make_store(root: root, vault: Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        restarted.consume("hitl001", timeout: 1, operation: "gem-push")
      end
      assert_match(/timed out waiting/, error.message)
    end
  end

  def test_expired_challenge_never_hands_over_the_secret
    clock = Struct.new(:now).new(Time.now)
    vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new(ttl_seconds: 60, clock: clock)
    with_lifecycle_root do |root|
      store = make_store(root: root, vault: vault)
      root_store = make_store(root: root, identity: root_identity, vault: vault)
      store.create(**request_args(kind: "otp", otp: otp_context))
      root_store.deliver("hitl001", stdin_reader("654321"))

      clock.now = Time.now + 61
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1, operation: "gem-push")
      end
      assert_match(/expired/, error.message)
    end
  end

  def test_delivered_before_challenge_expiry_cannot_be_consumed_at_or_after_expiry
    [:file, :memory].each do |type|
      [0, 1].each do |offset|
        now = Time.now
        Time.stub(:now, -> { now }) do
          vault = type == :file ? :file : Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
          with_lifecycle_root do |root|
            store = make_store(root: root, vault: vault)
            broker = make_store(root: root, identity: root_identity, vault: vault)
            store.create(**request_args(kind: "otp", otp: otp_context(expires_in: 10)))
            now += 9
            broker.deliver("hitl001", stdin_reader("654321"))
            broker.deliver("hitl001", stdin_reader("123456"))
            now += 1 + offset
            2.times do
              error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
                store.consume("hitl001", timeout: 1, operation: "gem-push")
              end
              assert_match(/expired.*new one/, error.message)
              refute_includes error.message, "654321"
            end
            assert_empty Dir.children(File.join(root, "secrets"))
            refute_equal "consumed", store.read("hitl001")["state"]
          end
        end
      end
    end
  end

  def test_waiting_consume_rechecks_expiry_after_delivery_and_vault_restart
    now = Time.now
    Time.stub(:now, -> { now }) do
      with_lifecycle_root do |root|
        vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
        store = make_store(root: root, vault: vault)
        broker = make_store(root: root, identity: root_identity, vault: vault)
        store.create(**request_args(kind: "otp", otp: otp_context(expires_in: 10)))
        store.define_singleton_method(:sleep) do |_seconds|
          now += 9
          broker.deliver("hitl001", ->(limit) { "654321"[0, limit] })
          now += 1
        end
        error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
          store.consume("hitl001", timeout: 30, operation: "gem-push")
        end
        assert_match(/expired/, error.message)
        restarted = make_store(root: root, vault: Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new)
        assert_raises(Ace::Hitl::Lifecycle::StateError) do
          restarted.consume("hitl001", timeout: 1, operation: "gem-push")
        end
        refute_equal "consumed", store.read("hitl001")["state"]
      end
    end
  end

  def test_a_vault_read_crossing_the_deadline_cannot_commit_success
    now = Time.now
    Time.stub(:now, -> { now }) do
      with_lifecycle_root do |root|
        answer = +"654321"
        vault = Object.new
        vault.define_singleton_method(:write) { |_store, _value, _answer| nil }
        vault.define_singleton_method(:read) do |_store, _value|
          now += 10
          answer
        end
        discarded = false
        vault.define_singleton_method(:discard) { |_store, _value| discarded = true }
        store = make_store(root: root, vault: vault)
        store.create(**request_args(kind: "otp", otp: otp_context(expires_in: 10)))
        assert_raises(Ace::Hitl::Lifecycle::StateError) do
          store.consume("hitl001", timeout: 1, operation: "gem-push")
        end
        assert discarded
        assert_empty answer
        refute_equal "consumed", store.read("hitl001")["state"]
      end
    end
  end

  def test_vault_itself_clamps_retention_to_the_challenge
    clock = Struct.new(:now).new(Time.now)
    vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new(ttl_seconds: 60, clock: clock)
    value = {"id" => "hitl001", "incarnation" => "one", "otp" => {"expires_at" => clock.now.to_i + 10}}
    vault.write(nil, value, "654321")
    clock.now += 10
    assert_raises(Ace::Hitl::Lifecycle::OtpVault::ExpiredError) { vault.read(nil, value) }
    refute vault.peek_present(nil, value)
    assert_raises(Ace::Hitl::Lifecycle::OtpVault::MissError) { vault.read(nil, value) }
  end

  def test_memory_retention_ends_at_the_earlier_deadline
    [5, 20].each do |ttl|
      now = Time.now
      clock = Struct.new(:now).new(now)
      Time.stub(:now, -> { now }) do
        with_lifecycle_root do |root|
          vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new(ttl_seconds: ttl, clock: clock)
          store = make_store(root: root, vault: vault)
          broker = make_store(root: root, identity: root_identity, vault: vault)
          store.create(**request_args(kind: "otp", otp: otp_context(expires_in: 10)))
          broker.deliver("hitl001", stdin_reader("654321"))
          now += [ttl, 10].min
          clock.now = now
          assert_raises(Ace::Hitl::Lifecycle::StateError) do
            store.consume("hitl001", timeout: 1, operation: "gem-push")
          end
        end
      end
    end
  end

  def test_file_vault_stays_the_library_default_with_service_owned_bytes
    with_lifecycle_root do |root|
      store = make_store(root: root)
      root_store = make_store(root: root, identity: root_identity)
      store.create(**request_args(kind: "otp", otp: otp_context))
      root_store.deliver("hitl001", stdin_reader("654321"))

      path = File.join(root, "secrets", "hitl001.answer")
      assert_path_exists path
      assert_equal 0o600, File.stat(path).mode & 0o777
      consumed = store.consume("hitl001", timeout: 1, operation: "gem-push")
      assert_equal "654321", consumed["answer"]
      refute_path_exists path
    end
  end

  def test_deliver_refuses_an_expired_challenge_without_storing_bytes
    with_lifecycle_root do |root|
      vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
      store = make_store(root: root, vault: vault)
      root_store = make_store(root: root, identity: root_identity, vault: vault)
      store.create(**request_args(kind: "otp", otp: otp_context(expires_in: 600)))

      # The challenge lapses after creation (backdated record, same
      # mechanism as the W651 legacy-expiry fixture).
      request_path = File.join(root, "requests", "hitl001.json")
      record = JSON.parse(File.read(request_path))
      record["otp"]["expires_at"] = Time.now.to_i - 10
      File.write(request_path, JSON.generate(record))

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        root_store.deliver("hitl001", stdin_reader("654321"))
      end
      assert_match(/expired/, error.message)
      assert_empty Dir.children(File.join(root, "secrets"))
    end
  end

  def test_malformed_expiry_is_a_classified_validation_error
    with_lifecycle_root do |root|
      store = make_store(root: root)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "otp",
          otp: otp_context.tap { |context| context[:expires_at] = "soon" }))
      end
      assert_match(/unix seconds/, error.message)
    end
  end

  def test_cancel_discards_a_pending_otp_without_exposing_bytes
    with_lifecycle_root do |root|
      vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
      store = make_store(root: root, vault: vault)
      root_store = make_store(root: root, identity: root_identity, vault: vault)
      store.create(**request_args(kind: "otp", otp: otp_context))
      root_store.deliver("hitl001", stdin_reader("654321"))

      store.cancel("hitl001", reason: "wrong window")
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.consume("hitl001", timeout: 1, operation: "gem-push")
      end
      assert_match(/already cancelled/, error.message)
    end
  end
end
