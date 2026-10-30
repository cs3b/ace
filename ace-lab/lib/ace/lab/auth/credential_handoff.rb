# frozen_string_literal: true

require "fileutils"

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
        def initialize(credentials_dir, recipient: )
          @credentials_dir = credentials_dir
          @recipient = recipient
        end

        def path(lease_id)
          File.join(@credentials_dir, "#{lease_id}-#{@recipient}")
        end

        # @return [String] the credential file path (the reference)
        def deliver(lease_id, secret)
          FileUtils.mkdir_p(@credentials_dir)
          target = path(lease_id)
          raise Error, "credential handoff path is a symlink; refusing" if File.symlink?(target)

          temporary = "#{target}.#{Process.pid}.tmp"
          File.write(temporary, secret.to_s)
          FileUtils.chmod(0o400, temporary)
          File.rename(temporary, target)
          target
        end

        def clear(lease_id)
          target = path(lease_id)
          File.delete(target) if File.file?(target) && !File.symlink?(target)
          :cleared
        rescue Errno::ENOENT
          :cleared
        end
      end
    end
  end
end
