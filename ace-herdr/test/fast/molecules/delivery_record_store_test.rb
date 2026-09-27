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
      end
    end
  end
end
