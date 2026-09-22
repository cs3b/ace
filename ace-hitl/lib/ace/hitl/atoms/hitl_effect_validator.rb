# frozen_string_literal: true

module Ace
  module Hitl
    module Atoms
      # Client-side mirror of the Lab effect-declaration bounds so invalid
      # requests fail fast, before any external call. Declarations are never
      # rewritten or "fixed": values pass through verbatim or fail.
      class HitlEffectValidator
        MAX_MATCH_LENGTH = 200
        MIN_ARGV_ELEMENTS = 1
        MAX_ARGV_ELEMENTS = 16
        MIN_ARG_LENGTH = 1
        MAX_ARG_LENGTH = 512
        MIN_TIMEOUT = 1
        MAX_TIMEOUT = 600

        class ValidationError < StandardError; end

        def self.validate!(match: nil, effect_args: [], effect_cwd: nil, effect_timeout: nil)
          new(
            match: match,
            effect_args: effect_args,
            effect_cwd: effect_cwd,
            effect_timeout: effect_timeout
          ).validate!
        end

        def initialize(match:, effect_args:, effect_cwd:, effect_timeout:)
          @match = present?(match) ? match.to_s : nil
          @effect_args = Array(effect_args)
          @effect_cwd = present?(effect_cwd) ? effect_cwd.to_s : nil
          @effect_timeout = present?(effect_timeout) ? effect_timeout.to_s : nil
        end

        def validate!
          validate_match
          validate_effect_args
          validate_effect_cwd
          validate_effect_timeout
          nil
        end

        private

        def present?(value)
          !(value.nil? || (value.respond_to?(:strip) ? value.strip.empty? : value.empty?))
        end

        def any_effect_flag?
          @match || @effect_cwd || @effect_timeout || !@effect_args.empty?
        end

        def validate_match
          return if @match.nil?

          if @match.length > MAX_MATCH_LENGTH
            raise ValidationError, "--effect-match exceeds #{MAX_MATCH_LENGTH} characters (got #{@match.length})"
          end

          begin
            Regexp.new(@match)
          rescue RegexpError => e
            raise ValidationError, "--effect-match does not compile: #{e.message}"
          end
        end

        def validate_effect_args
          if any_effect_flag? && @effect_args.empty?
            raise ValidationError, "at least one --effect-arg is required when any effect flag is present"
          end

          if @effect_args.length > MAX_ARGV_ELEMENTS
            raise ValidationError, "too many --effect-arg values (#{@effect_args.length}); max #{MAX_ARGV_ELEMENTS}"
          end

          @effect_args.each_with_index do |arg, index|
            length = arg.to_s.length
            if length < MIN_ARG_LENGTH
              raise ValidationError, "--effect-arg ##{index + 1} is empty"
            end
            if length > MAX_ARG_LENGTH
              raise ValidationError, "--effect-arg ##{index + 1} exceeds #{MAX_ARG_LENGTH} characters (got #{length})"
            end
          end
        end

        def validate_effect_cwd
          return if @effect_cwd.nil?

          unless Pathname.new(@effect_cwd).absolute?
            raise ValidationError, "--effect-cwd must be an absolute path (got '#{@effect_cwd}')"
          end

          return if File.directory?(@effect_cwd)

          raise ValidationError, "--effect-cwd does not exist: #{@effect_cwd}"
        end

        def validate_effect_timeout
          return if @effect_timeout.nil?

          seconds = begin
            Integer(@effect_timeout, 10)
          rescue ArgumentError
            raise ValidationError, "--effect-timeout-s must be an integer (got '#{@effect_timeout}')"
          end

          return if seconds >= MIN_TIMEOUT && seconds <= MAX_TIMEOUT

          raise ValidationError, "--effect-timeout-s must be between #{MIN_TIMEOUT} and #{MAX_TIMEOUT} (got #{@effect_timeout})"
        end
      end
    end
  end
end
