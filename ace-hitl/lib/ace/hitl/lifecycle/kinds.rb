# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # Request kinds and the secret/OTP answer gates (port of the
      # migrated kind model; spec 8wm.t.y21 §4).
      module Kinds
        ALL = %w[
          text choice confirm secret review
          question decision verification otp
        ].freeze
        SECRET = %w[otp].freeze

        REQUEST_ID = /\A[A-Za-z0-9_-]{6,64}\z/
        WORK_ID = /\AW[0-9]+\z/
        ATTEMPT_ID = /\AA-[0-9a-f]{24}\z/
        # Compact managed identifiers (ADR-030): ace-assign assignment and
        # attempt ids are Base36 timestamp ids plus optional local suffix.
        COMPACT_ID = /\A[0-9a-z][0-9a-z]{4,63}\z/
        SAFE_LABEL = /\A[A-Za-z0-9_. -]{1,48}\z/
        OTP_ANSWER = /\A[0-9]{6}\z/

        # The OTP challenge binds the answer to its ONE authorized
        # operation with non-secret publisher evidence (spec 8wq.t.34i):
        # an OTP is accepted only for this operation after an OTP-required
        # publisher result.
        OTP_OPERATION = /\A[a-z][a-z0-9.-]{0,63}\z/
        OTP_RESULT_REF = /\A[^\n\r\0]{1,256}\z/
        OTP_INPUT_DIGEST = /\A[0-9a-f]{64}\z/
        OTP_MAX_TTL_SECONDS = 24 * 60 * 60

        # Secret-shape scrubbing: tokens that must never enter a
        # non-OTP answer or a channel message.
        SECRET_SHAPED = Regexp.new(
          "(?:github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+|" \
          "sk-[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]+PRIVATE KEY-----|" \
          "\\b(?:otp|token|secret|password)\\s*[:=]\\s*\\S+|" \
          "\\b[0-9]{6}\\b)",
          Regexp::IGNORECASE
        ).freeze

        class << self
          def secret?(kind)
            SECRET.include?(kind.to_s)
          end

          def valid?(kind)
            ALL.include?(kind.to_s)
          end

          # The deliver/consume answer gate (port of check_answer):
          # OTP answers must be exactly six ASCII digits; every other
          # kind rejects secret-shaped content before persistence.
          def check_answer!(kind, answer)
            if secret?(kind)
              unless OTP_ANSWER.match?(answer)
                raise AnswerError, "OTP answer must be exactly six ASCII digits"
              end
            elsif SECRET_SHAPED.match?(answer)
              raise AnswerError, "secret-shaped content is forbidden in HITL answers"
            end
            nil
          end
        end
      end
    end
  end
end
