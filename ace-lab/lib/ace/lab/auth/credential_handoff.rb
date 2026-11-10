# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Ace
  module Lab
    module Auth
      # Ephemeral secret handoff (task 8xs.t.pu0.7): the leased secret
      # is written ONCE under the credentials dir (/run/lab/credentials
      # by default), in a per-lease, per-recipient file, mode 0400,
      # verified against symlink takeover; the child receives the file
      # REFERENCE (path), never the value in argv or the serialized
      # report. Removal after the lease is idempotent.
      class CredentialHandoff
        def self.projection_prefix(credential)
          "#{File.basename(credential)}.forgejo-session-"
        end

        def initialize(credentials_dir, recipient:)
          @credentials_dir = credentials_dir
          @recipient = recipient
        end

        def path(lease_id)
          raise Error, "invalid credential lease id" unless lease_id.to_s.match?(/\Alease-[a-zA-Z0-9_-]+\z/)
          File.join(@credentials_dir, "#{lease_id}-#{@recipient}")
        end

        def deliver(lease_id, secret)
          FileUtils.mkdir_p(@credentials_dir, mode: 0o700)
          target = path(lease_id)
          deliver_into(@credentials_dir, target, secret)
        end

        def clear(lease_id)
          target = path(lease_id)
          File.delete(target) if File.file?(target) && !File.symlink?(target)
          # A killed Forgejo executor may leave its private fj login
          # projection behind; it belongs to this same handoff lifecycle.
          prefix = self.class.projection_prefix(target)
          Dir.children(@credentials_dir).grep(/^#{Regexp.escape(prefix)}/).each do |name|
            dir = File.join(@credentials_dir, name)
            raise Error, "session projection is a symlink; refusing cleanup" if File.symlink?(dir)
            FileUtils.remove_entry_secure(dir) if File.directory?(dir)
          end
          :cleared
        rescue Errno::ENOENT
          :cleared
        end

        private

        def deliver_into(directory, public_target, secret)
          target = File.join(directory, File.basename(public_target))
          raise Error, "credential handoff path is a symlink; refusing" if File.symlink?(target)

          Tempfile.create([".credential-", ".tmp"], directory) do |temporary|
            temporary.write(secret.to_s)
            temporary.flush
            temporary.fsync
            temporary.chmod(0o400)
            File.rename(temporary.path, target)
          end
          public_target
        end

      end
    end
  end
end
