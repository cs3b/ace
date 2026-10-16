# frozen_string_literal: true

require "json"
require "digest"
require "ace/hitl/lifecycle"
require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Transport
        # A Telegram group retains one instruction target and any number of
        # explicit project authorities. Project identity never comes from reply text.
        class Registry
          CHANNEL_FIELDS = %w[name chat_id captain_user_ids machine folder target projects].freeze
          AUTHORITY_FIELDS = %w[hitl_socket hitl_endpoint hitl_service_uid tls_client_credential request_contexts].freeze

          attr_reader :channels

          def self.load(path)
            new(JSON.parse(File.read(path)))
          rescue JSON::ParserError, SystemCallError
            raise ContractError, "transport registry is unavailable or malformed"
          end

          def initialize(value)
            unless value.is_a?(Hash) && value["schema"] == "ace.hitl.hermes.channels/v2" &&
                (value.keys - %w[schema channels]).empty? && value["channels"].is_a?(Array) && !value["channels"].empty?
              raise ContractError, "transport registry requires channels/v2 and registered channels"
            end
            @channels = value["channels"].map do |entry|
              unless entry.is_a?(Hash) && (entry.keys - CHANNEL_FIELDS).empty?
                raise ContractError, "invalid transport channel fields"
              end
              unless entry["projects"].is_a?(Hash) && !entry["projects"].empty?
                raise ContractError, "channel requires explicit project routing"
              end
              entry["projects"].each do |project, authority|
                raise ContractError, "invalid project token" unless Atoms::HermesTokens.valid?(project)
                validate_authority!(authority, project)
              end
              %w[name machine target].each do |field|
                raise ContractError, "invalid channel #{field}" unless Atoms::HermesTokens.valid?(entry[field])
              end
              unless entry["chat_id"].is_a?(String) && entry["chat_id"].match?(/\A-\d{4,32}\z/) &&
                  entry["captain_user_ids"].is_a?(Array) && !entry["captain_user_ids"].empty? &&
                  entry["captain_user_ids"].all? { |id| id.is_a?(String) && id.match?(/\A\d{1,32}\z/) } &&
                  entry["folder"].is_a?(String) && File.absolute_path?(entry["folder"]) && !entry["folder"].include?("\0")
                raise ContractError, "channel requires group identity, Captain allowlist and absolute folder"
              end
              JSON.parse(JSON.generate(entry), freeze: true)
            end.freeze
            projects = @channels.flat_map { |channel| channel["projects"].keys }
            raise ContractError, "ambiguous project routing" unless projects.uniq.size == projects.size
            %w[name chat_id target folder].each do |field|
              unless @channels.map { |c| c[field] }.uniq.size == @channels.size
                raise ContractError, "ambiguous transport registry #{field}"
              end
            end
          end

          # Resolve all roots together before activation: aliases or overlapping
          # instruction/project trees would mix independent authority domains.
          def verify_folders!
            roots = @channels.map { |channel| File.realpath(channel.fetch("folder")) }
            roots.combination(2).each do |left, right|
              if left == right || left.start_with?(right + File::SEPARATOR) || right.start_with?(left + File::SEPARATOR)
                raise ContractError, "channel folders overlap or alias"
              end
            end
            @channels.each do |channel|
              raise ContractError, "channel folder cannot be a symlink" if File.lstat(channel.fetch("folder")).symlink?
              Molecules::HermesContract.verify_folder!(channel.fetch("folder"))
              channel.fetch("projects").each_key do |project|
                Relay.folder_box(project_channel(channel.fetch("name"), project))
              end
            end
            true
          rescue SystemCallError
            raise ContractError, "channel folder is unavailable"
          end

          def resolve(name)
            @channels.find { |c| c["name"] == name } || raise(UnknownChannelError, "unregistered transport channel")
          end

          def project_channel(name, project)
            entry = resolve(name)
            unless entry.fetch("projects").key?(project)
              raise ContractError, "project is not registered to this channel"
            end
            entry.merge("project" => project, "root_folder" => entry.fetch("folder"),
              "folder" => File.join(entry.fetch("folder"), "projects", project)).freeze
          end

          def route_identity(name, project)
            channel = resolve(name)
            authority = channel.fetch("projects").fetch(project) { raise ContractError, "unregistered project authority" }
            canonical = lambda do |value|
              case value
              when Hash then value.keys.sort.to_h { |key| [key, canonical.call(value.fetch(key))] }
              when Array then value.map { |item| canonical.call(item) }
              else value
              end
            end
            binding = channel.slice("name", "chat_id", "captain_user_ids", "machine", "folder", "target")
              .merge("project" => project, "authority" => authority)
            Digest::SHA256.hexdigest(JSON.generate(canonical.call(binding)))
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

          def validate_authority!(entry, project)
            unless entry.is_a?(Hash) && (entry.keys - AUTHORITY_FIELDS).empty? &&
                entry.key?("hitl_socket") != entry.key?("hitl_endpoint")
              raise ContractError, "project must declare exactly one authority"
            end
            if entry.key?("request_contexts")
              contexts = entry["request_contexts"]
              unless contexts.is_a?(Array) && !contexts.empty? && contexts.uniq == contexts &&
                  (contexts - %w[managed operator-question]).empty?
                raise ContractError, "invalid required request contexts"
              end
            end
            if entry.key?("hitl_endpoint")
              validate_remote_authority!(entry, project)
            else
              unless entry["hitl_socket"].is_a?(String) && File.absolute_path?(entry["hitl_socket"]) &&
                  entry["hitl_service_uid"].is_a?(Integer) && entry["hitl_service_uid"] >= 0 &&
                  !entry.key?("tls_client_credential")
                raise ContractError, "local project requires an absolute hitl_socket and explicit hitl_service_uid"
              end
            end
          end

          def validate_remote_authority!(entry, project)
            unless entry["tls_client_credential"].is_a?(Hash)
              raise ContractError, "remote project requires a tls_client_credential"
            end
            begin
              Ace::Hitl::Lifecycle::TlsCredentials.parse_endpoint(entry["hitl_endpoint"])
              credential = Ace::Hitl::Lifecycle::TlsCredentials.parse_client(entry["tls_client_credential"])
            rescue Ace::Hitl::Lifecycle::Error => e
              raise ContractError, "remote project #{project.inspect}: #{e.message}"
            end
            if entry.key?("hitl_service_uid")
              raise ContractError, "remote project must not declare a Unix hitl_service_uid"
            end
            credential_project = Ace::Hitl::Lifecycle::TlsCredentials.uri_san_project(
              credential.fetch("expected_server_uri_san"))
            unless project == credential_project
              raise ContractError, "remote route must match its credential project"
            end
          end
        end
      end
    end
  end
end
