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
        VIEW_PATHS = %w[/proc /proc/sys /sys /sys/fs/cgroup /dev /dev/pts /dev/mqueue /dev/shm /tmp /var/tmp].freeze
        MOUNT_FIELDS = %w[mount_id parent_id major_minor root mountpoint options filesystem_type].freeze
        class Files
          OPENAT2 = 437
          RESOLVE = 0x10 | 0x04 # IN_ROOT | NO_SYMLINKS; bind mounts are allowed.

          def supported!
            unless RUBY_PLATFORM.include?("linux") && %w[x86_64 aarch64 arm64].include?(RbConfig::CONFIG.fetch("host_cpu"))
              raise RuntimeUnavailableError, "contained server-root observation is unsupported"
            end
          end

          def namespace(pid, kind = "mnt")
            File.open("/proc/#{pid}/ns/#{kind}", File::RDONLY) { |file| identity(file.stat) }
          end

          def observe(pid, entries, authority_socket:)
            supported!
            root = File.open("/proc/#{pid}/root", File::RDONLY)
            namespace = File.open("/proc/#{pid}/ns/mnt", File::RDONLY)
            network = File.open("/proc/#{pid}/ns/net", File::RDONLY)
            network_identity = network_identity!(network)
            ipc = File.open("/proc/#{pid}/ns/ipc", File::RDONLY)
            hook_ipc = File.open("/proc/self/ns/ipc", File::RDONLY)
            root_identity, namespace_identity = identity(root.stat), identity(namespace.stat)
            ipc_identity, hook_ipc_identity = identity(ipc.stat), identity(hook_ipc.stat)
            table = LinuxMountInfo.new(File.read("/proc/#{pid}/mountinfo", LinuxMountInfo::LIMIT + 1))
            raise RuntimeUnavailableError, "server mount inventory exceeds bound" if table.records.size > 256
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
            views = VIEW_PATHS.map { |path| pinned_view(root, path, table: table) }
            socket_identity = pinned_socket(root, authority_socket)
            ptmx_identity, ptmx_link = pinned_ptmx(root, table: table)
            repeated = LinuxMountInfo.new(File.read("/proc/#{pid}/mountinfo", LinuxMountInfo::LIMIT + 1))
            unless namespace_identity == self.namespace(pid) && root_identity == identity(File.stat("/proc/#{pid}/root")) &&
                network_identity == self.namespace(pid, "net") &&
                ipc_identity == self.namespace(pid, "ipc") && hook_ipc_identity == self.namespace("self", "ipc") &&
                table.records == repeated.records &&
                views == VIEW_PATHS.map { |path| pinned_view(root, path, table: repeated) } &&
                socket_identity == pinned_socket(root, authority_socket) &&
                [ptmx_identity, ptmx_link] == pinned_ptmx(root, table: repeated)
              raise RuntimeUnavailableError, "server root or namespace changed during observation"
            end
            {"mount_namespace_identity" => namespace_identity, "network_namespace_identity" => network_identity, "resource_identities" => result, "resource_topology" => topology,
              "kernel_view_topology" => {"ipc_namespace_identity" => ipc_identity, "hook_ipc_namespace_identity" => hook_ipc_identity,
                "mounts" => table.records.map { |row| row.slice(*MOUNT_FIELDS) }, "views" => views, "authority_socket_identity" => socket_identity,
                "ptmx_identity" => ptmx_identity, "ptmx_link" => ptmx_link}}
          ensure
            root&.close
            namespace&.close
            network&.close
            ipc&.close
            hook_ipc&.close
          end

          private

          # NS_GET_NSTYPE is an nsfs ioctl. Pin the original server's object,
          # require CLONE_NEWNET, and retain it across the repeated path read.
          def network_identity!(handle)
            unless handle.ioctl(0xb703) == 0x40000000
              raise RuntimeUnavailableError, "server object is not a network namespace"
            end
            identity(handle.stat)
          rescue SystemCallError, IOError
            raise RuntimeUnavailableError, "server network namespace type is unavailable"
          end

          def identity(stat) = {"device" => stat.dev, "inode" => stat.ino}

          def pinned_view(root, path, table:)
            handle = open_inside(root, path, flags: 0x200000 | File::NOFOLLOW) # O_PATH, no data access.
            stat = handle.stat
            raise RuntimeUnavailableError, "fixed server view is not a directory" unless stat.directory?
            rows = File.read("/proc/self/fdinfo/#{handle.fileno}", 16_385).lines.filter_map { |line| /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1) }
            raise RuntimeUnavailableError, "fixed view mount is ambiguous" unless rows.size == 1
            mount = table.by_id(Integer(rows.first, 10))
            {"path" => path, "mount_id" => mount.fetch("mount_id"), "device" => stat.dev, "inode" => stat.ino, "type" => "directory"}
          ensure
            handle&.close
          end

          def pinned_socket(root, path)
            handle = open_inside(root, path, flags: 0x200000 | File::NOFOLLOW)
            stat = handle.stat
            raise RuntimeUnavailableError, "authority projection is not a socket" unless stat.socket?
            [stat.dev, stat.ino, stat.uid]
          ensure
            handle&.close
          end

          def pinned_ptmx(root, table:)
            dev = open_inside(root, "/dev", flags: 0x200000 | File::NOFOLLOW)
            link = read_ptmx_link(dev)
            raise RuntimeUnavailableError, "selected ptmx link differs" unless link == "pts/ptmx"
            node = open_inside(root, "/dev/pts/ptmx", flags: 0x200000 | File::NOFOLLOW)
            stat = node.stat
            raise RuntimeUnavailableError, "selected ptmx is not a character device" unless stat.chardev? && stat.rdev_major == 5 && stat.rdev_minor == 2
            rows = File.read("/proc/self/fdinfo/#{node.fileno}", 16_385).lines.filter_map { |line| /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1) }
            raise RuntimeUnavailableError, "selected ptmx mount is ambiguous" unless rows.size == 1
            mount = table.by_id(Integer(rows.first, 10))
            [{"device" => stat.dev, "inode" => stat.ino, "mount_id" => mount.fetch("mount_id"), "type" => "character",
              "rdev_major" => stat.rdev_major, "rdev_minor" => stat.rdev_minor}, link]
          ensure
            dev&.close
            node&.close
          end

          def read_ptmx_link(dev)
            call = Fiddle::Function.new(Fiddle::Handle::DEFAULT["readlinkat"],
              [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SSIZE_T)
            buffer = Fiddle::Pointer.malloc(64)
            count = call.call(dev.fileno, "ptmx\0", buffer, 64)
            raise RuntimeUnavailableError, "selected ptmx link cannot be observed" unless count.between?(1, 63)
            buffer.to_s(count)
          end

          def open_inside(root, path, flags: File::RDONLY | File::NONBLOCK | File::NOFOLLOW)
            unless path.is_a?(String) && path.bytesize.between?(1, 4096) && path.start_with?("/") &&
                !path.include?("\0") && File.expand_path(path) == path
              raise RuntimeUnavailableError, "server resource path differs"
            end
            syscall = Fiddle::Function.new(Fiddle::Handle::DEFAULT["syscall"],
              [Fiddle::TYPE_LONG, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T],
              Fiddle::TYPE_LONG)
            how = [flags, 0, RESOLVE].pack("Q<Q<Q<")
            descriptor = syscall.call(OPENAT2, root.fileno, path + "\0", how, how.bytesize)
            raise RuntimeUnavailableError, "contained server resource cannot be opened" if descriptor.negative?
            IO.for_fd(descriptor, autoclose: true)
          end
        end

        def initialize(kernel:, files: Files.new)
          @kernel, @files = kernel, files
        end

        def observe!(server:, entries:, authority_socket:)
          @kernel.live!(server)
          before = @kernel.capture(server.fetch("pid"))
          unless @kernel.same?(before, server)
            raise RuntimeUnavailableError, "server incarnation differs"
          end
          result = @files.observe(server.fetch("pid"), entries, authority_socket: authority_socket)
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
