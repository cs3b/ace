# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Hitl
    module CLI
      module Commands
        class Send < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Send a HITL event through the configured adapter routes"

          example [
            "8xhkep                   # Deliver one event; per-route results",
            "8xhkep --scope all       # Resolve across worktrees"
          ]

          argument :ref, required: true, desc: "HITL reference (full ID or shortcut)"

          option :scope, type: :string, desc: "Scope (current, all)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            scope = validate_scope(options[:scope])

            sender = Organisms::HitlSender.new
            report = sender.send(ref, scope: scope)

            unless options[:quiet]
              puts "HITL event #{report.event_id} sent through #{report.results.size} route(s):"
              report.results.each do |result|
                detail = result.detail ? " - #{result.detail}" : ""
                puts "  #{result.route} (#{result.adapter}): #{result.status}#{detail}"
              end
            end

            unless report.all_delivered?
              raise Ace::Support::Cli::Error.new(
                "HITL event '#{report.event_id}' not delivered on all routes"
              )
            end
          rescue Ace::Hitl::Organisms::HitlManager::AmbiguousReferenceError => e
            candidates = e.matches.map(&:file_path).join(", ")
            raise Ace::Support::Cli::Error.new(
              "HITL event '#{ref}' is ambiguous across scope '#{scope || "all"}'. Candidates: #{candidates}"
            )
          rescue Ace::Hitl::Adapters::Error,
            Ace::Hitl::Molecules::HitlRouteLoader::NoRoutesError,
            Ace::Hitl::Molecules::HitlRouteLoader::InvalidRouteError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def validate_scope(raw_scope)
            return nil if raw_scope.nil?

            scope = raw_scope.to_s.strip
            allowed = Ace::Hitl::Molecules::WorktreeScopeResolver::VALID_SCOPES
            return scope if allowed.include?(scope)

            raise Ace::Support::Cli::Error.new("Invalid scope '#{raw_scope}'. Allowed: #{allowed.join(", ")}")
          end
        end
      end
    end
  end
end
