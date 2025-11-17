# frozen_string_literal: true

require "open3"

module Ace
  module Review
    module Molecules
      # Parse and normalize PR identifiers to owner/repo/number format
      class PrIdentifierParser
        # Parse a PR identifier and return normalized components
        #
        # @param identifier [String] PR identifier (number, URL, or owner/repo#number)
        # @return [Hash] Parsed components with :owner, :repo, :number, :format
        # @raise [ArgumentError] if identifier is invalid
        def self.parse(identifier)
          return nil if identifier.nil? || identifier.strip.empty?

          identifier = identifier.to_s.strip

          # Detect format and parse accordingly
          format = detect_format(identifier)

          case format
          when :number
            parse_pr_number(identifier)
          when :url
            parse_github_url(identifier)
          when :qualified
            parse_qualified_ref(identifier)
          else
            raise ArgumentError, "Invalid PR identifier format: #{identifier}"
          end
        end

        # Detect the format of the PR identifier
        #
        # @param identifier [String] PR identifier
        # @return [Symbol] Format type (:number, :url, :qualified, :unknown)
        def self.detect_format(identifier)
          # Check for GitHub URL format
          return :url if identifier.match?(%r{^https?://})

          # Check for qualified reference (owner/repo#number)
          return :qualified if identifier.match?(%r{^[\w-]+/[\w.-]+#\d+$})

          # Check for plain PR number
          return :number if identifier.match?(/^\d+$/)

          :unknown
        end

        # Parse a plain PR number (assumes current repository)
        #
        # @param number [String] PR number
        # @return [Hash] Parsed components
        def self.parse_pr_number(number)
          pr_number = number.to_i

          raise ArgumentError, "Invalid PR number: #{number}" if pr_number <= 0

          # Get current repository from git remote
          repo_info = resolve_repository

          {
            owner: repo_info[:owner],
            repo: repo_info[:repo],
            number: pr_number,
            format: :number,
            gh_format: pr_number.to_s
          }
        end

        # Parse a GitHub URL
        #
        # @param url [String] GitHub PR URL
        # @return [Hash] Parsed components
        def self.parse_github_url(url)
          # Match github.com or GitHub Enterprise URLs
          # Format: https://github.com/owner/repo/pull/123
          match = url.match(%r{^https?://([^/]+)/([^/]+)/([^/]+)/pull/(\d+)})

          raise ArgumentError, "Invalid GitHub URL format: #{url}" unless match

          host = match[1]
          owner = match[2]
          repo = match[3]
          number = match[4].to_i

          # Remove .git suffix if present
          repo = repo.sub(/\.git$/, "")

          {
            owner: owner,
            repo: repo,
            number: number,
            format: :url,
            host: host,
            gh_format: "#{owner}/#{repo}##{number}"
          }
        end

        # Parse a qualified reference (owner/repo#number)
        #
        # @param ref [String] Qualified reference
        # @return [Hash] Parsed components
        def self.parse_qualified_ref(ref)
          match = ref.match(%r{^([\w-]+)/([\w.-]+)#(\d+)$})

          raise ArgumentError, "Invalid qualified reference format: #{ref}" unless match

          owner = match[1]
          repo = match[2]
          number = match[3].to_i

          {
            owner: owner,
            repo: repo,
            number: number,
            format: :qualified,
            gh_format: "#{owner}/#{repo}##{number}"
          }
        end

        # Resolve current repository from git remote
        #
        # @return [Hash] Repository info with :owner and :repo
        # @raise [StandardError] if not in a git repository or remote not found
        def self.resolve_repository
          # Get git remote URL
          stdout, stderr, status = Open3.capture3("git", "config", "--get", "remote.origin.url")

          unless status.success?
            raise StandardError, "Not in a git repository or remote.origin not configured"
          end

          remote_url = stdout.strip

          # Parse different remote URL formats
          # SSH: git@github.com:owner/repo.git
          # HTTPS: https://github.com/owner/repo.git
          if remote_url.match?(/^git@/)
            # SSH format
            match = remote_url.match(/git@[^:]+:([\w-]+)\/([\w.-]+)/)
          elsif remote_url.match?(%r{^https?://})
            # HTTPS format
            match = remote_url.match(%r{https?://[^/]+/([\w-]+)/([\w.-]+)})
          end

          raise StandardError, "Could not parse git remote URL: #{remote_url}" unless match

          owner = match[1]
          repo = match[2].sub(/\.git$/, "") # Remove .git suffix

          {
            owner: owner,
            repo: repo
          }
        end

        private_class_method :detect_format, :parse_pr_number, :parse_github_url,
                            :parse_qualified_ref, :resolve_repository
      end
    end
  end
end
