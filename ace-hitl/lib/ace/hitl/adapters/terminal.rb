# frozen_string_literal: true

require "ace/runtime"
require_relative "../adapters"

module Ace
  module Hitl
    module Adapters
      # Built-in terminal adapter: pushes the shared event text to a pane
      # through any Ace::Runtime terminal (tmux, herdr). The runtime is
      # named by the route configuration, so switching transports is pure
      # configuration — no sender or coworker change.
      #
      # The event's recipient steers the target: a panel-form address names
      # the pane the text goes to (the route `pane` is only the fallback
      # for legacy recipient-less events). A folder-form recipient cannot
      # be served by a terminal route — explicit refusal, never a silent
      # send to the route's own pane.
      class TerminalAdapter
        def initialize(route)
          @route_name = route["route"].to_s.strip
          @runtime_name = route["runtime"].to_s.strip
          @pane = route["pane"].to_s.strip
          if @runtime_name.empty?
            raise Error, "terminal route '#{@route_name}' missing required 'runtime' (tmux|herdr)"
          end
          if @pane.empty?
            raise Error, "terminal route '#{@route_name}' missing required 'pane' handle"
          end
        end

        def deliver(event:, text:, recipient:, reply_to:)
          pane = target_pane(recipient)
          unless pane
            return RouteResult.new(route: @route_name, adapter: "terminal", status: :failed,
              detail: "terminal route '#{@route_name}' cannot deliver to folder recipient " \
                      "#{Atoms::HitlAddress.to_s(recipient)} (panel recipient required; " \
                      "route pane '#{@pane}' not used)")
          end

          runtime = Ace::Runtime.resolve(@runtime_name)
          runtime.send_text(pane: pane, text: text)
          RouteResult.new(route: @route_name, adapter: "terminal", status: :delivered,
            detail: "text pushed to #{@runtime_name} pane #{pane}")
        rescue Ace::Runtime::UnknownRuntimeError,
          Ace::Runtime::RuntimeUnavailableError => e
          RouteResult.new(route: @route_name, adapter: "terminal", status: :unavailable,
            detail: e.message)
        rescue Ace::Runtime::Error => e
          RouteResult.new(route: @route_name, adapter: "terminal", status: :failed,
            detail: e.message)
        end

        private

        # The recipient's panel names the target pane; without a recipient
        # (legacy local-only events) the route's configured pane is used.
        def target_pane(recipient)
          return @pane if recipient.nil?

          panel = recipient["panel"].to_s
          panel.empty? ? nil : panel
        end
      end
    end
  end
end

Ace::Hitl::Adapters.register(:terminal, ->(route) { Ace::Hitl::Adapters::TerminalAdapter.new(route) })
