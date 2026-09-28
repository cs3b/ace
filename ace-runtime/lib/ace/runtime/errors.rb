# frozen_string_literal: true

module Ace
  module Runtime
    # Contract error hierarchy. Every runtime failure surfaces as one of
    # these typed errors; adapters translate their native failures into
    # them at the boundary.
    class Error < StandardError; end

    # The requested runtime name has no registered adapter (after the
    # convention-based entrypoint load attempt). Fails closed and names
    # the available runtimes.
    class UnknownRuntimeError < Error
      attr_reader :requested, :available

      def initialize(requested:, available:)
        @requested = requested
        @available = Array(available).sort.freeze
        super("unknown runtime '#{requested}' (available: #{@available.join(', ')})")
      end
    end

    # The runtime is known but not usable right now (server unreachable,
    # no live session/workspace). Never silently downgraded to another
    # runtime or to a headless mode.
    class RuntimeUnavailableError < Error; end

    # A window/pane target does not exist. Target values are opaque,
    # adapter-owned handles; the contract never predicts or formats them.
    class TargetNotFoundError < Error; end

    # ensure_window found an existing window with the same normalized
    # name scoped to the current session/workspace but an incompatible
    # root or preset.
    class WindowConflictError < Error; end

    # Pre-send rejection (invalid send shape or an agent pane blocking
    # the delivery). Raised before any transport call; terminal.
    class SendRejectedError < Error; end

    # The submission was accepted but the target did not start
    # processing it. The outcome is uncertain: callers must not
    # auto-resend the same content.
    class SendStalledError < Error; end

    # A wait exceeded its deadline. Timeout units at the contract level
    # are SECONDS; adapters convert to native units internally.
    class WaitTimeoutError < Error
      attr_reader :condition, :target, :timeout

      def initialize(condition:, timeout:, target: nil)
        @condition = condition
        @target = target
        @timeout = timeout
        target_part = target ? " on '#{target}'" : ""
        super("timed out waiting for #{condition}#{target_part} after #{timeout}s")
      end
    end
  end
end
