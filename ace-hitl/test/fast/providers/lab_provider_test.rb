# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# Provider=lab adapter contract (spec 8wm.t.vrz; store-based ask per
# spec 8wm.t.y21 §1): ONE ask operation = local event + native relay
# request through the generic lifecycle store with the labd-backed
# binding policy.
class LabProviderTest < AceHitlTestCase
  include LifecycleFixtures

  def ref
    Ace::Hitl::Providers::Ref.new(session: "w692", pane: "agent-1")
  end

  def with_provider_store
    Dir.mktmpdir("ace-hitl-provider") do |tmp|
      %w[requests secrets answers public effects].each do |dir|
        FileUtils.mkdir_p(File.join(tmp, dir))
      end
      store = make_store(root: tmp, identity: root_identity)
      provider = Ace::Hitl::Providers::Lab.new(store: store)
      yield provider, tmp, store
    end
  end

  def root_identity
    LifecycleFixtures::TestIdentity.new(username: "lab-admin", root: true)
  end

  def test_ask_creates_event_and_relay_request_and_persists_contract_fields
    with_provider_store do |provider, tmp, store|
      result = provider.ask(
        question: "Proceed with deploy?",
        ref: ref,
        work: "W685",
        attempt: "A-a73ebdaeb811210d51e0251e",
        effect: {match: nil, effect_args: [], effect_cwd: nil, effect_timeout: nil}
      )

      assert_match(/\Ahitl-[0-9a-f]{16}\z/, result.request_id)
      assert_path_exists File.join(tmp, "requests", "#{result.request_id}.json")
      record = JSON.parse(File.read(File.join(tmp, "requests", "#{result.request_id}.json")))
      assert_equal "W685", record["work"]
      assert_equal "Proceed with deploy?", record["question"]
      assert_equal result.event_id, record["ace_hitl_id"]
      assert_path_exists File.join(tmp, "public", "#{result.request_id}.json")

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: tmp)
      event = manager.show(result.event_id)[:event]
      assert_equal "Proceed with deploy?", event.questions.first
      assert_equal result.request_id, event.metadata["lab_request_id"]
      assert_equal "created", event.metadata["lab_request_state"]
      assert_equal "none", event.metadata["lab_request_effect"]
      assert_equal "lab", event.metadata["provider"]
      assert_equal "ace.hitl.ref/v1", event.metadata["ref_schema"]
      assert_equal "w692", event.metadata["ref_session"]
      assert_equal "agent-1", event.metadata["ref_pane"]
    end
  end

  def test_ask_title_defaults_to_question_and_effect_declared_is_persisted
    with_provider_store do |provider, tmp, _store|
      result = provider.ask(
        question: "Ship without tests?",
        title: nil,
        ref: ref,
        work: "W685",
        attempt: "A-a73ebdaeb811210d51e0251e",
        effect: {match: nil, effect_args: ["/bin/false"], effect_cwd: nil, effect_timeout: nil}
      )

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: tmp)
      event = manager.show(result.event_id)[:event]
      assert_equal "Ship without tests?", event.title
      assert_equal "declared", event.metadata["lab_request_effect"]
      record = JSON.parse(File.read(File.join(tmp, "requests", "#{result.request_id}.json")))
      assert_equal ["/bin/false"], record["effect"]["argv"]
    end
  end

  def test_store_failure_raises_provider_unavailable_with_orphan_event_id
    binding = LifecycleFixtures::TestBinding.new(
      on_validate: ->(**_args) { raise Ace::Hitl::Lifecycle::BindingError, "HITL request requires a valid active Work" }
    )
    Dir.mktmpdir("ace-hitl-provider") do |tmp|
      %w[requests secrets answers public effects].each { |dir| FileUtils.mkdir_p(File.join(tmp, dir)) }
      store = make_store(root: tmp, identity: root_identity, binding: binding)
      provider = Ace::Hitl::Providers::Lab.new(store: store)

      error = assert_raises(Ace::Hitl::Providers::ProviderUnavailableError) do
        provider.ask(
          question: "Orphaned?",
          ref: ref,
          work: "BAD",
          attempt: "A-a73ebdaeb811210d51e0251e"
        )
      end

      assert_match(/invalid work id/, error.message)
      orphan_id = error.message[/HITL event (\S+) was created/, 1]
      refute_nil orphan_id, "error must surface the orphan local event id"

      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: tmp)
      event = manager.show(orphan_id)[:event]
      refute_nil event, "orphan event stays inspectable"
      assert_nil event.metadata["lab_request_id"]
    end
  end

  def test_deliver_is_declared_but_not_implemented_until_push_delivery_lands
    provider = Ace::Hitl::Providers::Lab.new

    error = assert_raises(Ace::Hitl::Providers::UnsupportedOperationError) do
      provider.deliver(ref, "Use JWT with refresh tokens.")
    end

    assert_match(/does not deliver yet/, error.message)
    assert_match(/ace-herdr/, error.message)
  end

  def test_wait_is_not_implemented_through_the_adapter
    provider = Ace::Hitl::Providers::Lab.new

    error = assert_raises(Ace::Hitl::Providers::UnsupportedOperationError) do
      provider.wait(ref)
    end

    assert_match(/ace-hitl wait command/, error.message)
  end

  def test_lifecycle_store_factory_builds_a_store_with_the_labd_binding
    with_env("ACE_HITL_STORE_ROOT" => "/tmp/factory-root") do
      store = Ace::Hitl::Providers::Lab.lifecycle_store
      assert_instance_of Ace::Hitl::Lifecycle::Store, store
      assert_instance_of Ace::Hitl::Providers::Lab::DaemonBinding, store.binding
      assert_equal "/tmp/factory-root", store.root.to_s
    end

    sentinel = Object.new
    assert_same sentinel, Ace::Hitl::Providers::Lab.lifecycle_store(store: sentinel)
  end
end
