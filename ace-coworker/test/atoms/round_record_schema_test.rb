# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class RoundRecordSchemaTest < AceCoworkerTestCase
        def valid
          {"type" => "full", "status" => "completed",
           "confirmed" => [{"id" => "f-1", "severity" => "high"}], "resolved" => ["f-2"]}
        end

        def test_valid_record_has_no_errors
          assert_empty RoundRecordSchema.errors(valid)
        end

        def test_non_hash_record_is_rejected
          errors = RoundRecordSchema.errors(["f-1"])
          assert_equal 1, errors.length
          assert_match(/must be a Hash/, errors.first)
        end

        def test_symbol_keyed_record_is_rejected
          errors = RoundRecordSchema.errors({type: "full", status: "completed",
                                             confirmed: [], resolved: []})
          assert_equal 1, errors.length
          assert_match(/keys must be strings/, errors.first)
        end

        def test_invalid_type_and_status
          errors = RoundRecordSchema.errors(valid.merge("type" => "partial", "status" => "skipped"))
          assert_includes errors, "'type' must be one of: full, delta"
          assert_includes errors, "'status' must be one of: completed, aborted"
        end

        def test_confirmed_as_single_hash_is_rejected
          errors = RoundRecordSchema.errors(valid.merge("confirmed" => {"id" => "f-1", "severity" => "high"}))
          assert_equal 1, errors.length
          assert_match(/'confirmed' must be an array/, errors.first)
        end

        def test_confirmed_entry_without_id_or_severity
          errors = RoundRecordSchema.errors(valid.merge("confirmed" => [{"id" => "f-1"}]))
          assert_equal 1, errors.length
          assert_match(/'confirmed\[0\]' must have non-empty string 'id' and 'severity'/, errors.first)
        end

        def test_confirmed_non_hash_entry
          errors = RoundRecordSchema.errors(valid.merge("confirmed" => ["f-1"]))
          assert_equal 1, errors.length
          assert_match(/'confirmed\[0\]' must be a Hash, got String/, errors.first)
        end

        def test_resolved_non_string_entry
          errors = RoundRecordSchema.errors(valid.merge("resolved" => [42]))
          assert_equal 1, errors.length
          assert_match(/'resolved\[0\]' must be a non-empty string/, errors.first)
        end
      end
    end
  end
end
