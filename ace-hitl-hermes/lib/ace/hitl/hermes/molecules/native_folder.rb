# frozen_string_literal: true

require "digest"
require "json"
require "securerandom"
require "ace/hitl/hermes/errors"
require_relative "hermes_contract"
require_relative "hermes_atomic_writer"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Transport files only. Canonical questions/answers remain ace-hitl's
        # files; no lifecycle server, assignment journal, or Telegram credentials.
        #
        # Guard policy (cycle-2): origin-roots, worktree-roots, and
        # ownership/privacy checks WARN and proceed — the frame goes through,
        # the reason lands on stderr and in the receipt (warnings reader).
        # Guards that protect frame identity and content integrity (schema,
        # key binding, size, NOFOLLOW, collision) stay hard errors: they
        # decide WHAT is read, never whether a sender may ask.
        class NativeFolder
          SCHEMA = "ace.hitl.hermes.native/v1"
          MAX_BYTES = 65_536
          KEY = /\A[0-9a-f]{64}\z/
          TOKEN = /\A[a-z0-9][a-z0-9_-]{0,63}\z/i

          attr_reader :folder, :project, :channel, :machine, :event_roots, :route_name

          def initialize(route)
            @warnings = []
            @warned = {}
            @folder = File.expand_path(route.fetch("folder"))
            @project, @channel, @machine = route.values_at("project", "channel", "machine")
            @route_name = route["route"]
            unless @route_name.is_a?(String) && @route_name.match?(TOKEN)
              raise ContractError, "native Hermes requires a named adapter route"
            end
            unless [@project, @channel, @machine].all? { |v| v.is_a?(String) && v.match?(TOKEN) }
              raise ContractError, "native Hermes route requires project, channel and machine tokens"
            end
            @event_roots = Array(route["event_roots"])
            @worktree_roots = Array(route["worktree_roots"])
            if @event_roots.empty? && @worktree_roots.empty?
              warn_once("no explicit event_roots or worktree_roots configured; every origin root is accepted with a warning")
            end
            malformed = (@event_roots + @worktree_roots).reject { |p| p.is_a?(String) && p.start_with?("/") && File.expand_path(p) == p }
            unless malformed.empty?
              @event_roots = @event_roots.grep(String).select { |p| p.start_with?("/") && File.expand_path(p) == p }
              @worktree_roots = @worktree_roots.grep(String).select { |p| p.start_with?("/") && File.expand_path(p) == p }
              warn_once("ignoring non-absolute configured roots #{malformed.inspect}; origin checks degrade to a warning")
            end
            verify_folder!
          end

          # Reasons emitted to stderr and carried in the receipt (RouteResult
          # detail on the send path, the run result's "warnings" on sync).
          def warnings
            @warnings.dup
          end

          # Warn once per folder instance per reason: to stderr with the
          # reason, and retained in the receipt via #warnings.
          def warn_once(message)
            return if @warned.key?(message)

            @warned[message] = true
            @warnings << message
            warn "ace-hitl-hermes: warning: #{message}"
            nil
          end

          def request(event, text)
            raise ContractError, "managed requests retain their lifecycle transport" if event.metadata["lab_request_id"]
            path = File.realpath(event.file_path)
            root = event.reply_to&.fetch("folder", nil) ||
              (@event_roots + @worktree_roots.flat_map { |base| Dir.glob("#{base}/*/.ace-local/hitl") })
                .find { |candidate| path.start_with?("#{candidate}/") }
            if root.nil?
              # Guard policy: outside the configured roots the frame still goes
              # through, bound to the case's own event root (the hitl folder
              # containing the case directory).
              root = File.dirname(File.dirname(path))
              warn_once("native origin #{event.id} is outside the configured project/worktree roots; proceeding with its own root #{root}")
            end
            origin = {"file" => path, "root" => root, "case_id" => event.id}
            validate_origin!(origin)
            key = Digest::SHA256.hexdigest(JSON.generate([project, path, event.id]))
            {
              "schema" => SCHEMA, "kind" => "request", "key" => key,
              "project" => project, "channel" => channel, "machine" => machine,
              "route" => route_name,
              "origin" => origin, "event_type" => event.type || "question",
              "recipient" => event.recipient, "reply_to" => event.reply_to,
              "text" => text, "created_at" => event.created_at.to_s
            }
          end

          def validate_origin!(origin)
            raise ContractError, "invalid native origin" unless origin.is_a?(Hash)
            path, root, id = origin.values_at("file", "root", "case_id")
            # Structure and identity of the origin stay hard: a malformed
            # origin cannot be bound to a case at all.
            unless [root, path].all? { |p| p.is_a?(String) && File.realpath(p) == p } &&
                path.start_with?("#{root}/") && id.is_a?(String) && id.match?(TOKEN) &&
                File.basename(path).start_with?("#{id}-") && path.end_with?(".hitl.s.md")
              raise ContractError, "invalid native origin"
            end
            allowed = @event_roots.include?(root) || @worktree_roots.any? do |base|
              root.match?(%r{\A#{Regexp.escape(base)}/[^/]+/\.ace-local/hitl\z})
            end
            unless allowed
              warn_once("native origin #{id} is outside the configured project/worktree roots; proceeding")
            end
            validate_root!(root)
            origin
          end

          def validate_root!(root)
            stat = File.lstat(root)
            unless stat.directory? && File.realpath(root) == root &&
                stat.uid == Process.euid && (stat.mode & 0o077).zero?
              warn_once("native origin root is not a real, private, current-user directory (#{root}); proceeding")
            end
            root
          end

          def publish(event, text)
            record = request(event, text)
            write_once("request", record.fetch("key"), record)
            record
          end

          def read(kind, key)
            verify_folder!
            path = path_for(kind, key)
            File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
              stat = file.stat
              unless stat.file? && stat.uid == Process.euid && (stat.mode & 0o077).zero?
                warn_once("native Hermes frame #{File.basename(path)} is not a private current-user file; proceeding")
              end
              bytes = file.read(MAX_BYTES + 1)
              raise ContractError, "native Hermes frame too large" if bytes.bytesize > MAX_BYTES
              value = JSON.parse(bytes)
              unless value.is_a?(Hash) && value["schema"] == SCHEMA &&
                  value["kind"] == kind && value["key"] == key
                raise ContractError, "native Hermes frame identity differs"
              end
              value
            end
          rescue Errno::ENOENT
            nil
          rescue JSON::ParserError, Errno::ELOOP
            raise ContractError, "native Hermes frame is invalid"
          end

          def write_once(kind, key, record)
            existing = read(kind, key)
            if existing
              raise CollisionError, "native Hermes identity already contains different content" unless existing == record
              return existing
            end
            bytes = JSON.generate(record)
            raise ContractError, "native Hermes frame too large" if bytes.bytesize > MAX_BYTES
            temporary = File.join(folder, ".native-#{SecureRandom.hex(12)}")
            begin
              File.open(temporary, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
                file.write(bytes)
                file.fsync
              end
              File.link(temporary, path_for(kind, key)) # atomic create, never replace another writer
              HermesAtomicWriter.sync_directory(folder)
            ensure
              File.unlink(temporary) if temporary && File.exist?(temporary)
            end
            record
          rescue Errno::EEXIST, CollisionError
            raise unless read(kind, key) == record
            record
          end

          def keys(kind)
            verify_folder!
            Dir.children(folder).filter_map do |name|
              name.delete_prefix("#{kind}-").delete_suffix(".json") if name.match?(/\A#{Regexp.escape(kind)}-[0-9a-f]{64}\.json\z/)
            end.sort
          end

          def ack(kind, key)
            verify_folder!
            File.unlink(path_for(kind, key))
            HermesAtomicWriter.sync_directory(folder)
          rescue Errno::ENOENT
            nil
          end

          def synchronize
            verify_folder!
            File.open(File.join(folder, ".ace-sync.lock"), File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
              unless lock.stat.file? && lock.stat.uid == Process.euid && (lock.stat.mode & 0o077).zero?
                warn_once("native Hermes lock is not a private current-user file; proceeding")
              end
              lock.flock(File::LOCK_EX)
              yield
            end
          end

          private

          def verify_folder!
            stat = File.lstat(folder)
            unless stat.directory? && !stat.symlink? && File.realpath(folder) == folder &&
                stat.uid == Process.euid && (stat.mode & 0o077).zero? && !Process.euid.zero?
              warn_once("native Hermes folder is not a real, private, non-root-owned directory (#{folder}); proceeding")
            end
          rescue Errno::ENOENT, Errno::ENOTDIR, Errno::EACCES
            # An unavailable folder is operational, not policy: the frame
            # physically cannot go through, so this stays a hard failure.
            raise ContractError, "native Hermes folder is unavailable (#{folder})"
          end

          def path_for(kind, key)
            unless %w[request delivery reply instruction].include?(kind) && key.is_a?(String) && key.match?(KEY)
              raise ContractError, "invalid native Hermes transport identity"
            end
            File.join(folder, "#{kind}-#{key}.json")
          end
        end
      end
    end
  end
end
