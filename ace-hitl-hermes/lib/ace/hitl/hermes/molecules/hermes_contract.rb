# frozen_string_literal: true

require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Versioned folder contract constants + folder-level rules
        # (spec 8wm.t.vs1 §§1-5). The plugin implements contract version
        # ace.hitl.hermes.folder/v1; the canonical shared-contract file is
        # settled by A4 (8wm.t.vs2), the lab-config consumer side is
        # 8wm.t.vp9 (separate repository).
        module HermesContract
          FOLDER_CONTRACT = "ace.hitl.hermes.folder/v1"
          MESSAGE_SCHEMA = "ace.hitl.hermes.message/v1"

          # Content bounds: UTF-8 only, at most 64 KiB per message file.
          MAX_BYTES = 65_536

          # Permissions: message files 0640, tmp files 0600 during the
          # atomic write, quarantine directory 0750. No root, ever.
          FILE_MODE = 0o640
          TMP_MODE = 0o600
          QUARANTINE_DIR_MODE = 0o750

          MESSAGE_EXT = ".json"
          TMP_PREFIX = ".hermes-tmp-"
          QUARANTINE_DIR = ".quarantine"
          REASON_EXT = ".reason.txt"

          TMP_BASENAME_PREFIX = "." # every tmp file is a dotfile; poll never sees it

          module_function

          # Fail-closed folder verification before EVERY folder operation:
          # exists, is a directory, writable by the invoking user, and not
          # world-writable.
          def verify_folder!(path)
            unless File.exist?(path)
              raise ContractError, "hermes folder does not exist: #{path}"
            end
            unless File.directory?(path)
              raise ContractError, "hermes folder is not a directory: #{path}"
            end
            unless File.writable?(path)
              raise ContractError, "hermes folder is not writable by the invoking user: #{path}"
            end
            if File.stat(path).mode & 0o002 != 0
              raise ContractError, "hermes folder must not be world-writable: #{path}"
            end

            path
          end

          def file_name(id)
            "#{Atoms::HermesTokens.validate!(id, "message id")}#{MESSAGE_EXT}"
          end

          # `<token>.json` -> id token; anything else is not a message file.
          def parse_file_name(name)
            return nil unless name.is_a?(String) && name.end_with?(MESSAGE_EXT)

            id = name.delete_suffix(MESSAGE_EXT)
            Atoms::HermesTokens.valid?(id) ? id : nil
          end

          def message_path(folder, id)
            File.join(folder, file_name(id))
          end

          def quarantine_path(folder)
            File.join(folder, QUARANTINE_DIR)
          end

          # Shipped machine-readable contract artifact (JSON Schema
          # draft-07) for the message envelope v1.
          def schema_asset_path
            File.expand_path("../schemas/message.v1.schema.json", __dir__)
          end
        end
      end
    end
  end
end
