# frozen_string_literal: true
require_relative "../../organisms/command_executor"
module Ace
  module Lab
    module CLI
      module Commands
        class CommandExecute < Ace::Support::Cli::Command
          desc "Execute one admitted command for the installed root launcher"
          option :project, required: true
          option :fd, type: :integer, required: true
          def call(project:, fd:, **)
            raise SecurityError unless Process.uid.zero? && Process.euid.zero? && fd >= 3
            bytes = $stdin.read(16_385)
            raise ArgumentError if bytes.bytesize > 16_384
            request = JSON.parse(bytes, allow_duplicate_key: false, create_additions: false, max_nesting: 16)
            socket = UNIXSocket.for_fd(fd)
            Organisms::CommandExecutor.new(project: project).run(socket: socket, request: request)
            0 # Child status belongs to the framed result, not helper transport.
          rescue StandardError, SecurityError
            raise Ace::Support::Cli::Error, "command uncertain; inspect original execution reference"
          ensure
            socket&.close unless socket&.closed?
          end
        end
      end
    end
  end
end
