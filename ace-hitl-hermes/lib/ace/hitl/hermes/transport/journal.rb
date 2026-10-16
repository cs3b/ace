# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"
require_relative "../atoms/hermes_tokens"
require_relative "../molecules/hermes_message"

module Ace
  module Hitl
    module Hermes
      module Transport
        # Single lock serializes send/receive/checkpoint with durable fsync commits.
        # No message bodies or secret-derived digests belong in this journal.
        class Journal
          def initialize(directory)
            @directory = File.expand_path(directory)
            FileUtils.mkdir_p(@directory, mode: 0o700)
            stat = File.lstat(@directory)
            unless stat.directory? && !stat.symlink? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
              raise ContractError, "transport state requires an owned private directory"
            end
          end

          def synchronize
            path = File.join(@directory, "journal.lock")
            File.open(path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
              lock.flock(File::LOCK_EX)
              state = read
              yield state, -> { write(state) }
            ensure
              lock.flock(File::LOCK_UN)
            end
          end

          def actor
            path = File.join(@directory, "poller.lock")
            File.open(path, File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
              unless lock.flock(File::LOCK_EX | File::LOCK_NB)
                raise ContractError, "another Hermes polling actor owns this journal"
              end
              yield
            ensure
              lock.flock(File::LOCK_UN)
            end
          end

          def record_unregistered(updates:, observed_at:)
            return if updates.empty?

            synchronize do |state, commit|
              updates.each do |update|
                chat_id = update.fetch("chat_id")
                update_id = update.fetch("update_id")
                record = (state["unregistered_chats"][chat_id] ||= {
                  "chat_id" => chat_id, "first_seen_at" => observed_at, "count" => 0
                })
                next if record["last_update_id"] && update_id <= record["last_update_id"]

                record["last_seen_at"] = observed_at
                record["first_update_id"] ||= update_id
                record["last_update_id"] = update_id
                record["count"] += 1
              end
              commit.call
            end
          end

          private

          def read
            path = File.join(@directory, "journal.json")
            return {"schema" => "ace.hitl.hermes.transport/v2", "requests" => {}, "ingress" => [],
                    "sequence" => 0, "poll" => {}, "unregistered_chats" => {}} unless File.exist?(path)

            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
                raise ContractError, "transport journal must be owned and private"
              end
              state = JSON.parse(file.read)
              unless state["schema"] == "ace.hitl.hermes.transport/v2" && state["requests"].is_a?(Hash) &&
                  state["ingress"].is_a?(Array) && state["sequence"].is_a?(Integer) && state["sequence"] >= 0 &&
                  state["poll"].is_a?(Hash) &&
                  state["unregistered_chats"].is_a?(Hash)
                raise ContractError, "transport journal is malformed"
              end
              state.fetch("requests").each do |key, record|
                unless record.is_a?(Hash) &&
                    %w[channel project request].all? { |field| Atoms::HermesTokens.valid?(record[field]) } &&
                    key == JSON.generate(record.values_at("channel", "project", "request")) &&
                    record["route_identity"].is_a?(String) && record["route_identity"].match?(/\A[0-9a-f]{64}\z/)
                  raise ContractError, "transport request identity is malformed"
                end
                binding = record["binding"]
                unless [true, false].include?(record["sensitive"]) && binding.is_a?(Hash) &&
                    binding["sensitive"] == record["sensitive"] && binding["envelope"].is_a?(Hash) &&
                    binding.dig("envelope", "project") == record["project"] &&
                    (binding.dig("envelope", "kind") != "otp" || record["sensitive"] == true)
                  raise ContractError, "transport request classification is malformed"
                end
              end
              sequences = []
              origins = []
              state.fetch("ingress").each do |item|
                valid = item.is_a?(Hash) && Atoms::HermesTokens.valid?(item["channel"]) &&
                  item["message_id"].is_a?(String) && item["message_id"].match?(/\A[0-9]+\z/) &&
                  item["sequence"].is_a?(Integer) && item["sequence"] > 0 && item["sequence"] <= state["sequence"] &&
                  item["received_at"].is_a?(String) &&
                  item["user_id"].is_a?(String) && item["user_id"].match?(/\A[0-9]{1,32}\z/) &&
                  item["route_identity"].is_a?(String) && item["route_identity"].match?(/\A[0-9a-f]{64}\z/) &&
                  %w[queued unresolved secret-unavailable delivered closed rejected].include?(item["status"])
                raise ContractError, "transport ingress identity is malformed" unless valid
                Molecules::HermesMessage.validate_timestamp!(item["received_at"], "received_at")
                if item["request"]
                  record = state["requests"][JSON.generate(item.values_at("channel", "project", "request"))]
                  unless record && item["revision"] == record["revision"] &&
                      item["route_identity"] == record["route_identity"] && !(record["sensitive"] && item["body_sha256"])
                    raise ContractError, "transport ingress request binding is malformed"
                  end
                elsif item["project"] || item["revision"]
                  raise ContractError, "instruction ingress cannot name a request authority"
                end
                if item["body_sha256"] && (!item["body_sha256"].is_a?(String) ||
                    !item["body_sha256"].match?(/\A[0-9a-f]{64}\z/) ||
                    !item["route_identity"].is_a?(String) || !item["route_identity"].match?(/\A[0-9a-f]{64}\z/))
                  raise ContractError, "transport ingress body binding is malformed"
                end
                sequences << item["sequence"]
                origins << item.values_at("channel", "message_id")
              end
              unless sequences.uniq == sequences && origins.uniq == origins
                raise ContractError, "transport ingress sequence or origin is duplicated"
              end
              state
            end
          rescue JSON::ParserError, SystemCallError
            raise ContractError, "transport journal is unreadable"
          end

          def write(state)
            temporary = File.join(@directory, ".journal-#{SecureRandom.hex(8)}")
            File.open(temporary, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o600) do |file|
              file.write(JSON.generate(state))
              file.flush
              file.fsync
            end
            File.rename(temporary, File.join(@directory, "journal.json"))
            File.open(@directory) { |directory| directory.fsync }
          ensure
            File.unlink(temporary) if temporary && File.exist?(temporary)
          end
        end
      end
    end
  end
end
