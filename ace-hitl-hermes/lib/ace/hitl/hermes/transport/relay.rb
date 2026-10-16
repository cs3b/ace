# frozen_string_literal: true

require "time"
require "json"
require "digest"
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
        class IngressUnavailable < Error; end

        class Relay
          TERMINAL = %w[delivered closed rejected].freeze
          ORDER_RESOLVED = (TERMINAL + ["secret-unavailable"]).freeze

          def initialize(registry:, journal:, lifecycle_for:, sender:, clock: -> { Time.now.utc }, box_factory: nil)
            @registry, @journal, @lifecycle_for, @sender, @clock = registry, journal, lifecycle_for, sender, clock
            @box_factory = box_factory || lambda do |channel|
              lifecycle = channel["project"] && lifecycle_for(channel)
              self.class.folder_box(channel, answer_authorizer: lifecycle && ->(id) { lifecycle.read(id) })
            end
          end

          def self.folder_box(channel, answer_authorizer: nil)
            root = channel.fetch("root_folder", channel.fetch("folder"))
            raise ContractError, "channel folder cannot be a symlink" if File.lstat(root).symlink?
            if channel["project"]
              expected = File.join(File.realpath(channel.fetch("root_folder")), "projects", channel.fetch("project"))
              unless !File.lstat(channel.fetch("folder")).symlink? &&
                  !File.lstat(File.dirname(channel.fetch("folder"))).symlink? &&
                  File.realpath(channel.fetch("folder")) == expected
                raise ContractError, "project message folder aliases another authority"
              end
            end
            folder_channel = Molecules::HermesChannels::Channel.new(
              name: channel.fetch("name"), machine: channel.fetch("machine"), folder: channel.fetch("folder"),
              project: channel["project"])
            Organisms::HermesBox.new(channel: folder_channel, answer_authorizer: answer_authorizer)
          rescue SystemCallError
            raise ContractError, "project message folder is unavailable"
          end

          # A request revision names an immutable lifecycle binding, never a
          # mutable text hash. Metadata acknowledges submission, not reading.
          def submit(channel:, project:, request:, revision:)
            entry = @registry.project_channel(channel, project)
            lifecycle = lifecycle_for(entry)
            Atoms::HermesTokens.validate!(request, "request")
            Atoms::HermesTokens.validate!(revision, "revision")
            facts = lifecycle.read(request)
            unless facts["project"] == project
              raise ContractError, "request project is not registered to this channel"
            end
            binding = binding_for(facts)
            @journal.synchronize do |state, commit|
              previous = state["requests"][request_key(channel, project, request)]
              if previous
                verify_route!(previous)
                unless previous.values_at("channel", "project", "revision", "binding") ==
                    [channel, project, revision, binding]
                  raise ContractError, "request correlation binding cannot change"
                end
                if previous["status"] == "submitted"
                  acknowledge_proposal(previous, lifecycle)
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
              record = {"request" => request, "revision" => revision, "channel" => channel, "project" => project,
                        "route_identity" => @registry.route_identity(channel, project),
                        "chat_id" => entry["chat_id"], "binding" => binding,
                        "sensitive" => facts["sensitive"] == true, "status" => "uncertain",
                        "coverage_generation" => state["poll"].dig(channel, "generation") || 0}
              state["requests"][request_key(channel, project, request)] = record
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
                acknowledge_proposal(record, lifecycle)
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
                    key = request_key(channel["name"], duplicate.fetch("project"), duplicate["request"])
                    existing = state["requests"].fetch(key)
                    if existing["sensitive"]
                      duplicate["status"] = "secret-unavailable"
                      existing["secret_delivery"] = "unavailable"
                      commit.call
                      text.clear unless text.frozen?
                    else
                      unless duplicate["body_sha256"]
                        persist_ingress(duplicate, text, channel, existing)
                        commit.call
                      end
                      text = retained_ingress(duplicate, channel, existing)
                      deliver_reply(existing, duplicate, text, channel, commit, state)
                      cleanup_ingress(duplicate, channel, existing)
                    end
                  else
                    unless duplicate["body_sha256"]
                      persist_ingress(duplicate, text, channel, nil)
                      commit.call
                    end
                    text = retained_ingress(duplicate, channel, nil)
                    deliver_instruction(duplicate, text, channel, commit)
                    cleanup_ingress(duplicate, channel, nil)
                  end
                end
                return public_ingress(duplicate)
              end

              record = correlate(state, channel, event, text)
              request = record && record.fetch("request")
              item = {"sequence" => state["sequence"] += 1, "channel" => channel["name"],
                      "message_id" => event["message_id"], "user_id" => event["user_id"],
                      "received_at" => now, "status" => "queued",
                      "route_identity" => ingress_identity(channel, record)}
              if record
                item.merge!("request" => request, "project" => record.fetch("project"), "revision" => record["revision"])
              end
              state["ingress"] << item
              # Ordinary bodies are durable before the Telegram offset may advance.
              # Secret classification comes from the retained authenticated request;
              # a secret never enters a folder or a content-derived digest.
              commit.call # reserve stable sequence/classification before creating its body
              if !record || !record["sensitive"]
                persist_ingress(item, text, channel, record)
              end
              commit.call
              if record
                deliver_reply(record, item, text, channel, commit, state)
              else
                deliver_instruction(item, text, channel, commit)
              end
              cleanup_ingress(item, channel, record) unless record && record["sensitive"]
              public_ingress(item)
            end
          end

          # Retry the original durable body independently for each project. A
          # failed project never prevents later Telegram pages or another project.
          def drain
            @journal.synchronize do |state, commit|
              blocked = []
              state["ingress"].sort_by { |item| item.fetch("sequence") }.each do |item|
                next unless item["body_sha256"]
                scope = item.values_at("channel", "project")
                next if blocked.include?(scope)
                key = request_key(*item.values_at("channel", "project", "request")) if item["request"]
                record = item["request"] && state["requests"].fetch(key)
                begin
                  channel = @registry.resolve(item.fetch("channel"))
                  if TERMINAL.include?(item["status"])
                    cleanup_ingress(item, channel, record)
                    next
                  end
                  body = retained_ingress(item, channel, record)
                  if record
                    deliver_reply(record, item, body, channel, commit, state)
                  else
                    deliver_instruction(item, body, channel, commit)
                  end
                  cleanup_ingress(item, channel, record)
                rescue StandardError
                  unless TERMINAL.include?(item["status"])
                    item["status"] = "unresolved"
                    commit.call
                  end
                end
                blocked << scope unless ORDER_RESOLVED.include?(item["status"])
              end
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
              update_poll(state, channel: channel, started_at: started_at, through: through, continuous: continuous)
              commit.call
            end
          end

          def surface_registration_gaps(at:)
            validate_time(at)
            @journal.synchronize do |state, commit|
              gaps = @registry.channels.filter_map do |channel|
                record = state["unregistered_chats"][channel.fetch("chat_id")]
                next unless record
                next if record["surfaced_through_update_id"] == record["last_update_id"]

                name = channel.fetch("name")
                update_poll(state, channel: name, started_at: at, through: at, continuous: false)
                record["registered_channel"] = name
                record["surfaced_at"] = at
                record["surfaced_through_update_id"] = record["last_update_id"]
                record.slice("chat_id", "first_seen_at", "last_seen_at", "first_update_id", "last_update_id", "count")
                  .merge("channel" => name, "coverage_generation" => state["poll"].dig(name, "generation"))
              end
              commit.call unless gaps.empty?
              gaps
            end
          end

          def reconcile(channel:, project:, request:, through:)
            entry = @registry.project_channel(channel, project)
            lifecycle = lifecycle_for(entry)
            validate_time(through)
            @journal.synchronize do |state, _commit|
              record = state["requests"][request_key(channel, project, request)]
              return {"status" => "unknown", "healthy" => false, "drained" => false} unless record

              verify_route!(record)
              poll = state["poll"][record["channel"]]
              healthy = poll && poll["healthy"] && poll["from"] <= through && poll["through"] >= through &&
                record["status"] == "submitted" && poll["from"] <= record["submitted_at"] &&
                poll.fetch("generation", 0) == record.fetch("coverage_generation", 0)
              relevant = state["ingress"].select do |item|
                item["channel"] == channel && item["project"] == project && item["request"] == request &&
                  item["revision"] == record["revision"] && item["received_at"] <= through
              end
              unresolved = relevant.reject { |item| TERMINAL.include?(item["status"]) }.map { |i| public_ingress(i) }
              checkpoint = {"schema" => "ace.hitl.hermes.ingress-checkpoint/v1", "request" => request, "project" => project,
               "revision" => record["revision"], "channel" => record["channel"],
               "status" => healthy ? "healthy" : "unknown", "healthy" => !!healthy,
               "drained" => !!healthy && unresolved.empty?,
               "checkpoint" => healthy ? {"through" => through, "sequence" => state["sequence"]} : nil,
               "unresolved" => unresolved}
              if proposal?(record)
                # Same ingress lock as receive; no received reply can land
                # between this checkpoint and the HITL decision transition.
                checkpoint["proposal"] = lifecycle.proposal_reconcile(request,
                  project: record.fetch("binding").fetch("envelope").fetch("project"), checkpoint: checkpoint)
              end
              checkpoint
            end
          end

          def delivery(channel:, project:, request:)
            @registry.project_channel(channel, project)
            @journal.synchronize do |state, _commit|
              record = state["requests"][request_key(channel, project, request)]
              verify_route!(record) if record
              record ? projection(record) : {"request" => request, "project" => project, "status" => "unknown"}
            end
          end

          private

          def ingress_box(channel, record)
            scoped = record ? @registry.project_channel(channel.fetch("name"), record.fetch("project")) : channel
            self.class.folder_box(scoped) # reject project aliases before touching private ingress
            folder = File.join(scoped.fetch("folder"), ".ingress")
            begin
              Dir.mkdir(folder, 0o700)
              File.open(scoped.fetch("folder")) { |directory| directory.fsync }
            rescue Errno::EEXIST
              # Verify the existing object; never follow or repair an alias.
            end
            stat = File.lstat(folder)
            unless stat.directory? && !stat.symlink? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
              raise IngressUnavailable, "ordinary ingress requires an owned private directory"
            end
            entry = scoped.merge("folder" => folder).reject { |key, _| %w[project root_folder].include?(key) }
            self.class.folder_box(entry)
          end

          def ingress_identity(channel, record)
            return @registry.route_identity(channel.fetch("name"), record.fetch("project")) if record

            binding = channel.slice("name", "chat_id", "captain_user_ids", "machine", "folder", "target")
            Digest::SHA256.hexdigest(JSON.generate(binding))
          end

          def persist_ingress(item, text, channel, record)
            unless item.fetch("route_identity") == ingress_identity(channel, record)
              raise IngressUnavailable, "retained ingress authority configuration changed"
            end
            box = ingress_box(channel, record)
            id = "inb-#{item.fetch('sequence')}"
            if File.exist?(File.join(box.channel.folder, "#{id}.json"))
              # The actor may have died after the file fsync and before its
              # metadata commit. Keep the first body, including on edited replay.
              message = box.poll.messages.find { |candidate| candidate.id == id }
              unless message && message.question? && message.sender == "captain" &&
                  message.timestamp == item.fetch("received_at")
                raise IngressUnavailable, "ordinary ingress identity collision"
              end
              text = message.body
            else
              box.publish(kind: :question, id: id, body: text, sender: "captain", timestamp: item.fetch("received_at"))
            end
            item["body_sha256"] = Digest::SHA256.hexdigest(text)
            item["route_identity"] = ingress_identity(channel, record)
          rescue StandardError
            raise IngressUnavailable, "ordinary ingress could not be persisted; Telegram offset retained"
          end

          def retained_ingress(item, channel, record)
            unless item.fetch("route_identity") == ingress_identity(channel, record)
              raise IngressUnavailable, "retained ingress authority configuration changed"
            end
            box = ingress_box(channel, record)
            message = box.poll.messages.find { |candidate| candidate.id == "inb-#{item.fetch('sequence')}" }
            unless message && message.question? && message.sender == "captain" &&
                message.timestamp == item.fetch("received_at") &&
                Digest::SHA256.hexdigest(message.body) == item.fetch("body_sha256")
              raise IngressUnavailable, "retained ordinary ingress is unavailable"
            end
            message.body
          end

          def cleanup_ingress(item, channel, record)
            return unless TERMINAL.include?(item["status"])

            box = ingress_box(channel, record)
            box.ack("inb-#{item.fetch('sequence')}")
            File.open(box.channel.folder) { |directory| directory.fsync }
          end

          def proposal?(record)
            record.dig("binding", "envelope", "kind") == "proposal"
          end

          def acknowledge_proposal(record, lifecycle)
            return unless proposal?(record)
            lifecycle.proposal_acknowledge(record["request"],
              project: record.fetch("binding").fetch("envelope").fetch("project"),
              submitted_at: record.fetch("submitted_at"))
          end

          def lifecycle_for(channel)
            @lifecycle_for.call(channel, channel.fetch("project"))
          end

          def verify_route!(record)
            current = @registry.route_identity(record.fetch("channel"), record.fetch("project"))
            unless record.fetch("route_identity") == current
              raise ContractError, "retained request authority configuration changed"
            end
          end

          def request_key(channel, project, request)
            JSON.generate([channel, project, request])
          end

          def update_poll(state, channel:, started_at:, through:, continuous:)
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
          end

          def now
            @clock.call.utc.iso8601
          end

          def validate_time(value)
            Molecules::HermesMessage.validate_timestamp!(value, "through")
          end

          def binding_for(facts)
            unless [true, false].include?(facts["sensitive"]) &&
                (facts["kind"] != "otp" || facts["sensitive"] == true)
              raise ContractError, "authoritative request classification is invalid"
            end
            envelope = Ace::Hitl::Contract::ManagedEnvelope.load(facts.fetch("envelope"), expected: {
              request_id: facts["id"], correlation_id: facts["id"], assignment_id: facts["assignment"],
              attempt_id: facts["attempt"], project: facts["project"], requester: facts["requester"], kind: facts["kind"]
            })
            {"envelope" => envelope, "sensitive" => facts["sensitive"] == true, "otp" => facts["otp"]}
          rescue KeyError, Ace::Hitl::Contract::InvalidEnvelope => e
            raise ContractError, "authoritative managed binding is invalid (#{e.message})"
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
            verify_route!(records.first)
            records.first
          end

          def deliver_reply(record, item, text, channel, commit, state)
            verify_route!(record)
            channel = @registry.project_channel(channel.fetch("name"), record.fetch("project"))
            lifecycle = lifecycle_for(channel)
            # Durable terminal history in ace-hitl defeats late replies even
            # after transport tombstones expire. Hermes never runs the effect.
            if record["sensitive"] && record["secret_delivery"] == "unavailable"
              item["status"] = "secret-unavailable"
              commit.call
              return
            end
            if state["ingress"].any? { |earlier|
                earlier["channel"] == item["channel"] && earlier["project"] == item["project"] &&
                  earlier["sequence"] < item["sequence"] && !ORDER_RESOLVED.include?(earlier["status"]) }
              item["status"] = "unresolved"
              commit.call
              return
            end
            begin
              facts = lifecycle.read(record["request"])
            rescue Ace::Hitl::Lifecycle::StateError
              terminal = lifecycle.states.find { |value| value["id"] == record["request"] }
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
            if proposal?(record)
              lifecycle.proposal_reply(record["request"],
                project: record.fetch("binding").fetch("envelope").fetch("project"), answer: answer,
                received_at: item["received_at"], sequence: item["sequence"])
              item["status"] = "delivered"
              commit.call
              return
            end
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
            lifecycle.deliver(record["request"], answer)
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
              record.slice("request", "project", "revision", "channel", "chat_id", "message_id", "submitted_at", "status")
            )
          end

          def public_ingress(item)
            item.slice("request", "project", "revision", "channel", "message_id", "sequence",
              "received_at", "status", "target")
          end
        end
      end
    end
  end
end
