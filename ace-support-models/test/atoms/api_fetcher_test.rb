# frozen_string_literal: true

require_relative "../test_helper"
require "faraday"

class ApiFetcherTest < AceModelsTestCase
  def setup
    # Store original connection for cleanup
    @original_connection = nil
  end

  def teardown
    # Reset connection to allow fresh connections in next test
    Ace::Support::Models::Atoms::ApiFetcher.instance_variable_set(:@connection, nil)
  end

  def test_fetch_success
    stub_request_with_response(200, '{"test": "data"}')

    result = Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    assert_equal '{"test": "data"}', result
  end

  def test_fetch_raises_api_error_on_404
    stub_request_with_response(404, "Not Found")

    error = assert_raises(Ace::Support::Models::ApiError) do
      Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    end

    assert_match(/404/, error.message)
    assert_equal 404, error.status_code
  end

  def test_fetch_raises_api_error_on_500
    stub_request_with_response(500, "Internal Server Error")

    error = assert_raises(Ace::Support::Models::ApiError) do
      Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    end

    assert_match(/500/, error.message)
  end

  def test_fetch_raises_network_error_on_timeout
    stub_connection = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get("http://test.example/api.json") do
          raise Faraday::TimeoutError, "Connection timed out"
        end
      end
    end
    stub_connection_singleton(stub_connection)

    error = assert_raises(Ace::Support::Models::NetworkError) do
      Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    end

    assert_match(/timed out/i, error.message)
  end

  def test_fetch_raises_network_error_on_connection_failed
    stub_connection = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get("http://test.example/api.json") do
          raise Faraday::ConnectionFailed, "Connection refused"
        end
      end
    end
    stub_connection_singleton(stub_connection)

    error = assert_raises(Ace::Support::Models::NetworkError) do
      Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    end

    assert_match(/Connection failed/i, error.message)
  end

  def test_fetch_raises_network_error_on_ssl_error
    stub_connection = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get("http://test.example/api.json") do
          raise Faraday::SSLError, "SSL certificate verify failed"
        end
      end
    end
    stub_connection_singleton(stub_connection)

    error = assert_raises(Ace::Support::Models::NetworkError) do
      Ace::Support::Models::Atoms::ApiFetcher.fetch("http://test.example/api.json")
    end

    assert_match(/SSL/i, error.message)
  end

  def test_api_url_constant
    assert_equal "https://models.dev/api.json",
      Ace::Support::Models::Atoms::ApiFetcher::API_URL
  end

  def test_timeout_constant
    assert_equal 30, Ace::Support::Models::Atoms::ApiFetcher::TIMEOUT
  end

  def test_max_retries_constant
    assert_equal 2, Ace::Support::Models::Atoms::ApiFetcher::MAX_RETRIES
  end

  private

  def stub_request_with_response(status, body)
    stub_connection = Faraday.new do |f|
      f.adapter :test do |stub|
        stub.get("http://test.example/api.json") do
          [status, {"Content-Type" => "application/json"}, body]
        end
      end
    end
    stub_connection_singleton(stub_connection)
  end

  def stub_connection_singleton(connection)
    Ace::Support::Models::Atoms::ApiFetcher.instance_variable_set(:@connection, connection)
  end
end
