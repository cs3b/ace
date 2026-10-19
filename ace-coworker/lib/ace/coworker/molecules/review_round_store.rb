# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "../atoms/round_rule"

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
        def read(assignment_id)
          path = state_path(assignment_id)
          return [] unless File.file?(path)

          parsed = JSON.parse(File.read(path))
          parsed.is_a?(Array) ? parsed : []
        rescue JSON::ParserError
          []
        end

        # Persist the full round list atomically.
        def write(assignment_id, records)
          path = state_path(assignment_id)
          FileUtils.mkdir_p(File.dirname(path))
          tmp_path = "#{path}.tmp.#{Process.pid}"
          File.write(tmp_path, JSON.pretty_generate(records))
          File.rename(tmp_path, path)
          path
        end

        # Record one round and return the resulting rule verdict, so a
        # resumed reviewer process reconstructs counters from the same
        # file: `store.record!(id, round)` => RoundRule verdict hash.
        def record!(assignment_id, record)
          records = read(assignment_id) + [record]
          write(assignment_id, records)
          Atoms::RoundRule.evaluate(records)
        end

        private

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
