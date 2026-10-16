# frozen_string_literal: true

require_relative "../test_helper"
require "json"
require "open3"
require "socket"
require "uri"

module Ace
  module Lab
    module Molecules
      # The Forgejo merge adapter against the REAL lab forge (spec
      # 8x3.t.xz9.5 integration handoff). The forge HTTP layer is never
      # mocked: when a scoped test token is provided via
      # ACE_LAB_TEST_FORGE_TOKEN, the suite provisions a scratch repository
      # through the forge API, drives a real branch/PR through the
      # fast-forward-only merge invocation, proves the readback (merged flag
      # + merge sha) and the refusal path, and removes the scratch
      # repository. Without the token the suite skips with a clear message —
      # deployed acceptance runs later against the provisioned host config.
      class ForgejoMergeAdapterTest < Minitest::Test
        BASE_URL = ENV.fetch("ACE_LAB_TEST_FORGE_URL", "https://forgejo.tail6c0887.ts.net")

        def setup
          @token = ENV["ACE_LAB_TEST_FORGE_TOKEN"]
          unless @token
            skip "ACE_LAB_TEST_FORGE_TOKEN is not set — adapter acceptance needs a " \
              "scoped token against #{BASE_URL} (deployed acceptance happens later " \
              "against the provisioned /etc/lab/ace-lab/forge-merge.yml)"
          end
          @adapter = ForgejoMergeAdapter.new(base_url: BASE_URL, token: @token,
            timeout_seconds: 30)
          @scratch = nil
        end

        def teardown
          drop_scratch_repo if @scratch
        end

        def test_merge_invocation_readback_and_refusal_path_on_a_real_pull_request
          provision_scratch_repo
          head = push_branch_commit
          index = open_pull_request(head)

          readback = @adapter.pull_request(owner: @owner, repo: @repo, index: index)
          assert_equal false, readback.fetch("merged")
          assert_equal head, readback.dig("head", "sha")
          assert_equal @initial_head, readback.dig("base", "sha")

          # The one authorized comment scope: the independent review body.
          comment = @adapter.create_comment(owner: @owner, repo: @repo, index: index,
            body: "Independent final-head review evidence (test scratch PR)")
          assert_equal :invoked, comment.outcome, comment.reason

          result = @adapter.merge_pull_request!(owner: @owner, repo: @repo, index: index)
          assert_equal :invoked, result.outcome, result.reason

          readback = @adapter.pull_request(owner: @owner, repo: @repo, index: index)
          assert_equal true, readback.fetch("merged")
          # Fast-forward-only: the merge sha IS the merged candidate head.
          assert_equal head, readback.fetch("merge_commit_sha")

          # Failure path: a second merge invocation is definitively refused.
          refused = @adapter.merge_pull_request!(owner: @owner, repo: @repo, index: index)
          assert_equal :refused, refused.outcome
          assert refused.status >= 400 && refused.status < 500
          assert refused.reason && !refused.reason.empty?
        end

        def test_pull_request_readback_of_an_absent_pull_request_is_definitive_nil
          provision_scratch_repo
          assert_nil @adapter.pull_request(owner: @owner, repo: @repo, index: 9_999_999)
        end

        def test_unauthorized_token_surfaces_as_a_definitive_refusal
          anonymous = ForgejoMergeAdapter.new(base_url: BASE_URL, token: "invalid-token",
            timeout_seconds: 30)
          provision_scratch_repo
          result = anonymous.create_comment(owner: @owner, repo: @repo, index: 1,
            body: "must not land")
          assert_equal :refused, result.outcome
          assert_equal 401, result.status
          refute_includes result.reason, "invalid-token"
        end

        # ---- scratch repository provisioning (forge API only) --------------

        private

        def provision_scratch_repo
          login = forge_json(:get, "/api/v1/user").fetch("login")
          @owner = login
          @repo = "ace-lab-adapter-scratch-#{Process.pid}-#{Time.now.to_i}"
          @scratch = forge_json(:post, "/api/v1/user/repos",
            body: {"name" => @repo, "auto_init" => true, "private" => true,
                   "default_branch" => "main"})
          @initial_head = forge_json(:get,
            "/api/v1/repos/#{@owner}/#{@repo}/branches/main").dig("commit", "id")
        end

        def push_branch_commit
          forge_json(:post, "/api/v1/repos/#{@owner}/#{@repo}/branches",
            body: {"new_branch_name" => "feat/adapter"})
          # One content commit on the branch → a real one-ahead fast-forward.
          document = forge_json(:post,
            "/api/v1/repos/#{@owner}/#{@repo}/contents/adapter-#{Time.now.to_i}.txt",
            body: {"content" => [Time.now.utc.iso8601].pack("m0"),
                   "branch" => "feat/adapter"})
          document.dig("commit", "sha")
        end

        def open_pull_request(head)
          pull = forge_json(:post, "/api/v1/repos/#{@owner}/#{@repo}/pulls",
            body: {"title" => "adapter acceptance scratch PR", "head" => "feat/adapter",
                   "base" => "main"})
          assert_equal head, pull.dig("head", "sha")
          pull.fetch("number")
        end

        def drop_scratch_repo
          forge(:delete, "/api/v1/repos/#{@owner}/#{@repo}")
        rescue
          nil
        end

        def forge_json(method, path, body: nil)
          JSON.parse(forge(method, path, body: body))
        end

        def forge(method, path, body: nil)
          uri = URI.parse("#{BASE_URL}#{path}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.is_a?(URI::HTTPS)
          http.open_timeout = 10
          http.read_timeout = 30
          message = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri)
          message["Authorization"] = "token #{@token}"
          message["Content-Type"] = "application/json"
          message.body = JSON.generate(body) if body
          response = http.start { |session| session.request(message) }
          raise "forge #{method} #{path} failed: HTTP #{response.code}" unless
            response.is_a?(Net::HTTPSuccess) || method == :delete
          response.body.to_s
        end
      end

      # The adapter's WIRE CONTRACT against a real loopback HTTP server
      # (hermetic — no forge token needed): the forge HTTP layer is still
      # never mocked. The adapter performs genuine Net::HTTP exchanges with
      # a stdlib TCPServer bound on 127.0.0.1, so the exact outgoing merge
      # payload and the closed refusal classification are proven over real
      # HTTP wire semantics.
      class ForgejoMergeAdapterBindingTest < Minitest::Test
        CANDIDATE = "a" * 40
        MOVED_HEAD = "c" * 40

        def setup
          @server = LoopbackForgeServer.new
          @adapter = ForgejoMergeAdapter.new(
            base_url: "http://127.0.0.1:#{@server.port}", token: "binding-test-token",
            timeout_seconds: 5
          )
        end

        def teardown
          @server.stop
        end

        # The outgoing merge POST carries EXACTLY the merge method plus the
        # bound candidate head — `{"Do":"fast-forward-only","head_commit_id":
        # "<candidate>"}` — the payload the real forge enforces server-side.
        def test_merge_post_carries_exactly_the_head_bound_payload
          @server.enqueue(200)
          result = @adapter.merge_pull_request!(owner: "acme", repo: "widget",
            index: 7, head_commit_id: CANDIDATE)
          assert_equal :invoked, result.outcome
          request = @server.requests.first
          assert_equal "POST", request.method
          assert_equal "/api/v1/repos/acme/widget/pulls/7/merge", request.path
          assert_equal "{\"Do\":\"fast-forward-only\",\"head_commit_id\":\"#{CANDIDATE}\"}",
            request.body
        end

        # Race regression: the state readback (GET) still reports the
        # reviewed candidate as the PR head, but by the time the merge POST
        # arrives the head has moved. The forge's server-side exact-head
        # binding definitively refuses the stale binding (4xx) — outcome
        # :refused, no effect, never a false success merging an unreviewed
        # head, and never a re-dispatch (exactly the two wire exchanges).
        def test_head_moved_between_readback_and_merge_post_refuses_the_stale_binding
          @server.enqueue(200, JSON.generate(
            "merged" => false, "merge_commit_sha" => nil,
            "head" => {"sha" => CANDIDATE}, "base" => {"sha" => MOVED_HEAD}
          ))
          @server.enqueue(409,
            JSON.generate("message" => "head_commit_id does not match the pull request head"))
          readback = @adapter.pull_request(owner: "acme", repo: "widget", index: 7)
          assert_equal CANDIDATE, readback.dig("head", "sha")
          result = @adapter.merge_pull_request!(owner: "acme", repo: "widget",
            index: 7, head_commit_id: CANDIDATE)
          assert_equal :refused, result.outcome
          assert_equal 409, result.status
          assert_includes result.reason, "head_commit_id does not match"
          assert_equal 2, @server.requests.size
          assert_equal "GET", @server.requests[0].method
          assert_equal "POST", @server.requests[1].method
          assert_equal "{\"Do\":\"fast-forward-only\",\"head_commit_id\":\"#{CANDIDATE}\"}",
            @server.requests[1].body
        end

        # The binding is required and validated before anything touches the
        # wire: a missing, truncated, or non-lowercase-hex head never reaches
        # the forge.
        def test_merge_without_a_valid_full_sha_binding_never_reaches_the_wire
          assert_raises(ArgumentError) do
            @adapter.merge_pull_request!(owner: "acme", repo: "widget", index: 7)
          end
          assert_raises(ArgumentError) do
            @adapter.merge_pull_request!(owner: "acme", repo: "widget", index: 7,
              head_commit_id: "abc123")
          end
          assert_raises(ArgumentError) do
            @adapter.merge_pull_request!(owner: "acme", repo: "widget", index: 7,
              head_commit_id: CANDIDATE.upcase)
          end
          assert_empty @server.requests
        end
      end

      # A minimal but REAL HTTP/1.1 server on the loopback (stdlib TCPServer
      # only): each accepted connection is one wire exchange — the request
      # line, headers, and body are captured verbatim and one queued canned
      # response is written back. This is transport, not a mock: the adapter
      # runs its genuine Net::HTTP stack against it.
      class LoopbackForgeServer
        Request = Struct.new(:method, :path, :body)

        REASONS = {200 => "OK", 401 => "Unauthorized", 404 => "Not Found",
                   409 => "Conflict", 500 => "Internal Server Error"}.freeze

        attr_reader :port, :requests

        def initialize
          @listener = TCPServer.new("127.0.0.1", 0)
          @port = @listener.addr[1]
          @requests = []
          @responses = Queue.new
          @thread = Thread.new do
            while (session = @listener.accept)
              serve_one(session)
            end
          rescue IOError, Errno::EBADF
            nil # listener closed: server shutdown
          end
        end

        # Queue one canned HTTP response for the next accepted connection.
        def enqueue(status, body = "{}")
          @responses << [status, body]
        end

        def stop
          @listener.close unless @listener.closed?
          @thread.join
        end

        private

        def serve_one(session)
          request_line = session.gets
          headers = {}
          while (line = session.gets) && line != "\r\n"
            name, value = line.split(":", 2)
            headers[name.strip.downcase] = value.to_s.strip
          end
          body = session.read(headers["content-length"].to_i) if headers["content-length"]
          @requests << Request.new(method: request_line.split(" ").first,
            path: request_line.split(" ")[1], body: body)
          status, response_body = @responses.shift
          session.write("HTTP/1.1 #{status} #{REASONS.fetch(status)}\r\n" \
            "Content-Type: application/json\r\n" \
            "Content-Length: #{response_body.bytesize}\r\n" \
            "Connection: close\r\n\r\n#{response_body}")
          session.close
        end
      end
    end
  end
end
