# frozen_string_literal: true

require "etc"
require "fiddle"

module Ace
  module Lab
    module Auth
      # Execute a leased command as the OS identity of an isolated session.
      # The caller must obtain uid from an authenticated OS peer, never from
      # a request field. This primitive does not create or authenticate a
      # session and does not issue credentials.
      class SessionRunner
        def initialize(uid:, cwd:, attach: nil)
          raise ArgumentError, "session execution requires a root issuer" unless Process.euid.zero?

          uid = Integer(uid)
          raise ArgumentError, "a session must not run as root" if uid <= 0

          @account = Etc.getpwuid(uid)
          raise ArgumentError, "a session must not use the root group" if @account.gid.zero?
          raise ArgumentError, "session working directory must be an absolute path" unless cwd.is_a?(String) && cwd.start_with?("/")
          @cwd = File.realpath(cwd)
          raise ArgumentError, "session working directory is not a directory" unless File.directory?(@cwd)
          @attach = attach
        end

        def call(argv, env)
          raise ArgumentError, "a session command is required" unless argv.is_a?(Array) && !argv.empty?
          # Do not launch from the issuer's cgroup. Until the system entry
          # point can attach this child to an authenticated session lifetime,
          # it could outlive that session and inherit a recycled dynamic UID.
          raise ArgumentError, "session lifetime attachment is not available" unless @attach.respond_to?(:call)

          child_env = env.merge("HOME" => @account.dir, "USER" => @account.name,
            "LOGNAME" => @account.name)
          ready_reader, ready_writer = IO.pipe
          prepared_reader, prepared_writer = IO.pipe
          pid = fork do
            begin
              ready_writer.close
              prepared_reader.close
              Process.setpgid(0, 0)
              # Never carry the issuer's supplementary groups, including
              # wheel/sudo or root, into the session command.
              Process.groups = []
              # A process moved to a systemd cgroup does not inherit that
              # unit's process credentials. Set this on the child itself.
              restrict_privilege_escalation!
              Process::GID.change_privilege(@account.gid)
              Process::UID.change_privilege(@account.uid)
              Dir.chdir(@cwd)
              prepared_writer.write("1")
              prepared_writer.close
              exit! 127 unless ready_reader.read(1) == "1"
              ready_reader.close
              exec(child_env, *argv, unsetenv_others: true)
            rescue StandardError
              warn "ace-lab auth: failed to start the isolated session command"
              exit! 127
            end
          end
          ready_reader.close
          prepared_writer.close
          begin
            unless IO.select([prepared_reader], nil, nil, 10) && prepared_reader.read(1) == "1"
              raise ArgumentError, "session child could not drop privileges"
            end
            prepared_reader.close
            raise ArgumentError, "session attachment failed" unless @attach.call(pid) == true
            ready_writer.write("1")
            ready_writer.close
            _, status = Process.wait2(pid)
            status.exitstatus || 128 + status.termsig.to_i
          rescue Exception # ensure a cancelled issuer does not leave its child running
            begin
              Process.kill("KILL", -pid)
            rescue Errno::ESRCH
              begin
                Process.kill("KILL", pid)
              rescue Errno::ESRCH
                nil
              end
            end
            begin
              Process.waitpid(pid)
            rescue Errno::ECHILD
              nil
            end
            raise
          ensure
            ready_reader.close unless ready_reader.closed?
            ready_writer.close unless ready_writer.closed?
            prepared_reader.close unless prepared_reader.closed?
            prepared_writer.close unless prepared_writer.closed?
          end
        end

        private

        def restrict_privilege_escalation!
          raise ArgumentError, "session execution requires Linux" unless RUBY_PLATFORM.include?("linux")
          prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
          last_capability = Integer(File.read("/proc/sys/kernel/cap_last_cap").strip, 10)
          raise ArgumentError, "invalid capability range" unless last_capability.between?(0, 255)
          (0..last_capability).each do |capability|
            raise ArgumentError, "cannot restrict session capabilities" unless prctl.call(24, capability, 0, 0, 0).zero? # PR_CAPBSET_DROP
          end
          raise ArgumentError, "cannot restrict session privileges" unless prctl.call(38, 1, 0, 0, 0).zero? # PR_SET_NO_NEW_PRIVS
        rescue Fiddle::DLError
          raise ArgumentError, "cannot restrict session privileges"
        end
      end
    end
  end
end
