# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class DeliveryRecordStoreTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir("ace_herdr_store_test")
          @record = Models::DeliveryRecord.new(
            event_id: "evt-1", session: "ws-1", pane: "p5", answer_digest: "d" * 64
          )
        end

        def teardown
          FileUtils.rm_rf(@dir)
        end

        def test_save_and_load_roundtrip
          DeliveryRecordStore.save(@record, @dir)

          loaded = DeliveryRecordStore.load(@dir, "evt-1")
          assert_equal @record.to_h, loaded.to_h
        end

        def test_load_missing_returns_nil
          assert_nil DeliveryRecordStore.load(@dir, "nope")
        end

        def test_save_creates_directory_and_leaves_no_temp_files
          nested = File.join(@dir, "deliveries")

          DeliveryRecordStore.save(@record, nested)

          assert_equal ["evt-1.json"], Dir.children(nested).sort
        end

        def test_overwrite_replaces_record
          DeliveryRecordStore.save(@record, @dir)
          advanced = @record.record_attempt(state: "delivered", detail: {}, timestamp: "t1")

          DeliveryRecordStore.save(advanced, @dir)

          assert_equal "delivered", DeliveryRecordStore.load(@dir, "evt-1").state
        end

        def test_path_for
          assert_equal File.join(@dir, "evt-1.json"), DeliveryRecordStore.path_for(@dir, "evt-1")
        end

        # --- tidy (spec 8wq.t.1w0) -------------------------------------------

        def delivered(event_id, updated_at:)
          Models::DeliveryRecord.new(
            event_id: event_id, session: "ws-1", pane: "p5", answer_digest: "d" * 64,
            state: "delivered", updated_at: updated_at
          )
        end

        def test_list_records_missing_dir_is_empty
          assert_equal [], DeliveryRecordStore.list_records(File.join(@dir, "nope"))
        end

        def test_list_records_enumerates_top_level_records_sorted
          DeliveryRecordStore.save(delivered("evt-2", updated_at: "t2"), @dir)
          DeliveryRecordStore.save(delivered("evt-1", updated_at: "t1"), @dir)

          entries = DeliveryRecordStore.list_records(@dir)

          assert_equal %w[evt-1 evt-2], entries.map { |e| e[:event_id] }
          assert_equal "delivered", entries.first[:record].state
        end

        def test_list_records_ignores_locks_temps_and_archive_dir
          DeliveryRecordStore.save(@record, @dir)
          FileUtils.mkdir_p(File.join(@dir, "archive"))
          File.write(File.join(@dir, ".evt-1.lock"), "")
          File.write(File.join(@dir, ".evt-1.json.tmp.99"), "{}")

          entries = DeliveryRecordStore.list_records(@dir)

          assert_equal %w[evt-1], entries.map { |e| e[:event_id] }
        end

        def test_list_records_reports_malformed_file_as_unreadable_entry
          File.write(File.join(@dir, "evt-bad.json"), "{not json")
          DeliveryRecordStore.save(@record, @dir)

          entries = DeliveryRecordStore.list_records(@dir)

          bad = entries.find { |e| e[:event_id] == "evt-bad" }
          assert_nil bad[:record]
          assert entries.find { |e| e[:event_id] == "evt-1" }[:record]
        end

        def test_list_reports_record_with_unknown_state_as_unreadable
          File.write(File.join(@dir, "evt-weird.json"), JSON.generate(@record.to_h.merge("state" => "nope")))

          entries = DeliveryRecordStore.list_records(@dir)

          assert_nil entries.first[:record]
        end

        def test_archive_moves_record_into_archive_dir
          DeliveryRecordStore.save(@record, @dir)

          dest = DeliveryRecordStore.archive(@dir, "evt-1")

          assert_equal File.join(@dir, "archive", "evt-1.json"), dest
          assert File.exist?(dest)
          assert_nil DeliveryRecordStore.load(@dir, "evt-1")
          assert_equal ["archive"], Dir.children(@dir).sort
        end

        def test_archive_preserves_file_mode
          DeliveryRecordStore.save(@record, @dir)

          dest = DeliveryRecordStore.archive(@dir, "evt-1")

          assert_equal 0o600, (File.stat(dest).mode & 0o777)
        end

        def test_archive_enumeration_roundtrip
          DeliveryRecordStore.save(delivered("evt-9", updated_at: "t9"), @dir)
          DeliveryRecordStore.archive(@dir, "evt-9")

          assert_equal [], DeliveryRecordStore.list_records(@dir)
        end
      end
    end
  end
end
