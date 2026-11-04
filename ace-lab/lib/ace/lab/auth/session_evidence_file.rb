# frozen_string_literal: true
require "socket"
require "fcntl"
require "fiddle"
require_relative "session_peer"
require_relative "session_privileges"

module Ace
  module Lab
    module Auth
      # A fixed, non-executing reader. No root pathname open and no session
      # contents leave this boundary: the owner evaluator receives a read FD.
      class SessionEvidenceFile
        LIMIT = 64 * 1024 * 1024

        def initialize(privileged: -> { Process.euid.zero? }, drop: nil, parent_guard: nil)
          @privileged = privileged
          @drop = drop || lambda { |uid, gid|
            Process.groups = []
            SessionPrivileges.restrict!
            Process::GID.change_privilege(gid)
            Process::UID.change_privilege(uid)
          }
          @parent_guard = parent_guard || method(:guard_parent!)
        end

        def open(path, identity:)
          raise Error, "session evidence reader requires root" unless @privileged.call
          unless identity.is_a?(SessionPeer::Identity) && path.is_a?(String) && path.bytesize <= 4096
            raise Error, "authenticated evidence identity required"
          end
          root = File.join(identity.runtime_dir, "pi", "sessions")
          unless path.start_with?(root + "/") && File.expand_path(path) == path &&
              !path.match?(/[[:cntrl:]]/) && path.end_with?(".jsonl")
            raise Error, "session evidence path is outside private sessions"
          end
          parent, child = UNIXSocket.pair
          issuer_pid = Process.pid
          pid = fork do
            stage = "parent"
            begin
              parent.close
              @parent_guard.call(issuer_pid)
              stage = "descriptors"
              close_unrelated_descriptors(child.fileno)
              ENV.clear
              stage = "credentials"
              @drop.call(identity.uid, identity.gid)
              # Linux clears PDEATHSIG on effective UID/GID changes.
              @parent_guard.call(issuer_pid)
              stage = "open"
              file = anchored_open(identity.runtime_dir, path.delete_prefix(identity.runtime_dir + "/"))
              stage = "validate"
              validate_file!(file, identity.uid)
              stage = "transfer"
              child.send_io(file)
              file.close
              exit! 0
            rescue Exception
              child.write("failed:#{stage}") rescue nil
              exit! 1
            end
          end
          child.close
          raise Error, "session evidence reader timed out" unless IO.select([parent], nil, nil, 5)
          packet = parent.recvmsg_nonblock(64, 0, 4096, scm_rights: true, exception: false)
          raise Error, "session evidence descriptor is unavailable" if packet == :wait_readable
          bytes, _, flags, *controls = packet
          descriptors = controls.flat_map { |control| control.cmsg_is?(Socket::SOL_SOCKET, Socket::SCM_RIGHTS) ? control.unix_rights.to_a : [] }
          unless bytes.is_a?(String) && bytes.bytesize == 1 && (flags & Socket::MSG_CTRUNC).zero? && controls.size == 1 && descriptors.size == 1
            raise Error, "invalid session evidence descriptor#{bytes.to_s.match?(/\Afailed:(parent|descriptors|credentials|open|validate|transfer)\z/) ? " (#{bytes})" : ""}"
          end
          file = descriptors.fetch(0)
          file.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          validate_file!(file, identity.uid)
          unless (file.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE) == File::RDONLY
            raise Error, "session evidence descriptor is writable"
          end
          descriptors = []
          file
        rescue SystemCallError, IOError, ArgumentError
          raise Error, "session evidence file is unavailable"
        ensure
          descriptors&.each { |descriptor| descriptor.close unless descriptor.closed? }
          [parent, child].compact.each { |socket| socket.close unless socket.closed? }
          if pid
            # This method exclusively owns the unreaped child, so PID reuse
            # cannot race cancellation. No detached reaper is involved.
            unless Process.waitpid(pid, Process::WNOHANG)
              Process.kill("KILL", pid)
              Process.waitpid(pid)
            end
          end
        end

        private

        def validate_file!(file, uid)
          stat = file.stat
          unless stat.file? && stat.uid == uid && stat.size.between?(1, LIMIT)
            raise Error, "session evidence file has unsuitable type, owner or size"
          end
        end

        def anchored_open(root, relative)
          directory = File.open(root, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
          raise Error, "session runtime is not a directory" unless directory.stat.directory?
          components = relative.split("/")
          components[0...-1].each do |name|
            next_directory = File.open("/proc/self/fd/#{directory.fileno}/#{name}", File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            directory.close
            directory = next_directory
            raise Error, "session evidence ancestor is not a directory" unless directory.stat.directory?
          end
          File.open("/proc/self/fd/#{directory.fileno}/#{components.last}", File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
        ensure
          directory&.close
        end

        def close_unrelated_descriptors(keep)
          close_fd = Fiddle::Function.new(Fiddle::Handle::DEFAULT["close"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          dup2 = Fiddle::Function.new(Fiddle::Handle::DEFAULT["dup2"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          # Ruby IO#close/reopen can flush a buffer copied from the issuer.
          # Discard inherited application descriptors at the OS boundary and
          # prevent their Ruby wrappers from later closing a reused number.
          ObjectSpace.each_object(IO) do |io|
            next if io.closed? || io.fileno == keep || io.fileno <= 2
            fd = io.fileno
            io.autoclose = false
            close_fd.call(fd)
          rescue IOError
            # Allocated but uninitialized Ruby IO has no descriptor.
          end
          Dir.children("/proc/self/fd").each do |value|
            fd = Integer(value, 10)
            next if fd == keep || fd <= 2
            begin
              IO.for_fd(fd, autoclose: false)
              close_fd.call(fd)
            rescue Errno::EBADF, ArgumentError
              # RubyVM's internal event descriptors are not application IO.
            end
          end
          File.open(File::NULL, File::RDWR) do |null|
            (0..2).each { |fd| raise Error, "reader stdio isolation failed" if dup2.call(null.fileno, fd).negative? }
          end
        end

        def guard_parent!(expected)
          prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
          raise Error, "reader parent binding failed" unless prctl.call(1, 9, 0, 0, 0).zero? && Process.ppid == expected
        end
      end
    end
  end
end
