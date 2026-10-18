# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Molecules
      class HitlAddressResolverTest < AceHitlTestCase
        def config(recipients: {}, machine: nil, default: nil)
          {"hitl" => {
            "root_dir" => ".ace-local/hitl",
            "machine" => machine,
            "default_recipient" => default,
            "recipients" => recipients
          }.compact}
        end

        def test_resolves_folder_form_recipient
          resolver = HitlAddressResolver.new(config: config(
            recipients: {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
          ))
          address = resolver.resolve("overseer")
          assert_equal "lab01", address["machine"]
          assert_equal ".ace-local/hitl", address["folder"]
          assert_nil address["id"]
        end

        def test_resolves_panel_form_recipient
          resolver = HitlAddressResolver.new(config: config(
            recipients: {"captain" => {"machine" => "lab02", "panel" => "telegram"}}
          ))
          assert_equal({"machine" => "lab02", "panel" => "telegram"}, resolver.resolve("captain"))
        end

        def test_unknown_recipient_lists_configured_names
          resolver = HitlAddressResolver.new(config: config(
            recipients: {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
          ))
          error = assert_raises(HitlAddressResolver::UnknownRecipientError) do
            resolver.resolve("ghost")
          end
          assert_includes error.message, "Unknown HITL recipient 'ghost'"
          assert_includes error.message, "overseer"
        end

        def test_unknown_recipient_with_empty_config
          resolver = HitlAddressResolver.new(config: config)
          error = assert_raises(HitlAddressResolver::UnknownRecipientError) do
            resolver.resolve("anyone")
          end
          assert_includes error.message, "(none configured)"
        end

        def test_malformed_recipient_is_invalid_address
          resolver = HitlAddressResolver.new(config: config(
            recipients: {"broken" => {"machine" => "lab01", "folder" => "f", "panel" => "p"}}
          ))
          error = assert_raises(HitlAddressResolver::InvalidAddressError) do
            resolver.resolve("broken")
          end
          assert_includes error.message, "recipient 'broken'"
          assert_includes error.message, "both folder and panel"
        end

        def test_default_recipient
          resolver = HitlAddressResolver.new(config: config(default: "overseer"))
          assert_equal "overseer", resolver.default_recipient

          assert_nil HitlAddressResolver.new(config: config).default_recipient
        end

        def test_sender_address_requires_machine
          resolver = HitlAddressResolver.new(config: config(machine: nil))
          error = assert_raises(HitlAddressResolver::InvalidAddressError) do
            resolver.sender_address(folder: ".ace-local/hitl", id: "abc123")
          end
          assert_includes error.message, "hitl.machine is not configured"
        end

        def test_sender_address_builds_folder_form
          resolver = HitlAddressResolver.new(config: config(machine: "lab01"))
          address = resolver.sender_address(folder: ".ace-local/hitl", id: "abc123")
          assert_equal({"machine" => "lab01", "folder" => ".ace-local/hitl", "id" => "abc123"}, address)
        end

        def test_recipient_names_sorted
          resolver = HitlAddressResolver.new(config: config(
            recipients: {
              "zeta" => {"machine" => "m", "panel" => "p"},
              "alpha" => {"machine" => "m", "panel" => "q"}
            }
          ))
          assert_equal %w[alpha zeta], resolver.recipient_names
        end
      end
    end
  end
end
