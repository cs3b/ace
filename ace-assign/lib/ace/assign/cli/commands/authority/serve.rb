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
            # The original selected executable is evaluated inside this source
            # callback. No CLI option or environment variable selects an owner.
            def self.with_original_launch(launch)
              unless launch.is_a?(Ace::Assign::Authority::LaunchLifecycle) && block_given?
                raise ArgumentError, "original launch owner is unavailable"
              end
              key = :ace_assign_original_launch_owner
              raise ArgumentError, "original launch owner is already attached" if Thread.current[key]
              Thread.current[key] = launch
              begin
                yield
              ensure
                Thread.current[key] = nil
                launch.close
              end
            end

            def call(**options)
              deployment = Ace::Assign::Authority::Deployment.load
              history = Ace::Assign::Authority::DeploymentHistory.load
              launch = Thread.current[:ace_assign_original_launch_owner]
              if launch
                unless launch.deployment.artifact_reference == deployment.artifact_reference &&
                    launch.deployment_history && launch.deployment_history.artifact_reference == history.artifact_reference
                  raise ArgumentError, "original launch descriptor/history differs"
                end
              else
                has_context = deployment.data.fetch("projects").values.any? { |project| project.fetch("inbox_contexts", {}).values.any? { |context| context.key?("service") } }
                raise ArgumentError, "context authority requires original startup attachment" if has_context
                launch = Ace::Assign::Authority::LaunchLifecycle.new(deployment: deployment, deployment_history: history)
              end
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
