# frozen_string_literal: true

require "json"
require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Transport
        # Concrete configuration only; no default, legacy file or inferred authority.
        class Registry
          attr_reader :channels

          def self.load(path)
            new(JSON.parse(File.read(path)))
          rescue JSON::ParserError, SystemCallError
            raise ContractError, "transport registry is unavailable or malformed"
          end

          def initialize(value)
            unless value.is_a?(Hash) && value["schema"] == "ace.hitl.hermes.channels/v1" &&
                value["channels"].is_a?(Array) && !value["channels"].empty?
              raise ContractError, "transport registry requires channels/v1 and registered channels"
            end
            @channels = value["channels"].map do |entry|
              unless entry.is_a?(Hash) && (entry.keys - %w[name chat_id captain_user_ids machine folder target projects]).empty?
                raise ContractError, "invalid transport channel fields"
              end
              unless entry["projects"].is_a?(Array) && !entry["projects"].empty?
                raise ContractError, "channel requires explicit project routing"
              end
              entry["projects"].each { |project| Atoms::HermesTokens.validate!(project, "project") }
              %w[name machine target].each { |field| Atoms::HermesTokens.validate!(entry[field], field) }
              unless entry["chat_id"].is_a?(String) && entry["chat_id"].match?(/\A-\d{4,32}\z/) &&
                  entry["captain_user_ids"].is_a?(Array) && !entry["captain_user_ids"].empty? &&
                  entry["captain_user_ids"].all? { |id| id.is_a?(String) && id.match?(/\A\d{1,32}\z/) } &&
                  entry["folder"].is_a?(String) && File.absolute_path?(entry["folder"])
                raise ContractError, "channel requires group identity, Captain allowlist and absolute folder"
              end
              entry.transform_values { |v| v.is_a?(Array) ? v.dup.freeze : v }.freeze
            end.freeze
            projects = @channels.flat_map { |channel| channel["projects"] }
            raise ContractError, "ambiguous project routing" unless projects.uniq.size == projects.size
            %w[name chat_id target folder].each do |field|
              unless @channels.map { |c| c[field] }.uniq.size == @channels.size
                raise ContractError, "ambiguous transport registry #{field}"
              end
            end
          end

          def resolve(name)
            @channels.find { |c| c["name"] == name } || raise(UnknownChannelError, "unregistered transport channel")
          end

          def authorize(event)
            unless event.is_a?(Hash) && event["platform"] == "telegram" &&
                %w[group supergroup].include?(event["chat_type"]) &&
                event["message_id"].is_a?(String) && event["message_id"].match?(/\A\d+\z/)
              raise ContractError, "invalid Telegram event identity"
            end
            channel = @channels.find { |c| c["chat_id"] == event["chat_id"] }
            unless channel && channel["captain_user_ids"].include?(event["user_id"])
              raise ContractError, "unregistered channel or unauthorized sender"
            end
            channel
          end
        end
      end
    end
  end
end
