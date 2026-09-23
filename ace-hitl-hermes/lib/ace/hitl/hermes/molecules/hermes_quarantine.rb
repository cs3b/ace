# frozen_string_literal: true

require "fileutils"
require_relative "hermes_contract"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Quarantine for invalid message files (spec 8wm.t.vs1 §7): the
        # file is moved atomically into <folder>/.quarantine/ (0750) with
        # a <name>.reason.txt sidecar (0640). Quarantined content is never
        # rewritten, re-validated, or delivered.
        module HermesQuarantine
          module_function

          # Moves `path` (inside `folder`) into the quarantine directory
          # and writes the reason sidecar. Returns the quarantined path.
          def move(folder, path, reason:, now: -> { Time.now })
            quarantine_dir = HermesContract.quarantine_path(folder)
            unless File.directory?(quarantine_dir)
              Dir.mkdir(quarantine_dir, HermesContract::QUARANTINE_DIR_MODE)
            end

            base = File.basename(path)
            dest = File.join(quarantine_dir, base)
            suffix = 0
            while File.exist?(dest)
              suffix += 1
              dest = File.join(quarantine_dir, "#{base}.#{suffix}")
            end

            File.rename(path, dest)
            File.open("#{dest}#{HermesContract::REASON_EXT}",
              File::WRONLY | File::CREAT | File::EXCL,
              HermesContract::FILE_MODE) do |sidecar|
              sidecar.write("#{now.call.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} #{reason}\n")
            end
            dest
          end
        end
      end
    end
  end
end
