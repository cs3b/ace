# frozen_string_literal: true

module Ace
  module Lab
    # Authorization grants live in a single deployment-controlled file at a
    # FIXED path — never in the caller-writable configuration cascade and
    # never at a caller-selected location (review rounds 4-5, F3/F1). The
    # file must be root-owned and not group/world-writable, including every
    # directory on its real path; GrantResolver verifies and fails closed.
    AUTHORIZATION_PATH = "/etc/lab/ace-lab/authorization.yml"

    # Path of the trusted authorization grants document. A method (not a
    # bare constant reference) so tests can stub the seam without any
    # caller-controllable production override.
    # @return [String]
    def self.authorization_path
      AUTHORIZATION_PATH
    end
  end
end
