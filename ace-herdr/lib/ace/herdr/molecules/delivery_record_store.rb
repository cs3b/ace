# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Herdr
    module Molecules
      # Persists DeliveryRecord JSON files under a deliveries directory.
      # Writes are atomic (temp file + rename, mode 0600) so a crash never
      # yields a torn record and the answer stays re-deliverable. A per-event
      # flock serializes concurrent deliveries of the same event.
      module DeliveryRecordStore
        module_function

        # @return [Models::DeliveryRecord, nil] the record, falling back to
        #   the archive copy when the live record is gone — delivery
        #   idempotency (identical short-circuit, conflict fail-closed) must
        #   survive tidy archival
        # @raise on malformed/unreadable content (fail closed: callers must
        #   not treat a corrupt record as absent)
        def load(deliveries_dir, event_id)
          path = resolve_record_path(deliveries_dir, event_id)
          return nil unless path

          Models::DeliveryRecord.from_json(File.read(path))
        end

        # Tidy's lock-guarded revalidation load: like load, but a malformed
        # or unreadable record decodes as :unreadable instead of raising
        # (reported as preserved, never archived on unprovable evidence)
        # @return [Models::DeliveryRecord, nil, :unreadable]
        def load_revalidated(deliveries_dir, event_id)
          path = resolve_record_path(deliveries_dir, event_id)
          return nil unless path

          Models::DeliveryRecord.from_h(JSON.parse(File.read(path)))
        rescue JSON::ParserError, ArgumentError, TypeError, NoMethodError, Errno::EACCES
          :unreadable
        end

        # @return [String] path the record was written to
        def save(record, deliveries_dir)
          with_inventory_lock(deliveries_dir, exclusive: false, create: true) do
            save_held(record, deliveries_dir)
          end
        end

        def save_held(record, deliveries_dir)
          FileUtils.mkdir_p(deliveries_dir)
          path = path_for(deliveries_dir, record.event_id)
          tmp = "#{path}.tmp.#{Process.pid}"
          File.open(tmp, IO::CREAT | IO::TRUNC | IO::WRONLY, 0o600) do |file|
            file.write(JSON.generate(record.to_h))
            file.flush
            file.fsync
          end
          File.rename(tmp, path)
          File.open(deliveries_dir) { |dir| dir.fsync }
          path
        end

        # Hold the exclusive per-event lock while delivering; concurrent
        # callers block until the winner finishes, then observe its record.
        def with_lock(deliveries_dir, event_id, create: true)
          with_locks(deliveries_dir, [event_id], create: create) { yield }
        end

        def with_locks(deliveries_dir, event_ids, create: false)
          with_inventory_lock(deliveries_dir, exclusive: false, create: create) do
            with_event_locks_held(deliveries_dir, event_ids, create: create) { yield }
          end
        end

        # Global inventory always precedes event locks. Normal creators/writers
        # share it; maintenance exclusively holds it through its entire mutation
        # boundary. Reentrancy never upgrades a writer's shared lock.
        def with_inventory_lock(deliveries_dir, exclusive:, create: false, prepare_directory: true)
          held = Thread.current[:ace_herdr_delivery_inventory_locks] ||= {}
          if (existing = held[deliveries_dir])
            raise ArgumentError, "delivery inventory lock cannot be upgraded" if exclusive && existing != :exclusive
            return yield
          end
          FileUtils.mkdir_p(deliveries_dir) if create && prepare_directory
          flags = File::RDWR | File::NOFOLLOW | (create ? File::CREAT : 0)
          File.open(File.join(deliveries_dir, ".inventory.lock"), flags, 0o600) do |lock|
            raise ArgumentError, "delivery inventory lock is not a regular file" unless lock.stat.file?
            lock.flock(exclusive ? File::LOCK_EX : File::LOCK_SH)
            held[deliveries_dir] = exclusive ? :exclusive : :shared
            begin
              yield
            ensure
              held.delete(deliveries_dir)
              lock.flock(File::LOCK_UN)
            end
          end
        end

        def with_event_locks_held(deliveries_dir, event_ids, create: false)
          FileUtils.mkdir_p(deliveries_dir) if create
          flags = create ? "a" : File::RDWR | File::NOFOLLOW
          handles = []
          event_ids.sort.each do |event_id|
            lock = File.open(lock_path(deliveries_dir, event_id), flags)
            handles << lock
            lock.flock(File::LOCK_EX)
          end
          yield
        ensure
          handles&.reverse_each do |lock|
            lock.flock(File::LOCK_UN)
            lock.close
          end
        end

        def path_for(deliveries_dir, event_id)
          File.join(deliveries_dir, "#{event_id}.json")
        end

        def lock_path(deliveries_dir, event_id)
          File.join(deliveries_dir, ".#{event_id}.lock")
        end

        # --- tidy (spec 8wq.t.1w0) -------------------------------------------

        # Enumerate the top-level delivery records, sorted by event id.
        # Lock files, temp files, and the archive directory are ignored;
        # a malformed or unreadable file yields an entry with record: nil
        # (reported as preserved, never removed).
        # @return [Array<{event_id: String, record: Models::DeliveryRecord, nil}>]
        def list_records(deliveries_dir)
          return [] unless Dir.exist?(deliveries_dir)

          Dir.children(deliveries_dir).sort.filter_map do |name|
            next nil unless name.end_with?(".json")
            next nil unless record_file?(File.join(deliveries_dir, name))

            event_id = name.delete_suffix(".json")
            record =
              begin
                read_record(File.join(deliveries_dir, name))
              rescue Errno::EACCES
                nil # unreadable: reported as preserved, never removed
              rescue Errno::ENOENT
                next nil # vanished between listing and read: nothing to preserve
              end
            {event_id: event_id, record: record}
          end
        end

        # Archive directory for retired delivered records (inside the
        # deliveries dir so a same-filesystem rename stays atomic)
        def archive_dir(deliveries_dir)
          File.join(deliveries_dir, "archive")
        end

        # Atomically move one record file into the archive directory
        # (rename preserves the 0600 mode). Callers must hold the per-event
        # lock and re-check eligibility under it. Idempotent: an already
        # archived event just reports its archive path.
        # @return [String] the archive path the record lives at
        def archive(deliveries_dir, event_id)
          with_inventory_lock(deliveries_dir, exclusive: false, create: true) do
            archive_held(deliveries_dir, event_id)
          end
        end

        def archive_held(deliveries_dir, event_id)
          dest = File.join(archive_dir(deliveries_dir), "#{event_id}.json")
          return dest if !File.exist?(path_for(deliveries_dir, event_id)) && File.exist?(dest)

          FileUtils.mkdir_p(archive_dir(deliveries_dir))
          File.rename(path_for(deliveries_dir, event_id), dest)
          dest
        end

        def record_file?(path)
          File.file?(path) && !File.basename(path).start_with?(".")
        end

        # Live record path, falling back to the archive copy
        def resolve_record_path(deliveries_dir, event_id)
          live = path_for(deliveries_dir, event_id)
          return live if File.exist?(live)

          archived = File.join(archive_dir(deliveries_dir), "#{event_id}.json")
          File.exist?(archived) ? archived : nil
        end

        # Decode a record file fail-closed: anything that is not a decodable
        # delivery record (malformed JSON, non-object JSON, unknown state)
        # reads as nil (preserved/unreadable), never raises
        def read_record(path)
          parsed = JSON.parse(File.read(path))
          return nil unless parsed.is_a?(Hash)

          Models::DeliveryRecord.from_h(parsed)
        rescue JSON::ParserError, ArgumentError
          nil
        end
        private_class_method :save_held, :archive_held, :with_event_locks_held
      end
    end
  end
end
