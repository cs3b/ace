# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Categorizes items into "up next" and "recently done" buckets
        # for status overview displays. Generic — works with any item
        # responding to :status, :file_path, :special_folder, :id.
        class StatusCategorizer
          # @param items [Array] All loaded items
          # @param up_next_limit [Integer] Max up-next items (0 = disable section)
          # @param recently_done_limit [Integer] Max recently-done items (0 = disable section)
          # @param pending_statuses [Array<String>] Statuses considered "up next"
          # @param done_statuses [Array<String>] Statuses considered "recently done"
          # @return [Hash] { up_next: [...], recently_done: [{ item:, completed_at: }] }
          def self.categorize(items, up_next_limit:, recently_done_limit:,
                              pending_statuses: ["pending"], done_statuses: ["done"])
            up_next = if up_next_limit > 0
              items
                .select { |i| pending_statuses.include?(i.status) && i.special_folder.nil? }
                .sort_by(&:id)
                .first(up_next_limit)
            else
              []
            end

            recently_done = if recently_done_limit > 0
              items
                .select { |i| done_statuses.include?(i.status) }
                .map { |i| { item: i, completed_at: safe_mtime(i.file_path) } }
                .sort_by { |entry| -(entry[:completed_at]&.to_f || 0) }
                .first(recently_done_limit)
            else
              []
            end

            { up_next: up_next, recently_done: recently_done }
          end

          # Safely read file mtime, returning nil if the file is missing.
          def self.safe_mtime(path)
            File.mtime(path)
          rescue Errno::ENOENT, TypeError
            nil
          end

          private_class_method :safe_mtime
        end
      end
    end
  end
end
