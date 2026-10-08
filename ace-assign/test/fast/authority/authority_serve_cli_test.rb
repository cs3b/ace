# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/cli/commands/authority/serve"

module Ace
  module Assign
    class AuthorityServeCliTest < AceAssignTestCase
      def test_cli_constructs_the_installed_owner_without_an_app_server_attachment
        deployment, history, launch, router = Array.new(4) { Object.new }
        calls = []
        server = Object.new
        server.define_singleton_method(:serve) { calls << :served }
        Authority::Deployment.stub(:load, deployment) do
          Authority::DeploymentHistory.stub(:load, history) do
            Authority::LaunchLifecycle.stub(:new, lambda { |**selection|
              assert_equal({deployment: deployment, deployment_history: history}, selection)
              calls << :launch
              launch
            }) do
              Authority::Router.stub(:new, lambda { |**selection|
                assert_equal({launch: launch}, selection)
                calls << :router
                router
              }) do
                Authority::Server.stub(:new, lambda { |**selection|
                  assert_equal({authority_id: "authority", deployment: deployment, lifecycle: router}, selection)
                  server
                }) do
                  CLI::Commands::Authority::Serve.new.call(authority: "authority")
                end
              end
            end
          end
        end
        assert_equal [:launch, :router, :served], calls
        refute_respond_to CLI::Commands::Authority::Serve, :with_original_launch
      end
    end
  end
end
