# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::ValidatorChainTest < Minitest::Test
  # Helper to stub both runners' availability and linting
  def stub_runners(standardrb: {available: true, result: nil}, rubocop: {available: true, result: nil})
    # Reset caches before stubbing so stubs are called (not cached results)
    Ace::Lint::Atoms::StandardrbRunner.reset_availability_cache!
    Ace::Lint::Atoms::RuboCopRunner.reset_availability_cache!
    Ace::Lint::Atoms::ValidatorRegistry.reset_cache!

    # Stub availability checks for both runners
    Ace::Lint::Atoms::StandardrbRunner.stub(:system_has_command?, standardrb[:available]) do
      Ace::Lint::Atoms::RuboCopRunner.stub(:system_has_command?, rubocop[:available]) do
        # Stub Open3.capture3 for actual linting commands
        Open3.stub(:capture3, ->(*args) {
          if args.first == "standardrb"
            result = standardrb[:result] || {success: true, errors: [], warnings: []}
            mock_status = Object.new
            mock_status.define_singleton_method(:success?) { result[:success] }
            mock_status.define_singleton_method(:exitstatus) { result[:success] ? 0 : 1 }
            [result.to_json, "", mock_status]
          elsif args.first == "rubocop"
            result = rubocop[:result] || {success: true, errors: [], warnings: []}
            mock_status = Object.new
            mock_status.define_singleton_method(:success?) { result[:success] }
            mock_status.define_singleton_method(:exitstatus) { result[:success] ? 0 : 1 }
            [result.to_json, "", mock_status]
          else
            mock_fail = Object.new
            mock_fail.define_singleton_method(:success?) { false }
            mock_fail.define_singleton_method(:exitstatus) { 1 }
            ["", "", mock_fail]
          end
        }) do
          # Pre-populate both caches with stub values so subsequent tests hit cache
          Ace::Lint::Atoms::StandardrbRunner.available?
          Ace::Lint::Atoms::RuboCopRunner.available?
          yield
        end
      end
    end
  end

  def test_run_with_single_validator
    stub_runners(standardrb: {available: true}) do
      chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb])
      result = chain.run(["test.rb"])

      assert result[:success]
      assert_includes result[:runners], :standardrb
    end
  end

  def test_run_with_multiple_validators
    stub_runners(
      standardrb: {available: true},
      rubocop: {available: true}
    ) do
      chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb, :rubocop])
      result = chain.run(["test.rb"])

      assert result[:success]
      assert_equal [:standardrb, :rubocop], result[:runners]
    end
  end

  def test_run_skips_unavailable_validators
    stub_runners(
      standardrb: {available: false},
      rubocop: {available: true}
    ) do
      chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb, :rubocop])
      result = chain.run(["test.rb"])

      assert result[:success]
      assert_equal [:rubocop], result[:runners]
      assert chain.warnings.any? { |w| w.include?("standardrb") && w.include?("not available") }
    end
  end

  def test_run_uses_fallback_when_primary_unavailable
    stub_runners(
      standardrb: {available: false},
      rubocop: {available: true}
    ) do
      chain = Ace::Lint::Molecules::ValidatorChain.new(
        [:standardrb],
        fallback_validators: [:rubocop]
      )
      result = chain.run(["test.rb"])

      assert result[:success]
      assert_equal [:rubocop], result[:runners]
      assert chain.warnings.any? { |w| w.include?("fallback") }
    end
  end

  def test_run_returns_unavailable_when_no_validators
    stub_runners(
      standardrb: {available: false},
      rubocop: {available: false}
    ) do
      chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb])
      result = chain.run(["test.rb"])

      refute result[:success]
      assert result[:errors].any? { |e| e[:message].include?("No validators available") }
    end
  end

  def test_run_returns_empty_result_for_empty_files
    chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb])
    result = chain.run([])

    assert result[:success]
    assert_empty result[:errors]
    assert_empty result[:warnings]
    assert_empty result[:runners]
  end

  def test_deduplication_by_line_column_message
    # Simulate two validators reporting the same issue
    standardrb_result = {
      "files" => [{
        "path" => "test.rb",
        "offenses" => [{
          "severity" => "convention",
          "message" => "Missing frozen string literal",
          "cop_name" => "Style/FrozenStringLiteralComment",
          "location" => {"line" => 1, "column" => 0}
        }]
      }]
    }

    rubocop_result = {
      "files" => [{
        "path" => "test.rb",
        "offenses" => [{
          "severity" => "convention",
          "message" => "Missing frozen string literal",
          "cop_name" => "Style/FrozenStringLiteralComment",
          "location" => {"line" => 1, "column" => 0}
        }]
      }]
    }

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }
    mock_status.define_singleton_method(:exitstatus) { 1 }

    call_count = {standardrb: 0, rubocop: 0}

    # Stub availability for both runners
    Ace::Lint::Atoms::StandardrbRunner.stub(:system_has_command?, true) do
      Ace::Lint::Atoms::RuboCopRunner.stub(:system_has_command?, true) do
        Open3.stub(:capture3, ->(*args) {
          if args.first == "standardrb"
            call_count[:standardrb] += 1
            [standardrb_result.to_json, "", mock_status]
          elsif args.first == "rubocop"
            call_count[:rubocop] += 1
            [rubocop_result.to_json, "", mock_status]
          end
        }) do
          chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb, :rubocop])
          result = chain.run(["test.rb"])

          # Should have only 1 warning (deduplicated)
          assert_equal 1, result[:warnings].size
        end
      end
    end
  end

  def test_aggregates_different_issues
    standardrb_result = {
      "files" => [{
        "path" => "test.rb",
        "offenses" => [{
          "severity" => "convention",
          "message" => "Issue from StandardRB",
          "cop_name" => "Style/One",
          "location" => {"line" => 1, "column" => 0}
        }]
      }]
    }

    rubocop_result = {
      "files" => [{
        "path" => "test.rb",
        "offenses" => [{
          "severity" => "convention",
          "message" => "Different issue from RuboCop",
          "cop_name" => "Style/Two",
          "location" => {"line" => 5, "column" => 0}
        }]
      }]
    }

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { false }
    mock_status.define_singleton_method(:exitstatus) { 1 }

    # Reset caches before stubbing so stubs are called (not cached results)
    Ace::Lint::Atoms::StandardrbRunner.reset_availability_cache!
    Ace::Lint::Atoms::RuboCopRunner.reset_availability_cache!
    Ace::Lint::Atoms::ValidatorRegistry.reset_cache!

    # Stub availability for both runners
    Ace::Lint::Atoms::StandardrbRunner.stub(:system_has_command?, true) do
      Ace::Lint::Atoms::RuboCopRunner.stub(:system_has_command?, true) do
        Open3.stub(:capture3, ->(*args) {
          if args.first == "standardrb"
            [standardrb_result.to_json, "", mock_status]
          elsif args.first == "rubocop"
            [rubocop_result.to_json, "", mock_status]
          end
        }) do
          # Pre-populate both caches with stub values so subsequent tests hit cache
          Ace::Lint::Atoms::StandardrbRunner.available?
          Ace::Lint::Atoms::RuboCopRunner.available?

          chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb, :rubocop])
          result = chain.run(["test.rb"])

          # Should have both warnings (different issues)
          assert_equal 2, result[:warnings].size
        end
      end
    end
  end

  def test_chain_warnings_included_in_result
    stub_runners(standardrb: {available: false}, rubocop: {available: true}) do
      chain = Ace::Lint::Molecules::ValidatorChain.new([:standardrb], fallback_validators: [:rubocop])
      result = chain.run(["test.rb"])

      assert result[:chain_warnings].any?
    end
  end
end
