# frozen_string_literal: true

require "etc"
require "fiddle"
require_relative "error"
require_relative "session_namespace"

module Ace
  module Lab
    module Auth
      # Execute a leased command as the OS identity of an isolated session.
      # The caller must obtain uid from an authenticated OS peer, never from
      # a request field. This primitive does not create or authenticate a
      # session and does not issue credentials.
      class SessionRunner
        def initialize(uid:, cwd:, attach: nil, namespace: nil, namespace_joiner: SessionNamespace.method(:enter!))
          raise ArgumentError, "session execution requires a root issuer" unless Process.euid.zero?

          uid = Integer(uid)
          raise ArgumentError, "a session must not run as root" if uid <= 0

          @account = Etc.getpwuid(uid)
          raise ArgumentError, "a session must not use the root group" if @account.gid.zero?
          raise ArgumentError, "session working directory must be an absolute path" unless cwd.is_a?(String) && cwd.start_with?("/")
          # Resolve the name here, but enter it after setns so the session's
          # id-mapped project mount, rather than a host-opened fd, is used.
          @cwd = File.realpath(cwd)
          raise ArgumentError, "session working directory is not a directory" unless File.directory?(@cwd)
          @attach = attach
          @namespace, @namespace_joiner = namespace, namespace_joiner
        end

        def call(argv, env, before_start: nil)
          unless argv.is_a?(Array) && !argv.empty? && argv.all? { |arg| arg.is_a?(String) && !arg.include?("\0") } && !argv.first.empty?
            raise ArgumentError, "a valid session command is required"
          end
          unless env.is_a?(Hash) && env.all? { |key, value|
            key.is_a?(String) && !key.empty? && !key.include?("\0") && !key.include?("=") &&
              value.is_a?(String) && !value.include?("\0")
          }
            raise ArgumentError, "a valid session environment is required"
          end
          # Do not launch from the issuer's cgroup. Until the system entry
          # point can attach this child to an authenticated session lifetime,
          # it could outlive that session and inherit a recycled dynamic UID.
          unless @attach.respond_to?(:prepare) && @attach.respond_to?(:verify_child!)
            raise ArgumentError, "session lifetime attachment is not available"
          end
          raise ArgumentError, "session mount namespace is not available" unless @namespace.is_a?(IO) && !@namespace.closed?
          raise ArgumentError, "session start callback is invalid" unless before_start.nil? || before_start.respond_to?(:call)

          child_env = env.merge("HOME" => @account.dir, "USER" => @account.name,
            "LOGNAME" => @account.name)
          cgroup = @attach.prepare
          begin
            # Persist the exact command cgroup before a child can exist.
            # Recovery can then contain an orphan after an issuer crash.
            before_start&.call(cgroup.path)
            ready_reader, ready_writer = IO.pipe
            prepared_reader, prepared_writer = IO.pipe
            pid = fork do
              begin
                ready_writer.close
                prepared_reader.close
                cgroup.kill.close
                cgroup.events.close
                Process.setpgid(0, 0)
                @namespace_joiner.call(@namespace)
                @namespace.close
                # Never carry the issuer's supplementary groups, including
                # wheel/sudo or root, into the session command.
                Process.groups = []
                # A process moved to a systemd cgroup does not inherit that
                # unit's process credentials. Set this on the child itself.
                restrict_privilege_escalation!
                Process::GID.change_privilege(@account.gid)
                Process::UID.change_privilege(@account.uid)
                Dir.chdir(@cwd)
                cgroup.procs.sync = true
                raise ArgumentError, "session self-attachment failed" unless cgroup.procs.write("0\n") == 2
                cgroup.procs.close
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
          rescue Exception
            [ready_reader, ready_writer, prepared_reader, prepared_writer].compact.each { |io| io.close unless io.closed? }
            cgroup.close
            raise
          ensure
            cgroup.procs.close unless cgroup.procs.closed?
          end
          ready_reader.close
          prepared_writer.close
          handle = nil
          group_signal_supported = false
          begin
            handle = open_child_handle(pid)
            unless IO.select([prepared_reader], nil, nil, 10) && prepared_reader.read(1) == "1"
              raise ArgumentError, "session child could not drop privileges"
            end
            prepared_reader.close
            raise ArgumentError, "session attachment failed" unless @attach.verify_child!(pid) == true
            # Do not run a command unless cancellation can address the entire
            # process group through the pinned identity, without PID reuse.
            signal_child!(handle, 0, group: true)
            group_signal_supported = true
            ready_writer.write("1")
            ready_writer.close
            _, status = Process.wait2(pid)
            # A successful leader may have left detached descendants.
            # The command cgroup is separate from the session's main unit.
            contain!(cgroup)
            status.exitstatus || 128 + status.termsig.to_i
          rescue Exception # cancel through the pinned child identity
            ready_writer.close unless ready_writer.closed?
            prepared_reader.close unless prepared_reader.closed?
            begin
              signal_child!(handle, Signal.list.fetch("KILL"), group: group_signal_supported) if handle
            rescue StandardError
              # The command cgroup remains the containment backstop.
              nil
            end
            # Includes descendants that started a different process group.
            begin
              contain!(cgroup)
            rescue UncontainedSessionError
              # Do not block on a process whose death was not established;
              # reap it if it has already exited, otherwise wait on its
              # pinned identity in the background without polling.
              begin
                reap_later(handle) unless Process.waitpid(pid, Process::WNOHANG)
              rescue Errno::ECHILD
                nil
              end
              raise
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
            handle.close if handle && !handle.closed?
            cgroup.close
          end
        end

        private

        def contain!(cgroup)
          raise Error, "command cgroup did not confirm termination" unless cgroup.terminate! == true
        rescue StandardError => e
          raise UncontainedSessionError, "command cgroup could not be confirmed empty (#{e.class})"
        end

        def reap_later(handle)
          return unless handle && !handle.closed?
          held = handle.dup
          Thread.new do
            begin
              waitid = Fiddle::Function.new(Fiddle::Handle::DEFAULT["waitid"],
                [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
              info = Fiddle::Pointer.malloc(256, Fiddle::RUBY_FREE)
              loop do
                result = waitid.call(3, held.fileno, info, 4) # P_PIDFD, WEXITED
                break if result.zero? || Fiddle.last_error != Errno::EINTR::Errno
              end
            rescue Fiddle::DLError, IOError, SystemCallError
              nil
            ensure
              held.close unless held.closed?
            end
          end
        rescue ThreadError, SystemCallError, IOError
          held&.close unless held&.closed?
        end

        # Linux pidfds pin the child identity across exit and PID reuse. The
        # group flag requires Linux 6.9 or later; failure is a readiness error.
        def open_child_handle(pid)
          fn = Fiddle::Function.new(Fiddle::Handle::DEFAULT["pidfd_open"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_UINT], Fiddle::TYPE_INT)
          fd = fn.call(pid, 0)
          raise SystemCallError.new("pidfd_open", Fiddle.last_error) if fd.negative?
          IO.for_fd(fd, autoclose: true)
        rescue Fiddle::DLError
          raise ArgumentError, "session execution requires Linux pidfd support"
        end

        def signal_child!(handle, signal, group: false)
          fn = Fiddle::Function.new(Fiddle::Handle::DEFAULT["pidfd_send_signal"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_UINT], Fiddle::TYPE_INT)
          result = fn.call(handle.fileno, signal, 0, group ? 4 : 0) # PIDFD_SIGNAL_PROCESS_GROUP
          raise SystemCallError.new("pidfd_send_signal", Fiddle.last_error) if result.negative?
        rescue Fiddle::DLError
          raise ArgumentError, "session execution requires Linux pidfd signal support"
        end

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
