# frozen_string_literal: true

require "test_helper"

module Forgejo
  # Transport behaviors of the repository-bound API client beyond the
  # endpoint-specific molecule tests.
  class HttpClientTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :forgejo, url: "https://forge.example.com/owner/repo")

    def build_client(runner)
      Ace::Git::Forgejo::HttpClient.new(server: SERVER, timeout: 5, runner: runner)
    end

    def test_request_keeps_the_shared_taxonomy
      client = build_client(route(status: 409, body: {"message" => "conflict"}.to_json))
      assert_raises(Ace::Git::ProviderIdentityMismatchError) { client.request(:post, "labels", body: {}) }

      client = build_client(route(status: 404, body: ""))
      assert_raises(Ace::Git::ProviderObjectNotFoundError) { client.request(:get, "labels") }

      client = build_client(route(status: 503, body: ""))
      assert_raises(Ace::Git::ProviderUnreachableError) { client.request(:get, "labels") }

      client = build_client(route(status: 503, body: ""))
      assert_raises(Ace::Git::ProviderUnknownOutcomeError) { client.request(:post, "labels", body: {}) }
    end

    def test_transport_failure_classifies_by_method
      client = build_client(->(args:, **) { raise SocketError, "closed" })
      assert_raises(Ace::Git::ProviderUnreachableError) { client.request(:get, "pulls/1") }

      client = build_client(->(args:, **) { raise Faraday::TimeoutError, "timed out" })
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) { client.request(:post, "pulls", body: {}) }
      assert_match(/outcome unknown/, error.message)
    end

    def test_exchange_surveys_status_body_and_message
      client = build_client(route(status: 409, body: {"message" => "Merge: head out of date"}.to_json))
      status, payload, message = client.exchange(:post, "pulls/25/merge", body: {Do: "merge"})
      assert_equal 409, status
      assert_equal({"message" => "Merge: head out of date"}, payload)
      assert_equal "Merge: head out of date", message
    end

    def test_exchange_truncates_oversized_server_messages
      client = build_client(route(status: 422, body: {"message" => "x" * 500}.to_json))
      _, _, message = client.exchange(:post, "pulls", body: {})
      assert_equal 300, message.length
    end

    def test_exchange_hides_non_json_server_bodies
      client = build_client(route(status: 502, body: "<html>bad gateway</html>"))
      status, payload, message = client.exchange(:get, "pulls")
      assert_equal 502, status
      assert_nil payload
      assert_nil message
    end

    def test_repository_scoping_and_absolute_routes
      seen = []
      client = build_client(->(args:, **) { seen << args; route(status: 200, body: "[]").call(args: args) })
      client.request(:get, "labels")
      assert_equal "https://forge.example.com/api/v1/repos/owner/repo/labels", seen.last[2]

      client.request(:get, "/api/v1/version")
      assert_equal "https://forge.example.com/api/v1/version", seen.last[2]
    end

    def test_empty_success_body_parses_as_nil
      client = build_client(route(status: 200, body: ""))
      assert_nil client.request(:patch, "pulls/25", body: {title: "T"})
    end

    private

    def route(status:, body:)
      ->(args:, **) { {success: (200..299).cover?(status), status: status, stdout: body, stderr: "", exit_code: (200..299).cover?(status) ? 0 : 1} }
    end
  end
end
