# frozen_string_literal: true

module Ace
  module Hitl
    module Contract
      # Shared conservative ordinary-answer gate. Protected OTP IPC is the
      # only boundary that accepts these bytes; they never enter an envelope.
      module SecretGate
        PATTERN = Regexp.new(
          "(?:github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+|" \
          "sk-[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]+PRIVATE KEY-----|" \
          "\\b(?:otp|token|secret|password)\\s*[:=]\\s*\\S+|" \
          "\\b[0-9]{6}\\b)", Regexp::IGNORECASE
        ).freeze
      end
    end
  end
end
