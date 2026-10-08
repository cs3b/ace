# frozen_string_literal: true

require_relative "protected_workspace_exclusion"

module Ace
  module Assign
    module Molecules
      class LifecycleExclusion
        # Authority-side canonical guards. This owner never selects a Git/cache
        # root, resets a fence, or grants the lifetime workspace writer lease.
        class ControlExclusion
          class Protection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
            def initialize(authority_uid:, acl: Authority::PosixAcl.new, **options)
              super(**options)
              @authority_uid, @acl = authority_uid, acl
            end

            def verify!(path, handle, directory:)
              super
              unless (handle.stat.mode & 0o7000).zero? && @acl.entries(path).nil? &&
                  (!directory || @acl.entries(path, attribute: "system.posix_acl_default").nil?)
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle control protection differs"
              end
            end

            private
            def trusted_owner?(stat) = [0, @authority_uid].include?(stat.uid)
          end

          def initialize(authority:, project_id:, descriptor_sha256:, root_identity: nil, files: File, protection: nil)
            unless authority.is_a?(Hash) && project_id.is_a?(String) && token?(project_id) &&
                descriptor_sha256.is_a?(String) && descriptor_sha256.match?(/\A[0-9a-f]{64}\z/) &&
                %w[uid gid].all? { |key| authority[key].is_a?(Integer) && authority[key].positive? } &&
                authority["state_root"].is_a?(String) && authority["state_root"].valid_encoding? &&
                authority["state_root"].bytesize.between?(1, 4096) && !authority["state_root"].include?("\0") &&
                authority["state_root"].start_with?("/") && File.expand_path(authority["state_root"]) == authority["state_root"]
              unavailable!("Lifecycle control selection is malformed")
            end
            @root = File.join(authority.fetch("state_root"), "lifecycle-exclusion", project_id, "control")
            unavailable!("Lifecycle control path is oversized") if @root.bytesize > 4096
            @uid, @gid, @descriptor = authority.values_at("uid", "gid") + [descriptor_sha256.dup.freeze]
            if root_identity
              unless root_identity.is_a?(Hash) && root_identity.keys.sort == %w[device gid inode uid] &&
                  root_identity.values.all? { |value| value.is_a?(Integer) && value >= 0 } &&
                  root_identity.values_at("uid", "gid") == [@uid, @gid]
                unavailable!("Lifecycle control original identity differs")
              end
              @identity = root_identity.dup.freeze
            end
            @files = files
            @protection = protection || Protection.new(authority_uid: @uid)
          end

          def task_key(id) = key!("task", id)
          def assignment_key(id) = key!("assignment", id)

          def selection!
            with_root do |handles, identities|
              stat = handles.fetch(@root).stat
              @identity ||= {"device" => stat.dev, "inode" => stat.ino, "uid" => stat.uid, "gid" => stat.gid}.freeze
              {"descriptor_sha256" => @descriptor, "root_identity" => @identity}.freeze
            end
          end

          # Invoked only after the existing complete registration admission.
          # A partial creation is unavailable, not a missing-fence reset grant.
          def provision_keys!(keys:)
            ordered = keys!(keys)
            with_root do |handles, identities|
              root = handles.fetch(@root)
              ordered.each do |key|
                lock_path, marker_path = paths(key)
                lock, created = create_or_open!(lock_path, "", root)
                begin
                  validate_file!(lock_path, lock, empty: true)
                  marker = if created
                    create_or_open!(marker_path, Atoms::EvidenceDigest.canonical_json(
                      {"key" => key, "removed" => false, "removed_at" => nil}), root).first
                  else
                    @files.open(marker_path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
                  end
                  begin
                    live_marker!(key, marker_path, marker)
                  ensure
                    marker&.close
                  end
                ensure
                  lock&.close
                end
                unchanged!(handles, identities)
              end
            end
            self
          rescue SystemCallError, IOError, Ace::Runtime::RuntimeUnavailableError
            unavailable!("Lifecycle control provisioning is unavailable")
          end

          def with_shared_multi(keys, &block) = with_locks(keys, File::LOCK_SH, &block)
          def with_shared(key, &block) = with_shared_multi([key], &block)
          def with_exclusive(key, deadline: nil, &block) = with_locks([key], File::LOCK_EX, deadline: deadline, &block)

          # The canonical writer calls this again immediately before CAS. It
          # authenticates the same held keys, not freshly reopened substitutes.
          def verify_unchanged!
            checks = Thread.current[:ace_assign_control_checks]&.fetch(object_id, nil)
            unavailable!("Lifecycle control is not held") unless checks && !checks.empty?
            checks.each(&:call)
            true
          end

          private

          def with_locks(keys, mode, deadline: nil)
            ordered = keys!(keys)
            deadline!(deadline) if deadline
            with_root do |handles, identities|
              locks, markers, marker_facts, lock_facts = [], [], [], []
              begin
                ordered.each do |key|
                  path, marker_path = paths(key)
                  lock = @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
                  locks << lock
                  validate_file!(path, lock, empty: true)
                  lock_facts << file_metadata(lock.stat)
                  unless lock.flock(mode | File::LOCK_NB)
                    raise AttemptErrors::MaintenanceBusy, "Lifecycle control is under maintenance"
                  end
                  marker = @files.open(marker_path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
                  markers << marker
                  live_marker!(key, marker_path, marker)
                  marker_facts << file_metadata(marker.stat)
                end
                deadline!(deadline) if deadline
                unchanged!(handles, identities)
                check = proc do
                  ordered.each_with_index do |key, index|
                    path, marker_path = paths(key)
                    lock, marker = locks.fetch(index), markers.fetch(index)
                    validate_file!(path, lock, empty: true)
                    unless file_metadata(lock.stat) == lock_facts.fetch(index) &&
                        file_metadata(marker.stat) == marker_facts.fetch(index)
                      unavailable!("Lifecycle control key changed")
                    end
                    marker.rewind
                    live_marker!(key, marker_path, marker)
                  end
                  unchanged!(handles, identities)
                end
                registry = Thread.current[:ace_assign_control_checks] ||= {}
                checks = registry[object_id] ||= []
                checks << check
                begin
                  result = yield
                  verify_unchanged!
                ensure
                  checks.pop
                  registry.delete(object_id) if checks.empty?
                end
                deadline!(deadline) if deadline
                result
              ensure
                close_all!(locks + markers)
              end
            end
          rescue SystemCallError, IOError, Ace::Runtime::RuntimeUnavailableError
            unavailable!("Lifecycle control admission is unavailable")
          end

          def with_root
            handles, identities = {}, {}
            begin
              parts = @root.split("/").reject(&:empty?)
              (["/"] + parts.each_index.map { |index| "/" + parts.take(index + 1).join("/") }).each do |path|
                handle = @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
                handles[path] = handle
                unless handle.stat.directory? && file_identity(handle.stat) == file_identity(@files.lstat(path))
                  unavailable!("Lifecycle control directory changed")
                end
                @protection.verify!(path, handle, directory: true)
                identities[path] = file_identity(handle.stat)
              end
              root = handles.fetch(@root).stat
              unless [root.uid, root.gid, root.mode & 0o7777] == [@uid, @gid, 0o700] &&
                  (!@identity || [root.dev, root.ino, root.uid, root.gid] == @identity.values_at("device", "inode", "uid", "gid"))
                unavailable!("Lifecycle control original root differs")
              end
              result = yield handles, identities
              unchanged!(handles, identities)
              result
            ensure
              close_all!(handles.values)
            end
          rescue SystemCallError, IOError, Ace::Runtime::RuntimeUnavailableError
            unavailable!("Lifecycle control root is unavailable")
          end

          def unchanged!(handles, identities)
            handles.each do |path, handle|
              unless file_identity(handle.stat) == identities.fetch(path) &&
                  identities.fetch(path) == file_identity(@files.lstat(path))
                unavailable!("Lifecycle control directory changed")
              end
              @protection.verify!(path, handle, directory: true)
            end
          end

          def create_or_open!(path, bytes, root)
            created = true
            file = begin
              @files.open(path, File::RDWR | File::CREAT | File::EXCL | File::NOFOLLOW | File::NONBLOCK, 0o600)
            rescue Errno::EEXIST
              created = false
              @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            end
            if created
              file.write(bytes)
              file.flush
              file.fsync
              root.fsync
            end
            file.rewind
            [file, created]
          rescue Exception
            file&.close
            raise
          end

          def validate_file!(path, file, empty: false)
            stat = file.stat
            unless stat.file? && stat.nlink == 1 && [stat.uid, stat.gid, stat.mode & 0o7777] == [@uid, @gid, 0o600] &&
                file_identity(stat) == file_identity(@files.lstat(path)) && (empty ? stat.size.zero? : stat.size.between?(1, 8192))
              unavailable!("Lifecycle control file differs")
            end
            @protection.verify!(path, file, directory: false)
          end

          def live_marker!(key, path, file)
            validate_file!(path, file)
            before = file.stat
            bytes = file.read(8193)
            state = LifecycleExclusion.workspace_marker!(bytes: bytes, key: key)
            unless bytes.bytesize == before.size && file_metadata(before) == file_metadata(file.stat) &&
                file_metadata(before) == file_metadata(@files.lstat(path))
              unavailable!("Lifecycle control marker changed")
            end
            raise AttemptErrors::Conflict, "Lifecycle control identity is fenced" if state.fetch("removed")
          end

          def keys!(keys)
            values = Array(keys).uniq
            unless values.any? && values.all? { |key| key.is_a?(String) && key.match?(/\A(?:task|assignment):[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/) }
              unavailable!("Lifecycle control keys differ")
            end
            values.sort_by { |key| [key.start_with?("task:") ? 0 : 1, key] }
          end

          def key!(kind, id)
            unavailable!("Lifecycle control key differs") unless id.is_a?(String) && token?(id)
            "#{kind}:#{id}"
          end
          def token?(value) = value.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/)
          def paths(key)
            stem = File.join(@root, Digest::SHA256.hexdigest(key))
            [stem + ".lock", stem + ".state.json"]
          end
          def file_identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode]
          def file_metadata(stat) = file_identity(stat) + [stat.size, stat.mtime, stat.ctime]
          def unavailable!(message) = raise(AttemptErrors::EvidenceUnavailable, message)
          def deadline!(deadline)
            unless deadline.is_a?(Numeric) && deadline.finite? && deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
              raise AttemptErrors::MaintenanceBusy, "Lifecycle control admission deadline elapsed"
            end
          end
          def close_all!(files)
            error = nil
            files.reverse_each do |file|
              begin
                file.close unless file.closed?
              rescue SystemCallError, IOError => caught
                error ||= caught
              end
            end
            raise error if error
          end
        end
      end
    end
  end
end
