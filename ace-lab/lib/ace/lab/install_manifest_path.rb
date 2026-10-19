# frozen_string_literal: true

module Ace
  module Lab
    # The trusted install manifest is a deployment document at a FIXED path
    # — never in the caller-writable configuration cascade and never at a
    # caller-selected location. It must be root-owned and not
    # group/world-writable along its whole path, exactly like
    # AUTHORIZATION_PATH; InstallManifestLoader verifies through
    # GrantResolver.read_verified and fails closed. A caller-writable
    # manifest could provision accounts, directories and keys, i.e.
    # manufacture privileges.
    INSTALL_MANIFEST_PATH = "/etc/lab/ace-lab/install.yml"

    # Path of the trusted install manifest. A method (not a bare constant
    # reference) so tests stub the seam without any caller-controllable
    # production override; the CLI deliberately exposes no --manifest flag.
    # @return [String]
    def self.install_manifest_path
      INSTALL_MANIFEST_PATH
    end
  end
end
