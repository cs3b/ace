# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"

class ProposalCreationBoundaryTest < AceHitlTestCase
  include LifecycleFixtures
  class DecisionPolicy < AllowTransportPolicy
    def proposal?(_peer, project:); project == "ace"; end
  end

  def test_ordinary_questions_keep_the_character_limit
    with_lifecycle_root do |root|
      store = make_store(root: root)
      value = store.create(**request_args(kind: "text", question: "é" * 121))
      assert_equal "é" * 121, store.read(value["id"])["question"]
      assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(id: "hitl002", kind: "text", question: "é" * 241))
      end
    end
  end

  def test_generic_create_refuses_proposal_without_persisting_an_orphan
    with_lifecycle_root do |root|
      store = make_store(root: root, policy: DecisionPolicy.new)
      assert_raises(Ace::Hitl::Lifecycle::StateError) do
        store.create(**request_args(kind: "proposal"))
      end
      assert_empty Dir.children(File.join(root, "requests"))
      assert_empty Dir.children(File.join(root, "public"))
    end
  end
end
