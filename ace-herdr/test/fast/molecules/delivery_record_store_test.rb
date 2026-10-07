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

        def test_bounded_inventory_and_event_locks_refuse_contention_without_leaks
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
          DeliveryRecordStore.with_inventory_lock(@dir, exclusive: true, create: true) {}
          File.write(DeliveryRecordStore.lock_path(@dir, "a"), "")
          File.write(DeliveryRecordStore.lock_path(@dir, "b"), "")
          File.open(File.join(@dir, ".inventory.lock"), File::RDWR) do |held|
            held.flock(File::LOCK_EX)
            assert_raises(DeliveryRecordStore::LockUnavailable) do
              DeliveryRecordStore.with_inventory_lock(@dir, exclusive: true, deadline: deadline) { flunk "busy entered" }
            end
          end
          File.open(DeliveryRecordStore.lock_path(@dir, "b"), File::RDWR) do |held|
            held.flock(File::LOCK_EX)
            assert_raises(DeliveryRecordStore::LockUnavailable) do
              DeliveryRecordStore.with_locks(@dir, %w[a b], deadline: deadline) { flunk "busy entered" }
            end
            DeliveryRecordStore.with_locks(@dir, ["a"], deadline: deadline) { assert true }
          end
          DeliveryRecordStore.with_locks(@dir, %w[a b], deadline: deadline) { assert true }
          assert_raises(DeliveryRecordStore::LockUnavailable) do
            DeliveryRecordStore.with_inventory_lock(@dir, exclusive: true, deadline: 0) {}
          end
          assert_raises(ArgumentError) do
            DeliveryRecordStore.with_inventory_lock(@dir, exclusive: true, deadline: false) {}
          end
          assert_empty Thread.current[:ace_herdr_delivery_inventory_locks]
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

          assert_equal [".inventory.lock", "evt-1.json"], Dir.children(nested).sort
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

        def test_list_survives_non_object_json_as_unreadable
          File.write(File.join(@dir, "evt-null.json"), "null")
          File.write(File.join(@dir, "evt-arr.json"), "[1,2]")

          entries = DeliveryRecordStore.list_records(@dir)

          assert_equal %w[evt-arr evt-null], entries.map { |e| e[:event_id] }
          assert entries.all? { |e| e[:record].nil? }
        end

        def test_list_survives_permission_denied_file_as_unreadable
          skip "readable as root" if Process.euid.zero?

          path = File.join(@dir, "evt-denied.json")
          File.write(path, "{}")
          File.chmod(0o000, path)

          entries = DeliveryRecordStore.list_records(@dir)

          assert_nil entries.first[:record]
        ensure
          File.chmod(0o600, path) if path && File.exist?(path)
        end

        def test_archive_moves_record_into_archive_dir
          DeliveryRecordStore.save(@record, @dir)

          dest = DeliveryRecordStore.archive(@dir, "evt-1")

          assert_equal File.join(@dir, "archive", "evt-1.json"), dest
          assert File.exist?(dest)
          refute File.exist?(DeliveryRecordStore.path_for(@dir, "evt-1"))
          assert_equal [".inventory.lock", "archive"], Dir.children(@dir).sort
        end

        def test_exclusive_inventory_lifetime_blocks_normal_save_and_archive
          DeliveryRecordStore.save(@record, @dir)
          %i[save create archive].each do |operation|
            started = Queue.new
            writer = nil
            DeliveryRecordStore.with_inventory_lock(@dir, exclusive: true, create: false) do
              writer = Thread.new do
                started << true
                case operation
                when :save then DeliveryRecordStore.save(@record, @dir)
                when :create then DeliveryRecordStore.save(Models::DeliveryRecord.new(event_id: "new-event", session: "ws-1", pane: "p5", answer_digest: "e" * 64), @dir)
                when :archive then DeliveryRecordStore.archive(@dir, "evt-1")
                end
              end
              started.pop
              assert_nil writer.join(0.05), "normal writer escaped exclusive inventory lifetime"
              assert File.exist?(DeliveryRecordStore.path_for(@dir, "evt-1"))
              refute File.exist?(DeliveryRecordStore.path_for(@dir, "new-event")) if operation == :create
            end
            assert writer.join(2), "normal writer did not resume after inventory release"
            assert File.exist?(DeliveryRecordStore.path_for(@dir, "new-event")) if operation == :create
          ensure
            writer&.kill if writer&.alive?
          end
        end

        def test_load_falls_back_to_archived_record
          DeliveryRecordStore.save(@record, @dir)
          DeliveryRecordStore.archive(@dir, "evt-1")

          loaded = DeliveryRecordStore.load(@dir, "evt-1")

          assert_equal @record.to_h, loaded.to_h
        end

        def test_archive_is_idempotent_for_already_archived_event
          DeliveryRecordStore.save(@record, @dir)
          first = DeliveryRecordStore.archive(@dir, "evt-1")

          second = DeliveryRecordStore.archive(@dir, "evt-1")

          assert_equal first, second
          assert File.exist?(first)
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
