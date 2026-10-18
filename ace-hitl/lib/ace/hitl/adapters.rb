# frozen_string_literal: true

require_relative "adapters/registry"

module Ace
  module Hitl
    # Duck-typed HITL delivery-adapter registry (mirrors Ace::Runtime).
    #
    # Adapter contract (transport translation only — never role rules):
    #
    #   Ace::Hitl::Adapters.register(:name, ->(route) { adapter })
    #   adapter.deliver(event:, text:, recipient:, reply_to:)
    #     -> Adapters::RouteResult(route:, adapter:, status:, detail:)
    #   status: :delivered | :failed | :unavailable
    #
    # `text` is the shared rendering from Atoms::HitlEventText — identical
    # for every adapter. `recipient`/`reply_to` are the address hashes from
    # the event (nil for legacy local-only events). A route delivers only
    # to its own configured destination and never reroutes on any status.
    #
    # Adapter packages ship a lib/ace/hitl/adapters/<name>.rb entrypoint
    # that calls Adapters.register; it is loaded lazily on first resolve,
    # so a future adapter (e.g. nervus) needs no ace-hitl change.
    module Adapters
      class Error < StandardError; end

      # Unknown adapter name; carries the requested name and the sorted
      # list of currently available adapters.
      class UnknownAdapterError < Error
        attr_reader :requested, :available

        def initialize(requested:, available:)
          @requested = requested
          @available = available
          super("unknown HITL adapter '#{requested}' (available: #{available.sort.join(", ")})")
        end
      end

      # Per-route delivery outcome. `detail` is a human-readable,
      # single-line explanation (may be nil for a plain success).
      RouteResult = Struct.new(:route, :adapter, :status, :detail, keyword_init: true) do
        def delivered?
          status == :delivered
        end
      end

      class << self
        def register(name, factory = nil, &block)
          registry.register(name, factory, &block)
        end

        def registry
          @registry ||= Registry.new
        end

        # Resetting re-registers the built-in adapters: a plain Registry.new
        # would permanently lose :terminal (the entrypoint require is a
        # no-op once loaded), breaking registry-level resolution in tests
        # and long-lived processes.
        def reset_registry!
          @registry = Registry.new
          register(:terminal, ->(route) { TerminalAdapter.new(route) })
          nil
        end

        def available
          registry.available
        end

        def registered?(name)
          registry.registered?(name)
        end

        def resolve(name, route: {})
          registry.resolve(name, route: route)
        end
      end
    end
  end
end
