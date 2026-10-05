# frozen_string_literal: true

require_relative "protected_socket"

module Ace
  module Runtime
    module Molecules
      # Fixed installed system-manager units only. This adapter does not decide
      # when a generation may start/stop: canonical lifecycle owns admission.
      class SystemdScopeManager
        SYSTEMCTL = "/usr/bin/systemctl"
        UNIT = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        PROPERTIES = %w[Id LoadState ActiveState SubState InvocationID ControlGroup Job
          FragmentPath DropInPaths].freeze
        SERVICE_PROPERTIES = (PROPERTIES + %w[MainPID Slice]).freeze

        class Command
          LIMIT = 65_536

          def call(argv, timeout:)
            unless RUBY_PLATFORM.include?("linux") && File.directory?("/run/systemd/system")
              raise RuntimeUnavailableError, "execution scope requires the Linux system systemd manager"
            end
            ProtectedSocket.root_path!(SYSTEMCTL)
            unless File.executable?(SYSTEMCTL) && (File.stat(SYSTEMCTL).mode & 0o6000).zero?
              raise RuntimeUnavailableError, "installed system manager client is unsafe"
            end
            output_reader, output_writer = IO.pipe
            error_reader, error_writer = IO.pipe
            pid = Process.spawn({"PATH" => "/usr/bin:/bin", "LANG" => "C", "LC_ALL" => "C"}, *argv,
              in: File::NULL, out: output_writer, err: error_writer, unsetenv_others: true, close_others: true)
            output_writer.close
            error_writer.close
            deadline = ProtectedSocket.deadline(timeout)
            readers = [output_reader, error_reader]
            bytes = {output_reader => +"", error_reader => +""}
            until readers.empty?
              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
              ready = remaining.positive? && IO.select(readers, nil, nil, remaining)
              raise RuntimeUnavailableError, "system manager job outcome is unavailable" unless ready
              ready.first.each do |reader|
                chunk = reader.read_nonblock(4096, exception: false)
                next if chunk == :wait_readable
                if chunk.nil?
                  readers.delete(reader)
                else
                  bytes.fetch(reader) << chunk
                  if bytes.values.sum(&:bytesize) > LIMIT
                    raise RuntimeUnavailableError, "system manager response is oversized"
                  end
                end
              end
            end
            loop do
              waited = Process.waitpid(pid, Process::WNOHANG)
              if waited
                status = $?
                pid = nil
                raise RuntimeUnavailableError, "fixed system manager operation was refused" unless status.success?
                return bytes.fetch(output_reader)
              end
              unless Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
                raise RuntimeUnavailableError, "system manager job outcome is unavailable"
              end
              sleep 0.01
            end
          rescue SystemCallError, IOError
            raise RuntimeUnavailableError, "system manager operation is unavailable"
          ensure
            [output_reader, output_writer, error_reader, error_writer].compact.each do |stream|
              stream.close unless stream.closed?
            end
            if pid
              begin
                Process.kill("KILL", pid)
              rescue Errno::ESRCH
                nil
              ensure
                begin
                  Process.waitpid(pid)
                rescue Errno::ECHILD
                  nil
                end
              end
            end
          end
        end

        def initialize(slice_unit:, service_unit:, command: Command.new)
          unless slice_unit.is_a?(String) && service_unit.is_a?(String) &&
              UNIT.match?(slice_unit) && UNIT.match?(service_unit) &&
              slice_unit.end_with?(".slice") && service_unit.end_with?(".service") &&
              !%w[system.slice user.slice machine.slice].include?(slice_unit)
            raise ArgumentError, "execution scope requires fixed dedicated slice/service units"
          end
          @slice_unit, @service_unit, @command = slice_unit, service_unit, command
        end

        def inspect_units
          slice = show(@slice_unit)
          service = show(@service_unit, properties: SERVICE_PROPERTIES)
          unless slice["LoadState"] == "loaded" && service["LoadState"] == "loaded" &&
              service["Slice"] == @slice_unit
            raise RuntimeUnavailableError, "fixed execution units are missing or their placement changed"
          end
          {"slice" => slice, "service" => service}
        end

        def start_slice
          operate("start", @slice_unit)
        end

        def start_service
          operate("start", @service_unit)
        end

        def stop_slice
          operate("stop", @slice_unit)
        end

        def stop_service
          operate("stop", @service_unit)
        end

        private

        def operate(verb, unit)
          @command.call([SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", verb, "--", unit], timeout: 30)
          true
        end

        def show(unit, properties: PROPERTIES)
          bytes = @command.call([SYSTEMCTL, "--system", "--no-pager", "--no-ask-password", "show",
            "--property=#{properties.join(',')}", "--", unit], timeout: 5)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, Command::LIMIT)
            raise RuntimeUnavailableError, "fixed unit properties are unavailable"
          end
          expected = properties
          properties = {}
          bytes.each_line do |line|
            key, value = line.chomp.split("=", 2)
            unless expected.include?(key) && value && !properties.key?(key) && !value.include?("\0")
              raise RuntimeUnavailableError, "fixed unit property response is malformed"
            end
            properties[key] = value
          end
          unless properties.keys.sort == expected.sort && properties["Id"] == unit
            raise RuntimeUnavailableError, "fixed system manager unit identity differs"
          end
          properties
        end
      end
    end
  end
end
