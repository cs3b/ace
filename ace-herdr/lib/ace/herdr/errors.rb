# frozen_string_literal: true

module Ace
  module Herdr
    # Base for herdr CLI executor failures; retry classification drives the
    # ace-hitl DeliverResult state mapping (retryable vs terminal).
    class ExecutorError < Error
      # Terminal by default: retrying with identical content cannot succeed
      def retryable?
        false
      end
    end

    # Agent rejected the prompt before any input was sent (agent_blocked)
    class AgentBlockedError < ExecutorError; end

    # Accepted prompt did not observe a working/blocked state in time
    # (agent_prompt_stalled / wait timeout) — transient, safe to re-push
    class AgentNotReadyError < ExecutorError
      def retryable?
        true
      end
    end

    # Target pane does not exist (pane_not_found)
    class PaneNotFoundError < ExecutorError; end

    # Target tab does not exist (tab_not_found)
    class TabNotFoundError < ExecutorError; end

    # Target workspace does not exist (workspace_not_found)
    class WorkspaceNotFoundError < ExecutorError; end

    # No agent detected in the target pane
    class AgentNotFoundError < ExecutorError; end

    # herdr CLI binary or its socket is unreachable — transient
    class ExecutorUnavailableError < ExecutorError
      def retryable?
        true
      end
    end

    # Unclassified herdr CLI failure — treated as transient within retry limits
    class CommandError < ExecutorError
      def retryable?
        true
      end
    end
  end
end
