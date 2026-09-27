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

        # @return [Models::DeliveryRecord, nil]
        def load(deliveries_dir, event_id)
          path = path_for(deliveries_dir, event_id)
          return nil unless File.exist?(path)

          Models::DeliveryRecord.from_json(File.read(path))
        end

        # @return [String] path the record was written to
        def save(record, deliveries_dir)
          FileUtils.mkdir_p(deliveries_dir)
          path = path_for(deliveries_dir, record.event_id)
          tmp = "#{path}.tmp.#{Process.pid}"
          File.open(tmp, IO::CREAT | IO::TRUNC | IO::WRONLY, 0o600) do |file|
            file.write(JSON.generate(record.to_h))
          end
          File.rename(tmp, path)
          path
        end

        # Hold the exclusive per-event lock while delivering; concurrent
        # callers block until the winner finishes, then observe its record.
        def with_lock(deliveries_dir, event_id)
          FileUtils.mkdir_p(deliveries_dir)
          File.open(lock_path(deliveries_dir, event_id), "a") do |lock|
            lock.flock(File::LOCK_EX)
            begin
              return yield
            ensure
              lock.flock(File::LOCK_UN)
            end
          end
        end

        def path_for(deliveries_dir, event_id)
          File.join(deliveries_dir, "#{event_id}.json")
        end

        def lock_path(deliveries_dir, event_id)
          File.join(deliveries_dir, ".#{event_id}.lock")
        end
      end
    end
  end
end
