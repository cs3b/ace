# frozen_string_literal: true

module Ace
  module Git
    module Forgejo
      # Parse `fj` human-oriented output (minimal style) into structured data.
      #
      # `fj` has no JSON output mode, so the provider owns parsers for the
      # stable text formats. All parsers are pure functions over strings.
      module Parsers
        # Invisible bidi isolate/pop-directional marks. Real `fj` (v0.6.0) wraps
        # dynamic fields (titles, numbers, URLs) in U+2068/U+2069 even in minimal
        # style; they are Unicode Cf format characters, so `[[:cntrl:]]` does not
        # cover them and they must be stripped explicitly. Includes the full
        # isolate/pop set (U+2066-U+2069, U+202A-U+202E), directional marks
        # (U+200E/U+200F), and the soft hyphen.
        BIDI_MARKS = /[\u00ad\u200e\u200f\u202a-\u202e\u2066-\u2069]/.freeze

        # Strip control characters, bidi isolate/pop-directional marks, and
        # surrounding whitespace from an `fj` line.
        def self.clean(line)
          line.to_s.gsub(/[[:cntrl:]]/, "").gsub(BIDI_MARKS, "").strip
        end

        # Parse `fj pr view <ID>` output.
        #
        # Layout (minimal style):
        #   Ship the provider contract #25
        #   By lab-builder - Merged - +252 -8
        #   From `owner/repo:head-branch` into `main`
        #
        # @return [Hash, nil] {number:, title:, author:, state:, head_ref:, base_ref:}
        def self.parse_pr_view(text)
          lines = text.to_s.lines.map { |line| clean(line) }.reject(&:empty?)
          return nil if lines.empty?

          title_line = lines[0]
          numbered = title_line.match(/^(?<title>.+?)\s+#(?<number>\d+)\z/)
          return nil unless numbered

          info = {
            number: numbered[:number].to_i,
            title: numbered[:title],
            author: nil,
            state: nil,
            head_ref: nil,
            base_ref: nil
          }

          byline = lines[1].to_s
          if (match = byline.match(/\ABy\s+(?<author>\S+)\s+[-\u2013\u2014]\s+(?<state>\w+)/))
            info[:author] = match[:author]
            info[:state] = normalize_state(match[:state])
          end

          refs = lines.find { |line| line.start_with?("From ") }
          if (match = refs.to_s.match(/\AFrom\s+`(?:[^`:]+:)?(?<head>[^`]+)`\s+into\s+`(?<base>[^`]+)`\z/))
            info[:head_ref] = match[:head]
            info[:base_ref] = match[:base]
          end

          info
        end

        # Parse `fj pr view <ID> commits` output; the first commit line carries
        # the head sha.
        #
        # @return [String, nil] head commit sha
        def self.parse_head_sha(text)
          match = text.to_s.match(/^commit\s+(?<sha>[0-9a-f]{7,64})\b/)
          match && match[:sha]
        end

        # Parse `fj pr search` / issue search listing output.
        #
        # Layout (minimal style):
        #   25 pull requests
        #   #31: Wire status to providers (by lab-builder)
        #
        # @return [Array<Hash>] {number:, title:, author:}
        def self.parse_search(text)
          text.to_s.lines.map { |line| clean(line) }.filter_map do |line|
            match = line.match(/\A#(?<number>\d+):\s+(?<title>.+?)\s+\(by\s+(?<author>[^)]+)\)\z/)
            next nil unless match

            {
              number: match[:number].to_i,
              title: match[:title],
              author: match[:author]
            }
          end
        end

        # Parse `fj issue view <ID>` output (same layout as PR view).
        #
        # @return [Hash, nil] {number:, title:, author:, state:}
        def self.parse_issue_view(text)
          parsed = parse_pr_view(text)
          return nil unless parsed

          parsed.slice(:number, :title, :author, :state)
        end

        # Parse `fj actions tasks` output into check evidence entries.
        #
        # Layout (minimal style):
        #   #83 (fc14c43d36) success Complete package suite 23s (push): subject
        #
        # @return [Array<Hash>] {name:, state:, sha:}
        def self.parse_actions_tasks(text)
          text.to_s.lines.map { |line| clean(line) }.filter_map do |line|
            match = line.match(
              /\A#(?<task>\d+)\s+\((?<sha>[0-9a-f]+)\)\s+(?<state>\w+)\s+(?<name>.+?)\s+[\dhms.]+\s+\((?:push|pull_request|schedule)\)/
            )
            next nil unless match

            {
              name: match[:name],
              state: match[:state].downcase.to_sym,
              sha: match[:sha]
            }
          end
        end

        # Parse `fj repo view` output.
        #
        # @return [Hash] {full_name:, url:}
        def self.parse_repo_view(text)
          lines = text.to_s.lines.map { |line| clean(line) }.reject(&:empty?)
          full_name = lines[0].to_s.empty? ? nil : lines[0]
          url_line = lines.find { |line| line.start_with?("View online at") }
          url = url_line && url_line.sub(/\AView online at\s+/, "")

          {
            full_name: full_name,
            url: url
          }
        end

        # Map `fj` state vocabulary onto the neutral state symbols.
        def self.normalize_state(raw)
          case raw.to_s.downcase
          when "open" then :open
          when "merged" then :merged
          when "closed" then :closed
          else raw.to_s.downcase.to_sym
          end
        end
      end
    end
  end
end
