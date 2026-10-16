# frozen_string_literal: true

require_relative "../atoms/git_blob_batch"

module Ace
  module Assign
    module Authority
      # Same cat-file batch dialect/codec as the canonical journal. Chunked
      # bodies avoid retaining the entire expanded tree a second time.
      module CandidateBlobBatch
        BATCH_BYTES = 8 * 1024 * 1024
        BATCH_OBJECTS = 512
        MAX_OBJECTS = 20_000

        private

        def candidate_blob_sizes(repository, deadline, oids)
          unless oids.is_a?(Array) && oids.size <= MAX_OBJECTS &&
              oids.all? { |oid| oid.is_a?(String) && self.class::SHA.match?(oid) }
            reject!("Candidate blob inventory is invalid or oversized")
          end
          oids.each_slice(64).flat_map do |slice|
            raw = git(repository, deadline, "cat-file", "--batch-check", stdin_data: slice.join("\n") + "\n", limit: slice.size * 128)
            Atoms::GitBlobBatch.sizes(slice, raw)
          end
        rescue Atoms::GitBlobBatch::Invalid => error
          reject!("Candidate blob batch #{error.reason} differs")
        end

        def each_candidate_blob(repository, deadline, entries)
          batch = []
          bytes = 0
          entries.each do |entry|
            if !batch.empty? && (batch.size >= BATCH_OBJECTS || bytes + entry.last > BATCH_BYTES)
              yield_candidate_blob_batch(repository, deadline, batch) { |oid, content| yield oid, content }
              batch = []
              bytes = 0
            end
            batch << entry
            bytes += entry.last
          end
          yield_candidate_blob_batch(repository, deadline, batch) { |oid, content| yield oid, content } unless batch.empty?
        end

        def yield_candidate_blob_batch(repository, deadline, entries)
          limit = entries.sum { |_oid, size| size + 128 }
          raw = git(repository, deadline, "cat-file", "--batch", stdin_data: entries.map { |oid, _size| "#{oid}\n" }.join, limit: limit)
          Atoms::GitBlobBatch.decode(entries, raw).zip(entries).each { |content, (oid, _size)| yield oid, content }
        rescue Atoms::GitBlobBatch::Invalid => error
          reject!("Candidate blob batch #{error.reason} differs")
        end
      end
    end
  end
end
