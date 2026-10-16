# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"

class OperatorQuestionsTest < AceHitlTestCase
  include LifecycleFixtures
  L = Ace::Hitl::Lifecycle

  def setup
    super
    @dir = Dir.mktmpdir("operator-questions", "/tmp")
    @document = {"hitl" => {"operator_uids" => [Process.uid], "transport_uids" => [Process.uid]},
      "authorization" => {"principals" => {Process.uid.to_s => {"projects" => ["ace"]}}}}
    @policy = L::GrantsPolicy.new(document: @document)
    @identity = L::Peer.for_uid(Process.uid)
    @store = store
  end
  def teardown
    FileUtils.rm_rf(@dir)
    super
  end
  def store(identity: @identity)
    L::Store.new(root: File.join(@dir, "state"), binding: L::OperatorOnlyBinding.new,
      policy: @policy, identity: identity, ownership: RecordingOwnership.new, group: Etc.getgrgid(Process.gid).name)
  end
  def ask(**changes)
    @store.operator_question(**{id: "operator001", project: "ace", plan: "Operator question",
      question: "Which documented option?", options: ["A", "B"]}.merge(changes))
  end
  def answer(text = "Option A")
    @store.deliver("operator001", ->(_) { text })
  end

  def test_truthful_question_has_kernel_uid_and_no_execution_binding
    result = ask
    envelope = result.fetch("envelope")
    assert_equal Process.uid, envelope.fetch("requester_uid")
    assert_equal @identity.username, envelope.fetch("requester")
    assert_equal "operator-question", envelope.fetch("context")
    %w[assignment_id attempt_id effect reverse otp].each { |key| refute envelope.key?(key) }
    assert_includes @store.capabilities.fetch("request_contexts"), "operator-question"
    refute_includes @store.capabilities.fetch("request_contexts"), "managed"
    facts = @store.read("operator001")
    assert_equal Process.uid, facts.fetch("requester_uid")
    assert_includes facts.fetch("question"), "Context: Operator question"
    assert_includes facts.fetch("question"), "1. A\n2. B"
    assert_equal Digest::SHA256.hexdigest(facts.fetch("question")), envelope.fetch("payload_sha256")
    assert_equal ["operator001"], @store.pending(project: "ace").map { |value| value.fetch("id") }
  end

  def test_stable_id_retries_restart_and_terminal_receipt_without_another_question
    original = ask.fetch("envelope")
    @store = store
    assert_equal original, ask.fetch("envelope")
    assert ask.fetch("replay")
    answer
    assert_equal "Option A", @store.consume("operator001", timeout: 1).fetch("answer")
    @store = store
    assert_equal "Option A", @store.consume("operator001", timeout: 1).fetch("answer")
    assert_equal original, ask.fetch("envelope")
    assert_empty @store.pending(project: "ace")
  end

  def test_changed_content_project_and_context_fail_without_overwriting
    original = ask.fetch("envelope")
    assert_raises(L::StateError) { ask(question: "Different?") }
    assert_raises(L::StateError) { ask(options: ["C"]) }
    assert_raises(L::PermissionError) { ask(project: "other") }
    assert_equal original, @store.read("operator001").fetch("envelope")
    assert_raises(L::BindingError) do
      @store.create(id: "managed001", assignment: "assign500", attempt: "attempt500", project: "ace",
        plan: "managed", question: "Question", ace_hitl_id: "event001")
    end
  end

  def test_operator_cannot_supply_secret_effect_or_managed_authority
    %i[effect otp assignment attempt requester requester_uid kind publication_binding].each do |field|
      assert_raises(ArgumentError) { ask(**{field => "forged"}) }
    end
    assert_raises(L::AnswerError) { ask(question: "987654") }
    ask
    assert_raises(L::AnswerError) { answer("987654") }
    assert_raises(L::StateError) { @store.consume("operator001", timeout: 1, native_delivery: true) }
    assert_raises(L::StateError) { @store.consume("operator001", timeout: 1, operation: "gem-push") }
  end

  def test_requester_grant_revocation_blocks_read_delivery_consume_and_terminal_replay
    ask
    @document.fetch("hitl")["operator_uids"] = []
    assert_raises(L::PermissionError) { @store.read("operator001") }
    assert_raises(L::PermissionError) { answer }
    assert_raises(L::PermissionError) { @store.consume("operator001", timeout: 1) }
    assert_empty @store.pending(project: "ace")
    @document.fetch("hitl")["operator_uids"] = [Process.uid]
    answer
    @store.consume("operator001", timeout: 1)
    @document.fetch("hitl")["operator_uids"] = []
    assert_raises(L::PermissionError) { @store.consume("operator001", timeout: 1) }
  end

  def test_empty_project_grant_never_grants_all_operator_projects
    @document.fetch("authorization").fetch("principals").fetch(Process.uid.to_s)["projects"] = []
    assert_raises(L::PermissionError) { ask }
  end
  def test_same_claimed_name_with_different_uid_cannot_read_consume_or_retry
    ask
    stranger = L::Peer.new(uid: Process.uid + 1000, gid: Process.gid, username: @identity.username)
    foreign = store(identity: stranger)
    assert_raises(L::PermissionError) { foreign.read("operator001") }
    assert_raises(L::PermissionError) { foreign.consume("operator001", timeout: 1) }
    assert_raises(L::PermissionError) do
      foreign.operator_question(id: "operator001", project: "ace", plan: "Operator question",
        question: "Which documented option?", options: ["A", "B"])
    end
  end

  def test_transport_revocation_is_independent_of_operator_requester_grant
    ask
    @document.fetch("hitl")["transport_uids"] = []
    assert_raises(L::PermissionError) { answer }
    assert_equal "created", @store.read("operator001").fetch("state")
    @document.fetch("hitl")["transport_uids"] = [Process.uid]
    answer
    @store.consume("operator001", timeout: 1)
    assert_raises(L::StateError) { @store.consume("operator001", timeout: 1, operation: "gem-push") }
    assert_raises(L::StateError) { @store.consume("operator001", timeout: 1, native_delivery: true) }
  end

  def test_states_tolerates_projection_removed_during_managed_id_reuse
    managed = make_store(root: File.join(@dir, "managed"))
    managed.create(**request_args)
    managed.cancel("hitl001")
    managed.create(**request_args(id: "keep002"))
    directory = managed.public_dir
    inventory = directory.glob("*.json")
    assert_equal 2, inventory.size
    original = managed.method(:update_public)
    observed = false
    test = self
    managed.define_singleton_method(:update_public) do |value, state, **options|
      # A states caller has inventoried the old projection before the new
      # incarnation removes it. Exercise that real unlink/recreate window.
      test.refute directory.join("hitl001.json").exist?
      managed.stub(:public_dir, directory) do
        directory.stub(:glob, inventory) do
          test.assert_equal ["keep002"], managed.states.map { |entry| entry.fetch("id") }
        end
      end
      observed = true
      original.call(value, state, **options)
    end
    managed.create(**request_args(ace_hitl_id: "ace-hitl-2"))
    assert observed
    assert_equal ["hitl001", "keep002"], managed.states.map { |value| value.fetch("id") }
  end

  def test_terminal_commit_before_cleanup_remains_authoritative_on_recovery
    ask
    answer
    original = @store.method(:update_public)
    @store.define_singleton_method(:update_public) do |value, state, **options|
      raise IOError, "interrupted after terminal commit" if state == "consumed"
      original.call(value, state, **options)
    end
    assert_raises(IOError) { @store.consume("operator001", timeout: 1) }
    @store = store
    assert_equal "consumed", @store.read("operator001").fetch("state")
    assert_empty @store.pending(project: "ace")
    assert ask.fetch("replay")
    assert_equal "Option A", @store.consume("operator001", timeout: 1).fetch("answer")
  end

end
