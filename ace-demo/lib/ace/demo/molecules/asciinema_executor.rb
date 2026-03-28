# frozen_string_literal: true

require "open3"
require "pty"
require "thread"

module Ace
  module Demo
    module Molecules
      class AsciinemaExecutor
        INSTALL_URL = "https://docs.asciinema.org/getting-started/"

        def initialize(open3: Open3, sleeper: Kernel, pty: PTY)
          @open3 = open3
          @sleeper = sleeper
          @pty = pty
        end

        def asciinema_available?(asciinema_bin: "asciinema")
          _stdout, _stderr, status = @open3.capture3(asciinema_bin, "--version")
          status.success?
        rescue Errno::ENOENT
          false
        end

        def run(cmd, asciinema_bin: "asciinema", chdir: nil)
          effective_bin = cmd.first || asciinema_bin
          options = {}
          options[:chdir] = chdir if chdir
          stdout, stderr, status = @open3.capture3(*cmd, **options)
          result = Models::ExecutionResult.new(
            stdout: stdout.strip,
            stderr: stderr.strip,
            success: status.success?,
            exit_code: status.exitstatus
          )

          return result if result.success?

          raise AsciinemaExecutionError, "Asciinema execution failed: #{result.stderr}"
        rescue Errno::ENOENT
          raise AsciinemaNotFoundError, "Asciinema not found (#{effective_bin}). Install: #{INSTALL_URL}"
        end

        def run_interactive(cmd, commands:, env: {}, asciinema_bin: "asciinema", chdir: nil)
          effective_bin = cmd.first || asciinema_bin
          options = {}
          options[:chdir] = chdir if chdir

          stdout = +""
          read_io = nil
          write_io = nil
          pid = nil
          reader = nil
          buffer = +""
          buffer_mutex = Mutex.new
          buffer_cv = ConditionVariable.new

          begin
            read_io, write_io, pid = @pty.spawn(env, *cmd, **options)
            cols, rows = tty_size_from(cmd)
            if cols && rows && read_io.respond_to?(:winsize=)
              read_io.winsize = [rows, cols]
            end
            if cols && rows && write_io.respond_to?(:winsize=)
              write_io.winsize = [rows, cols]
            end
            reader = Thread.new do
              loop do
                chunk = read_io.readpartial(4096)
                buffer_mutex.synchronize do
                  buffer << chunk
                  buffer_cv.broadcast
                end
              end
            rescue EOFError, Errno::EIO
              buffer_mutex.synchronize { buffer.dup }
            end

            wait_for_prompt(buffer, buffer_mutex, buffer_cv)

            commands.each do |command|
              write_io.write("#{command.fetch(:command)}\n")
              write_io.flush
              @sleeper.sleep(command.fetch(:sleep))
            end

            write_io.write("exit\n")
            write_io.flush
            write_io.close

            _wait_pid, status = Process.wait2(pid)
            stdout = reader.value
          ensure
            read_io&.close unless read_io&.closed?
            write_io&.close unless write_io&.closed?
          end

          result = Models::ExecutionResult.new(
            stdout: stdout.strip,
            stderr: "",
            success: status.success?,
            exit_code: status.exitstatus
          )

          return result if result.success?

          raise AsciinemaExecutionError, "Asciinema execution failed: #{result.stderr}"
        rescue Errno::ENOENT
          raise AsciinemaNotFoundError, "Asciinema not found (#{effective_bin}). Install: #{INSTALL_URL}"
        end

        private

        def tty_size_from(cmd)
          cols = nil
          rows = nil

          cmd.each_with_index do |part, index|
            cols = cmd[index + 1].to_i if part == "--cols" && cmd[index + 1]
            rows = cmd[index + 1].to_i if part == "--rows" && cmd[index + 1]
          end

          return [nil, nil] unless cols && rows && cols.positive? && rows.positive?

          [cols, rows]
        end

        PROMPT_PATTERN = /(?:^|[\r\n])(?:\e\[[0-9;?]*[A-Za-z])*[^ \r\n]*[$#] $/.freeze
        private_constant :PROMPT_PATTERN

        def wait_for_prompt(buffer, mutex, cv, timeout: 5.0)
          deadline = Time.now + timeout
          mutex.synchronize do
            until buffer.match?(PROMPT_PATTERN)
              remaining = deadline - Time.now
              break if remaining <= 0

              cv.wait(mutex, remaining)
            end
          end
        end
      end
    end
  end
end
