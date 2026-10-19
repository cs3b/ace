# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class ReviewRoundStoreTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-rounds")
          @store = ReviewRoundStore.new(project_root: @dir)
        end

        def teardown
          FileUtils.remove_entry(@dir)
          super
        end

        def clean
          {"type" => "full", "status" => "completed", "confirmed" => [], "resolved" => []}
        end

        def test_record_returns_the_rule_verdict_and_persists
          verdict = @store.record!("rev-1", clean)
          assert_equal :continue, verdict[:verdict]
          assert File.file?(@store.state_path("rev-1"))
          assert_equal [clean], @store.read("rev-1")
        end

        def test_restart_preserves_counters_and_verdict
          error_round = {"type" => "full", "status" => "completed",
                         "confirmed" => [{"id" => "f-1", "severity" => "High"}], "resolved" => []}
          resolving = {"type" => "full", "status" => "completed", "confirmed" => [], "resolved" => ["f-1"]}
          @store.record!("rev-1", error_round)
          @store.record!("rev-1", resolving)

          # simulated restart: a fresh store instance over the same root
          restarted = ReviewRoundStore.new(project_root: @dir)
          assert_equal 2, restarted.read("rev-1").length
          verdict = restarted.record!("rev-1", clean)
          assert_equal :accept, verdict[:verdict]
          assert_equal 3, verdict[:completed_full_rounds]
        end

        def test_read_returns_empty_list_when_absent_or_unparseable
          assert_empty @store.read("rev-1")

          path = @store.state_path("rev-1")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "{not json")
          assert_empty @store.read("rev-1")
        end

        def test_non_array_state_is_ignored
          path = @store.state_path("rev-1")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, JSON.generate({"verdict" => "accept"}))
          assert_empty @store.read("rev-1")
        end

        def test_state_lives_in_the_coworker_owned_local_location
          expected = File.join(@dir, ".ace-local", "coworker", "review-rounds", "rev-1.json")
          assert_equal expected, @store.state_path("rev-1")
        end

        def test_invalid_assignment_id_is_rejected
          error = assert_raises(Error) { @store.record!("../escape", clean) }
          assert_match(/invalid assignment id/, error.message)
        end
      end
    end
  end
end
