# frozen_string_literal: true

require "test_helper"

module Providers
  # The Base contract is the core boundary: it must never execute provider
  # commands itself, and every contract method demands a real implementation.
  class BaseTest < AceGitTestCase
    def setup
      super
      @server = Ace::Git::ResolvedServer.new(name: "s", provider: :fakeforge, url: "https://s.example.com")
      @base = Ace::Git::Providers::Base.new(server: @server)
    end

    def test_holds_server_identity_and_default_timeout
      assert_equal @server, @base.server
      assert_equal Ace::Git.network_timeout, @base.timeout
    end

    def test_timeout_override
      base = Ace::Git::Providers::Base.new(server: @server, timeout: 5)
      assert_equal 5, base.timeout
    end

    def test_contract_methods_are_abstract
      methods = {
        available?: {},
        check_available!: {},
        authenticated?: {},
        check_authenticated!: {},
        pull_request: {number: 1},
        pull_request_for_branch: {branch: "main"},
        pull_request_diff: {number: 1},
        recent_pull_requests: {limit: 5},
        issue: {number: 1},
        checks: {ref: "main"},
        repository: {}
      }

      methods.each do |method_name, kwargs|
        error = assert_raises(NotImplementedError, "#{method_name} must be abstract") do
          if kwargs.empty?
            @base.public_send(method_name)
          else
            @base.public_send(method_name, **kwargs)
          end
        end
        assert_match(/must implement/, error.message)
      end
    end
  end
end
