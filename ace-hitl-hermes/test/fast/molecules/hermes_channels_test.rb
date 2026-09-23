# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesChannelsTest < AceHermesTestCase
          def test_register_resolve_address_and_listing
            registry = HermesChannels::Registry.new
            registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
            registry.register("archive", machine: "lab02", folder: "/srv/hermes/archive")

            channel = registry.resolve("inbox")
            assert_equal "inbox", channel.name
            assert_equal "lab01", channel.machine
            assert_equal "/run/lab/hermes/inbox", channel.path
            assert_equal "lab01/inbox/m-1", channel.address("m-1")
            assert_equal %w[archive inbox], registry.available
          end

          def test_duplicate_registration_fails_closed
            registry = HermesChannels::Registry.new
            registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
            error = assert_raises(ContractError) do
              registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
            end
            assert_match(/already registered/, error.message)
          end

          def test_unknown_channel_fails_closed_with_available_list
            registry = HermesChannels::Registry.new
            error = assert_raises(UnknownChannelError) { registry.resolve("nope") }
            assert_match(/unknown hermes channel "nope"/, error.message)
          end

          def test_registration_validates_tokens_and_folder_shape
            registry = HermesChannels::Registry.new

            assert_raises(ContractError) do
              registry.register("../escape", machine: "lab01", folder: "/run/x")
            end
            assert_raises(ContractError) do
              registry.register("inbox", machine: "la b", folder: "/run/x")
            end
            assert_raises(ContractError) do
              registry.register("inbox", machine: "lab01", folder: "relative/path")
            end
            assert_raises(ContractError) do
              registry.register("inbox", machine: "lab01", folder: "/run/x/.hidden")
            end
            assert_equal [], registry.available
          end

          def test_default_channel_resolution
            registry = HermesChannels::Registry.new
            error = assert_raises(ContractError) { registry.resolve_default }
            assert_match(/no default/, error.message)

            registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
            registry.default = "inbox"
            assert_equal "inbox", registry.default
            assert_equal "/run/lab/hermes/inbox", registry.resolve_default.path

            error = assert_raises(UnknownChannelError) { registry.default = "ghost" }
            assert_match(/unknown hermes channel/, error.message)
          end
        end
      end
    end
  end
end
