# frozen_string_literal: true

require "yaml"
require "ace/hitl/lifecycle"
require_relative "../hermes"

module Ace
  module Hitl
    module Hermes
      class Runtime
        attr_reader :registry, :journal, :relay, :config

        def initialize(path)
          @config = JSON.parse(File.read(path))
          unless @config.is_a?(Hash) && @config["schema"] == "ace.hitl.hermes.runtime/v1"
            raise ContractError, "runtime configuration requires runtime/v1"
          end
          @registry = Transport::Registry.load(@config.fetch("registry"))
          @journal = Transport::Journal.new(@config.fetch("state"))
          @lifecycle = Ace::Hitl::Lifecycle::Client.new(
            socket_path: @config.fetch("hitl_socket"), service_uid: @config.fetch("hitl_service_uid")
          )
          @relay = Transport::Relay.new(registry: @registry, journal: @journal, lifecycle: @lifecycle,
            sender: ->(channel, question) { telegram.call(channel, question) })
        rescue JSON::ParserError, KeyError, SystemCallError, ArgumentError
          raise ContractError, "runtime configuration is unavailable or malformed"
        end

        def serve(once: false)
          verify_polling_owner!
          @journal.actor do
            poller = Transport::Poller.new(relay: @relay, telegram: telegram, journal: @journal, registry: @registry)
            # Establish the new coverage epoch before issuing questions, so
            # a startup submission is never stamped before its coverage begins.
            begin
              poller.once
            rescue ContractError
              raise if once
            end
            loop do
              # Every folder question is an actual lifecycle request. Plain
              # instructions have Captain sender and are left for the target.
              @registry.channels.each do |channel|
                box_channel = Molecules::HermesChannels::Channel.new(
                  name: channel["name"], machine: channel["machine"], folder: channel["folder"]
                )
                Organisms::HermesBox.new(channel: box_channel).poll.messages.each do |message|
                  next unless message.question? && message.sender != "captain"
                  begin
                    facts = @lifecycle.read(message.id)
                    revision = facts.fetch("attempt")
                    @relay.submit(channel: channel["name"], request: message.id, revision: revision)
                  rescue StandardError
                    # Pending folder + visible delivery status are retained.
                  end
                end
              end
              begin
                poller.once
              rescue ContractError
                raise if once
                sleep 1
              end
              break if once
            end
          end
        end

        def verify_polling_owner!
          unless @config["polling_owner"] == "ace-hitl-hermes"
            raise ContractError, "serve requires explicit polling_owner ace-hitl-hermes"
          end
          path = @config.fetch("hermes_gateway_config")
          gateway = YAML.safe_load_file(path, aliases: false)
          unless gateway.is_a?(Hash) && gateway.dig("platforms", "telegram", "enabled") == false
            raise ContractError, "disable Telegram in the configured Hermes gateway before starting serve"
          end
        rescue KeyError, SystemCallError, Psych::Exception
          raise ContractError, "cannot verify Hermes gateway Telegram polling is disabled"
        end

        private

        def telegram
          @telegram ||= Transport::Telegram.new(token_file: @config.fetch("token_file"))
        end
      end
    end
  end
end
