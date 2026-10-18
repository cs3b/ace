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
          runtime = Ace::Runtime.resolve(@runtime_name)
          runtime.send_text(pane: @pane, text: text)
          RouteResult.new(route: @route_name, adapter: "terminal", status: :delivered,
            detail: "text pushed to #{@runtime_name} pane #{@pane}")
        rescue Ace::Runtime::UnknownRuntimeError,
          Ace::Runtime::RuntimeUnavailableError => e
          RouteResult.new(route: @route_name, adapter: "terminal", status: :unavailable,
            detail: e.message)
        rescue Ace::Runtime::Error => e
          RouteResult.new(route: @route_name, adapter: "terminal", status: :failed,
            detail: e.message)
        end
      end
    end
  end
end

Ace::Hitl::Adapters.register(:terminal, ->(route) { Ace::Hitl::Adapters::TerminalAdapter.new(route) })
