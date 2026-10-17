# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/ordinary_release_publication"

module Ace
  module Lab
    class OrdinaryReleasePublicationTest < Minitest::Test
      Staging = Organisms::OrdinaryReleaseStaging

      class FakeExecutor
        attr_accessor :failures, :calls
        def initialize(failures = [])
          @failures = failures.dup
          @calls = []
        end

        def publish(name:, version:)
          @calls << [name, version]
          if @failures.delete(name)
            {exit_status: 1, signal: nil, output: "push refused"}
          else
            {exit_status: 0, signal: nil, output: "pushed"}
          end
        end
      end

      class FakeRegistry
        attr_accessor :digests, :unreachable
        def initialize(digests = {})
          @digests = digests
          @unreachable = false
        end
        def published_digest(name, version) = @unreachable ? :unreachable : @digests.fetch("#{name}-#{version}", nil)
      end

      def entry(id, name, state, digest = "d" * 64)
        {"name" => name, "version" => "1.0.0", "artifact_digest" => digest,
          "bytes" => 16, "state" => state, "artifact_id" => id}
      end

      def staged(*entries)
        map = entries.to_h { |e| [e.fetch("artifact_id"), e] }
        Staging::State.new(map, entries.map { |e| e.fetch("artifact_id") },
          map.keys - map.select { |_k, v| %w[pending published].include?(v["state"]) }.keys)
      end

      def publish(staged_set, executor, registry)
        Organisms::OrdinaryReleasePublication.new(registry: registry, executor: executor).run(staged_set)
      end

      def test_publishes_pending_in_order_and_marks_dependents_blocked_on_failure
        executor = FakeExecutor.new(["gem-b"])
        registry = FakeRegistry.new
        set = staged(entry("a", "gem-a", "published"), entry("b", "gem-b", "pending"), entry("c", "gem-c", "pending"))
        registry.digests["gem-c-1.0.0"] = nil
        result = publish(set, executor, registry)
        assert_equal "published", result["results"]["a"]["state"]
        assert_equal "uncertain", result["results"]["b"]["state"], "failed push stays uncertain"
        assert_equal "dependent_blocked", result["results"]["c"]["state"]
        assert_equal "b", result["halted_by"]
        assert_equal 1, result["published"]
        assert_equal [%w[gem-b 1.0.0]], executor.calls, "dependents are not executed after a halt"
      end

      def test_successful_push_reconciles_to_published_and_continues
        executor = FakeExecutor.new
        registry = FakeRegistry.new
        registry.digests["gem-a-1.0.0"] = "d" * 64
        set = staged(entry("a", "gem-a", "pending"), entry("b", "gem-b", "published"))
        result = publish(set, executor, registry)
        assert_equal 2, result["published"]
        assert_nil result["halted_by"]
        assert_equal [%w[gem-a 1.0.0]], executor.calls, "already-published artifacts are skipped"
      end

      def test_exit_zero_with_absent_readback_is_uncertain_never_assumed
        executor = FakeExecutor.new
        registry = FakeRegistry.new
        set = staged(entry("a", "gem-a", "pending"))
        result = publish(set, executor, registry)
        assert_equal "uncertain", result["results"]["a"]["state"]
        assert_equal "absent", result["results"]["a"]["registry_readback"]
        assert_equal ["a"], result["uncertain"]
      end

      def test_failed_push_that_landed_earlier_reconciles_to_published_and_chain_continues
        executor = FakeExecutor.new(["gem-a"])
        registry = FakeRegistry.new
        registry.digests["gem-a-1.0.0"] = "d" * 64
        registry.digests["gem-b-1.0.0"] = "d" * 64
        set = staged(entry("a", "gem-a", "pending"), entry("b", "gem-b", "pending"))
        result = publish(set, executor, registry)
        assert_equal "published", result["results"]["a"]["state"], "a retry that landed reconciles to published"
        assert_equal "published", result["results"]["b"]["state"]
        assert_nil result["halted_by"], "the chain is not halted by a reconciled artifact"
        assert_includes executor.calls.map(&:first), "gem-b", "dependents still execute"
      end

      def test_conflict_artifact_halts_without_any_push
        executor = FakeExecutor.new
        registry = FakeRegistry.new
        set = staged(entry("a", "gem-a", "conflict"), entry("b", "gem-b", "pending"))
        result = publish(set, executor, registry)
        assert_equal "conflict", result["results"]["a"]["state"]
        assert_equal "dependent_blocked", result["results"]["b"]["state"]
        assert_empty executor.calls
      end
    end
  end
end
