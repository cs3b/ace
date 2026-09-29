# frozen_string_literal: true

# Stubbed for Spinel builds: execute's CRuby Time.parse path cannot
# type-check in the AOT chain; the compiled CLI entry uses
# CompactIdEncoder.encode_cli instead. See build.sh / REPORT.md.
module Ace
  module B36ts
    module Commands
      class EncodeCommand
        def self.execute(_time_string, _options = {})
          raise NotImplementedError, "use CompactIdEncoder.encode_cli in compiled builds"
        end
      end
    end
  end
end
