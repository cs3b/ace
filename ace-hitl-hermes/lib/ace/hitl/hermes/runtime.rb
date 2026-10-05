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
                box = Organisms::HermesBox.new(channel: box_channel)
                begin
                  publish_pending(channel, box)
                rescue Ace::Hitl::Lifecycle::TransportError => e
                  raise if once
                  warn "ace-hitl-hermes: pending publication unavailable for #{channel['name']} (#{e.class}); retrying"
                  sleep 1
                  next
                end
                box.poll.messages.each do |message|
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

        # The installed transport owns publication as well as Telegram polling.
        # Ask writes only scoped lifecycle state; no hidden Lab watcher or
        # HITL→Hermes dependency is required to get a question into message.v1.
        def publish_pending(channel, box)
          channel["projects"].each do |project|
            @lifecycle.pending(project: project).each do |facts|
              next unless facts["state"] == "created"
              envelope = Ace::Hitl::Contract::ManagedEnvelope.load(facts.fetch("envelope"), expected: {
                request_id: facts["id"], project: project, assignment_id: facts["assignment"], attempt_id: facts["attempt"]
              })
              status = @relay.delivery(facts["id"])["status"]
              next unless %w[unknown failed].include?(status)
              existing = box.poll.messages.find { |message| message.id == facts["id"] }
              if existing
                unless existing.question? && existing.body == facts["question"]
                  raise ContractError, "managed question folder identity conflicts"
                end
                next
              end
              box.publish(kind: :question, id: facts["id"], body: facts["question"], sender: envelope["requester"],
                timestamp: Time.at(Integer(facts["created_at"])).utc.iso8601)
            end
          end
        rescue Ace::Hitl::Contract::InvalidEnvelope, KeyError, ArgumentError => e
          raise ContractError, "managed pending publication binding is invalid (#{e.class})"
        end

        def telegram
          @telegram ||= Transport::Telegram.new(token_file: @config.fetch("token_file"))
        end
      end
    end
  end
end
