# frozen_string_literal: true

require "securerandom"
require "fileutils"
require_relative "hermes_contract"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Atomic write protocol (spec 8wm.t.vs1 §5): same-directory tmp
        # file (0600) + fsync + chmod 0640 + rename(2) onto the target.
        # Readers never observe partial content; no root privileges are
        # required or used - running as root is refused fail closed.
        module HermesAtomicWriter
          module_function

          # Writes `bytes` to `final_path` atomically. The target must not
          # exist (CollisionError otherwise); tmp files are removed on
          # every failure path. Returns the final path.
          def write(final_path, bytes, euid_provider: -> { Process.euid })
            if euid_provider.call.zero?
              raise RootUserError,
                "hermes writes without root: refusing atomic write as euid 0 " \
                "(#{final_path})"
            end

            folder = File.dirname(final_path)
            HermesContract.verify_folder!(folder)
            if File.exist?(final_path)
              raise CollisionError, "hermes message file already exists: #{final_path}"
            end

            tmp_path = File.join(
              folder,
              "#{HermesContract::TMP_PREFIX}#{Process.pid}-#{SecureRandom.hex(8)}.tmp"
            )
            begin
              File.open(tmp_path, File::WRONLY | File::CREAT | File::EXCL,
                HermesContract::TMP_MODE) do |file|
                file.write(bytes)
                file.fsync
              end
              File.chmod(HermesContract::FILE_MODE, tmp_path)
              File.rename(tmp_path, final_path)
            rescue StandardError
              File.delete(tmp_path) if File.exist?(tmp_path)
              raise
            end
            final_path
          end
        end
      end
    end
  end
end
