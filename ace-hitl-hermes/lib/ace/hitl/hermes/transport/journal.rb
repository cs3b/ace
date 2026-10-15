# frozen_string_literal: true

require "json"
require "fileutils"
require "securerandom"

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
            return {"schema" => "ace.hitl.hermes.transport/v1", "requests" => {}, "ingress" => [],
                    "sequence" => 0, "poll" => {}, "unregistered_chats" => {}} unless File.exist?(path)

            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
                raise ContractError, "transport journal must be owned and private"
              end
              state = JSON.parse(file.read)
              state["unregistered_chats"] ||= {}
              state["requests"] = normalize_request_keys(state["requests"])
              unless state["schema"] == "ace.hitl.hermes.transport/v1" && state["requests"].is_a?(Hash) &&
                  state["ingress"].is_a?(Array) && state["sequence"].is_a?(Integer) && state["poll"].is_a?(Hash) &&
                  state["unregistered_chats"].is_a?(Hash)
                raise ContractError, "transport journal is malformed"
              end
              state
            end
          rescue JSON::ParserError, SystemCallError
            raise ContractError, "transport journal is unreadable"
          end

          def normalize_request_keys(requests)
            return requests unless requests.is_a?(Hash)

            requests.each_value.each_with_object({}) do |record, normalized|
              unless record.is_a?(Hash) && record["channel"].is_a?(String) && record["request"].is_a?(String)
                raise ContractError, "transport journal request binding is malformed"
              end
              key = JSON.generate([record["channel"], record["request"]])
              raise ContractError, "transport journal request binding is ambiguous" if normalized.key?(key)

              normalized[key] = record
            end
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
