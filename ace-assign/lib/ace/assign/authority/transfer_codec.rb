# frozen_string_literal: true

require "digest"
require "tempfile"
require "timeout"
require_relative "private_directory"

module Ace
  module Assign
    module Authority
      # Binary framing after the existing authenticated control header. The
      # Server selects purpose from a source handler's fixed operation table,
      # admits a transfer slot before calling, and holds no journal lock here.
      class TransferCodec
        LIMITS = {candidate: [64 * 1024 * 1024, 1, 64 * 1024 * 1024],
                  artifacts: [256 * 1024, 16, 64 * 1024],
                  receipt_artifacts: [272 * 1024, 17, 64 * 1024],
                  service_input: [64 * 1024, 1, 64 * 1024]}.freeze
        SHA256 = /\A[0-9a-f]{64}\z/

        class Input
          def initialize(file, descriptor)
            @file, @descriptor = file, descriptor
          end

          def bytes(index: 0)
            unless index.is_a?(Integer) && index.between?(0, count - 1)
              raise ArgumentError, "Invalid transferred part index"
            end
            part = @descriptor.fetch("parts").fetch(index)
            offset = @descriptor.fetch("parts").take(index).sum { |entry| entry.fetch("bytes") }
            @file.seek(offset)
            bytes = (@file.read(part.fetch("bytes")) || "").b
            unless bytes.bytesize == part["bytes"] && Digest::SHA256.hexdigest(bytes) == part["sha256"]
              raise AttemptErrors::ReceiptRejected, "Transferred bytes no longer match accepted binding"
            end
            bytes
          end

          def count
            @descriptor.fetch("parts").length
          end
        end

        def initialize(root:)
          @root = PrivateDirectory.verify!(root)
        end

        # Upload write-EOF is required before invoking the mutation consumer.
        # Persistent launch gate connections never use this codec.
        def receive(socket, descriptor:, purpose:, deadline:)
          validate!(descriptor, purpose)
          descriptor = descriptor.merge("parts" => descriptor.fetch("parts").map { |part| part.dup.freeze }.freeze).freeze
          deadline = [deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30].min
          PrivateDirectory.verify!(@root)
          Tempfile.create(["transfer-", ".bytes"], @root, binmode: true) do |file|
            digest = Digest::SHA256.new
            descriptor.fetch("parts").each do |part|
              part_digest = Digest::SHA256.new
              remaining = part.fetch("bytes")
              while remaining.positive?
                chunk = read(socket, [remaining, 65_536].min, deadline)
                reject!("Transferred bytes ended early") if chunk.nil?
                file.write(chunk)
                digest.update(chunk)
                part_digest.update(chunk)
                remaining -= chunk.bytesize
              end
              reject!("Transferred part digest differs") unless part_digest.hexdigest == part["sha256"]
            end
            reject!("Transferred aggregate digest differs") unless digest.hexdigest == descriptor["sha256"]
            reject!("Transferred bytes exceed declared size") unless read(socket, 1, deadline).nil?
            file.flush
            file.rewind
            yield Input.new(file, descriptor)
          end
        end

        def descriptor(parts, purpose:)
          reject!("Invalid transfer parts") unless parts.is_a?(Array) && parts.all? { |part| part.is_a?(String) }
          digest = Digest::SHA256.new
          parts.each { |part| digest.update(part.b) }
          result = {"version" => 1, "bytes" => parts.sum(&:bytesize), "sha256" => digest.hexdigest,
                    "parts" => parts.map { |part| {"bytes" => part.bytesize, "sha256" => Digest::SHA256.hexdigest(part.b)} }}
          validate!(result, purpose)
          result
        end

        # The caller writes the bounded JSON descriptor first, then these raw
        # bytes. Both directions share the Server's original monotonic deadline.
        def send(socket, parts:, descriptor:, purpose:, deadline:)
          expected = self.descriptor(parts, purpose: purpose)
          reject!("Export descriptor differs from bytes") unless expected == descriptor
          deadline = [deadline, Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30].min
          parts.each do |part|
            offset = 0
            while offset < part.bytesize
              wait(socket, deadline, write: true)
              written = socket.write_nonblock(part.byteslice(offset, [65_536, part.bytesize - offset].min), exception: false)
              offset += written unless written == :wait_writable
            end
          end
        end

        def validate!(descriptor, purpose)
          total, count, each = LIMITS.fetch(purpose) { reject!("Unknown source transfer purpose") }
          unless descriptor.is_a?(Hash) && descriptor.keys.sort == %w[bytes parts sha256 version] &&
              descriptor["version"] == 1 && descriptor["bytes"].is_a?(Integer) &&
              descriptor["bytes"].between?(0, total) && descriptor["sha256"].is_a?(String) && descriptor["sha256"].match?(SHA256) &&
              descriptor["parts"].is_a?(Array) && descriptor["parts"].length.between?(1, count) &&
              descriptor["parts"].all? { |part| part.is_a?(Hash) && part.keys.sort == %w[bytes sha256] &&
                part["bytes"].is_a?(Integer) && part["bytes"].between?(0, each) &&
                part["sha256"].is_a?(String) && part["sha256"].match?(SHA256) } &&
              descriptor["bytes"] == descriptor["parts"].sum { |part| part["bytes"] } &&
              (!%i[candidate service_input].include?(purpose) || descriptor["bytes"].positive?)
            reject!("Invalid or oversized transfer descriptor")
          end
          if purpose == :receipt_artifacts
            receipt, *evidence = descriptor.fetch("parts")
            unless receipt.fetch("bytes").between?(1, 16 * 1024) && evidence.sum { |part| part.fetch("bytes") } <= 256 * 1024
              reject!("Receipt or evidence exceeds its fixed transfer limit")
            end
          end
          true
        end

        private

        def read(socket, count, deadline)
          loop do
            wait(socket, deadline)
            bytes = socket.read_nonblock(count, exception: false)
            return bytes unless bytes == :wait_readable
          end
        end

        def wait(socket, deadline, write: false)
          remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise Timeout::Error, "Transfer deadline exceeded" unless remaining.positive?
          ready = IO.select(write ? nil : [socket], write ? [socket] : nil, nil, remaining)
          raise Timeout::Error, "Transfer deadline exceeded" unless ready
        end

        def reject!(message)
          raise AttemptErrors::ReceiptRejected, message
        end
      end
    end
  end
end
