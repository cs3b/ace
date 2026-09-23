# frozen_string_literal: true

require "test_helper"
require "ace/hitl/providers/providers"

class LabProviderTest < AceHitlTestCase
  def stub_transport(request_id: "hitl-deadbeef1234", lab_request_id: "labreq42", fail_submit: false)
    submitted = []
    runner = lambda do |argv|
      if fail_submit
        ["", "lab-hitl: invalid work id", failing_status]
      else
        submitted << argv
        ["{\"id\": \"#{lab_request_id}\"}", "", ok_status]
      end
    end
    transport = Ace::Hitl::Providers::Lab::Transport.new(
      bin: "/usr/local/bin/lab-hitl",
      runner: runner,
      id_generator: -> { request_id }
    )
    [transport, submitted]
  end

  def ok_status
    status = Object.new
    status.define_singleton_method(:success?) { true }
    status.define_singleton_method(:exitstatus) { 0 }
    status
  end

  def failing_status
    status = Object.new
    status.define_singleton_method(:success?) { false }
    status.define_singleton_method(:exitstatus) { 1 }
    status
  end

  def ref
    Ace::Hitl::Providers::Ref.new(session: "w692", pane: "agent-1")
  end

  def test_ask_creates_event_sends_transport_and_persists_contract_fields
    with_hitl_dir do |root|
      with_cli_root(root) do
        transport, submitted = stub_transport
        provider = Ace::Hitl::Providers::Lab.new(transport: transport)

        result = provider.ask(
          question: "Proceed with deploy?",
          ref: ref,
          work: "W685",
          attempt: "A-a73ebdaeb811210d51e0251e",
          effect: {match: nil, effect_args: [], effect_cwd: nil, effect_timeout: nil}
        )

        assert_equal "labreq42", result.request_id
        assert_equal 1, submitted.length

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        event = manager.show(result.event_id)[:event]
        assert_equal "Proceed with deploy?", event.questions.first
        assert_equal "labreq42", event.metadata["lab_request_id"]
        assert_equal "created", event.metadata["lab_request_state"]
        assert_equal "none", event.metadata["lab_request_effect"]
        assert_equal "lab", event.metadata["provider"]
        assert_equal "ace.hitl.ref/v1", event.metadata["ref_schema"]
        assert_equal "w692", event.metadata["ref_session"]
        assert_equal "agent-1", event.metadata["ref_pane"]

        argv = submitted.first
        assert_equal result.event_id, argv[argv.index("--ace-hitl-id") + 1]
      end
    end
  end

  def test_ask_title_defaults_to_question_and_effect_declared_is_persisted
    with_hitl_dir do |root|
      with_cli_root(root) do
        transport, _submitted = stub_transport
        provider = Ace::Hitl::Providers::Lab.new(transport: transport)

        result = provider.ask(
          question: "Ship without tests?",
          title: nil,
          ref: ref,
          work: "W685",
          attempt: "A-a73ebdaeb811210d51e0251e",
          effect: {match: nil, effect_args: ["/bin/false"], effect_cwd: nil, effect_timeout: nil}
        )

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        event = manager.show(result.event_id)[:event]
        assert_equal "Ship without tests?", event.title
        assert_equal "declared", event.metadata["lab_request_effect"]
      end
    end
  end

  def test_transport_failure_raises_provider_unavailable_with_orphan_event_id
    with_hitl_dir do |root|
      with_cli_root(root) do
        transport, _submitted = stub_transport(fail_submit: true)
        provider = Ace::Hitl::Providers::Lab.new(transport: transport)

        error = assert_raises(Ace::Hitl::Providers::ProviderUnavailableError) do
          provider.ask(
            question: "Orphaned?",
            ref: ref,
            work: "BAD",
            attempt: "A-a73ebdaeb811210d51e0251e"
          )
        end

        assert_match(/lab-hitl request failed/, error.message)
        orphan_id = error.message[/HITL event (\S+) was created/, 1]
        refute_nil orphan_id, "error must surface the orphan local event id"

        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root)
        event = manager.show(orphan_id)[:event]
        refute_nil event, "orphan event stays inspectable"
        assert_nil event.metadata["lab_request_id"]
      end
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
end
