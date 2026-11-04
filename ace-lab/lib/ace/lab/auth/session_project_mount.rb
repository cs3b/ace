# frozen_string_literal: true

require_relative "session_namespace"
require_relative "session_launcher"

module Ace
  module Lab
    module Auth
      # Host-side preparation only. The entry barrier must remain closed until
      # private-state masking and the rest of session preparation also pass.
      class SessionProjectMount
        def initialize(platform: Ace::Runtime::Molecules::ProtectedLinux.new, runner: nil)
          @platform = platform
          @runner = runner || method(:run!)
        end

        def call(identity:, project:)
          raise Error, "project mount requires root" unless Process.euid.zero?
          unless identity.is_a?(SessionLauncher::Identity) && project.is_a?(String) &&
              project.match?(%r{\A/lab/[a-zA-Z0-9][a-zA-Z0-9_.-]*\z})
            raise Error, "invalid configured session project"
          end
          @platform.live!(identity.process)
          raise Error, "session has exited" if @platform.exited?(identity.pidfd)
          namespace = SessionNamespace.capture(identity.process.fetch("pid"))
          source = File.open(project, File::RDONLY | File::NOFOLLOW)
          role = SessionPeer::UNIT.match(identity.unit)&.captures&.first
          raise Error, "session role is unavailable" unless SessionUnit::ROLES.include?(role)
          private_tasks = File.join(project, ".ace-tasks", "_overseer")
          hide_private_tasks = %w[worker verifier integrator].include?(role)
          if hide_private_tasks
            [File.dirname(private_tasks), private_tasks].each do |path|
              entry = File.lstat(path)
              raise Error, "private task directory must be prepared before session start" unless entry.directory? && !entry.symlink?
            end
          end
          stat = source.stat
          unless stat.directory? && stat.uid.positive? && stat.gid.positive? && (stat.mode & 0o022).zero?
            raise Error, "project ownership is not suitable for session mapping"
          end
          wire = Ace::Runtime::Molecules::ProtectedSocket
          wire.root_path!(File.dirname(project), directory: true, owner: stat.uid)
          %w[/usr/bin/nsenter /bin/mount].each { |path| wire.root_path!(File.realpath(path)) }
          uid, gid = identity.process.values_at("uid", "gid")
          unless SessionPeer::DYNAMIC_UIDS.cover?(uid) && uid == gid
            raise Error, "session mapping identity is invalid"
          end
          @platform.live!(identity.process)
          @runner.call(["/usr/bin/nsenter", "--mount=/proc/self/fd/3", "--", "/bin/mount",
            "--bind", "-o", "X-mount.idmap=u:#{stat.uid}:#{uid}:1 g:#{stat.gid}:#{gid}:1",
            "/proc/self/fd/4", project], namespace: namespace, source: source)
          # ProtectSystem=strict makes the inherited project mount read-only.
          # Relax only this private bind mount after applying the identity map.
          @runner.call(["/usr/bin/nsenter", "--mount=/proc/self/fd/3", "--", "/bin/mount",
            "-o", "remount,bind,rw", "--", project], namespace: namespace, source: source)
          if hide_private_tasks
            @runner.call(["/usr/bin/nsenter", "--mount=/proc/self/fd/3", "--", "/bin/mount",
              "-t", "tmpfs", "-o", "ro,nosuid,nodev,noexec,mode=000,size=4k", "none", private_tasks],
              namespace: namespace, source: source)
          end
          @platform.live!(identity.process)
          unless SessionNamespace.matches?(namespace, identity.process.fetch("pid"))
            raise Error, "session namespace changed during project preparation"
          end
          true
        ensure
          namespace&.close
          source&.close
        end

        private

        def run!(argv, namespace:, source:)
          pid = Process.spawn({"PATH" => "/usr/bin:/bin", "LANG" => "C"}, *argv,
            3 => namespace, 4 => source, in: File::NULL, out: File::NULL, err: File::NULL,
            unsetenv_others: true, close_others: true)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
          loop do
            result = Process.waitpid2(pid, Process::WNOHANG)
            if result
              pid = nil
              raise Error, "session project mount failed" unless result.last.success?
              return true
            end
            raise Error, "session project mount deadline expired" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            sleep 0.01
          end
        ensure
          if pid
            begin
              Process.kill("KILL", pid)
            rescue Errno::ESRCH
              nil
            end
            Process.waitpid(pid)
          end
        end
      end
    end
  end
end
