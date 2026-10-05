# frozen_string_literal: true

require "etc"
require "yaml"

module Ace
  module Hitl
    module Lifecycle
      # Reads ONE trusted deployment-controlled document (the same grants
      # file ace-lab resolves principals from — the format is the shared
      # contract) with the same traversal trust rules: every element of
      # the original path — directories, symlinks, and the file itself —
      # must be root-owned and not group/world-writable, the final
      # component is opened O_NOFOLLOW and re-verified via fstat. Any
      # failed verification fails closed: no trusted document means
      # nobody is authorized and no service identity is trusted.
      module TrustedFile
        MAX_SYMLINK_HOPS = 8

        module_function

        # @return [Hash, nil] parsed mapping, or nil when the document is
        #   absent (deployments without grants authorize nothing)
        def read_yaml(path)
          content = read_verified(path)
          return nil if content.nil?

          document = YAML.safe_load(content, permitted_classes: [Time], aliases: true)
          unless document.is_a?(Hash)
            raise Lifecycle::Error, "trusted HITL authorization file must contain a mapping: #{path}"
          end
          document
        rescue Psych::Exception
          raise Lifecycle::Error, "trusted HITL authorization file could not be parsed: #{path}"
        end

        def read_verified(path)
          # Unconfigured (no path) authorizes nothing — fail closed
          # without crashing the caller.
          return nil if path.nil? || path.to_s.empty?

          resolved = verify_traversal(path.to_s)
          flags = File::RDONLY | File::NOFOLLOW
          fd = IO.sysopen(resolved, flags)
          io = IO.for_fd(fd, mode: "r")
          begin
            stat = io.stat
            verify_owned!(stat, "HITL authorization file", resolved)
            content = io.read
          ensure
            io.close
          end
          content
        rescue Errno::ENOENT
          nil
        rescue SystemCallError, IOError
          raise Lifecycle::Error, "trusted HITL authorization file is unavailable: #{path}"
        end

        # Every component along the ORIGINAL path must be root-owned and
        # not group/world-writable; symlink components are followed but
        # each hop is re-verified (bounded hop count).
        def verify_traversal(path)
          hops = 0
          current = path
          loop do
            stat = File.lstat(current)
            if stat.symlink?
              hops += 1
              raise Lifecycle::Error, "trusted HITL authorization path has too many symlinks: #{path}" if hops > MAX_SYMLINK_HOPS

              # A relative link target resolves against the DIRECTORY
              # CONTAINING THE LINK, never the original path's directory
              # (review 8x333sqw).
              target = File.readlink(current)
              current = File.expand_path(target, File.dirname(current))
              next
            end
            verify_owned!(stat, "trusted HITL authorization path component", current)
            parent = File.dirname(current)
            break if parent == current || parent == "."

            current = parent
          end
          File.realpath(path)
        rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
          raise Lifecycle::Error, "trusted HITL authorization path is not verifiable: #{path}"
        end

        def verify_owned!(stat, what, path)
          return if stat.uid.zero? && (stat.mode & 0o022).zero?

          raise Lifecycle::Error,
            "#{what} must be root-owned and not group/world-writable: #{path}"
        end
      end

      # The authorization seam of the scoped store boundary (spec
      # 8wq.t.34i): which authenticated peers may act as the configured
      # transport (submit correlated answers, observe non-secret
      # projections). ace-lab supplies the deployment facts; ace-hitl owns
      # the contract. The default denies everything — direct-library use
      # gets requester-only semantics and no transport authority.
      class AccessPolicy
        def proposal?(_peer, project:)
          false
        end
        # @return [Boolean] true when the peer may deliver answers and
        #   observe pending/states for the given project
        def transport?(_peer, project: nil)
          false
        end

        # @return [Integer, nil] the trusted service identity clients must
        #   see on the boundary endpoint, or nil when unconfigured
        def service_uid
          nil
        end
      end

      # Grants-backed policy: transport principals and the service
      # identity come only from the trusted deployment document, matched
      # against the KERNEL-VERIFIED peer uid (never a claimed name).
      class GrantsPolicy < AccessPolicy
        attr_reader :grants_path

        def initialize(grants_path: nil, document: nil)
          @grants_path = grants_path
          @document = document
        end

        def transport?(peer, project: nil)
          facts = hitl_facts
          return false unless facts["transport_uids"].is_a?(Array) && facts["transport_uids"].include?(peer.uid)

          projects = authorized_projects(peer.uid)
          return false if projects.nil?
          # A transport uid without a principals entry is nobody (aligned
          # with ace-lab's HitlAuthorizer; review 8x327buh); an entry
          # with an empty project list sees every project.
          project.nil? || projects.empty? || projects.include?(project.to_s)
        end

        def service_uid
          uid = hitl_facts["service_uid"]
          uid.is_a?(Integer) ? uid : nil
        end

        # Decision admission is explicitly installed, never inferred from
        # an ordinary requester or transport grant.
        def proposal?(peer, project:)
          uids = hitl_facts["proposal_uids"]
          projects = authorized_projects(peer.uid)
          uids.is_a?(Array) && uids.include?(peer.uid) && projects &&
            (projects.empty? || projects.include?(project.to_s))
        end

        private

        def document
          @document ||= TrustedFile.read_yaml(@grants_path) || {}
        end

        def hitl_facts
          facts = document["hitl"]
          facts.is_a?(Hash) ? facts : {}
        end

        # Union of project IDs visible to this transport uid through the
        # principals section (uid-string grants share one namespace with
        # usernames; a numeric match is uid-exact).
        def authorized_projects(uid)
          principals = document["authorization"].is_a?(Hash) ? document["authorization"]["principals"] : {}
          return nil unless principals.is_a?(Hash)

          policy = principals[uid.to_s]
          return nil unless policy.is_a?(Hash)

          Array(policy["projects"]).map(&:to_s)
        end
      end
    end
  end
end
