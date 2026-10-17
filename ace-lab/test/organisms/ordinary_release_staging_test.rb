# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/ordinary_release_staging"

module Ace
  module Lab
    class OrdinaryReleaseStagingTest < Minitest::Test
      StubOwner = Struct.new(:artifacts, :ref) do
        def result_events(_params, _commit) = []
        def journal = Struct.new(:ref_value).new(ref || "r" * 40)
        def release_artifact_at!(events:, commit:, artifact_id:)
          entry = artifacts.fetch(artifact_id) { raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "unknown artifact" }
          entry.merge("bytes" => "x" * entry.fetch("bytes"))
        end
      end

      class FakeRegistry
        attr_accessor :digests
        def initialize(digests = {}) = @digests = digests
        def published_digest(name, version) = @digests.fetch("#{name}-#{version}", nil)
      end

      def artifact(id, name, version, digest = "d" * 64)
        {"assignment_id" => "producer", "attempt_id" => "producer-run", "artifact_id" => id,
          "input" => {"target" => {"name" => name, "version" => version, "artifact_digest" => digest},
            "publication" => {"artifact_bytes" => 16}}, "bytes" => 16}
      end

      def stage(owner_artifacts, references, order, registry)
        Organisms::OrdinaryReleaseStaging.new(owner: StubOwner.new(owner_artifacts), registry: registry)
          .stage(references: references, order: order)
      end

      def refs(*ids)
        ids.map { |id| {"assignment_id" => "producer", "attempt_id" => "producer-run", "artifact_id" => id} }
      end

      def test_reconciles_published_pending_and_conflict_with_dependency_order
        artifacts = {"a" => artifact("a", "gem-a", "1.0.0"), "b" => artifact("b", "gem-b", "2.0.0", "e" * 64)}
        registry = FakeRegistry.new("gem-a-1.0.0" => "d" * 64)
        staged = stage(artifacts, refs("a", "b"), refs("a", "b"), registry)
        assert_equal "published", staged.artifacts.fetch("a").fetch("state")
        assert_equal "pending", staged.artifacts.fetch("b").fetch("state")
        assert_equal %w[a b], staged.order
        assert_equal ["b"], staged.pending
      end

      def test_registry_digest_mismatch_is_conflict_never_republish
        artifacts = {"a" => artifact("a", "gem-a", "1.0.0")}
        registry = FakeRegistry.new("gem-a-1.0.0" => "different" * 8)
        staged = stage(artifacts, refs("a"), refs("a"), registry)
        assert_equal "conflict", staged.artifacts.fetch("a").fetch("state")
        assert_equal ["a"], staged.blocked
        assert_empty staged.pending
      end

      def test_unreachable_registry_is_uncertain_not_pending
        registry = Object.new
        registry.define_singleton_method(:published_digest) { |*_| :unreachable }
        staged = stage({"a" => artifact("a", "gem-a", "1.0.0")}, refs("a"), refs("a"), registry)
        assert_equal "uncertain", staged.artifacts.fetch("a").fetch("state")
        assert_empty staged.pending
      end

      def test_order_must_cover_the_exact_set_once
        artifacts = {"a" => artifact("a", "gem-a", "1.0.0"), "b" => artifact("b", "gem-b", "2.0.0")}
        error = assert_raises(ArgumentError) { stage(artifacts, refs("a", "b"), refs("a"), FakeRegistry.new) }
        assert_includes error.message, "exact artifact set"
        error = assert_raises(ArgumentError) { stage(artifacts, refs("a", "b"), refs("a", "a", "b"), FakeRegistry.new) }
        assert_includes error.message, "exact artifact set"
      end

      def test_unknown_retained_artifact_refuses
        registry = FakeRegistry.new
        error = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
          stage({"a" => artifact("a", "gem-a", "1.0.0")}, refs("a", "zz"), refs("a", "zz"), registry)
        end
        assert_includes error.message, "unknown artifact"
      end
    end
  end
end
