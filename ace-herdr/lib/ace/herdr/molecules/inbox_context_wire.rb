# frozen_string_literal: true

require_relative "inbox_context_store"
require "ace/runtime/molecules/protected_socket"

module Ace
  module Herdr
    module Molecules
      module InboxContextWire
        LIMIT = 16_384
        DEADLINE = 30
        module_function

        def read(socket, deadline:)
          bytes = +""
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([socket], nil, nil, remaining)
              raise ValidationError, "context deadline reports blocked"
            end
            chunk = socket.read_nonblock(1, exception: false)
            next if chunk == :wait_readable
            raise ValidationError, "context frame was not completed" unless chunk
            bytes << chunk
            raise ValidationError, "context frame exceeds bounds" if bytes.bytesize > LIMIT
            break if chunk == "\n"
          end
          InboxContextStore.decode(bytes, limit: LIMIT)
        end

        def write(socket, value, deadline:)
          Ace::Runtime::Molecules::ProtectedSocket.write(socket, value, deadline: deadline, limit: LIMIT)
        end

        def read_proof(socket, sizes:, deadline:)
          unless sizes.is_a?(Array) && sizes.size == 2 && sizes.all? { |size| size.is_a?(Integer) && size.between?(1, LIMIT) }
            raise ValidationError, "context proof byte counts differ"
          end
          sizes.map do |size|
            bytes = +"".b
            while bytes.bytesize < size
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              unless remaining.positive? && IO.select([socket], nil, nil, remaining)
                raise ValidationError, "context proof upload deadline expired"
              end
              part = socket.read_nonblock([size - bytes.bytesize, 4096].min, exception: false)
              next if part == :wait_readable
              raise ValidationError, "context proof upload was not completed" unless part
              bytes << part
            end
            bytes.freeze
          end
        end

        def write_proof(socket, parts:, deadline:)
          unless parts.is_a?(Array) && parts.size == 2 && parts.all? { |part| part.is_a?(String) && part.bytesize.between?(1, LIMIT) }
            raise ValidationError, "context proof exceeds bounds"
          end
          parts.each do |part|
            offset = 0
            while offset < part.bytesize
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              unless remaining.positive? && IO.select(nil, [socket], nil, remaining)
                raise ValidationError, "context proof upload deadline expired"
              end
              sent = socket.write_nonblock(part.byteslice(offset..), exception: false)
              next if sent == :wait_writable
              offset += sent
            end
          end
        end

        def require_eof!(socket, deadline:)
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([socket], nil, nil, remaining)
              raise ValidationError, "context request upload was not completed"
            end
            byte = socket.read_nonblock(1, exception: false)
            next if byte == :wait_readable
            raise ValidationError, "context request has extra bytes" if byte
            return
          end
        end

        def deadline = Ace::Runtime::Molecules::ProtectedSocket.deadline(DEADLINE)
      end
    end
  end
end
