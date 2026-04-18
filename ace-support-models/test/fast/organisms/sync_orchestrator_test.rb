# frozen_string_literal: true

require_relative "../../test_helper"

class SyncOrchestratorTest < AceModelsTestCase
  SyncOrchestrator = Ace::Support::Models::Organisms::SyncOrchestrator

  def test_sync_returns_stats_for_string_keyed_provider_payloads
    cache_manager = Minitest::Mock.new
    payload = {
      "anthropic" => {"models" => {"claude-4-sonnet" => {}, "claude-4-opus" => {}}},
      "openai" => {"models" => {"gpt-5" => {}}}
    }

    cache_manager.expect(:fresh?, false) { |max_age:| max_age == SyncOrchestrator::DEFAULT_CACHE_MAX_AGE }
    cache_manager.expect :write, nil, [payload]

    result = with_stubbed_sync_dependencies(payload: payload) do
      SyncOrchestrator.new(cache_manager: cache_manager).sync
    end

    assert_equal :success, result[:status]
    assert_equal 2, result[:stats][:provider_count]
    assert_equal 3, result[:stats][:model_count]
    assert_equal({"anthropic" => 2, "openai" => 1}, result[:stats][:top_providers])
    cache_manager.verify
  end

  def test_status_tolerates_empty_provider_entries
    cache_manager = Minitest::Mock.new
    payload = {
      "anthropic" => {},
      "openai" => {"models" => {"gpt-5" => {}}}
    }

    cache_manager.expect :exists?, true
    cache_manager.expect :read, payload
    cache_manager.expect :fresh?, true
    cache_manager.expect :last_sync_at, Time.utc(2026, 4, 16)

    result = SyncOrchestrator.new(cache_manager: cache_manager).status

    assert_equal true, result[:cached]
    assert_equal 2, result[:stats][:provider_count]
    assert_equal 1, result[:stats][:model_count]
    assert_equal({"openai" => 1, "anthropic" => 0}, result[:stats][:top_providers])
    cache_manager.verify
  end

  private

  def with_stubbed_sync_dependencies(payload:)
    api_fetcher = Ace::Support::Models::Atoms::ApiFetcher
    json_parser = Ace::Support::Models::Atoms::JsonParser

    api_fetcher.stub(:fetch, "{}") do
      json_parser.stub(:parse, payload) do
        yield
      end
    end
  end
end
