# frozen_string_literal: true
require_relative "../../../authority/server"
require_relative "../../../authority/router"
require_relative "../../../authority/launch_lifecycle"
module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Serve < Ace::Support::Cli::Command
            desc "Serve the installed protected assignment authority"
            option :authority, required: true, desc: "Installed authority ID"
            def call(**options)
              deployment = Ace::Assign::Authority::Deployment.load
              history = Ace::Assign::Authority::DeploymentHistory.load
              launch = Ace::Assign::Authority::LaunchLifecycle.new(deployment: deployment, deployment_history: history)
              router = Ace::Assign::Authority::Router.new(launch: launch)
              server = Ace::Assign::Authority::Server.new(authority_id: options.fetch(:authority), deployment: deployment, lifecycle: router)
              signals = %w[INT TERM].to_h { |signal| [signal, Signal.trap(signal) { server.request_stop }] }
              server.serve
            rescue ArgumentError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            ensure
              signals&.each { |signal, handler| Signal.trap(signal, handler) }
            end
          end
        end
      end
    end
  end
end
