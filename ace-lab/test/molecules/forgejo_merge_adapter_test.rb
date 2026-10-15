# frozen_string_literal: true

require_relative "../test_helper"
require "json"
require "open3"
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
    end
  end
end
