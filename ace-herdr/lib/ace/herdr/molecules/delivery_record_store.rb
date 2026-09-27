# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Herdr
    module Molecules
      # Persists DeliveryRecord JSON files under a deliveries directory.
      # Writes are atomic (temp file + rename) so a crash never yields a
      # torn record and the answer stays re-deliverable.
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
          File.write(tmp, JSON.generate(record.to_h))
          File.rename(tmp, path)
          path
        end

        def path_for(deliveries_dir, event_id)
          File.join(deliveries_dir, "#{event_id}.json")
        end
      end
    end
  end
end
