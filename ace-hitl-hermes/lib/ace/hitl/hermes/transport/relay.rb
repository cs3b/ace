# frozen_string_literal: true

require "time"
require "ace/hitl/lifecycle"
require_relative "registry"
require_relative "journal"
require_relative "../organisms/hermes_box"

module Ace
  module Hitl
    module Hermes
      module Transport
        # A definite refusal is recoverable. Everything else may have reached
        # Telegram and must be investigated rather than automatically resent.
        class SubmitFailed < Error; end

        class Relay
          TERMINAL = %w[delivered closed rejected].freeze

          def initialize(registry:, journal:, lifecycle:, sender:, clock: -> { Time.now.utc }, box_factory: nil)
            @registry, @journal, @lifecycle, @sender, @clock = registry, journal, lifecycle, sender, clock
            @box_factory = box_factory || lambda do |channel|
              folder_channel = Molecules::HermesChannels::Channel.new(
                name: channel["name"], machine: channel["machine"], folder: channel["folder"]
              )
              Organisms::HermesBox.new(channel: folder_channel, answer_authorizer: ->(id) { @lifecycle.read(id) })
            end
          end

          # A request revision names an immutable lifecycle binding, never a
          # mutable text hash. Metadata acknowledges submission, not reading.
          def submit(channel:, request:, revision:)
            entry = @registry.resolve(channel)
            Atoms::HermesTokens.validate!(request, "request")
            Atoms::HermesTokens.validate!(revision, "revision")
            facts = @lifecycle.read(request)
            unless entry["projects"].include?(facts["project"])
              raise ContractError, "request project is not registered to this channel"
            end
            binding = binding_for(facts)
            @journal.synchronize do |state, commit|
              previous = state["requests"][request]
              if previous
                unless previous.values_at("channel", "revision", "binding") == [channel, revision, binding]
                  raise ContractError, "request correlation binding cannot change"
                end
                if previous["status"] == "submitted"
                  box = @box_factory.call(entry)
                  question = box.poll.messages.find { |m| m.id == request && m.question? }
                  box.ack(request) if question && question.body == facts["question"]
                end
                return projection(previous) unless previous["status"] == "failed"
              end
              raise ContractError, "request is not pending" unless %w[created answer-delivered].include?(facts["state"])

              box = @box_factory.call(entry)
              message = box.poll.messages.find { |m| m.id == request && m.question? }
              raise ContractError, "pending request question is absent from channel folder" unless message
              unless message.body == facts["question"]
                raise ContractError, "folder question differs from authoritative lifecycle request"
              end
              record = {"request" => request, "revision" => revision, "channel" => channel,
                        "chat_id" => entry["chat_id"], "binding" => binding,
                        "sensitive" => facts["sensitive"] == true, "status" => "uncertain",
                        "coverage_generation" => state["poll"].dig(channel, "generation") || 0}
              state["requests"][request] = record
              commit.call # crash/send timeout leaves uncertain; no duplicate send
              begin
                ack = @sender.call(entry, message.body)
                unless ack.is_a?(Hash) && ack["success"] == true && ack["chat_id"].to_s == entry["chat_id"] &&
                    ack["message_id"].to_s.match?(/\A\d+\z/)
                  raise ContractError, "submission did not confirm exact channel/message identity"
                end
                record.merge!("status" => "submitted", "message_id" => ack["message_id"].to_s,
                  "submitted_at" => now)
                commit.call
                box.ack(request)
              rescue SubmitFailed
                record["status"] = "failed"
                commit.call
              rescue StandardError
                # Sanitized status only: transport errors can contain message text.
                record["status"] = "uncertain" unless record["status"] == "submitted"
                commit.call
              end
              projection(record)
            end
          end

          # Always called at pre_gateway_dispatch, before inbound preview logs.
          # Source timestamps are untrusted: received_at is stamped here, under
          # the same lock used to issue a reconciliation checkpoint.
          def receive(event)
            channel = @registry.authorize(event)
            text = event["text"]
            unless text.is_a?(String) && text.valid_encoding? && !text.strip.empty? &&
                text.bytesize <= 4096 && !text.include?("\0")
              raise ContractError, "invalid Telegram reply envelope"
            end
            @journal.synchronize do |state, commit|
              duplicate = state["ingress"].find do |item|
                item["channel"] == channel["name"] && item["message_id"] == event["message_id"]
              end
              if duplicate
                if %w[queued unresolved].include?(duplicate["status"])
                  if duplicate["request"]
                    existing = state["requests"].fetch(duplicate["request"])
                    if existing["sensitive"]
                      duplicate["status"] = "secret-unavailable"
                      existing["secret_delivery"] = "unavailable"
                      commit.call
                      text.clear unless text.frozen?
                    else
                      deliver_reply(existing, duplicate, text, channel, commit)
                    end
                  else
                    deliver_instruction(duplicate, text, channel, commit)
                  end
                end
                return public_ingress(duplicate)
              end

              request = correlate(state, channel, event, text)
              record = request && state["requests"].fetch(request)
              item = {"sequence" => state["sequence"] += 1, "channel" => channel["name"],
                      "message_id" => event["message_id"], "received_at" => now, "status" => "queued"}
              item.merge!("request" => request, "revision" => record["revision"]) if record
              state["ingress"] << item
              commit.call # write no answer, no digest, before any delivery
              if record
                deliver_reply(record, item, text, channel, commit)
              else
                deliver_instruction(item, text, channel, commit)
              end
              public_ingress(item)
            end
          end

          # Only a trusted poll adapter calls this after every event in a batch
          # has synchronously completed receive. No source-provided watermark.
          def poll_complete(channel:, started_at:, through:, continuous:)
            @registry.resolve(channel)
            validate_time(started_at)
            validate_time(through)
            raise ContractError, "invalid poll interval" if started_at > through || through > now
            @journal.synchronize do |state, commit|
              old = state["poll"][channel]
              gap = old && started_at > old["through"] && old["healthy"]
              broken = continuous != true || gap
              generation = old ? old.fetch("generation", 0) : 0
              if broken
                state["poll_history"] ||= {}
                (state["poll_history"][channel] ||= []) << old.dup if old
                generation += 1 if !old || old["healthy"]
                state["poll"][channel] = {"from" => started_at, "through" => through,
                                          "healthy" => false, "generation" => generation}
              else
                recovering = old && !old["healthy"]
                state["poll"][channel] = {
                  "from" => recovering ? [old["from"], started_at].max : (old ? old["from"] : started_at),
                  "through" => through, "healthy" => true, "generation" => generation
                }
              end
              commit.call
            end
          end

          def reconcile(request:, through:)
            validate_time(through)
            @journal.synchronize do |state, _commit|
              record = state["requests"][request]
              return {"status" => "unknown", "healthy" => false, "drained" => false} unless record

              poll = state["poll"][record["channel"]]
              healthy = poll && poll["healthy"] && poll["from"] <= through && poll["through"] >= through &&
                record["status"] == "submitted" && poll["from"] <= record["submitted_at"] &&
                poll.fetch("generation", 0) == record.fetch("coverage_generation", 0)
              relevant = state["ingress"].select do |item|
                item["request"] == request && item["revision"] == record["revision"] && item["received_at"] <= through
              end
              unresolved = relevant.reject { |item| TERMINAL.include?(item["status"]) }.map { |i| public_ingress(i) }
              {"schema" => "ace.hitl.hermes.ingress-checkpoint/v1", "request" => request,
               "revision" => record["revision"], "channel" => record["channel"],
               "status" => healthy ? "healthy" : "unknown", "healthy" => !!healthy,
               "drained" => !!healthy && unresolved.empty?,
               "checkpoint" => healthy ? {"through" => through, "sequence" => state["sequence"]} : nil,
               "unresolved" => unresolved}
            end
          end

          def delivery(request)
            @journal.synchronize do |state, _commit|
              record = state["requests"][request]
              record ? projection(record) : {"request" => request, "status" => "unknown"}
            end
          end

          private

          def now
            @clock.call.utc.iso8601
          end

          def validate_time(value)
            Molecules::HermesMessage.validate_timestamp!(value, "through")
          end

          def binding_for(facts)
            facts.slice("id", "work", "assignment", "attempt", "project", "requester", "kind", "sensitive", "otp")
          end

          def correlate(state, channel, event, text)
            command = text.match(/\A\/hitl-reply(?:@\w+)?(?:\s+(\S+)\s+(.+))?\z/im)
            replied = event["reply_to_message_id"].to_s
            records = state["requests"].values.select { |r| r["channel"] == channel["name"] }
            if text.split(/\s/, 2).first.to_s.split("@").first.downcase == "/hitl-reply"
              unless command && command[1] && command[2] && !command[2].strip.empty?
                raise ContractError, "use /hitl-reply ID ANSWER"
              end
              records = records.select { |r| r["request"] == command[1] }
              if !replied.empty?
                records = records.select { |r| r["message_id"] == replied }
              end
            elsif !replied.empty?
              records = records.select { |r| r["message_id"] == replied }
            else
              return nil # plain message is ALWAYS a new instruction
            end
            unless records.size == 1 && records.first["status"] == "submitted"
              raise ContractError, "unknown or ambiguous Reply correlation"
            end
            records.first["request"]
          end

          def deliver_reply(record, item, text, channel, commit)
            # Durable terminal history in ace-hitl defeats late replies even
            # after transport tombstones expire. Hermes never runs the effect.
            if record["sensitive"] && record["secret_delivery"] == "unavailable"
              item["status"] = "secret-unavailable"
              commit.call
              return
            end
            begin
              facts = @lifecycle.read(record["request"])
            rescue Ace::Hitl::Lifecycle::StateError
              terminal = @lifecycle.states.find { |value| value["id"] == record["request"] }
              if terminal && %w[consumed cancelled].include?(terminal["state"])
                item["status"] = "closed"
                commit.call
                return
              end
              raise
            end
            unless binding_for(facts) == record["binding"]
              item["status"] = "rejected"
              commit.call
              return
            end
            unless %w[created answer-delivered].include?(facts["state"])
              item["status"] = "closed"
              commit.call
              return
            end
            answer = text.sub(/\A\/hitl-reply(?:@\w+)?\s+\S+\s+/i, "")
            if !record["sensitive"]
              box = @box_factory.call(channel)
              existing = box.poll.messages.find { |m| m.id == record["request"] && m.answer? }
              if existing
                answer = existing.body.dup
              else
                box.publish(kind: :answer, id: record["request"], body: answer,
                  sender: "captain", timestamp: item["received_at"])
              end
            end
            @lifecycle.deliver(record["request"], answer)
            if record["sensitive"]
              item["status"] = "delivered"
            else
              # The protected folder remains the ordinary answer interface.
              # A crash after lifecycle delivery cannot run its effect twice.
              item["status"] = "delivered"
            end
            commit.call
          rescue StandardError
            item["status"] = record["sensitive"] ? "secret-unavailable" : "unresolved"
            record["secret_delivery"] = "unavailable" if record["sensitive"]
            commit.call
          ensure
            answer&.clear
            text.clear if record["sensitive"] && !text.frozen?
          end

          def deliver_instruction(item, text, channel, commit)
            box = @box_factory.call(channel)
            id = "inb-#{item['sequence']}"
            existing = box.poll.messages.find { |message| message.id == id }
            if existing
              unless existing.question? && existing.sender == "captain" && existing.body == text
                raise ContractError, "instruction folder identity collision"
              end
            else
              box.publish(kind: :question, id: id, body: text, sender: "captain", timestamp: item["received_at"])
            end
            item["target"] = channel["target"]
            item["status"] = "delivered"
            commit.call
          rescue StandardError
            item["status"] = "unresolved"
            commit.call
          end

          def projection(record)
            {"schema" => "ace.hitl.hermes.delivery/v1"}.merge(
              record.slice("request", "revision", "channel", "chat_id", "message_id", "submitted_at", "status")
            )
          end

          def public_ingress(item)
            item.slice("request", "revision", "channel", "message_id", "sequence", "received_at", "status", "target")
          end
        end
      end
    end
  end
end
