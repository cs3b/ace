# frozen_string_literal: true

require "ace/support/items"
require_relative "hitl_scanner"

module Ace
  module Hitl
    module Molecules
      class HitlResolver
        def initialize(root_dir)
          @scanner = HitlScanner.new(root_dir)
        end

        def resolve(ref, warn_on_ambiguity: true)
          scan_results = @scanner.scan
          resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(scan_results)

          on_ambiguity = if warn_on_ambiguity
            ->(matches) {
              ids = matches.map(&:id).join(", ")
              warn "Warning: Ambiguous shortcut '#{ref}' matches #{matches.size} HITL events: #{ids}. Using most recent."
            }
          end

          resolver.resolve(ref, on_ambiguity: on_ambiguity)
        end
      end
    end
  end
end
