# frozen_string_literal: true

module Ace
  module Lab
    module Auth
      # Wait on the kernel-held session-main pidfd and a monotonic deadline.
      # The issuer uses the result to exit and let its existing systemd
      # cleanup run; no state store or polling loop is introduced.
      class SessionLifetime
        def self.wait(handle, timeout:)
          unless handle.is_a?(IO) && !handle.closed? && timeout.is_a?(Numeric) && timeout.finite? && timeout >= 0
            raise ArgumentError, "session lifetime requires a live handle and a finite deadline"
          end

          IO.select([handle], nil, nil, timeout) ? :session_ended : :expired
        end
      end
    end
  end
end
