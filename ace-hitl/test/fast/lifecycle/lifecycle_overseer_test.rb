# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# Test successors of lab-config tests/test_hitl.py TransportTest
# (reverse-address rows, M1 audit brief 8wm.t.y21 §6): the bounded,
# type-tagged Overseer response channel — send/pending/ack — plus the
# standing-duty projection (§7).
class LifecycleOverseerTest < AceHitlTestCase
  include LifecycleFixtures

  def make_overseer(root, identity: nil)
    Ace::Hitl::Lifecycle::Overseer.new(
      outbox_dir: File.join(root, "outbox"),
      identity: identity || LifecycleFixtures::TestIdentity.new(username: "mo")
    )
  end

  def test_overseer_queues_bounded_tagged_response
    Dir.mktmpdir do |root|
      outbox = File.join(root, "outbox")
      FileUtils.mkdir_p(outbox)
      overseer = make_overseer(root)
      queued = overseer.send_response(
        reply_to: "321",
        reader: ->(limit) { "[decyzja] Plan jest gotowy. Rekomendacja: A."[0, limit] }
      )
      assert_equal true, queued["queued"]
      assert_equal "321", queued["reply_to_message_id"]

      record = JSON.parse(File.read(Dir.children(outbox).map { |f| File.join(outbox, f) }.first))
      assert_equal "[decyzja] Plan jest gotowy. Rekomendacja: A.", record["response"]
      assert_equal "mo", record["requester"]
    end
  end

  def test_non_overseer_cannot_queue_channel_response
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(
        root,
        identity: LifecycleFixtures::TestIdentity.new(username: "lab-builder")
      )
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        overseer.send_response(reply_to: "321", reader: ->(_limit) { "[info] ready" })
      end
      assert_match(/only the Root Overseer/, error.message)
    end
  end

  def test_response_requires_a_type_tag
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        overseer.send_response(reply_to: "321", reader: ->(_limit) { "Techniczny status bez struktury." })
      end
      assert_match(/type tag/, error.message)
      assert_empty Dir.children(File.join(root, "outbox"))
    end
  end

  def test_response_accepts_each_type_tag
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      root_overseer = make_overseer(root, identity: LifecycleFixtures::TestIdentity.new(username: "root", root: true))
      %w[[decyzja] [pytanie] [info]].each do |tag|
        queued = overseer.send_response(reply_to: "", reader: ->(_limit) { "#{tag} Treść." })
        assert_equal true, queued["queued"], "tag #{tag} must be accepted"
        root_overseer.ack(queued["id"])
      end
    end
  end

  def test_response_rejects_internal_ids_and_hashes
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      [
        "[decyzja] Work W420 ma SHA-256 #{"a" * 64}.",
        "[decyzja] Attempt A-#{"a" * 24} skończony.",
        "[info] Zadanie 8wm.t.y21 zamknięte.",
        "[decyzja] The commit SHA is bad.",
        "[pytanie] Czy wdrożyć commit #{"a" * 40}?"
      ].each do |forbidden|
        error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
          overseer.send_response(reply_to: "321", reader: ->(_limit) { forbidden })
        end
        assert_match(/rewrite for Captain/, error.message)
      end
      assert_empty Dir.children(File.join(root, "outbox"))
    end
  end

  def test_response_bounds_are_enforced
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        overseer.send_response(reply_to: "321", reader: ->(_limit) { "" })
      end
      assert_match(/1-1200/, error.message)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        overseer.send_response(reply_to: "321", reader: ->(limit) { "[info] #{"a" * limit}" })
      end
      assert_match(/1-1200/, error.message)
      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        overseer.send_response(reply_to: "not-digits", reader: ->(_limit) { "[info] ok" })
      end
      assert_match(/invalid source message id/, error.message)
    end
  end

  def test_broker_drains_and_acks_exactly_once
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      queued = overseer.send_response(reply_to: "321", reader: ->(_limit) { "[info] Gotowe." })

      root_overseer = make_overseer(root, identity: LifecycleFixtures::TestIdentity.new(username: "root", root: true))
      pending = root_overseer.pending
      assert_equal 1, pending.length
      assert_equal queued["id"], pending[0]["id"]
      assert_equal "[info] Gotowe.", pending[0]["response"]
      assert_equal "321", pending[0]["reply_to_message_id"]

      acknowledged = root_overseer.ack(queued["id"])
      assert_equal true, acknowledged["acknowledged"]
      assert_empty Dir.children(File.join(root, "outbox"))

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        root_overseer.ack(queued["id"])
      end
      assert_match(/unknown Overseer response/, error.message)
    end
  end

  def test_overseer_pending_and_ack_are_root_only
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "outbox"))
      overseer = make_overseer(root)
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        overseer.pending
      end
      assert_match(/host-broker operation/, error.message)
      error = assert_raises(Ace::Hitl::Lifecycle::PermissionError) do
        overseer.ack("msg-0123456789abcdef")
      end
      assert_match(/host-broker operation/, error.message)
    end
  end

  def test_duty_projects_pending_and_escalated
    with_lifecycle_root do |root|
      store = make_store(root: root, identity: unprivileged_identity)
      script = write_callback_script(root, <<~SH)
        #!/bin/sh
        exit 1
      SH
      store.create(**request_args(id: "hitl001", effect: {
        match: nil, effect_args: [script], effect_cwd: root, effect_timeout: 30
      }))
      store.create(**request_args(id: "hitl002"))

      root_store = make_store(root: root, identity: root_identity)
      root_store.deliver("hitl001", stdin_reader("approved"))
      root_store.deliver("hitl002", stdin_reader("plain answer"))
      # hitl002 consumed by its requester; hitl001 stays answer-delivered.
      make_store(root: root, identity: unprivileged_identity, poll_seconds: 0.05)
        .consume("hitl002", timeout: 1)

      duty = Ace::Hitl::Lifecycle::Duty.project(root_store)
      # Nothing is pending any more: both were delivered.
      assert_empty duty["pending"]
      assert_equal ["hitl001"], duty["escalated"].map { |record| record["id"] }
      assert_equal "callback-escalated", duty["escalated"][0]["effect_state"]

      # A fresh pending request shows with its effect visibility.
      store.create(**request_args(id: "hitl003", effect: {
        match: nil, effect_args: ["/bin/true"], effect_cwd: root, effect_timeout: 30
      }))
      store.create(**request_args(id: "hitl004"))
      duty = Ace::Hitl::Lifecycle::Duty.project(root_store)
      assert_equal %w[hitl003 hitl004], duty["pending"].map { |entry| entry["id"] }
      assert_equal [true, false], duty["pending"].map { |entry| entry["has_effect"] }
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
end
