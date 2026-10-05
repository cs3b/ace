# frozen_string_literal: true

require "digest"
require_relative "cgroup_observation"
require_relative "../errors"
require_relative "protected_socket"

module Ace
  module Runtime
    module Molecules
      # Content evidence only. Retains every artifact and ancestor descriptor for
      # one bounded verification, then rechecks their identities before closing.
      class ProtectedArtifactSet
        LIMIT = 1_048_576
        TOTAL_LIMIT = 16 * LIMIT
        COUNT_LIMIT = 256

        class Protection
          # These local Linux filesystems enforce POSIX mode/ACL mask semantics.
          # Other models (including remote/FUSE filesystems) are not presumed safe.
          FILESYSTEMS = %w[ext2 ext3 ext4 xfs btrfs tmpfs].freeze

          def initialize(mounts: CgroupObservation::KernelFiles.new)
            @mounts = mounts
          end

          def root_path!(path)
            ProtectedSocket.root_path!(path)
          end

          def verify!(path, handle, directory:)
            stat = handle.stat
            unless trusted_owner?(stat) && (stat.mode & 0o022).zero? &&
                (directory ? stat.directory? : stat.file?)
              raise RuntimeUnavailableError, "network artifact ownership, mode or kind is unsafe"
            end
            unless FILESYSTEMS.include?(@mounts.mount_identity(handle).fetch("filesystem_type"))
              raise RuntimeUnavailableError, "network artifact filesystem protection is unsupported"
            end
            # On these filesystems group bits are the access ACL mask: with no
            # group/other write, no named non-root user/group can write either.
            # Default ACLs grant no access to the existing descriptor. Every
            # referenced file and ancestor is checked, including inherited mode.
          end

          private

          def trusted_owner?(stat) = stat.uid.zero?
        end

        def initialize(protection: Protection.new)
          @protection = protection
        end

        def with
          @handles, @references, @contents, @total = {}, {}, {}, 0
          yield self
        ensure
          @handles&.each_value { |entry| entry.fetch(:handle).close }
          @handles = @references = @contents = nil
        end

        def read!(reference)
          path = reference.fetch("path")
          previous = @references[path]
          if previous
            raise RuntimeUnavailableError, "network artifact references conflict" unless previous == reference
            return @contents.fetch(path)
          end
          raise RuntimeUnavailableError, "network artifact graph is oversized" if @references.size >= COUNT_LIMIT
          size = reference.fetch("bytes")
          unless size.is_a?(Integer) && size.between?(1, LIMIT) && @total + size <= TOTAL_LIMIT
            raise RuntimeUnavailableError, "network artifact bytes exceed bounds"
          end
          @protection.root_path!(path)
          ancestors(path).reverse_each { |ancestor| pin!(ancestor, directory: true) }
          handle = pin!(path, directory: false)
          unless handle.stat.size == size
            raise RuntimeUnavailableError, "network artifact declared length differs"
          end
          bytes = handle.read(size + 1)
          unless bytes.is_a?(String) && bytes.bytesize == size &&
              Digest::SHA256.hexdigest(bytes) == reference.fetch("sha256")
            raise RuntimeUnavailableError, "network artifact content differs"
          end
          @references[path] = reference.dup.freeze
          @contents[path] = bytes.freeze
          @total += size
          bytes
        end

        def verify_unchanged!
          @handles.each do |path, entry|
            handle = entry.fetch(:handle)
            unless snapshot(handle.stat) == entry.fetch(:snapshot) &&
                snapshot(File.lstat(path)) == entry.fetch(:snapshot)
              raise RuntimeUnavailableError, "network artifact changed during verification"
            end
            @protection.verify!(path, handle, directory: entry.fetch(:directory))
          end
          true
        end

        private

        def ancestors(path)
          result = []
          current = File.dirname(path)
          loop do
            result << current
            break if current == "/"
            current = File.dirname(current)
          end
          result
        end

        def pin!(path, directory:)
          return @handles.fetch(path).fetch(:handle) if @handles.key?(path)
          stat = File.lstat(path)
          unless !stat.symlink? && (directory ? stat.directory? : stat.file?)
            raise RuntimeUnavailableError, "network artifact kind or link is unsafe"
          end
          # NONBLOCK also prevents blocking if a hostile special file replaces a
          # regular file between lstat and open; descriptor type is checked below.
          handle = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
          begin
            handle.close_on_exec = true
            @protection.verify!(path, handle, directory: directory)
            unless snapshot(stat) == snapshot(handle.stat) && snapshot(File.lstat(path)) == snapshot(handle.stat)
              raise RuntimeUnavailableError, "network artifact changed while opening"
            end
            @handles[path] = {handle: handle, directory: directory, snapshot: snapshot(handle.stat)}
            handle
          rescue Exception
            handle.close
            raise
          end
        end

        def snapshot(stat)
          [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode, stat.size, stat.mtime, stat.ctime]
        end
      end
    end
  end
end
