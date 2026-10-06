# frozen_string_literal: true

require "fiddle"
require "rbconfig"
require_relative "linux_mount_info"
require_relative "../errors"

module Ace
  module Runtime
    module Molecules
      # Observes declared reachable objects in a pinned server root. This does
      # not enter or modify a namespace and carries no admission authority.
      class ServerResourceObservation
        class Files
          OPENAT2 = 437
          RESOLVE = 0x10 | 0x04 # IN_ROOT | NO_SYMLINKS; bind mounts are allowed.

          def supported!
            unless RUBY_PLATFORM.include?("linux") && %w[x86_64 aarch64 arm64].include?(RbConfig::CONFIG.fetch("host_cpu"))
              raise RuntimeUnavailableError, "contained server-root observation is unsupported"
            end
          end

          def namespace(pid)
            File.open("/proc/#{pid}/ns/mnt", File::RDONLY) { |file| identity(file.stat) }
          end

          def observe(pid, entries)
            supported!
            root = File.open("/proc/#{pid}/root", File::RDONLY)
            namespace = File.open("/proc/#{pid}/ns/mnt", File::RDONLY)
            root_identity, namespace_identity = identity(root.stat), identity(namespace.stat)
            table = LinuxMountInfo.new(File.read("/proc/#{pid}/mountinfo", LinuxMountInfo::LIMIT + 1))
            topology = []
            result = entries.map do |entry|
              handle = open_inside(root, entry.fetch("view_path"))
              begin
                stat = handle.stat
                raise RuntimeUnavailableError, "declared server resource is not a directory" unless stat.directory?
                rows = File.read("/proc/self/fdinfo/#{handle.fileno}", 16_385).lines.filter_map do |line|
                  /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1)
                end
                raise RuntimeUnavailableError, "server resource mount is ambiguous" unless rows.size == 1
                mount = table.by_id(Integer(rows.first, 10))
                topology << entry.slice("host_path", "view_path").merge(mount.slice("mountpoint", "root", "major_minor", "options"))
                entry.slice("host_path", "view_path").merge("device" => stat.dev, "inode" => stat.ino,
                  "uid" => stat.uid, "gid" => stat.gid, "filesystem_type" => mount.fetch("filesystem_type"),
                  "mount_id" => mount.fetch("mount_id"))
              ensure
                handle.close
              end
            end
            unless namespace_identity == self.namespace(pid) && root_identity == identity(File.stat("/proc/#{pid}/root"))
              raise RuntimeUnavailableError, "server root or namespace changed during observation"
            end
            {"mount_namespace_identity" => namespace_identity, "resource_identities" => result, "resource_topology" => topology}
          ensure
            root&.close
            namespace&.close
          end

          private

          def identity(stat) = {"device" => stat.dev, "inode" => stat.ino}

          def open_inside(root, path)
            unless path.is_a?(String) && path.bytesize.between?(1, 4096) && path.start_with?("/") &&
                !path.include?("\0") && File.expand_path(path) == path
              raise RuntimeUnavailableError, "server resource path differs"
            end
            syscall = Fiddle::Function.new(Fiddle::Handle::DEFAULT["syscall"],
              [Fiddle::TYPE_LONG, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
              Fiddle::TYPE_LONG)
            how = [File::RDONLY | File::NONBLOCK | File::NOFOLLOW, 0, RESOLVE].pack("Q<Q<Q<")
            descriptor = syscall.call(OPENAT2, root.fileno, path + "\0", how, how.bytesize)
            raise RuntimeUnavailableError, "contained server resource cannot be opened" if descriptor.negative?
            IO.for_fd(descriptor, autoclose: true)
          end
        end

        def initialize(kernel:, files: Files.new)
          @kernel, @files = kernel, files
        end

        def observe!(server:, entries:)
          @kernel.live!(server)
          before = @kernel.capture(server.fetch("pid"))
          unless @kernel.same?(before, server)
            raise RuntimeUnavailableError, "server incarnation differs"
          end
          result = @files.observe(server.fetch("pid"), entries)
          @kernel.live!(server)
          unless @kernel.same?(@kernel.capture(server.fetch("pid")), before)
            raise RuntimeUnavailableError, "server credentials changed during resource observation"
          end
          result
        end
      end
    end
  end
end
