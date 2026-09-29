# frozen_string_literal: true

# Timeout shim for Spinel-compiled ace binaries: pass-through.
#
# Spinel's runtime has no Timeout. ace-support-core requires "timeout"
# for subprocess helpers unreachable from the CLIs compiled here. The
# block runs without a deadline; Timeout::Error can never be raised.
# Documented divergence — see REPORT.md.

module Timeout
  class Error < RuntimeError; end

  class ExitException < Exception; end

  def self.timeout(seconds = nil, exception = nil, message = nil)
    yield seconds
  end
end
