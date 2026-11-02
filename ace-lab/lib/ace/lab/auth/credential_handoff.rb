# frozen_string_literal: true

require "fileutils"
require "etc"
require "pathname"
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

        def initialize(credentials_dir, recipient:, owner_uid: nil)
          @credentials_dir = credentials_dir
          @recipient = recipient
          @owner = Etc.getpwuid(Integer(owner_uid)) unless owner_uid.nil?
          raise Error, "credential recipient must not be root" if @owner && (@owner.uid.zero? || @owner.gid.zero?)
          raise Error, "credential recipient does not match its uid" if @owner && @recipient != @owner.name
        end

        def path(lease_id)
          raise Error, "invalid credential lease id" unless lease_id.to_s.match?(/\Alease-[a-zA-Z0-9_-]+\z/)
          File.join(@credentials_dir, "#{lease_id}-#{@recipient}")
        end

        def prepare!
          @owner ? prepare_owned_directory! : FileUtils.mkdir_p(@credentials_dir)
        end

        # @return [String] the credential file path (the reference)
        def deliver(lease_id, secret)
          prepare!
          target = path(lease_id)
          raise Error, "credential handoff path is a symlink; refusing" if File.symlink?(target)

          Tempfile.create([".credential-", ".tmp"], @credentials_dir) do |temporary|
            temporary.write(secret.to_s)
            temporary.flush
            temporary.fsync
            temporary.chmod(0o400)
            temporary.chown(@owner.uid, @owner.gid) if @owner && Process.euid.zero?
            File.rename(temporary.path, target)
          end
          target
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

        # A privileged issuer may only deliver under a root-controlled,
        # non-symlink path. Search permission lets the recipient reach its
        # own 0400 file without granting directory listing or write access.
        def prepare_owned_directory!
          raise Error, "session credential delivery requires root" unless Process.euid.zero?

          directory = Pathname.new(@credentials_dir)
          unless directory.absolute? && directory.cleanpath.to_s == @credentials_dir && directory.to_s != "/"
            raise Error, "session credential directory must be a normalized absolute path"
          end
          current = "/"
          directory.each_filename do |part|
            current = File.join(current, part)
            begin
              stat = File.lstat(current)
            rescue Errno::ENOENT
              created = false
              begin
                Dir.mkdir(current, 0o711)
                created = true
              rescue Errno::EEXIST
                # Another issuer created it; validate it below.
              end
              File.chmod(0o711, current) if created
              stat = File.lstat(current)
            end
            unless stat.directory? && !stat.symlink? && stat.uid.zero? && (stat.mode & 0o022).zero?
              raise Error, "session credential path is not root-controlled: #{current}"
            end
            unless (stat.mode & 0o001) != 0
              raise Error, "session credential path is not searchable by the recipient: #{current}"
            end
          end
        end
      end
    end
  end
end
