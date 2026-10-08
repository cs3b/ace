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

        def read_payload(socket, size:, deadline:)
          unless size.is_a?(Integer) && size.between?(1, 65_536)
            raise ValidationError, "context payload byte count differs"
          end
          bytes = +"".b
          while bytes.bytesize < size
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([socket], nil, nil, remaining)
              raise ValidationError, "context payload upload deadline expired"
            end
            part = socket.read_nonblock([size - bytes.bytesize, 4096].min, exception: false)
            next if part == :wait_readable
            raise ValidationError, "context payload upload was not completed" unless part
            bytes << part
          end
          text = bytes.force_encoding(Encoding::UTF_8)
          raise ValidationError, "context payload encoding differs" unless text.valid_encoding? && !text.include?("\0")
          text.freeze
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
