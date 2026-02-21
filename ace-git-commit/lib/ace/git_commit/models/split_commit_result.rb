# frozen_string_literal: true

module Ace
  module GitCommit
    module Models
      # SplitCommitResult tracks results for split commit execution
      class SplitCommitResult
        CommitRecord = Struct.new(:group, :sha, :status, :error, keyword_init: true)

        attr_reader :records, :original_head, :rollback_error

        def initialize(original_head: nil)
          @records = []
          @original_head = original_head
          @rollback_error = nil
        end

        def add_success(group, sha)
          @records << CommitRecord.new(group: group, sha: sha, status: :success, error: nil)
        end

        def add_dry_run(group)
          @records << CommitRecord.new(group: group, sha: nil, status: :dry_run, error: nil)
        end

        def add_failure(group, error)
          @records << CommitRecord.new(group: group, sha: nil, status: :failure, error: error)
        end

        def add_skipped(group, reason)
          @records << CommitRecord.new(group: group, sha: nil, status: :skipped, error: reason)
        end

        def commit_shas
          records.map(&:sha).compact
        end

        def success?
          records.all? { |record| record.status == :success || record.status == :dry_run || record.status == :skipped }
        end

        def skipped?
          records.any? { |record| record.status == :skipped }
        end

        def dry_run?
          records.any? { |record| record.status == :dry_run }
        end

        def failed?
          !success?
        end

        def mark_rollback_error(error)
          @rollback_error = error
        end
      end
    end
  end
end
