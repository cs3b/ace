# frozen_string_literal: true

require_relative "../atoms/hitl_address"

module Ace
  module Hitl
    module Molecules
      # Config-backed recipient resolution and sender/reply address
      # construction. The single place that reads address configuration;
      # consumers pass a configured recipient name without own routing.
      class HitlAddressResolver
        class UnknownRecipientError < StandardError; end
        class InvalidAddressError < StandardError; end

        # @param config [Hash] merged hitl namespace config
        def initialize(config: {})
          @config = config || {}
        end

        # @return [Array<String>] configured recipient names
        def recipient_names
          recipients.keys.sort
        end

        # @return [String, nil] name applied when --to is absent
        def default_recipient
          value = @config.dig("hitl", "default_recipient").to_s.strip
          value.empty? ? nil : value
        end

        # @param name [String] configured recipient name
        # @return [Hash] validated base address (folder or panel form)
        # @raise [UnknownRecipientError] listing configured names
        # @raise [InvalidAddressError] when the configured address is malformed
        def resolve(name)
          entry = recipients[name.to_s]
          unless entry
            listed = recipient_names.empty? ? "(none configured)" : recipient_names.join(", ")
            raise UnknownRecipientError, "Unknown HITL recipient '#{name}'. Configured recipients: #{listed}"
          end

          begin
            Atoms::HitlAddress.validate!(entry)
          rescue Atoms::HitlAddress::InvalidAddress => e
            raise InvalidAddressError, "recipient '#{name}' has an invalid address: #{e.message}"
          end
        end

        # Sender (reply) address: this machine + this events folder + case id.
        #
        # @param folder [String] configured events root (sender's folder)
        # @param id [String] the event's own case ID
        # @return [Hash] validated folder-form address
        # @raise [InvalidAddressError] when hitl.machine is unset or malformed
        def sender_address(folder:, id:)
          machine = @config.dig("hitl", "machine").to_s.strip
          if machine.empty?
            raise InvalidAddressError,
              "cannot build reply address: hitl.machine is not configured"
          end

          begin
            Atoms::HitlAddress.validate!(machine: machine, folder: folder, id: id)
          rescue Atoms::HitlAddress::InvalidAddress => e
            raise InvalidAddressError, "invalid sender address: #{e.message}"
          end
        end

        private

        def recipients
          @recipients ||= begin
            raw = @config.dig("hitl", "recipients")
            raw.is_a?(Hash) ? raw : {}
          end
        end
      end
    end
  end
end
