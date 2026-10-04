# frozen_string_literal: true

require "json"
require "securerandom"
require_relative "../molecules/hermes_contract"
require_relative "../molecules/hermes_formats"
require_relative "../molecules/hermes_message"
require_relative "../molecules/hermes_atomic_writer"
require_relative "../molecules/hermes_quarantine"
require_relative "../molecules/hermes_retry_policy"
require_relative "../molecules/hermes_notifications"
require_relative "../molecules/hermes_channels"

module Ace
  module Hitl
    module Hermes
      module Organisms
        # The folder interface per channel (spec 8wm.t.vs1 §9): publish
        # (atomic write + collision retry), poll (validate + quarantine),
        # ack (deletion IS the ACK), age (retry clock), identical?
        # (redelivery identity). The Box is role-agnostic: the hermes
        # side polls for questions, the lab side (labd) polls for answers.
        class HermesBox
          QuarantinedFile = Struct.new(:path, :reason)
          PollResult = Struct.new(:messages, :quarantined)

          attr_reader :channel

          def initialize(channel:, registry: nil, id_generator: -> { SecureRandom.hex(6) },
            notifier: nil, euid_provider: -> { Process.euid }, answer_authorizer: nil)
            @channel =
              if channel.is_a?(Molecules::HermesChannels::Channel)
                channel
              elsif registry
                registry.resolve(channel)
              else
                raise ContractError,
                  "hermes box needs a Channel or a registry to resolve the channel name"
              end
            @id_generator = id_generator
            @notifier = notifier || ->(_line) {}
            @euid_provider = euid_provider
            @answer_authorizer = answer_authorizer
          end

          def address(id)
            @channel.address(id)
          end

          # Atomic write of a validated message. A GENERATED id is
          # regenerated (bounded, notified) on a filename collision; an
          # EXPLICITLY supplied id never gets regenerated - it asserts
          # correlation (e.g. the answer of question `q-1` is `q-1.json`),
          # so a collision there fails loudly instead of silently breaking
          # the question -> answer pairing. Returns the published Message.
          def publish(kind:, body:, sender:, timestamp:, id: nil)
            if kind.to_s == "answer"
              unless id && @answer_authorizer
                raise ContractError, "answer publication requires authenticated request classification"
              end
              facts = @answer_authorizer.call(id)
              unless facts.is_a?(Hash) && facts["id"] == id && facts["sensitive"] == false &&
                  !%w[otp secret].include?(facts["kind"])
                raise ContractError, "sensitive answers must use the protected HITL boundary"
              end
            end
            explicit_id = !id.nil?
            attempts = 0
            loop do
              message = build_message(
                kind: kind, id: id || @id_generator.call,
                sender: sender, timestamp: timestamp, body: body
              )
              # Producer fail-closed gate: the exact BYTES about to be
              # written must survive the consumers' decode gate (UTF-8 +
              # 64 KiB cap + schema id), and the decoded envelope must
              # satisfy the exact message contract, BEFORE any disk
              # write - so an envelope its own poll would terminally
              # quarantine can never be published (review 8wq2zttx on
              # PR#336).
              envelope = message.to_json
              Molecules::HermesFormats.decode!(envelope)
              Molecules::HermesMessage.from_hash(
                JSON.parse(envelope), filename_id: message.id
              )
              begin
                Molecules::HermesAtomicWriter.write(
                  Molecules::HermesContract.message_path(@channel.folder, message.id),
                  envelope,
                  euid_provider: @euid_provider
                )
              rescue CollisionError
                raise if explicit_id

                attempts += 1
                unless Molecules::HermesRetryPolicy.collision_retry?(attempts)
                  raise
                end

                notify(:retry_scheduled, address(message.id), attempt: attempts,
                  max_attempts: Molecules::HermesRetryPolicy::DEFAULT_MAX_ATTEMPTS,
                  policy: "collision")
                id = nil # force a fresh id on the next iteration
                next
              end

              notify(:answer_written, address(message.id)) if message.answer?
              return message
            end
          end

          # Validate + collect everything currently in the folder.
          # Valid files become Messages; files failing the fail-closed
          # gate are quarantined (never delivered). Foreign names
          # (dotfiles, tmp leftovers, non-`<token>.json`) are ignored.
          def poll
            Molecules::HermesContract.verify_folder!(@channel.folder)
            messages = []
            quarantined = []

            Dir.children(@channel.folder).sort.each do |name|
              id = Molecules::HermesContract.parse_file_name(name)
              next if id.nil? # dotfiles, tmp leftovers, foreign names

              path = File.join(@channel.folder, name)
              # Opened with O_NOFOLLOW and verified regular on the open
              # descriptor: a top-level symlink must never be followed -
              # it could import content from outside the channel or
              # reverse a quarantine's terminal state (review 8wq2ztu3
              # on PR#336).
              begin
                file = File.open(path, File::RDONLY | File::NOFOLLOW)
              rescue Errno::ENOENT
                next # concurrently acked between listing and reading
              rescue Errno::ELOOP
                quarantined << quarantine(path, id, "message file is a symlink")
                next
              end

              begin
                begin
                  regular = file.stat.file?
                rescue Errno::ENOENT
                  next # concurrently acked after the open
                end
                unless regular
                  quarantined << quarantine(path, id, "message file is not a regular file")
                  next
                end

                bytes = file.read(Molecules::HermesContract::MAX_BYTES + 1) || ""
                hash = Molecules::HermesFormats.decode!(bytes)
                message = Molecules::HermesMessage.from_hash(hash, filename_id: id)
              rescue Error => e
                quarantined << quarantine(path, id, e.message)
                next
              ensure
                file.close
              end

              notify(:question_received, address(message.id)) if message.question?
              messages << message
            end

            PollResult.new(messages: messages, quarantined: quarantined)
          end

          # Deletion is the ACK; idempotent (an absent file reports
          # :already_acked, never an error). The delete is a folder write,
          # so the no-root gate applies exactly like on publish.
          def ack(id)
            if @euid_provider.call.zero?
              raise RootUserError,
                "hermes writes without root: refusing ack deletion as euid 0 " \
                "(#{Molecules::HermesContract.message_path(@channel.folder, id)})"
            end
            Molecules::HermesContract.verify_folder!(@channel.folder)
            path = Molecules::HermesContract.message_path(@channel.folder, id)
            if File.exist?(path)
              File.delete(path)
              notify(:acked, address(id))
              :acked
            else
              :already_acked
            end
          end

          # Seconds since the message file was written (mtime); nil when
          # the file is gone (already acked). The undeleted-file retry
          # clock (spec §8).
          def age(id)
            path = Molecules::HermesContract.message_path(@channel.folder, id)
            File.exist?(path) ? Time.now - File.mtime(path) : nil
          end

          # True when the file for `id` currently holds exactly `bytes` -
          # the identity check every redelivery must pass (retries never
          # duplicate answers).
          def identical?(id, bytes)
            path = Molecules::HermesContract.message_path(@channel.folder, id)
            File.exist?(path) && read_capped(path) == bytes
          rescue Errno::ENOENT
            false
          end

          private

          def build_message(kind:, id:, sender:, timestamp:, body:)
            case kind.to_s
            when "question"
              Molecules::HermesMessage.question(
                id: id, question: body, sender: sender, created_at: timestamp
              )
            when "answer"
              Molecules::HermesMessage.answer(
                id: id, answer: body, sender: sender, received_at: timestamp
              )
            else
              raise ContractError,
                "hermes message kind must be question or answer (got #{kind.inspect})"
            end
          end

          # Read at most MAX_BYTES + 1 bytes so an oversized file fails
          # the size gate without reading the whole file. An empty file
          # reads as "" (File.read with an explicit length returns nil at
          # EOF) so the empty payload still fails the formats gate and is
          # quarantined instead of crashing the poll loop.
          def read_capped(path)
            File.read(path, Molecules::HermesContract::MAX_BYTES + 1) || ""
          end

          def quarantine(path, id, reason)
            quarantined = Molecules::HermesQuarantine.move(
              @channel.folder, path, reason: reason,
              euid_provider: @euid_provider
            )
            notify(:quarantined, address(id), reason: reason)
            QuarantinedFile.new(path: quarantined, reason: reason)
          end

          def notify(event, address, **details)
            @notifier.call(
              Molecules::HermesNotifications.emit(event, address: address, **details)
            )
          end
        end
      end
    end
  end
end
