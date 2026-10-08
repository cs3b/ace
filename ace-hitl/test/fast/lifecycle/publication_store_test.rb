# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
require "ace/hitl/lifecycle/service_publication_binding"

class PublicationStoreTest < AceHitlTestCase
  include LifecycleFixtures

  def setup
    @peer = {"pid" => Process.pid, "uid" => Process.uid, "gid" => Process.gid, "started_at" => "original"}
    peer = @peer
    kernel = Object.new
    kernel.define_singleton_method(:capture) { |_| peer.dup }
    kernel.define_singleton_method(:live!) { |_| true }
    @authority = Object.new
    @authority.define_singleton_method(:with_publication_hitl!) do |binding:, project:, peer:, &block|
      raise "wrong project" unless project == "ace"
      block.call({"executor_process_binding" => peer, "challenge_ref" => {"ref" => binding.fetch("challenge_digest")}})
    end
    @authority.define_singleton_method(:publication_executor_identity?) { |**| true }
    @binding = Ace::Hitl::Lifecycle::ServicePublicationBinding.new(ordinary: TestBinding.new, authority: @authority, kernel: kernel)
    @selector = {"schema" => "ace.hitl-publication-binding/v1", "mapping_id" => "mapping", "assignment_id" => "assign500",
      "attempt_id" => "attempt500", "request_id" => "publication1", "claim_binding" => "a" * 64,
      "input_digest" => "b" * 64, "candidate_generation" => 1, "head" => "c" * 40, "challenge_digest" => "d" * 64}
    @args = request_args(kind: "otp", otp: otp_context(operation: "publish", result_ref: {"ref" => "d" * 64})).merge(publication_binding: @selector)
  end

  def test_same_delivery_is_idempotent_secret_is_ephemeral_and_consumed_once
    with_lifecycle_root do |root|
      vault = Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new
      store = make_store(root: root, binding: @binding, vault: vault, poll_seconds: 0.01)
      first = store.create(**@args)
      replay = store.create(**@args)
      assert replay.fetch("replay")
      assert_equal first.fetch("envelope"), replay.fetch("envelope")
      assert_raises(Ace::Hitl::Lifecycle::StateError) { store.create(**@args.merge(id: "second")) }
      secret = (1..6).to_a.join
      store.deliver("hitl001", stdin_reader(secret))
      store.deliver("hitl001", stdin_reader(secret))
      Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }.each do |path|
        refute_includes File.binread(path), secret
      end
      assert_equal secret, store.consume("hitl001", timeout: 1, operation: "publish").fetch("answer")
      refute store.consume("hitl001", timeout: 1, operation: "publish").key?("answer")
      assert_raises(Ace::Hitl::Lifecycle::StateError) { store.create(**@args) }
    end
  end

  def test_changed_original_birth_refuses_read_and_cancellation
    with_lifecycle_root do |root|
      store = make_store(root: root, binding: @binding, vault: Ace::Hitl::Lifecycle::OtpVault::MemoryVault.new)
      store.create(**@args)
      @peer["started_at"] = "replacement"
      assert_raises(Ace::Hitl::Lifecycle::BindingError) { store.read("hitl001") }
      assert_raises(Ace::Hitl::Lifecycle::BindingError) { store.cancel("hitl001", reason: "cancel") }
      assert File.file?(File.join(root, "requests", "hitl001.json"))
    end
  end
end
