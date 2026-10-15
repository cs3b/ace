# frozen_string_literal: true

require "json"
require "ace/hitl/lifecycle"
require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Transport
        # Concrete configuration only; no default, legacy file or inferred authority.
        # Each channel resolves to EXACTLY ONE authority: a local
        # `hitl_socket` (same-runtime Unix peer authentication) or a
        # remote `hitl_endpoint` — the selected
        # `tls+tcp://HOST_TAILNET_DNS:PORT` host/Incus crossing (spec
        # 8xa.t.nh0), which requires the channel's exact
        # `tls_client_credential` and must not carry a Unix service uid.
        class Registry
          CHANNEL_FIELDS = %w[name chat_id captain_user_ids machine folder target projects
            hitl_socket hitl_endpoint hitl_service_uid tls_client_credential].freeze

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
              unless entry.is_a?(Hash) && (entry.keys - CHANNEL_FIELDS).empty?
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
              validate_authority!(entry)
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

          private

          # Exactly one local or remote authority per channel. A remote
          # channel serves ONE project authority: its endpoint is the
          # selected tls+tcp:// form, its credential reference is the
          # project's exact client identity, and no Unix service uid
          # exists across the crossing.
          def validate_authority!(entry)
            if entry.key?("hitl_socket") &&
                !(entry["hitl_socket"].is_a?(String) && File.absolute_path?(entry["hitl_socket"]))
              raise ContractError, "channel hitl_socket must be an absolute socket path"
            end
            if entry.key?("hitl_endpoint") && entry.key?("hitl_socket")
              raise ContractError,
                "channel #{entry['name'].inspect} must declare exactly one authority: " \
                "hitl_endpoint and hitl_socket are mutually exclusive"
            end
            if entry.key?("hitl_endpoint")
              validate_remote_authority!(entry)
            else
              unless entry["hitl_service_uid"].is_a?(Integer) && entry["hitl_service_uid"] >= 0
                raise ContractError, "local channel requires an explicit hitl_service_uid"
              end
            end
          end

          def validate_remote_authority!(entry)
            unless entry["tls_client_credential"].is_a?(Hash)
              raise ContractError,
                "remote channel #{entry['name'].inspect} requires a tls_client_credential"
            end
            begin
              Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(entry["hitl_endpoint"])
              credential = Ace::Hitl::Lifecycle::TlsCredentials.parse_client(entry["tls_client_credential"])
            rescue Ace::Hitl::Lifecycle::Error => e
              raise ContractError, "remote channel #{entry['name'].inspect}: #{e.message}"
            end
            if entry.key?("hitl_service_uid")
              raise ContractError,
                "remote channel #{entry['name'].inspect} must not declare a Unix hitl_service_uid"
            end
            project = Ace::Hitl::Lifecycle::TlsCredentials.uri_san_project(
              credential.fetch("expected_server_uri_san"))
            unless entry["projects"] == [project]
              raise ContractError,
                "remote channel #{entry['name'].inspect} must route exactly its credential project " \
                "#{project.inspect} (got #{entry['projects'].inspect})"
            end
          end
        end
      end
    end
  end
end
