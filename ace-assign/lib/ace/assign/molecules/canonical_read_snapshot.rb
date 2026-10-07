# frozen_string_literal: true

require "digest"
require "fileutils"
require "tmpdir"
require "ace/herdr/molecules/bounded_process"
require_relative "evidence_journal"
require_relative "../authority/private_directory"

module Ace
  module Assign
    module Molecules
      # Isolates read-only Git from an installed authority's live configuration.
      # The copied view never publishes evidence or mutates the source journal.
      class CanonicalReadSnapshot
        class Unavailable < AttemptErrors::EvidenceUnavailable; end
        BYTE_LIMIT = 256 * 1_048_576
        ENTRY_LIMIT = 4096
        OID = /\A[0-9a-f]{40}\z/
        ENVIRONMENT = {"PATH" => "/usr/bin:/bin", "LC_ALL" => "C",
          "GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_SYSTEM" => "/dev/null",
          "GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_TERMINAL_PROMPT" => "0",
          "GIT_ALLOW_PROTOCOL" => "", "GIT_NO_REPLACE_OBJECTS" => "1",
          "GIT_NO_LAZY_FETCH" => "1", "GIT_OPTIONAL_LOCKS" => "0"}.freeze

        # These selections come from installed source composition, not frames.
        def initialize(repo_root:, checkout_root:, ref:, private_root:, git_executable: "/usr/bin/git")
          paths = [repo_root, checkout_root, private_root, git_executable]
          unless paths.all? { |path| path.is_a?(String) && path.start_with?("/") &&
              !path.include?("\0") && File.expand_path(path) == path } &&
              ref.is_a?(String) && ref.match?(/\Arefs\/[a-zA-Z0-9_-]+(?:\/[a-zA-Z0-9_-]+)+\z/)
            raise ArgumentError, "canonical snapshot source selection is malformed"
          end
          @repo_root, @checkout_root, @private_root, @git = paths.map { |path| path.dup.freeze }
          @ref = ref.dup.freeze
          @verification = Mutex.new
        end

        def with(deadline:)
          refuse!("snapshot_busy") unless @verification.try_lock
          begin
            with_snapshot(deadline: deadline) { |snapshot| yield snapshot }
          ensure
            @verification.unlock
          end
        end

        def with_snapshot(deadline:)
          validate_deadline!(deadline)
          verify_private_root!
          private_stat = directory!(@private_root)
          unless private_stat.uid == Process.uid && (private_stat.mode & 0o7777) == 0o700
            refuse!("private_storage_unprotected")
          end
          Dir.mktmpdir("canonical-read-", @private_root) do |view|
            verify_private_root!
            refuse!("private_storage_unprotected") unless directory_identity(File.lstat(@private_root)) == directory_identity(private_stat)
            @view, @deadline = view, deadline
            @held, @directories, @inventory, @inventory_files, @metadata_files = [], [], [], [], []
            @bytes, @entries = 0, 0
            git_dir = File.join(@repo_root, ".git")
            directory!(git_dir)
            %w[commondir reftable shallow].each do |name|
              refuse!("unsupported_source") if exists?(File.join(git_dir, name))
            end
            lock, original_lock = held_file!(File.join(@checkout_root, ".evidence.lock"), limit: 128)
            begin
              acquire!(lock)
              begin
                source_config!(git_dir)
                @commit = select_ref!(git_dir)
                objects = File.join(git_dir, "objects")
                inventory = inventory!(objects)
                inventory.each { |relative, handle| copy!(relative, handle) }
                verify_held!
                refuse!("source_changed") unless inventory_names!(objects) == @inventory &&
                  select_ref!(git_dir) == @commit && identity(File.lstat(lock.path)) == original_lock
                verify_held!
              ensure
                lock.flock(File::LOCK_UN)
              end
            end
            prepare_view!
            run!(%w[fsck --full --strict --no-reflogs], limit: 65_536)
            yield self
          ensure
            @held&.each { |handle| handle.close unless handle.closed? }
            @held = @directories = @inventory = @inventory_files = @metadata_files = @view = @deadline = @commit = nil
          end
        rescue Timeout::Error
          refuse!("resource_limit")
        rescue IOError, SystemCallError, Herdr::Molecules::BoundedProcess::PostLaunchError
          refuse!("source_unavailable")
        end
        private :with_snapshot

        attr_reader :commit

        # EvidenceJournal uses this only as its existing read command boundary.
        def call(argv, stdin_data: "", output_limit: BYTE_LIMIT)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless read_command?(argv, stdin_data)
            refuse!("write_or_unsupported_command")
          end
          result = run!(argv, stdin_data: stdin_data, limit: [output_limit, BYTE_LIMIT].min)
          [result.stdout.to_s.strip, result.stderr.to_s.strip, result.status]
        end

        def blob_batch(entries, output_limit:)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless entries.is_a?(Array) && entries.all? { |oid| oid.is_a?(String) && oid.match?(OID) }
            refuse!("unsupported_command")
          end
          result = run!(["cat-file", "--batch"], stdin_data: entries.join("\n") + "\n",
            limit: [output_limit, BYTE_LIMIT].min)
          result.stdout.to_s.b
        end

        def blob(path, commit:, max_bytes:)
          refuse!("read_outside_snapshot") unless @view && @commit
          unless commit.is_a?(String) && commit.match?(OID) && max_bytes.is_a?(Integer) && max_bytes.positive?
            refuse!("unsupported_command")
          end
          result = run!(["cat-file", "blob", "#{commit}:#{path}"], limit: [max_bytes, BYTE_LIMIT].min)
          result.stdout.to_s.b
        end

        private

        def refuse!(reason)
          raise Unavailable, "canonical read snapshot unavailable: #{reason}"
        end

        def validate_deadline!(deadline)
          unless deadline.is_a?(Numeric) && deadline.finite? && deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
            refuse!("resource_limit")
          end
        end

        def remaining
          value = @deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          refuse!("resource_limit") unless value.positive?
          value
        end

        def acquire!(lock)
          until lock.flock(File::LOCK_SH | File::LOCK_NB)
            sleep [remaining, 0.005].min
          end
        end

        def identity(stat)
          [stat.dev, stat.ino, stat.mode, stat.uid, stat.gid, stat.size, stat.mtime, stat.ctime]
        end

        def verify_private_root!
          Authority::PrivateDirectory.verify!(@private_root)
        rescue AttemptErrors::ReceiptRejected
          refuse!("private_storage_unprotected")
        end

        def directory_identity(stat)
          [stat.dev, stat.ino, stat.mode, stat.uid, stat.gid]
        end

        def directory!(path)
          stat = File.lstat(path)
          refuse!("unsupported_source") unless stat.directory? && !stat.symlink?
          stat
        end

        def exists?(path)
          File.lstat(path)
          true
        rescue Errno::ENOENT
          false
        end

        def held_file!(path, limit:)
          remaining
          parent = File.dirname(path)
          until parent == "/"
            stat = directory!(parent)
            @directories << [parent, directory_identity(stat)]
            parent = File.dirname(parent)
          end
          handle = File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
          @held << handle
          stat = handle.stat
          refuse!("unsupported_source") unless stat.file?
          refuse!("resource_limit") if stat.size > limit
          [handle, identity(stat)]
        end

        def select_ref!(git_dir)
          loose = File.join(git_dir, @ref)
          if exists?(loose)
            handle, before = held_file!(loose, limit: 128)
            bytes = handle.read(129)
            @metadata_files << [loose, handle, before]
            refuse!("source_changed") unless identity(handle.stat) == before
            refuse!("unsupported_ref") unless bytes.match?(/\A[0-9a-f]{40}\n?\z/)
            return bytes.strip
          end
          packed = File.join(git_dir, "packed-refs")
          handle, before = held_file!(packed, limit: 65_536)
          bytes = handle.read(65_537)
          @metadata_files << [packed, handle, before]
          refuse!("source_changed") unless identity(handle.stat) == before
          entries = {}
          bytes.lines.each do |line|
            next if line.start_with?("#") || line.match?(/\A\^[0-9a-f]{40}\n?\z/)
            match = /\A([0-9a-f]{40}) (refs\/[^\s\0]+)\n?\z/.match(line)
            refuse!("unsupported_ref") unless match && !entries.key?(match[2])
            entries[match[2]] = match[1]
          end
          entries.fetch(@ref) { refuse!("unsupported_ref") }
        end

        def source_config!(git_dir)
          path = File.join(git_dir, "config")
          handle, before = held_file!(path, limit: 65_536)
          bytes = handle.read(65_537)
          @metadata_files << [path, handle, before]
          refuse!("source_changed") unless identity(handle.stat) == before
          # Standalone file parsing does not select the target repository,
          # follow includes or execute aliases/hooks/helpers. No source config
          # is installed into the private administrative view.
          result = run!(["config", "--no-includes", "--null", "--list", "--file", "/dev/stdin"],
            stdin_data: bytes, limit: 65_536)
          versions = []
          result.stdout.split("\0").each do |entry|
            key, value = entry.split("\n", 2)
            refuse!("unsupported_source") if key.start_with?("extensions.") || key == "core.worktree"
            versions << value if key == "core.repositoryformatversion"
          end
          refuse!("unsupported_source") unless versions.empty? || versions == ["0"]
        end

        def inventory_names!(objects)
          names = []
          walk = lambda do |path, relative|
            remaining
            stat = File.lstat(path)
            names << [relative, stat.directory? ? "directory" : "file"]
            refuse!("resource_limit") if names.size > ENTRY_LIMIT
            refuse!("unsupported_source") if stat.symlink? || !(stat.directory? || stat.file?)
            if stat.directory?
              unless relative.empty? || %w[pack info].include?(relative) || relative.match?(/\A[0-9a-f]{2}\z/)
                refuse!("unsupported_source")
              end
              children = []
              Dir.each_child(path) do |name|
                remaining
                children << name
                refuse!("resource_limit") if children.size + names.size > ENTRY_LIMIT
              end
              children.sort.each { |name| walk.call(File.join(path, name), relative.empty? ? name : "#{relative}/#{name}") }
            end
          end
          walk.call(objects, "")
          names
        end

        def inventory!(objects)
          @inventory = inventory_names!(objects)
          files = @inventory.select { |_relative, kind| kind == "file" }.map(&:first)
          packs = files.grep(/\Apack\/pack-[0-9a-f]{40}\.pack\z/)
          unless packs.all? { |pack| files.include?(pack.sub(/\.pack\z/, ".idx")) } &&
              files.grep(/\Apack\/pack-[0-9a-f]{40}\.(?:idx|rev)\z/).all? { |file| packs.include?(file.sub(/\.(?:idx|rev)\z/, ".pack")) }
            refuse!("unsupported_source")
          end
          @inventory.filter_map do |relative, kind|
            path = relative.empty? ? objects : File.join(objects, relative)
            if kind == "directory"
              unless relative.empty? || relative == "pack" || relative == "info" || relative.match?(/\A[0-9a-f]{2}\z/)
                refuse!("unsupported_source")
              end
              @directories << [path, directory_identity(File.lstat(path))]
              next
            end
            # These ordinary Git indexes/retention hints do not redirect
            # storage. The clean view never reads them; only object bytes and
            # pack indexes are copied. Redirect/lazy-fetch metadata refuses.
            next if relative.match?(/\Ainfo\/(?:packs|commit-graph)\z/) ||
              relative.match?(/\Apack\/pack-[0-9a-f]{40}\.(?:bitmap|keep)\z/)
            unless relative.match?(/\A[0-9a-f]{2}\/[0-9a-f]{38}\z/) ||
                relative.match?(/\Apack\/pack-[0-9a-f]{40}\.(?:pack|idx|rev)\z/)
              refuse!("unsupported_source")
            end
            handle, before = held_file!(path, limit: BYTE_LIMIT)
            @bytes += handle.stat.size
            refuse!("resource_limit") if @bytes > BYTE_LIMIT
            @inventory_files << [path, handle, before]
            [relative, handle]
          end
        end

        def copy!(relative, source)
          destination = File.join(@view, "objects", relative)
          FileUtils.mkdir_p(File.dirname(destination), mode: 0o700)
          File.open(destination, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |target|
            copied = 0
            expected = source.stat.size
            while (chunk = source.read(65_536))
              remaining
              copied += chunk.bytesize
              refuse!("source_changed") if copied > expected
              target.write(chunk)
            end
            refuse!("source_changed") unless copied == expected
          end
        end

        def verify_held!
          @directories.each { |path, before| refuse!("source_changed") unless directory_identity(File.lstat(path)) == before }
          (@inventory_files + @metadata_files).each do |path, handle, before|
            refuse!("source_changed") unless identity(handle.stat) == before && identity(File.lstat(path)) == before
          end
        end

        def prepare_view!
          FileUtils.mkdir_p(File.join(@view, "objects"), mode: 0o700)
          FileUtils.mkdir_p(File.join(@view, "refs"), mode: 0o700)
          File.binwrite(File.join(@view, "HEAD"), "#{@commit}\n")
          File.binwrite(File.join(@view, "config"), "[core]\nrepositoryformatversion = 0\nbare = true\n")
          ref = File.join(@view, @ref)
          FileUtils.mkdir_p(File.dirname(ref), mode: 0o700)
          File.binwrite(ref, "#{@commit}\n")
        end

        def read_command?(argv, stdin)
          return false unless argv.is_a?(Array) && argv.all? { |item| item.is_a?(String) && !item.include?("\0") } && stdin.empty?
          allowed = {"rev-parse" => %w[--verify --quiet --git-dir], "cat-file" => %w[-t -s blob],
            "rev-list" => %w[--first-parent --parents], "ls-tree" => %w[-r -l -d --name-only --],
            "show" => [], "log" => %w[--diff-filter=A -1 --format=%H --]}
          flags = allowed[argv.first]
          flags && argv.drop(1).all? { |item| !item.start_with?("-") || flags.include?(item) || item == "--max-count=100001" }
        end

        def run!(argv, stdin_data: "", limit:)
          result = Herdr::Molecules::BoundedProcess.call([@git, "--git-dir=#{@view}", "--no-pager", *argv],
            environment: ENVIRONMENT, chdir: @view, stdin_data: stdin_data,
            timeout_s: remaining, output_limit: limit, stderr_limit: 65_536)
          refuse!(result.oversized ? "resource_limit" : "git_unavailable") unless result.status.success? && !result.oversized
          result
        end
      end
    end
  end
end
