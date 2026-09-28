# frozen_string_literal: true

module Ace
  module Runtime
    module Atoms
      # Central send-shape validation and normalization. Runs BEFORE any
      # adapter transport call: a SendRejectedError guarantees the
      # adapter made no native call. Adapters declare exactly one
      # send_profile (:plain_pane or :agent_aware) and normalize their
      # public send input through this contract; the shared adapter
      # contract suite (Ace::Runtime::Testing::AdapterContract) enforces
      # the normative matrix for both profiles.
      #
      # Normalized request shape:
      # - plain_pane: `command` is submitted once (with Enter); `items`
      #   are delivered afterwards in order — messages as raw text
      #   (no implicit submission), keys as keystrokes.
      # - agent_aware: `command` is always nil; the prompt (from
      #   `command` or the concatenated messages) is the single leading
      #   `{message:}` entry and submits itself; remaining items are
      #   trailing keys. At most one trailing Enter is dropped and
      #   reported via `dropped_trailing_enter`.
      module SendContract
        PROFILES = %i[plain_pane agent_aware].freeze

        # The four lifecycle observations wait_lifecycle accepts; a wait
        # reports the condition only and never authorizes completion,
        # receipts, or pruning.
        LIFECYCLE_CONDITIONS = %w[window-exists window-active pane-exists pane-exited].freeze

        Request = Struct.new(:profile, :command, :items, :dropped_trailing_enter, keyword_init: true)
        Result = Struct.new(:dropped_trailing_enter, keyword_init: true)

        ENTER_PATTERN = /\Aenter\z/i
        PROMPT_JOIN = "\n"

        module_function

        def normalize!(command:, items:, profile:)
          unless PROFILES.include?(profile)
            raise ArgumentError, "unknown send profile '#{profile}' (expected one of: #{PROFILES.join(', ')})"
          end

          normalized_command = normalize_command(command)
          normalized_items = normalize_items(items)
          require_content!(normalized_command, normalized_items)
          command_requires_key_items!(normalized_command, normalized_items)

          return plain_request(normalized_command, normalized_items) if profile == :plain_pane

          agent_aware_request(normalized_command, normalized_items)
        end

        # Convenience shape: send(command:) — submit once.
        def command_request(command:, profile:)
          normalize!(command: command, items: [], profile: profile)
        end

        # Convenience shape: send(items: keys.map { {key: _1} }).
        def keys_request(keys, profile:)
          items = Array(keys).map { |name| {key: name} }
          normalize!(command: nil, items: items, profile: profile)
        end

        def normalize_command(command)
          text = command.to_s
          return nil if text.strip.empty?

          text
        end

        def normalize_items(items)
          Array(items).each_with_index.map { |item, index| normalize_item(item, index) }
        end

        private_class_method def self.normalize_item(item, index)
          unless item.is_a?(Hash) && item.size == 1
            raise SendRejectedError,
              "items[#{index}] must be a single-key {message: String} or {key: String} hash"
          end

          name, value = item.first
          case name.to_s
          when "message"
            unless value.is_a?(String) && !value.empty?
              raise SendRejectedError, "items[#{index}] message must be a non-empty String"
            end

            {message: value}
          when "key"
            key_name = value.to_s.strip
            raise SendRejectedError, "items[#{index}] key must be a non-empty key name" if key_name.empty?

            {key: key_name}
          else
            raise SendRejectedError, "items[#{index}] must use :message or :key (got :#{name})"
          end
        end

        def require_content!(command, items)
          return if command || !items.empty?

          raise SendRejectedError, "send requires content: a nonblank command or at least one message/key item"
        end

        def command_requires_key_items!(command, items)
          return unless command
          return if items.all? { |item| item.key?(:key) }

          raise SendRejectedError,
            "command submits on its own: when command is present, items must be post-command keys only"
        end

        def plain_request(command, items)
          Request.new(profile: :plain_pane, command: command, items: items, dropped_trailing_enter: false)
        end

        def agent_aware_request(command, items)
          messages = items.select { |item| item.key?(:message) }
          keys = items.select { |item| item.key?(:key) }
          enter_count = keys.count { |item| enter?(item[:key]) }
          raise SendRejectedError, "agent panes accept at most one Enter per send" if enter_count > 1

          if command
            non_enter_keys = keys.reject { |item| enter?(item[:key]) }
            unless non_enter_keys.empty?
              raise SendRejectedError, "command on an agent pane only supports a single trailing Enter key"
            end

            return prompt_request(command, dropped: enter_count == 1)
          end

          if messages.any?
            if keys.length > 1 || (keys.length == 1 && !enter?(keys.first[:key]))
              raise SendRejectedError,
                "agent panes reject interleaved input: messages may only be followed by a single Enter"
            end

            return prompt_request(messages.map { |item| item[:message] }.join(PROMPT_JOIN), dropped: enter_count == 1)
          end

          Request.new(profile: :agent_aware, command: nil, items: keys, dropped_trailing_enter: false)
        end

        def prompt_request(prompt, dropped:)
          Request.new(
            profile: :agent_aware,
            command: nil,
            items: [{message: prompt}],
            dropped_trailing_enter: dropped
          )
        end

        def enter?(key_name)
          !key_name.to_s.strip.match(ENTER_PATTERN).nil?
        end
      end
    end
  end
end
