# frozen_string_literal: true

require_relative "session_unit"
require "ace/runtime/molecules/protected_socket"

module Ace
  module Lab
    module Auth
      # Trusted host entry, not a general command endpoint. The caller obtains
      # SessionUnit from protected configuration and owns the resulting process
      # until systemd lifecycle verification and terminal handoff complete.
      class SessionLauncher
        Launch = Data.define(:unit, :transport_pid)

        def initialize(privileged: Process.euid.zero?, platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          verify_path: nil, spawn: Process.method(:spawn))
          @privileged, @platform, @spawn = privileged, platform, spawn
          @verify_path = verify_path || Ace::Runtime::Molecules::ProtectedSocket.method(:root_path!)
        end

        def start(unit:, terminal:)
          raise Error, "session launch requires the root host endpoint" unless @privileged
          raise ArgumentError, "configured session unit required" unless unit.is_a?(SessionUnit)
          @platform.supported!
          unless terminal.is_a?(IO) && !terminal.closed? && terminal.stat.chardev? && terminal.tty?
            raise Error, "session launch requires an open terminal descriptor"
          end
          @verify_path.call("/usr/bin/systemd-run")
          @verify_path.call(unit.executable)
          # An inherited Bundler, loader, credential or Ruby environment must
          # never reach the privileged systemd client. SessionUnit supplies
          # the configured child environment separately.
          pid = @spawn.call({"PATH" => "/usr/bin:/bin", "LANG" => "C", "LC_ALL" => "C"},
            *unit.argv, in: terminal, out: terminal, err: terminal,
            unsetenv_others: true, close_others: true)
          Launch.new(unit: unit.name, transport_pid: pid)
        rescue Ace::Runtime::Error, SystemCallError, IOError => error
          raise Error, "session launch failed (#{error.class})"
        end
      end
    end
  end
end
