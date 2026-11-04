# frozen_string_literal: true
require "ace/lab/molecules/install_manifest_loader"

module Ace::Overseer::Molecules
  module IsolatedRuntime
    def self.enabled?(env: ENV)
      return true if env["ACE_LAB_SESSION"] == "1"
      return false unless env["ACE_TOOLCHAIN"] == "installed" && File.exist?(Ace::Lab.install_manifest_path)
      document = Ace::Lab::Molecules::InstallManifestLoader.load
      unless document["session_runtime"].is_a?(Hash)
        raise Ace::Overseer::Error, "installed lab runtime is missing its isolated session configuration"
      end
      true
    end
  end
end
