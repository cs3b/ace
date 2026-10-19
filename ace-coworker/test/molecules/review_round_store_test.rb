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

        def test_record_refuses_unparseable_history_instead_of_resetting
          path = @store.state_path("rev-1")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "{not json")

          error = assert_raises(Error) { @store.record!("rev-1", clean) }
          assert_match(/corrupt round history at #{Regexp.escape(path)}/, error.message)
          # the corrupt evidence is preserved on disk, never overwritten
          assert_equal "{not json", File.read(path)
        end

        def test_record_refuses_non_array_history_instead_of_resetting
          path = @store.state_path("rev-1")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, JSON.generate({"rounds" => []}))

          error = assert_raises(Error) { @store.record!("rev-1", clean) }
          assert_match(/corrupt round history at .* expected an array, got Hash/, error.message)
        end

        def test_record_preserves_valid_history
          @store.record!("rev-1", clean)
          @store.record!("rev-1", clean)
          verdict = @store.record!("rev-1", clean)
          assert_equal :accept, verdict[:verdict]
          assert_equal 3, @store.read("rev-1").length
        end

        def test_record_rejects_non_hash_element
          @store.record!("rev-1", clean)
          File.write(@store.state_path("rev-1"), JSON.generate([clean, "f-1"]))

          error = assert_raises(Error) { @store.record!("rev-1", clean) }
          assert_match(/record 1: round record must be a Hash/, error.message)
        end

        def test_record_rejects_symbol_keyed_record
          error = assert_raises(Error) do
            @store.record!("rev-1", {type: "full", status: "completed",
                                      confirmed: [], resolved: []})
          end
          assert_match(/keys must be strings/, error.message)
        end

        def test_record_rejects_confirmed_as_single_hash
          error = assert_raises(Error) do
            @store.record!("rev-1", clean.merge(
              "confirmed" => {"id" => "f-1", "severity" => "high"}
            ))
          end
          assert_match(/'confirmed' must be an array/, error.message)
        end

        def test_record_is_last_write_wins_under_interleaved_writers
          # Documented single-writer assumption: record! is an
          # unsynchronized read-modify-write. Two writers that both read
          # the same state before either writes are last-write-wins -
          # the earlier write's round is lost, not merged. The lab flow
          # runs one executor per worktree, so this never happens in
          # practice; the test pins the assumption intentionally.
          writer_a = ReviewRoundStore.new(project_root: @dir)
          writer_b = ReviewRoundStore.new(project_root: @dir)
          state_a = writer_a.read("rev-1")
          state_b = writer_b.read("rev-1")

          writer_a.write("rev-1", state_a + [clean])
          writer_b.write("rev-1", state_b + [clean.merge("resolved" => ["f-9"])])

          history = writer_a.read("rev-1")
          assert_equal 1, history.length
          assert_equal ["f-9"], history.last["resolved"]
        end

        def test_write_cleans_up_tmp_file_on_failure
          @store.record!("rev-1", clean)
          dir = File.dirname(@store.state_path("rev-1"))

          File.stub :rename, ->(*_args) { raise Errno::EPERM } do
            assert_raises(Errno::EPERM) { @store.record!("rev-1", clean) }
          end

          leftovers = Dir.children(dir).select { |name| name.include?(".tmp.") }
          assert_empty leftovers, "tmp files must not survive a failed write"
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
