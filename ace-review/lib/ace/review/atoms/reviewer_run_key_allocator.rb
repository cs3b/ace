# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Review
    module Atoms
      # Allocates stable reviewer run keys for a single review execution.
      #
      # Reviewer names are normally sufficient to distinguish lanes, but duplicate
      # reviewer identities can still occur through composition or overrides.
      # In that case, duplicate base keys receive deterministic Base36 suffixes so
      # prompt files, outputs, and feedback provenance remain unique and stable.
      class ReviewerRunKeyAllocator
        FIXED_SEQUENCE_ORIGIN = Time.utc(2025, 1, 1).freeze
        DEFAULT_REVIEWER_NAME = "reviewer"

        def self.allocate(reviewers)
          reviewers = Array(reviewers).compact
          return [] if reviewers.empty?

          base_keys = reviewers.map { |reviewer| base_key(reviewer) }
          counts = base_keys.each_with_object(Hash.new(0)) { |key, index| index[key] += 1 }
          suffixes = duplicate_suffixes(counts)
          seen = Hash.new(0)

          reviewers.map do |reviewer|
            base = base_key(reviewer)
            duplicate_index = seen[base]
            seen[base] += 1

            run_key = if counts[base] > 1
                        "#{base}:#{suffixes.fetch(base).fetch(duplicate_index)}"
                      else
                        base
                      end

            {
              reviewer: reviewer,
              base_key: base,
              run_key: run_key,
              model: reviewer_model(reviewer)
            }
          end
        end

        def self.base_key(reviewer)
          lane_id = reviewer_lane_id(reviewer)
          return lane_id unless lane_id.to_s.strip.empty?

          "#{reviewer_name(reviewer)}:#{SlugGenerator.generate(reviewer_model(reviewer))}"
        end

        def self.reviewer_name(reviewer)
          name = if reviewer.respond_to?(:name)
                   reviewer.name
                 elsif reviewer.is_a?(Hash)
                   reviewer[:name] || reviewer["name"]
                 end

          name = name.to_s.strip
          name.empty? ? DEFAULT_REVIEWER_NAME : name
        end

        def self.reviewer_model(reviewer)
          if reviewer.respond_to?(:model)
            reviewer.model
          elsif reviewer.is_a?(Hash)
            reviewer[:model] || reviewer["model"]
          end
        end

        def self.reviewer_lane_id(reviewer)
          if reviewer.respond_to?(:lane_id)
            reviewer.lane_id
          elsif reviewer.is_a?(Hash)
            reviewer[:lane_id] || reviewer["lane_id"]
          end
        end

        def self.duplicate_suffixes(counts)
          counts.each_with_object({}) do |(base_key, count), index|
            next if count <= 1

            index[base_key] = Ace::B36ts::Atoms::CompactIdEncoder.encode_sequence(
              FIXED_SEQUENCE_ORIGIN,
              count: count,
              format: :ms
            )
          end
        end

        private_class_method :duplicate_suffixes
      end
    end
  end
end
