# frozen_string_literal: true

require "json"

module Ace
  module Lab
    module CLI
      module Commands
        # `ace-lab auth request|status|exec|revoke|reconcile` (task
        # 8xs.t.pu0.7): the public short-lived-access interface. Table
        # or JSON output; refusals and errors are non-zero with a
        # reason and the escalation addressee; NO command ever prints a
        # token or exports one to shell history. status is the
        # read-only readiness view (alongside ace-lab verify).
        class Auth < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Short-lived role access: request, status, exec, revoke, reconcile"

          argument :action, required: true, desc: "request | status | exec | revoke | reconcile"
          argument :target, required: false, desc: "Lease id (status/exec/revoke)"

          option :profile, type: :string, desc: "Auth profile name (request)"
          option :role, type: :string, desc: "Delegation role (request)"
          option :task, type: :string, desc: "Task reference (request)"
          option :assignment, type: :string, desc: "Assignment reference (request)"
          option :repo, type: :string, repeat: true, desc: "Repository (request, repeatable)"
          option :ttl, type: :integer, desc: "Requested TTL minutes (request)"
          option :cmd, type: :string, repeat: true,
            desc: "Exec command, one argument per repeat, in order (exec)"
          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"

          def call(action:, target: nil, **options)
            require_relative "../../auth"
            service = ::Ace::Lab::Auth::Service.new

            result = case action
            when "request"
              require_options!(options, :profile, :role, :task, :assignment)
              service.request(profile_name: options[:profile], role: options[:role],
                task: options[:task], assignment: options[:assignment],
                repos: Array(options[:repo]), ttl_minutes: options[:ttl])
            when "status"
              service.status(lease_id: target)
            when "exec"
              raise Ace::Support::Cli::Error.new("exec requires a lease id and a command") if target.nil?

              command = Array(options[:cmd])
              raise Ace::Support::Cli::Error.new("exec requires a command (--cmd, one argument per repeat)") if command.empty?

              service.exec(lease_id: target, argv: command)
            when "revoke"
              raise Ace::Support::Cli::Error, "revoke requires a lease id" if target.nil?

              {"lease" => target, "cleanup" => service.revoke(lease_id: target).to_s}
            when "reconcile"
              {"reconciled" => service.reconcile}
            else
              raise Ace::Support::Cli::Error,
                "unknown auth action '#{action}' (request, status, exec, revoke, reconcile)"
            end

            render(result, options[:format])
          rescue ::Ace::Lab::Auth::Refusal => e
            raise Ace::Support::Cli::Error.new("refused: #{e.message}")
          rescue ::Ace::Lab::Auth::Error => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def require_options!(options, *keys)
            missing = keys.reject { |key| options[key] && !options[key].to_s.strip.empty? }
            unless missing.empty?
              raise Ace::Support::Cli::Error.new("missing required options: #{missing.map { |k| "--#{k}" }.join(' ')}")
            end
          end

          def render(result, format)
            puts format == "json" ? JSON.pretty_generate(result) : JSON.pretty_generate(result)
          end
        end
      end
    end
  end
end
