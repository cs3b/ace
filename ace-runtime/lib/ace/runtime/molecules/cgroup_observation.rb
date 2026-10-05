# frozen_string_literal: true

require_relative "../errors"

module Ace
  module Runtime
    module Molecules
      # A live descriptor pins the parent object, never the reusable pathname.
      # Population is an observation only: canonical admission seal and verified
      # resource boundaries remain the authority owner's responsibility.
      class CgroupObservation
        ROOT = "/sys/fs/cgroup"
        IDENTITY_FIELDS = %w[path mount_id filesystem_type device inode].freeze

        class KernelFiles
          def open_directory(path)
            File.open(path, File::RDONLY | File::NOFOLLOW)
          end

          def read(path, limit:)
            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              bytes = file.read(limit + 1)
              raise RuntimeUnavailableError, "kernel scope observation is oversized" if bytes.bytesize > limit
              bytes
            end
          end

          def mount_identity(handle)
            info = read("/proc/self/fdinfo/#{handle.fileno}", limit: 4096)
            matches = info.lines.filter_map { |line| /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1) }
            raise RuntimeUnavailableError, "scope mount identity is unavailable" unless matches.size == 1
            mount_id = Integer(matches.first, 10)
            mounts = read("/proc/self/mountinfo", limit: 1_048_576).lines.filter_map do |line|
              fields = line.split
              next unless fields.first == mount_id.to_s
              separator = fields.index("-")
              next unless separator && fields.size >= separator + 4
              {"mount_id" => mount_id, "filesystem_type" => fields[separator + 1],
               "root" => fields[3], "mountpoint" => fields[4]}
            end
            raise RuntimeUnavailableError, "scope mount is ambiguous" unless mounts.size == 1
            mounts.first
          end
        end

        def initialize(files: KernelFiles.new)
          @files = files
        end

        def pin(path, expected: nil)
          validate_path!(path)
          handle = @files.open_directory(path)
          identity = identity_for(handle, path)
          unless expected.nil? || valid_identity?(expected) && identity == expected
            raise RuntimeUnavailableError, "retained scope object was replaced"
          end
          verify_path!(handle, identity)
          {handle: handle, identity: identity.freeze}
        rescue SystemCallError, IOError
          handle&.close
          raise RuntimeUnavailableError, "exact scope object cannot be pinned"
        rescue Exception
          handle&.close
          raise
        end

        def observe(pinned)
          handle, identity = pinned.values_at(:handle, :identity)
          unless handle && !handle.closed? && valid_identity?(identity) && identity_for(handle, identity.fetch("path")) == identity
            raise RuntimeUnavailableError, "pinned scope identity changed"
          end
          verify_path!(handle, identity)
          bytes = @files.read("/proc/self/fd/#{handle.fileno}/cgroup.events", limit: 4096)
          fields = parse_events(bytes)
          verify_path!(handle, identity)
          {"cgroup_identity" => identity.dup, "populated" => fields.fetch("populated")}
        rescue SystemCallError, IOError, KeyError
          raise RuntimeUnavailableError, "retained scope cannot be observed"
        end

        # Membership checks use the caller's independently pinned birth policy.
        # A namespace-relative cgroup value must agree with the host parent;
        # unresolved membership refuses rather than following another mount.
        def member!(identity, pinned:, kernel:)
          kernel.live!(identity)
          observe(pinned)
          bytes = @files.read("/proc/#{identity.fetch('pid')}/cgroup", limit: 4096)
          paths = bytes.lines.filter_map { |line| /\A0::(\/[^\n]*)\n?\z/.match(line)&.[](1) }
          parent = pinned.fetch(:identity).fetch("path").delete_prefix(ROOT)
          unless paths.size == 1 && (paths.first == parent || paths.first.start_with?(parent + "/"))
            raise RuntimeUnavailableError, "process is outside the exact execution scope"
          end
          kernel.live!(identity)
          observe(pinned)
          true
        end

        def parse_events(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 4096)
            raise RuntimeUnavailableError, "cgroup population is unavailable"
          end
          fields = {}
          bytes.each_line do |line|
            match = /\A([a-z_]+) ([0-9]+)\n?\z/.match(line)
            unless match && !fields.key?(match[1])
              raise RuntimeUnavailableError, "cgroup events are malformed"
            end
            fields[match[1]] = Integer(match[2], 10)
          end
          unless [0, 1].include?(fields["populated"])
            raise RuntimeUnavailableError, "cgroup population is not a positive kernel observation"
          end
          fields
        end

        private

        def valid_identity?(value)
          value.is_a?(Hash) && value.keys.sort == IDENTITY_FIELDS.sort &&
            value["path"].is_a?(String) && value["filesystem_type"] == "cgroup2" && %w[mount_id device inode].all? do |key|
              value[key].is_a?(Integer) && value[key] >= 0
            end
        end

        def validate_path!(path)
          unless path.is_a?(String) && path.bytesize <= 4096 && !path.include?("\0") &&
              path.start_with?(ROOT + "/") && File.expand_path(path) == path && path != ROOT
            raise RuntimeUnavailableError, "scope must be an exact parent below the unified cgroup root"
          end
        end

        def identity_for(handle, path)
          stat = handle.stat
          mount = @files.mount_identity(handle)
          unless stat.directory? && mount["filesystem_type"] == "cgroup2" &&
              mount["mountpoint"] == ROOT && mount["root"] == "/"
            raise RuntimeUnavailableError, "scope requires the host unified cgroup-v2 mount"
          end
          {"path" => path, "mount_id" => mount.fetch("mount_id"), "filesystem_type" => "cgroup2",
           "device" => stat.dev, "inode" => stat.ino}
        end

        def verify_path!(handle, identity)
          current = @files.open_directory(identity.fetch("path"))
          unless identity_for(current, identity.fetch("path")) == identity && handle.stat.ino == current.stat.ino
            raise RuntimeUnavailableError, "scope pathname no longer names its pinned object"
          end
          true
        ensure
          current&.close
        end
      end
    end
  end
end
