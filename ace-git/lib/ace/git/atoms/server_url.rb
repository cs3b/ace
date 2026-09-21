# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Normalize forge server URLs and remote URLs to a canonical comparable
      # form. Purely textual: no network access, no hostname allow-lists, and
      # no assumptions about any particular forge host.
      #
      # Supported input shapes:
      # - "https://forge.example.com/owner/repo.git"
      # - "http://forge.internal:3000/owner/repo"
      # - "git@forge.example.com:owner/repo.git" (scp-style)
      # - "ssh://git@forge.example.com:2222/owner/repo.git"
      # - "forge.example.com/owner/repo"
      #
      # Canonical form: lowercase "host[:port]/path" with any credentials,
      # scheme, trailing slash, and ".git" suffix removed. A colon segment is
      # treated as a port (not an scp separator) only when it is all digits and
      # followed by a slash; everything else is scp-style "host:path".
      module ServerUrl
        # Normalize a server or remote URL to the canonical comparable form.
        #
        # @param url [String] server or remote URL
        # @return [String] canonical "host[:port]/path" form
        def self.normalize(url)
          text = url.to_s.strip
          text = text.sub(%r{\A[a-z][a-z0-9+.\-]*://}i, "")
          text = text.sub(%r{\A[^/@]+@}, "")

          if (port_match = text.match(%r{\A([^/:]+):(\d+)(/.+)\z}))
            text = "#{port_match[1]}:#{port_match[2]}#{port_match[3]}"
          elsif (scp_match = text.match(%r{\A([^/:]+):(.+)\z}))
            text = "#{scp_match[1]}/#{scp_match[2]}"
          end

          text = text.sub(%r{/?\.git/?\z}i, "")
          text.chomp("/").downcase
        end

        # Compare a configured server URL against a remote URL for identity.
        #
        # @param server_url [String] configured server base URL
        # @param remote_url [String] git remote URL
        # @return [Boolean] true when both normalize to the same form
        def self.match?(server_url, remote_url)
          normalized_server = normalize(server_url)
          normalized_remote = normalize(remote_url)
          return false if normalized_server.empty? || normalized_remote.empty?

          normalized_server == normalized_remote
        end
      end
    end
  end
end
