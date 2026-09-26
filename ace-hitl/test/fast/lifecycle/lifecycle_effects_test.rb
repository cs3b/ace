# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# Test successor of the deployed 8wl.t.ga9 effect contract (recovered;
# the lab-config tests/test_hitl_effects.py does not exist on this
# snapshot): callback declared by the requester, executed AS THE
# REQUESTER after the answer relay, exec-argv with {answer}, regex gate,
# timeout, log redaction, deduped escalation, callback-* states — all on
# the REAL filesystem with real child processes.
class LifecycleEffectsTest < AceHitlTestCase
  include LifecycleFixtures

  def test_callback_executes_as_requester_with_answer_substitution
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        printf '%s\\n' "$1" >> "#{root}/received.txt"
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script, "{answer}"], effect_cwd: root, effect_timeout: 30
      }))

      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("app-roved"))

      assert_equal "app-roved\n", File.read(File.join(root, "received.txt"))
      assert_equal "callback-ok", public_effect_state(root)
      log = effects_log(root)
      assert_equal "ok", log["attempts"][0]["outcome"]
      assert_equal 0, log["attempts"][0]["exit_status"]
    end
  end

  def test_match_gate_blocks_execution_and_records_match_failed
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        printf '%s\\n' "$1" >> "#{root}/received.txt"
      SH
      store.create(**request_args(effect: {
        match: "[0-9]{4}", effect_args: [script, "{answer}"], effect_cwd: root, effect_timeout: 30
      }))

      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("abcd"))

      refute_path_exists File.join(root, "received.txt")
      assert_equal "callback-escalated", public_effect_state(root)
      log = effects_log(root)
      assert_equal false, log["attempts"][0]["match_ok"]
      assert_equal "escalated", log["attempts"][0]["outcome"]
    end
  end

  def test_fullmatch_requires_the_whole_answer
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        printf '%s\\n' "$1" >> "#{root}/received.txt"
      SH
      store.create(**request_args(effect: {
        match: "[0-9]{4}", effect_args: [script, "{answer}"], effect_cwd: root, effect_timeout: 30
      }))

      # A fullmatch gate: a superset string does not match either.
      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("12345"))

      refute_path_exists File.join(root, "received.txt")
      assert_equal "callback-escalated", public_effect_state(root)
    end
  end

  def test_callback_failure_escalates
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        exit 3
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 30
      }))

      delivered = make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("approved"))

      # The answer is ALWAYS relayed, even when the callback fails.
      assert_equal true, delivered["delivered"]
      assert_equal "approved", File.read(File.join(root, "answers", "hitl001.answer"))
      assert_equal "callback-escalated", public_effect_state(root)
      assert_equal "escalated", effects_log(root)["attempts"][0]["outcome"]
    end
  end

  def test_callback_timeout_kills_and_escalates
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity, poll_seconds: 0.05)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        sleep 30
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 1
      }))

      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("approved"))

      log = effects_log(root)
      assert_equal true, log["attempts"][0]["timed_out"]
      assert_equal "escalated", log["attempts"][0]["outcome"]
      assert_equal "callback-escalated", public_effect_state(root)
      # The relay still happened and consumption keeps working.
      consumed = store.consume("hitl001", timeout: 1)
      assert_equal "approved", consumed["answer"]
    end
  end

  def test_effects_log_is_redacted_and_escalation_is_deduped
    with_lifecycle_root do |root|
      sink_calls = []
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        exit 1
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script, "answer-was-{answer}"], effect_cwd: root, effect_timeout: 30
      }))
      root_store = make_store(root: root, identity: root_identity)
      root_store.escalation_sink = lambda do |**kwargs|
        sink_calls << kwargs
      end

      root_store.deliver("hitl001", stdin_reader("s3cr3t-answer"))

      raw_log = File.read(File.join(root, "effects", "hitl001.json"))
      refute_includes raw_log, "s3cr3t-answer"
      refute_includes raw_log, "answer-was-s3cr3t-answer"
      refute_includes raw_log, "script"
      refute_includes raw_log, "argv"
      log = effects_log(root)
      assert_equal true, log["escalated"] && log["escalated"].is_a?(Hash)
      assert_equal 1, sink_calls.length
      assert_equal "hitl001", sink_calls[0][:request_id]

      # Deduped: no second escalation path exists — the projection keeps
      # one escalated state and the effects log one escalation marker.
      assert_equal "callback-escalated", public_effect_state(root)
    end
  end

  def test_no_sink_wired_records_state_without_spooling
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        exit 1
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 30
      }))

      make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("approved"))

      assert_equal "callback-escalated", public_effect_state(root)
      assert_equal "escalated", effects_log(root)["attempts"][0]["outcome"]
    end
  end

  def test_spawn_failure_escalates_and_deliver_completes
    with_lifecycle_root do |root|
      sink_calls = []
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(effect: {
        match: nil, effect_args: ["/definitely/absent/hitl-callback"], effect_cwd: root, effect_timeout: 30
      }))
      root_store = make_store(root: root, identity: root_identity)
      root_store.escalation_sink = lambda do |**kwargs|
        sink_calls << kwargs
      end

      delivered = root_store.deliver("hitl001", stdin_reader("approved"))

      # The answer is ALWAYS relayed; the spawn failure is recorded as a
      # deduped escalation outcome instead of crashing deliver (review
      # F2 on W696).
      assert_equal true, delivered["delivered"]
      assert_equal "approved", File.read(File.join(root, "answers", "hitl001.answer"))
      assert_equal "callback-escalated", public_effect_state(root)
      log = effects_log(root)
      assert_equal "escalated", log["attempts"][0]["outcome"]
      assert_equal "Errno::ENOENT", log["attempts"][0]["error"]
      assert_equal 1, sink_calls.length
      assert_equal "hitl001", sink_calls[0][:request_id]
    end
  end

  def test_non_executable_callback_escalates_and_deliver_completes
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = File.join(root, "callback.sh")
      File.write(script, "#!/bin/sh\nexit 0\n")
      File.chmod(0o644, script)
      store.create(**request_args(effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 30
      }))

      delivered = make_store(root: root, identity: root_identity).deliver("hitl001", stdin_reader("approved"))

      assert_equal true, delivered["delivered"]
      assert_equal "approved", File.read(File.join(root, "answers", "hitl001.answer"))
      assert_equal "callback-escalated", public_effect_state(root)
      log = effects_log(root)
      assert_equal "escalated", log["attempts"][0]["outcome"]
      assert_equal "Errno::EACCES", log["attempts"][0]["error"]
    end
  end

  def test_child_spawn_happens_inside_the_dropped_groups_window
    with_lifecycle_root do |root|
      dropped = []
      fake_spawner = Object.new
      exited = Object.new
      exited.define_singleton_method(:exitstatus) { 0 }
      fake_spawner.define_singleton_method(:spawn) do |*_argv, **_options|
        99_999
      end
      fake_spawner.define_singleton_method(:waitpid2) do |*_args|
        [nil, exited]
      end
      dropper = Object.new
      dropper.define_singleton_method(:call) do |gid, &block|
        dropped << gid
        block.call
      end

      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(effect: {
        match: nil, effect_args: ["/bin/true"], effect_cwd: root, effect_timeout: 30
      }))
      Ace::Hitl::Lifecycle::Effects.run(
        store,
        JSON.parse(File.read(File.join(root, "requests", "hitl001.json"))),
        "the-answer",
        requester_uid: 1234,
        requester_gid: 966,
        identity: LifecycleFixtures::TestIdentity.new(username: "lab-admin", root: true),
        spawner: fake_spawner,
        group_dropper: dropper
      )

      # The supplementary-group drop wraps the spawn window itself: the
      # forked child inherits the dropped list (review F7 on W696).
      assert_equal [966], dropped
      assert_equal "callback-ok", public_effect_state(root)
    end
  end

  def test_non_root_executor_facing_foreign_requester_fails_closed
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        exit 0
      SH
      store.create(**request_args(effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 30
      }))
      value = JSON.parse(File.read(File.join(root, "requests", "hitl001.json")))

      # A non-root executor of a foreign requester's callback.
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        Ace::Hitl::Lifecycle::Effects.run(
          store, value, "approved",
          requester_uid: 1234, requester_gid: 966,
          identity: LifecycleFixtures::TestIdentity.new(username: "broker", root: false, euid: 4242)
        )
      end
      assert_match(/root authority to drop/, error.message)
    end
  end

  def test_root_drops_to_the_requester_identity_for_the_callback
    with_lifecycle_root do |root|
      spawned = []
      fake_spawner = Object.new
      exited = Object.new
      exited.define_singleton_method(:exitstatus) { 0 }
      fake_spawner.define_singleton_method(:spawn) do |*argv, **options|
        spawned << [argv, options]
        99_999
      end
      fake_spawner.define_singleton_method(:waitpid2) do |*_args|
        [nil, exited]
      end

      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(effect: {
        match: nil, effect_args: ["/bin/true"], effect_cwd: root, effect_timeout: 30
      }))
      Ace::Hitl::Lifecycle::Effects.run(
        store,
        JSON.parse(File.read(File.join(root, "requests", "hitl001.json"))),
        "the-answer",
        requester_uid: 1234,
        requester_gid: 966,
        identity: LifecycleFixtures::TestIdentity.new(username: "lab-admin", root: true),
        spawner: fake_spawner
      )

      argv, options = spawned[0]
      assert_equal ["/bin/true"], argv
      assert_equal 1234, options[:uid]
      assert_equal 966, options[:gid]
      assert_equal root, options[:chdir]
      assert_equal "callback-ok", public_effect_state(root)
    end
  end

  def test_effect_declaration_bounds_are_enforced_at_the_store_boundary
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      error = assert_raises(Ace::Hitl::Lifecycle::Effects::DeclarationError) do
        store.create(**request_args(effect: {
          match: nil, effect_args: [], effect_cwd: root, effect_timeout: 30
        }))
      end
      assert_match(/at least one --effect-arg/, error.message)

      error = assert_raises(Ace::Hitl::Lifecycle::Effects::DeclarationError) do
        store.create(**request_args(effect: {
          match: nil, effect_args: ["/bin/true"], effect_cwd: "/definitely/not/here", effect_timeout: 30
        }))
      end
      assert_match(/does not exist/, error.message)
      assert_empty Dir.children(File.join(root, "requests"))
    end
  end

  def test_cwd_less_declaration_is_rejected_at_declaration_time
    # The declaration error sits inside the lifecycle error taxonomy:
    # typed rescues (Providers::Lab#ask orphan-event wrapper) catch it
    # instead of a raw backtrace escaping to the CLI (review F-R1 on
    # W696).
    assert_operator(
      Ace::Hitl::Lifecycle::Effects::DeclarationError, :<,
      Ace::Hitl::Lifecycle::Error
    )
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      [nil, ""].each do |missing_cwd|
        error = assert_raises(Ace::Hitl::Lifecycle::Effects::DeclarationError) do
          store.create(**request_args(effect: {
            match: nil, effect_args: ["/bin/true"], effect_cwd: missing_cwd, effect_timeout: 30
          }))
        end
        assert_match(/--effect-cwd is required/, error.message)
      end
      # The typed rejection happens at the declaration boundary: nothing
      # is persisted, so a cwd-less callback can never reach answer time
      # as a misleading Errno::ENOENT escalation (review F-A on W696).
      assert_empty Dir.children(File.join(root, "requests"))
      assert_empty Dir.children(File.join(root, "public"))
    end
  end

  def test_effect_declaration_is_persisted_verbatim_in_the_deployed_shape
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      store.create(**request_args(effect: {
        match: "[0-9]{4}", effect_args: ["/bin/false"], effect_cwd: root, effect_timeout: 45
      }))
      persisted = JSON.parse(File.read(File.join(root, "requests", "hitl001.json")))
      assert_equal({
        "argv" => ["/bin/false"],
        "cwd" => root,
        "match" => "[0-9]{4}",
        "timeout_s" => 45
      }, persisted["effect"])

      duty = Ace::Hitl::Lifecycle::Duty.project(make_store(root: root, identity: root_identity))
      assert_equal [true], duty["pending"].map { |entry| entry["has_effect"] }
    end
  end

  private

  def unprivileged_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: false)
  end

  def root_identity
    LifecycleFixtures::TestIdentity.new(username: "lab-admin", root: true)
  end

  def write_callback_script(root, body)
    script = File.join(root, "callback.sh")
    File.write(script, body)
    File.chmod(0o755, script)
    script
  end

  def exited_status(code)
    status = Object.new
    status.define_singleton_method(:exitstatus) { code }
    status
  end

  def public_state(root)
    JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["state"]
  end

  def public_effect_state(root)
    JSON.parse(File.read(File.join(root, "public", "hitl001.json")))["effect_state"]
  end

  def effects_log(root)
    JSON.parse(File.read(File.join(root, "effects", "hitl001.json")))
  end
end
