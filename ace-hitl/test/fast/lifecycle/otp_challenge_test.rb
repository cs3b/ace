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

      # The service restarts: a fresh vault knows nothing, and the
      # requester is prompted again — no persisted verifier exists.
      restarted = make_store(root: root, vault: Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        restarted.consume("hitl001", timeout: 1, operation: "gem-push")
      end
      assert_match(/no OTP is pending/, error.message)
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
