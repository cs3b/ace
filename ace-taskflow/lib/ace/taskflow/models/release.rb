# frozen_string_literal: true

module Ace
  module Taskflow
    module Models
      # Release data structure
      class Release
        attr_reader :name, :path, :status, :version, :statistics,
                    :created_at, :modified_at

        def initialize(attributes = {})
          @name = attributes[:name]
          @path = attributes[:path]
          @status = attributes[:status]
          @version = attributes[:version]
          @statistics = attributes[:statistics] || default_statistics
          @created_at = attributes[:created_at]
          @modified_at = attributes[:modified_at]
        end

        # Convert to hash
        def to_h
          {
            name: name,
            path: path,
            status: status,
            version: version,
            statistics: statistics,
            created_at: created_at,
            modified_at: modified_at
          }
        end

        # Check if release is active
        def active?
          status == "active"
        end

        # Check if release is in backlog
        def backlog?
          status == "backlog"
        end

        # Check if release is done
        def done?
          status == "done"
        end

        # Get completion percentage
        def completion_percentage
          total = statistics[:total]
          return 0 if total == 0

          done_count = statistics[:statuses]["done"] || 0
          (done_count.to_f / total * 100).round
        end

        # Get pending task count
        def pending_count
          statistics[:statuses]["pending"] || 0
        end

        # Get in-progress task count
        def in_progress_count
          statistics[:statuses]["in-progress"] || 0
        end

        # Get done task count
        def done_count
          statistics[:statuses]["done"] || 0
        end

        # Check if release is ready for completion
        def ready_for_completion?
          in_progress_count == 0 && pending_count == 0
        end

        # Compare releases for sorting
        def <=>(other)
          return 0 unless other.is_a?(Release)

          # First by status (active first, then backlog, then done)
          status_order = status_value <=> other.status_value
          return status_order unless status_order == 0

          # Then by version
          version_parts <=> other.version_parts
        end

        protected

        def status_value
          case status
          when "active" then 0
          when "backlog" then 1
          when "done" then 2
          else 3
          end
        end

        def version_parts
          return [999, 999, 999] unless version

          version.split('.').map(&:to_i)
        end

        private

        def default_statistics
          {
            total: 0,
            statuses: {},
            created_at: nil,
            modified_at: nil
          }
        end
      end
    end
  end
end