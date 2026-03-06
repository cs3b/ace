# frozen_string_literal: true

require "test_helper"

module Ace
  module Review
    module Atoms
      class ReviewerRunKeyAllocatorTest < AceReviewTest
        def test_allocate_keeps_unique_base_keys_unsuffixed
          reviewers = [
            Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash"),
            Models::Reviewer.new(name: "tests", model: "google:gemini-2.5-flash")
          ]

          lanes = ReviewerRunKeyAllocator.allocate(reviewers)

          assert_equal 2, lanes.size
          assert_equal "correctness:google-gemini-2-5-flash", lanes[0][:run_key]
          assert_equal "tests:google-gemini-2-5-flash", lanes[1][:run_key]
        end

        def test_allocate_adds_deterministic_suffixes_for_duplicate_base_keys
          reviewers = [
            Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash"),
            Models::Reviewer.new(name: "correctness", model: "google:gemini-2.5-flash")
          ]

          first = ReviewerRunKeyAllocator.allocate(reviewers)
          second = ReviewerRunKeyAllocator.allocate(reviewers)

          assert_equal first.map { |lane| lane[:run_key] }, second.map { |lane| lane[:run_key] }
          assert_equal 2, first.map { |lane| lane[:run_key] }.uniq.size
          assert_match(/\Acorrectness:google-gemini-2-5-flash:/, first[0][:run_key])
          assert_match(/\Acorrectness:google-gemini-2-5-flash:/, first[1][:run_key])
        end
      end
    end
  end
end
