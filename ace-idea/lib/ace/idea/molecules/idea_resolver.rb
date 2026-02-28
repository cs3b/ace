# frozen_string_literal: true

require "ace/support/items"
require_relative "idea_scanner"

module Ace
  module Idea
    module Molecules
      # Wraps ShortcutResolver for raw idea IDs (no .t. type marker).
      # Resolves 3-char suffix shortcuts, full 6-char IDs.
      # Explicitly detects and warns on ambiguity collisions.
      class IdeaResolver
        # @param root_dir [String] Root directory containing ideas
        def initialize(root_dir)
          @root_dir = root_dir
          @scanner = IdeaScanner.new(root_dir)
        end

        # Resolve a reference to a scan result
        # @param ref [String] Full ID (6 chars) or suffix shortcut (3 chars)
        # @param warn_on_ambiguity [Boolean] Whether to print warning on ambiguity
        # @return [ScanResult, nil] Resolved result or nil
        def resolve(ref, warn_on_ambiguity: true)
          scan_results = @scanner.scan
          resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(scan_results)

          on_ambiguity = if warn_on_ambiguity
            ->(matches) {
              ids = matches.map(&:id).join(", ")
              warn "Warning: Ambiguous shortcut '#{ref}' matches #{matches.size} ideas: #{ids}. Using most recent."
            }
          end

          resolver.resolve(ref, on_ambiguity: on_ambiguity)
        end

        # Resolve with explicit ambiguity detection
        # @param ref [String] Reference to resolve
        # @return [Hash] Result with :result, :ambiguous, :matches keys
        def resolve_with_info(ref)
          scan_results = @scanner.scan
          resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(scan_results)

          matches = resolver.all_matches(ref)

          if matches.empty?
            { result: nil, ambiguous: false, matches: [] }
          elsif matches.size == 1
            { result: matches.first, ambiguous: false, matches: matches }
          else
            { result: matches.last, ambiguous: true, matches: matches }
          end
        end
      end
    end
  end
end
