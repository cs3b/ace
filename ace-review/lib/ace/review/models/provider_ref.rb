# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Normalized provider reference for reviewer lane execution.
      class ProviderRef
        MAX_REF_LENGTH = 240
        SEGMENT_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/.freeze

        attr_reader :raw_ref, :kind, :target, :model, :options

        def initialize(raw_ref:, kind:, target:, model: nil, options: {})
          @raw_ref = raw_ref.to_s
          @kind = kind.to_s
          @target = target.to_s
          @model = model&.to_s
          @options = deep_stringify(options)
          validate!
        end

        def self.from_entry(entry, default_options: {})
          case entry
          when String
            from_ref(entry, default_options: default_options)
          when Hash
            normalized = deep_stringify(entry)
            ref = normalized["provider"].to_s.strip
            raise ArgumentError, "Provider map entry is missing required key 'provider'" if ref.empty?

            inline_options = normalized.reject { |key, _| key == "provider" }
            from_ref(ref, default_options: default_options, inline_options: inline_options)
          else
            raise ArgumentError, "Provider entry must be a string or mapping"
          end
        end

        def self.from_ref(ref, default_options: {}, inline_options: {})
          parsed = parse_ref(ref)
          options = deep_stringify(default_options).merge(deep_stringify(inline_options))
          new(
            raw_ref: parsed[:raw_ref],
            kind: parsed[:kind],
            target: parsed[:target],
            model: parsed[:model],
            options: options
          )
        end

        def self.parse_ref(provider_ref)
          ref = provider_ref.to_s.strip
          raise ArgumentError, "Provider reference cannot be empty" if ref.empty?
          raise ArgumentError, "Invalid provider reference '#{ref}': max length is #{MAX_REF_LENGTH}" if ref.length > MAX_REF_LENGTH
          raise ArgumentError, "Invalid provider reference '#{ref}': cannot contain path separators or '..'" if invalid_path?(ref)

          kind, remainder = ref.split(":", 2)
          raise ArgumentError, "Invalid provider reference '#{ref}': kind is required" if kind.to_s.empty?
          raise ArgumentError, "Invalid provider reference '#{ref}': target is required" if remainder.to_s.empty?

          unless kind.match?(SEGMENT_PATTERN)
            raise ArgumentError, "Invalid provider reference '#{ref}': kind '#{kind}' is not supported"
          end

          case kind
          when "llm"
            target, model = remainder.split(":", 2)
            raise ArgumentError, "Invalid provider reference '#{ref}': llm refs must use llm:<target>:<model>" if target.to_s.empty? || model.to_s.empty?
            unless target.match?(SEGMENT_PATTERN)
              raise ArgumentError, "Invalid provider reference '#{ref}': target '#{target}' is not supported"
            end
            { raw_ref: ref, kind: kind, target: target, model: model }
          when "tool"
            target, extra = remainder.split(":", 2)
            raise ArgumentError, "Invalid provider reference '#{ref}': tool refs must use tool:<target>" if target.to_s.empty? || !extra.to_s.empty?
            unless target.match?(SEGMENT_PATTERN)
              raise ArgumentError, "Invalid provider reference '#{ref}': target '#{target}' is not supported"
            end
            { raw_ref: ref, kind: kind, target: target, model: nil }
          else
            raise ArgumentError, "Unsupported provider kind '#{kind}'. Supported kinds: llm, tool"
          end
        end

        def llm?
          kind == "llm"
        end

        def tool?
          kind == "tool"
        end

        def model_target
          llm? ? model : "tool:#{target}"
        end

        def to_h
          {
            "raw_ref" => raw_ref,
            "kind" => kind,
            "target" => target,
            "model" => model,
            "options" => options
          }.compact
        end

        def self.deep_stringify(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, nested_value), index|
              index[key.to_s] = deep_stringify(nested_value)
            end
          when Array
            value.map { |item| deep_stringify(item) }
          else
            value
          end
        end

        private_class_method :deep_stringify

        def deep_stringify(value)
          self.class.send(:deep_stringify, value)
        end

        def self.invalid_path?(ref)
          ref.include?("/") || ref.include?("\\") || ref.include?("..")
        end
        private_class_method :invalid_path?

        def validate!
          if llm? && model.to_s.strip.empty?
            raise ArgumentError, "LLM provider '#{raw_ref}' is missing model target"
          end
        end
      end
    end
  end
end
