# frozen_string_literal: true

require_relative "lifecycle_exclusion"
require_relative "../authority/posix_acl"
require "ace/runtime/molecules/protected_artifact_set"

module Ace
  module Assign
    module Molecules
      class LifecycleExclusion
        # A retained reader lease only. It cannot provision, reset or publish.
        # Source-owned original PreparedInput selects its closed projection.
        class WorkspaceReader
          class Protection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
            def initialize(projection:, acl: Authority::PosixAcl.new, **options)
              super(**options)
              @projection, @acl = projection, acl
            end

            def verify!(path, handle, directory:)
              super
              unless (handle.stat.mode & 0o7000).zero? && @acl.entries(path).nil? &&
                  (!directory || @acl.entries(path, attribute: "system.posix_acl_default").nil?)
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader protection differs"
              end
              root = @projection.fetch("root_resource")
              if path == root_path(root)
                actual = handle.stat
                unless directory && [actual.dev, actual.ino, actual.uid, actual.gid, actual.mode & 0o7777] ==
                    root.values_at("device", "inode", "uid", "gid") + [0o755]
                  raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader root identity differs"
                end
                verify_root_mount!(path, handle, root)
              elsif !directory
                unless handle.stat.nlink == 1 && (handle.stat.mode & 0o7777) == 0o644
                  raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader file protection differs"
                end
              end
            end

            private

            def root_path(root) = root.fetch("view_path")

            def verify_root_mount!(path, handle, root)
                mount = @mounts.mount_identity(handle)
                table = Ace::Runtime::Molecules::LinuxMountInfo.new(
                  @mounts.read("/proc/self/mountinfo", limit: Ace::Runtime::Molecules::LinuxMountInfo::LIMIT))
                selected = table.by_id(mount.fetch("mount_id"))
                unless mount == selected.slice(*mount.keys) && selected.fetch("mountpoint") == path &&
                    selected.fetch("filesystem_type") == root.fetch("filesystem_type") &&
                    selected.fetch("options").include?("ro") && !selected.fetch("options").include?("rw")
                  raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader view is not the selected readonly mount"
                end
            end

            def trusted_owner?(stat)
              [0, @projection.fetch("authority_uid")].include?(stat.uid)
            end
          end

          def initialize(projection:, protection: nil, files: File)
            @projection = JSON.parse(JSON.generate(projection))
            validate_projection!
            pending = [@projection]
            until pending.empty?
              value = pending.pop
              pending.concat(value.values) if value.is_a?(Hash)
              pending.concat(value) if value.is_a?(Array)
              value.freeze
            end
            @root = @projection.fetch("root_resource").fetch("view_path")
            @protection = protection || Protection.new(projection: @projection)
            @files = files
            @handles, @lock, @active = {}, nil, false
          end

          def acquire!
            raise AttemptErrors::Conflict, "Lifecycle reader already acquired" if @active || !@handles.empty?
            parts = @root.split("/").reject(&:empty?)
            (["/"] + parts.each_index.map { |index| "/" + parts.take(index + 1).join("/") }).each do |path|
              pin!(path, directory: true)
            end
            @lock = pin!(path_for("lock"), directory: false)
            stat = @lock.stat
            unless stat.size.zero? && [stat.uid, stat.gid] == @projection.values_at("authority_uid", "authority_gid")
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader immutable lock differs"
            end
            unless @lock.flock(lock_mode | File::LOCK_NB)
              raise AttemptErrors::MaintenanceBusy, "Lifecycle workspace is under maintenance"
            end
            @active = true
            marker = pin!(path_for("state.json"), directory: false)
            state = read_marker!(marker)
            owner = [marker.stat.uid, marker.stat.gid]
            unless owner == @projection.values_at("authority_uid", "authority_gid") || state.fetch("removed") && owner == [0, 0]
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker selected owner differs"
            end
            require_live_marker!(state)
            verify_unchanged!
            self
          rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError, JSON::ParserError, KeyError, TypeError, ArgumentError
            close!
            raise AttemptErrors::EvidenceUnavailable, "Original lifecycle reader admission is unavailable"
          rescue Exception
            close!
            raise
          end

          def verify_unchanged!
            raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader is not held" unless @active
            @handles.each do |path, entry|
              unless identity(entry.fetch(:handle).stat) == entry.fetch(:identity) &&
                  identity(@files.lstat(path)) == entry.fetch(:identity)
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader retained object changed"
              end
              @protection.verify!(path, entry.fetch(:handle), directory: entry.fetch(:directory))
            end
            true
          end

          # The maintained creator calls this only after confirmed completion.
          # Unknown child ownership retains the lease until its owner exits.
          def close!
            begin
              @lock.flock(File::LOCK_UN) if @active && @lock && !@lock.closed?
            ensure
              close_error = nil
              @handles.values.reverse_each do |entry|
                begin
                  entry.fetch(:handle).close unless entry.fetch(:handle).closed?
                rescue IOError, SystemCallError => error
                  close_error ||= error
                end
              end
              @handles.clear
              @active = false
              raise close_error if close_error
            end
          end

          private

          def require_live_marker!(state)
            raise AttemptErrors::Conflict, "Original lifecycle workspace was fenced for removal" if state.fetch("removed")
          end

          def lock_mode = File::LOCK_SH

          def validate_projection!
            fields = %w[authority_gid authority_uid key root_resource worker_cwd_resource]
            resource_fields = %w[device filesystem_type gid host_path inode mount_id uid view_path]
            unless @projection.is_a?(Hash)
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle original reader projection differs"
            end
            root, cwd = @projection.values_at("root_resource", "worker_cwd_resource")
            unless @projection.keys.sort == fields && [root, cwd].all? { |value| value.is_a?(Hash) && value.keys.sort == resource_fields } &&
                %w[authority_uid authority_gid].all? { |key| @projection[key].is_a?(Integer) && @projection[key].positive? }
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle original reader projection differs"
            end
            unless [root, cwd].all? { |value|
                %w[host_path view_path].all? { |key| value[key].is_a?(String) && value[key].valid_encoding? &&
                  value[key].bytesize.between?(1, 4096) && !value[key].include?("\0") && value[key].start_with?("/") &&
                  File.expand_path(value[key]) == value[key] } &&
                %w[device inode uid gid].all? { |key| value[key].is_a?(Integer) && value[key] >= 0 } &&
                value["mount_id"].is_a?(Integer) && value["mount_id"].positive? &&
                %w[ext4 xfs btrfs tmpfs].include?(value["filesystem_type"]) }
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle original reader resource differs"
            end
            mapping = root.fetch("view_path").delete_prefix("/run/ace/lifecycle-exclusion/")
            digest = Atoms::EvidenceDigest.digest(cwd)
            unless mapping.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/) &&
                @projection.fetch("key") == "workspace:#{mapping}:#{digest}" &&
                root.fetch("host_path").end_with?("/workspaces/#{mapping}/#{digest}") &&
                root.values_at("uid", "gid") == @projection.values_at("authority_uid", "authority_gid")
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle original reader association differs"
            end
          end

          def pin!(path, directory:)
            file = @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            @protection.verify!(path, file, directory: directory)
            stat = file.stat
            unless (directory ? stat.directory? : stat.file?) && identity(stat) == identity(@files.lstat(path))
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle reader object is substituted"
            end
            @handles[path] = {handle: file, identity: identity(stat), directory: directory}
            file
          ensure
            file&.close unless @handles.key?(path)
          end

          def identity(stat)
            core = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode]
            stat.directory? ? core : core + [stat.nlink, stat.size, stat.mtime, stat.ctime]
          end

          def path_for(suffix)
            File.join(@root, "#{Digest::SHA256.hexdigest(@projection.fetch('key'))}.#{suffix}")
          end

          def read_marker!(file)
            size = file.stat.size
            unless size.between?(1, 8192)
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker bytes differ"
            end
            bytes = file.read(8193).force_encoding(Encoding::UTF_8)
            unless bytes.valid_encoding? && bytes.bytesize == size
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker is not bounded UTF8"
            end
            state = LifecycleExclusion.workspace_marker!(bytes: bytes, key: @projection.fetch("key"))
            @marker_bytes = bytes.freeze
            state
          end
        end
        # Native activation owns this host lease for the original scope lifetime.
        # An admission deadline must not become a provider lifetime ceiling.
        class WorkspaceNativeReader < WorkspaceReader
          def initialize(projection:, protection: nil, files: File)
            super(projection: projection, protection: protection, files: files)
            @root = @projection.fetch("root_resource").fetch("host_path")
            @protection = protection || WorkspaceHostReader::Protection.new(projection: @projection)
          end
        end

        class WorkspaceHostReader < WorkspaceReader
          class Protection < WorkspaceReader::Protection
            private
            def root_path(root) = root.fetch("host_path")
            def verify_root_mount!(_path, handle, root)
              unless @mounts.mount_identity(handle).fetch("filesystem_type") == root.fetch("filesystem_type")
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle writer filesystem differs"
              end
            end
          end

          def initialize(projection:, protection: nil, files: File)
            super(projection: projection, protection: protection, files: files)
            @root = @projection.fetch("root_resource").fetch("host_path")
            @protection = protection || Protection.new(projection: @projection)
          end

          def acquire!(deadline:)
            @deadline = deadline
            deadline!(deadline)
            super()
            deadline!(deadline)
            self
          rescue Exception
            close!
            raise
          end

          def verify_unchanged!
            deadline!(@deadline) unless @deadline.nil?
            super
          end

          private
          def deadline!(value)
            unless value.is_a?(Numeric) && value.finite? && value > Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise AttemptErrors::MaintenanceBusy, "Lifecycle maintenance deadline elapsed"
            end
          end
        end

        # Inspection evidence only: never permits creation or publication.
        class WorkspaceFenceReader < WorkspaceHostReader
          def fence_evidence!
            verify_unchanged!
            bytes = @marker_bytes
            reference = {"path" => path_for("state.json").freeze,
              "sha256" => Digest::SHA256.hexdigest(bytes).freeze, "bytes" => bytes.bytesize}.freeze
            {"reference" => reference, "bytes" => bytes}.freeze
          end

          private
          def require_live_marker!(_state); end
        end

        class WorkspaceWriter < WorkspaceHostReader
          # Refusal fence only; canonical physical proof is owned separately.
          def publish_removed!(removed_at:)
            verify_unchanged!
            unless removed_at.is_a?(String) && Time.iso8601(removed_at).utc.iso8601 == removed_at
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle fence timestamp differs"
            end
            bytes = Atoms::EvidenceDigest.canonical_json({"key" => @projection.fetch("key"),
              "removed" => true, "removed_at" => removed_at}).freeze
            target = path_for("state.json")
            temporary = File.join(@root, ".#{SecureRandom.hex(16)}.fence")
            begin
              @files.open(temporary, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW | File::NONBLOCK, 0o644) do |file|
                file.chmod(0o644)
                file.write(bytes)
                file.flush
                unless file.stat.file? && file.stat.nlink == 1 && file.stat.size == bytes.bytesize &&
                    [file.stat.uid, file.stat.gid, file.stat.mode & 0o7777] == [0, 0, 0o644]
                  raise AttemptErrors::EvidenceUnavailable, "Lifecycle temporary fence protection differs"
                end
                file.fsync
              end
              verify_unchanged!
              @files.rename(temporary, target)
              @handles.fetch(@root).fetch(:handle).fsync
              previous = @handles.delete(target)
              previous.fetch(:handle).close
              marker = pin!(target, directory: false)
              unless [marker.stat.uid, marker.stat.gid] == [0, 0] && read_marker!(marker).fetch("removed")
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle published fence owner differs"
              end
              verify_unchanged!
              reference = {"path" => target.freeze, "sha256" => Digest::SHA256.hexdigest(bytes).freeze,
                "bytes" => bytes.bytesize}.freeze
              {"reference" => reference, "bytes" => bytes}.freeze
            ensure
              @files.unlink(temporary) if @files.exist?(temporary)
            end
          rescue SystemCallError, IOError, ArgumentError
            raise AttemptErrors::EvidenceUnavailable, "Lifecycle removal fence publication is unavailable"
          end

          private
          def lock_mode = File::LOCK_EX
        end
      end
    end
  end
end
