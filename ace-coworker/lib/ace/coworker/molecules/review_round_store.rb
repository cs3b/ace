# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "../atoms/round_rule"
require_relative "../atoms/round_record_schema"

module Ace
  module Coworker
    module Molecules
      # File-based review-round history for one reviewer assignment
      # (.ace-local/coworker/review-rounds/<assignment_id>.json), following
      # ReportStateStore. Coworker owns this location; a restart reads the
      # same file back, so the round counter and findings history survive
      # (contract: "wznowienie zachowuje dotychczasowe ustalenia,
      # liczniki i wyniki"). There is no separate journal - this file is
      # the deterministic counterpart of the reviewer's step-report round
      # record (reviewer.wf.md rule 6).
      class ReviewRoundStore
        def initialize(project_root:)
          @project_root = project_root
        end

        def state_path(assignment_id)
          File.join(@project_root, ".ace-local", "coworker", "review-rounds",
                    "#{validated(assignment_id)}.json")
        end

        # @return [Array<Hash>] recorded rounds, [] when absent or unparseable
        #   (lenient for pure readers; the destructive append in record!
        #   refuses corrupt state instead of resetting history).
        def read(assignment_id)
          path = state_path(assignment_id)
          return [] unless File.file?(path)

          parsed = JSON.parse(File.read(path))
          parsed.is_a?(Array) ? parsed : []
        rescue JSON::ParserError
          []
        end

        # Persist the full round list atomically; the tmp file never
        # survives a failed write.
        def write(assignment_id, records)
          path = state_path(assignment_id)
          FileUtils.mkdir_p(File.dirname(path))
          tmp_path = "#{path}.tmp.#{Process.pid}"
          begin
            File.write(tmp_path, JSON.pretty_generate(records))
            File.rename(tmp_path, path)
          ensure
            File.delete(tmp_path) if File.exist?(tmp_path)
          end
          path
        end

        # Record one round and return the resulting rule verdict, so a
        # resumed reviewer process reconstructs counters from the same
        # file: `store.record!(id, round)` => RoundRule verdict hash.
        #
        # Single-writer assumption: record! is an unsynchronized
        # read-modify-write, so concurrent record! calls on the same
        # assignment are last-write-wins (an earlier interleaved round
        # is lost). The lab flow runs one executor per worktree, so one
        # reviewer process owns this file at a time; no locking is added.
        def record!(assignment_id, record)
          errors = Atoms::RoundRecordSchema.errors(record)
          unless errors.empty?
            raise Error, "invalid round record for '#{assignment_id}': #{errors.join('; ')}"
          end

          records = strict_read(assignment_id) + [record]
          write(assignment_id, records)
          Atoms::RoundRule.evaluate(records)
        end

        private

        # Corrupt or non-array state must never be silently reset by an
        # append: an unparseable or non-array file raises, because
        # discarding it would erase the 10-round cap and the unresolved
        # High/Critical history - the exact evidence this store exists
        # to keep. An absent file is a legitimate empty history.
        def strict_read(assignment_id)
          path = state_path(assignment_id)
          return [] unless File.file?(path)

          parsed = begin
            JSON.parse(File.read(path))
          rescue JSON::ParserError
            raise Error, "corrupt round history at #{path}"
          end
          raise Error, "corrupt round history at #{path}: expected an array, got #{parsed.class}" unless parsed.is_a?(Array)

          parsed.each_with_index do |element, index|
            element_errors = Atoms::RoundRecordSchema.errors(element)
            unless element_errors.empty?
              raise Error, "corrupt round history at #{path}: record #{index}: #{element_errors.join('; ')}"
            end
          end
          parsed
        end

        def validated(assignment_id)
          id = assignment_id.to_s
          unless id.match?(/\A[\w.-]+\z/) && !id.match?(/\A\.+\z/)
            raise Error, "invalid assignment id '#{id}'"
          end

          id
        end
      end
    end
  end
end
