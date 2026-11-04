# frozen_string_literal: true

require_relative "error"

module Ace
  module Lab
    module Auth
      # The launcher retains the PTY master until mount preparation finishes.
      # This unprivileged entry waits without running any agent code. After
      # release exec preserves the systemd MainPID and its pinned identity.
      class SessionEntry
        RELEASE = "start\n"

        def self.run(argv, directory:, input: STDIN, environment: ENV, timeout: 30, execute: ->(args) { exec(*args) })
          unless environment["ACE_TOOLCHAIN"] == "installed" && environment["ACE_LAB_SESSION"] == "1" &&
              argv.is_a?(Array) && !argv.empty? && argv.all? { |arg| arg.is_a?(String) && !arg.include?("\0") } &&
              argv.first.start_with?("/") && File.expand_path(argv.first) == argv.first &&
              directory.is_a?(String) && directory.start_with?("/") && !directory.include?("\0") &&
              File.expand_path(directory) == directory
            raise Error, "session entry requires a configured installed command"
          end
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
          bytes = +""
          until bytes.bytesize == RELEASE.bytesize
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select([input], nil, nil, remaining)
              raise Error, "session preparation deadline expired"
            end
            chunk = input.read_nonblock(RELEASE.bytesize - bytes.bytesize, exception: false)
            next if chunk == :wait_readable
            raise Error, "session preparation channel closed" unless chunk
            bytes << chunk
            raise Error, "session preparation was not confirmed" unless RELEASE.start_with?(bytes)
          end
          # Resolve only after the launcher has installed the session view.
          # systemd WorkingDirectory would retain the pre-mount directory inode.
          raise Error, "session directory is not canonical" unless File.realpath(directory) == directory
          Dir.chdir(directory) { execute.call(argv) }
        end
      end
    end
  end
end
