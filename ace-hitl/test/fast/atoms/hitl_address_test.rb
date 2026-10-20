# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Atoms
      class HitlAddressTest < AceHitlTestCase
        def test_folder_form_with_id
          address = HitlAddress.validate!(machine: "lab01", folder: ".ace-local/hitl", id: "abc123")
          assert_equal({"machine" => "lab01", "folder" => ".ace-local/hitl", "id" => "abc123"}, address)
          assert HitlAddress.folder_form?(address)
          refute HitlAddress.panel_form?(address)
          assert_equal "lab01/.ace-local/hitl/abc123", HitlAddress.to_s(address)
        end

        def test_folder_form_without_id
          address = HitlAddress.validate!(machine: "lab01", folder: ".ace-local/hitl")
          assert_equal "lab01/.ace-local/hitl", HitlAddress.to_s(address)
        end

        def test_panel_form
          address = HitlAddress.validate!(machine: "lab02", panel: "telegram")
          assert_equal({"machine" => "lab02", "panel" => "telegram"}, address)
          assert HitlAddress.panel_form?(address)
          assert_equal "lab02/panel/telegram", HitlAddress.to_s(address)
        end

        def test_native_herdr_handle_round_trips_without_weakening_machine_or_folder_validation
          address = HitlAddress.validate!(machine: "lab", panel: "w7:p1")
          assert_equal "w7:p1", address["panel"]
          assert_equal "lab/panel/w7:p1", HitlAddress.to_s(address)
          assert_raises(HitlAddress::InvalidAddress) { HitlAddress.validate!(machine: "w7:p1", panel: "p1") }
          ["../p1", "w7/p1", "w7:p1;sh", "w7:p1\n", "x" * 129].each do |bad|
            assert_raises(HitlAddress::InvalidAddress) { HitlAddress.validate!(machine: "lab", panel: bad) }
          end
        end

        def test_panel_form_drops_id
          address = HitlAddress.validate!(machine: "lab02", panel: "telegram", id: "x")
          refute address.key?("id")
          assert_equal "lab02/panel/telegram", HitlAddress.to_s(address)
        end

        def test_missing_machine_errors
          error = assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(folder: ".ace-local/hitl")
          end
          assert_includes error.message, "machine"
        end

        def test_bad_machine_token_errors
          assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(machine: "bad machine!", folder: "x")
          end
        end

        def test_neither_and_both_folder_panel_error
          assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(machine: "lab01")
          end
          assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(machine: "lab01", folder: "f", panel: "p")
          end
        end

        def test_folder_traversal_errors
          error = assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(machine: "lab01", folder: "../outside")
          end
          assert_includes error.message, "must not traverse"
        end

        def test_absolute_folder_is_allowed
          address = HitlAddress.validate!(machine: "lab01", folder: "/var/tmp/hitl")
          assert_equal "/var/tmp/hitl", address["folder"]
        end

        def test_bad_panel_token_errors
          assert_raises(HitlAddress::InvalidAddress) do
            HitlAddress.validate!(machine: "lab01", panel: "not a token")
          end
        end
      end
    end
  end
end
