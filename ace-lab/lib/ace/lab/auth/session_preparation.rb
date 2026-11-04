# frozen_string_literal: true

require "json"
require_relative "session_launcher"
require_relative "session_configuration"

module Ace
  module Lab
    module Auth
      # Runs while SessionEntry is still waiting. The launcher must stop the
      # unit on any failure; systemd removes its private runtime directory.
      class SessionPreparation
        MAX_CREDENTIALS = 65_536

        def initialize(privileged: Process.euid.zero?, claim: ->(identity) { SessionPeer.new.prepare_runtime(identity) },
          verify: Ace::Runtime::Molecules::ProtectedSocket.method(:root_path!),
          platform: Ace::Runtime::Molecules::ProtectedLinux.new, owner_uid: 0)
          @privileged, @claim, @verify, @platform, @owner_uid = privileged, claim, verify, platform, owner_uid
        end

        def call(identity:, selection:)
          raise Error, "session preparation requires root" unless @privileged
          unless identity.is_a?(SessionLauncher::Identity) && selection.is_a?(SessionConfiguration::Selection)
            raise ArgumentError, "configured session identity required"
          end
          source = selection.runtime.fetch("credentials")
          @verify.call(source, directory: false)
          credentials = File.open(source, File::RDONLY | File::NOFOLLOW) do |file|
            stat = file.stat
            unless stat.file? && stat.uid == @owner_uid && (stat.mode & 0o7777) == 0o600
              raise Error, "model credential source is not private and host-owned"
            end
            bytes = file.read(MAX_CREDENTIALS + 1)
            raise Error, "model credential source exceeds its limit" if bytes.bytesize > MAX_CREDENTIALS
            JSON.parse(bytes, create_additions: false, allow_duplicate_key: false, max_nesting: 8)
          end
          provider = selection.runtime.fetch("provider")
          unless credentials.is_a?(Hash) && credentials[provider].is_a?(Hash) && !credentials[provider].empty?
            raise Error, "configured model provider credentials are unavailable"
          end
          root = @claim.call(identity)
          uid, gid = identity.process.values_at("uid", "gid")
          %w[home pi].each do |name|
            path = File.join(root, name)
            Dir.mkdir(path, 0o700)
            File.chown(uid, gid, path)
          end
          File.open(File.join(root, "pi", "auth.json"), File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o400) do |file|
            file.write(JSON.generate(provider => credentials.fetch(provider)))
            file.flush
            file.fsync
            file.chown(uid, gid)
          end
          @platform.live!(identity.process)
          raise Error, "session exited during preparation" if @platform.exited?(identity.pidfd)
          root
        rescue JSON::ParserError, SystemCallError, IOError, KeyError, Ace::Runtime::Error
          raise Error, "private session preparation failed"
        end
      end
    end
  end
end
