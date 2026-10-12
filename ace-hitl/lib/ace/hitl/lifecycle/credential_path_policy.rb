# frozen_string_literal: true

require "etc"

module Ace
  module Hitl
    module Lifecycle
      # Provisioning-time enforcement of the one exact ownership/mode
      # layout of the host/Incus crossing (spec 8xa.t.nh0). There are no
      # mode alternatives:
      #
      # - every credential-tree ancestor above the project leaf is
      #   `root:root` mode `0755` (verified up to the filesystem root);
      # - the project credential directory is `root:<service-group>`
      #   mode `0750`;
      # - the referenced private key is `<service-user>:<service-group>`
      #   mode `0400` and never hard-linked;
      # - the referenced certificate and CA bundle are `root:root`
      #   mode `0444`;
      # - the root-owned runtime file containing endpoint/credential
      #   references is `root:<service-group>` mode `0640`;
      # - each path component and file is a regular owned object: no
      #   symlink, group/world-writable component, hard-linked key or
      #   ownership substitution is accepted.
      #
      # Exact mode + exact owner/group verification is the enforceable
      # ACL proxy: any POSIX ACL that grants beyond the declared mode
      # surfaces in the group class bits and fails the exact match.
      #
      # Any missing, unreadable, redirected, over-broad, incorrectly
      # owned/mode-set or mismatched object REFUSES STARTUP before a
      # socket is opened: every check runs before the TLS service binds.
      class CredentialPathPolicy
        Error = Class.new(Lifecycle::Error)

        ANCESTOR_MODE = 0o755
        PROJECT_DIR_MODE = 0o750
        KEY_MODE = 0o400
        PUBLIC_MODE = 0o444
        RUNTIME_FILE_MODE = 0o640

        class << self
          # Verify the three referenced credential files of one project
          # credential object (server or client form; both share the
          # layout).
          def verify_credential_tree!(credential:, service_user:, service_group:)
            new(service_user: service_user, service_group: service_group)
              .verify_credential_tree!(credential)
          end

          # Verify one root-owned runtime configuration file that holds
          # endpoint/credential references.
          def verify_runtime_file!(path, service_group:)
            new(service_user: nil, service_group: service_group).verify_runtime_file!(path)
          end
        end

        def initialize(service_user:, service_group:)
          # The runtime-file check verifies root ownership only; the
          # service user is required for the key ownership rule.
          @service_uid = service_user.nil? ? nil : resolve_user(service_user)
          @service_gid = resolve_group(service_group)
        end

        def verify_credential_tree!(credential)
          roles = {"certificate_file" => :public, "private_key_file" => :key, "ca_file" => :public}
          # Pass one: structural verification of EVERY referenced file
          # (existence, no symlink, regular file) before any ownership
          # comparison — structural refusals never depend on privilege.
          paths = roles.map do |field, role|
            path = credential.fetch(field)
            lstat_file!(path, "credential file")
            [path, role]
          end
          # Pass two: the exact ownership/mode rules per role.
          paths.each do |path, role|
            verify_owner_mode!(path, role)
          end
          project_dir = File.dirname(paths.first.first)
          unless paths.all? { |path, _role| File.dirname(path) == project_dir }
            raise Error,
              "credential files must share one project credential directory " \
              "(#{paths.map(&:first).join(", ")})"
          end
          verify_project_directory(project_dir)
          verify_ancestors(project_dir)
          self
        end

        def verify_runtime_file!(path)
          stat = lstat_file!(path, "runtime configuration file")
          unless stat.uid.zero? && stat.gid == @service_gid && (stat.mode & 0o7777) == RUNTIME_FILE_MODE
            raise Error,
              "runtime configuration file must be root:<service-group> mode 0640: #{path} " \
              "(got uid=#{stat.uid} gid=#{stat.gid} mode=#{stat.mode.to_s(8)})"
          end

          self
        end

        private

        def verify_owner_mode!(path, role)
          stat = File.lstat(path)
          expected_owner = role == :key ? [@service_uid, @service_gid] : [0, 0]
          expected_mode = role == :key ? KEY_MODE : PUBLIC_MODE
          unless [stat.uid, stat.gid] == expected_owner && (stat.mode & 0o7777) == expected_mode
            raise Error,
              "credential file has the wrong owner or mode: #{path} (got uid=#{stat.uid} " \
              "gid=#{stat.gid} mode=#{stat.mode.to_s(8)})"
          end
          if role == :key && stat.nlink != 1
            raise Error, "credential private key must not be hard-linked: #{path}"
          end
        end

        def verify_project_directory(path)
          stat = File.lstat(path)
          unless stat.directory? && !stat.symlink?
            raise Error, "project credential directory is not a regular directory: #{path}"
          end
          unless stat.uid.zero? && stat.gid == @service_gid && (stat.mode & 0o7777) == PROJECT_DIR_MODE
            raise Error,
              "project credential directory must be root:<service-group> mode 0750: #{path} " \
              "(got uid=#{stat.uid} gid=#{stat.gid} mode=#{stat.mode.to_s(8)})"
          end
        rescue Errno::ENOENT
          raise Error, "project credential directory does not exist: #{path}"
        end

        # Every ancestor above the project leaf — up to the filesystem
        # root — is a root:root 0755 directory. A group/world-writable,
        # foreign-owned or symlinked component anywhere on the chain
        # would allow credential substitution.
        def verify_ancestors(path)
          parent = File.expand_path("..", path)
          components = parent.split("/").reject(&:empty?)
          verify_ancestor!("/", File.lstat("/"))
          components.each_with_object("") do |component, current|
            current << "/#{component}"
            stat = File.lstat(current)
            verify_ancestor!(current, stat)
          end
        end

        def verify_ancestor!(path, stat)
          unless stat.directory? && !stat.symlink? && stat.uid.zero? && stat.gid.zero? &&
              (stat.mode & 0o7777) == ANCESTOR_MODE
            raise Error,
              "credential path ancestor must be a root:root mode 0755 directory: #{path} " \
              "(got uid=#{stat.uid} gid=#{stat.gid} mode=#{stat.mode.to_s(8)})"
          end
        rescue Errno::ENOENT
          raise Error, "credential path ancestor does not exist: #{path}"
        end

        def lstat_file!(path, label)
          stat = File.lstat(path)
          raise Error, "#{label} must not be a symlink: #{path}" if stat.symlink?
          raise Error, "#{label} is not a regular file: #{path}" unless stat.file?

          stat
        rescue Errno::ENOENT
          raise Error, "#{label} does not exist: #{path}"
        rescue SystemCallError
          raise Error, "#{label} is not verifiable: #{path}"
        end

        def resolve_user(name)
          Etc.getpwnam(name.to_s).uid
        rescue ArgumentError
          raise Error, "the configured service user does not exist: #{name.inspect}"
        end

        def resolve_group(name)
          Etc.getgrnam(name.to_s).gid
        rescue ArgumentError
          raise Error, "the configured service group does not exist: #{name.inspect}"
        end
      end
    end
  end
end
