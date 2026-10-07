# frozen_string_literal: true
require "socket"
require "json"

module Ace
  module Runtime
    module Molecules
      module ProtectedSocket
        LIMIT = 65_536
        # Fixed protocols that forbid descriptors use this for every control,
        # binary-body and EOF read; rights never bypass a later framing check.
        class Ingress
          def initialize(socket) = @socket = socket
          def to_io = @socket

          def read_nonblock(length, exception: false)
            result = @socket.recvmsg_nonblock(length, 0, 4096, scm_rights: true, exception: exception)
            return result if result == :wait_readable
            return nil if result.nil?
            bytes, _, flags, *controls = result
            controls.each { |control| control.unix_rights&.each(&:close) if control.cmsg_is?(Socket::SOL_SOCKET, Socket::SCM_RIGHTS) }
            raise SecurityError, "protected ancillary input is forbidden" unless controls.empty? && (flags & Socket::MSG_CTRUNC).zero?
            bytes.empty? ? nil : bytes
          end
        end
        module_function

        def root_path!(path, directory: false, owner: 0)
          unless path.is_a?(String) && path.start_with?("/") && File.expand_path(path) == path
            raise RuntimeUnavailableError, "protected path must be canonical and absolute"
          end
          current = path
          loop do
            stat = File.lstat(current)
            unless !stat.symlink? && (current == path ? stat.uid == owner : [0, owner].include?(stat.uid)) && (stat.mode & 0o022).zero?
              raise RuntimeUnavailableError, "protected path ownership or ancestry is unsafe"
            end
            if current != path && !stat.directory?
              raise RuntimeUnavailableError, "protected ancestor is not a directory"
            end
            if current == path && directory && !stat.directory?
              raise RuntimeUnavailableError, "protected root is not a directory"
            end
            break if current == "/"
            current = File.dirname(current)
          end
          true
        rescue SystemCallError
          raise RuntimeUnavailableError, "protected path is unavailable"
        end

        def connect(path, deadline: self.deadline)
          socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_STREAM, 0)
          socket.close_on_exec = true
          result = socket.connect_nonblock(Socket.sockaddr_un(path), exception: false)
          if result == :wait_writable
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select(nil, [socket], nil, remaining) && socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_ERROR).int.zero?
              raise RuntimeUnavailableError, "protected socket connection deadline expired"
            end
          end
          yield socket
        ensure
          socket&.close unless socket&.closed?
        end

        def socket_identity(path, mode: nil)
          stat = File.lstat(path)
          raise RuntimeUnavailableError, "protected endpoint is not a socket" unless stat.socket? && !stat.symlink?
          if !mode.nil? && (!mode.is_a?(Integer) || !mode.between?(0, 0o7777) || (stat.mode & 0o7777) != mode)
            raise RuntimeUnavailableError, "protected endpoint mode differs"
          end
          [stat.dev, stat.ino, stat.uid]
        rescue SystemCallError
          raise RuntimeUnavailableError, "protected endpoint is unavailable"
        end

        def read(socket, deadline:, limit: LIMIT, with_size: false)
          buffer = +""
          loop do
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise RuntimeUnavailableError, "protected socket deadline expired" unless remaining.positive? &&
              IO.select([socket], nil, nil, remaining)
            chunk = socket.read_nonblock(1, exception: false)
            next if chunk == :wait_readable
            raise RuntimeUnavailableError, "protected socket closed before response" unless chunk
            buffer << chunk
            raise RuntimeUnavailableError, "protected socket frame is oversized" if buffer.bytesize > limit
            break if chunk == "\n"
          end
          buffer.force_encoding(Encoding::UTF_8)
          raise RuntimeUnavailableError, "protected socket frame is malformed" unless buffer.valid_encoding?
          value = JSON.parse(buffer, create_additions: false, max_nesting: 32,
            allow_duplicate_key: false, allow_comments: false)
          with_size ? {data: value, bytesize: buffer.bytesize} : value
        rescue JSON::ParserError
          raise RuntimeUnavailableError, "protected socket frame is malformed"
        end

        def write(socket, value, deadline:, limit: LIMIT)
          bytes = JSON.generate(value) + "\n"
          raise RuntimeUnavailableError, "protected socket frame is oversized" if bytes.bytesize > limit
          until bytes.empty?
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise RuntimeUnavailableError, "protected socket deadline expired" unless remaining.positive? &&
              IO.select(nil, [socket], nil, remaining)
            sent = socket.write_nonblock(bytes, exception: false)
            next if sent == :wait_writable
            bytes = bytes.byteslice(sent..)
          end
        end

        def deadline(seconds = 5)
          Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
        end
      end
    end
  end
end
