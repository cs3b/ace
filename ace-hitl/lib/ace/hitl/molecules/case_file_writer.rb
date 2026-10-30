# frozen_string_literal: true

require "ace/support/items"

module Ace
  module Hitl
    module Molecules
      # The one crash-atomic writer for HITL case files (re-review R2):
      # every mutation locks a STABLE sidecar (`<case>.lock`, a file that
      # is never renamed) and replaces the case file via tmp+fsync+rename.
      # A process killed mid-write leaves either the old or the new
      # content — never a truncated or zero-byte case — and mutual
      # exclusion survives the rename (a lock on the case file itself
      # would break the moment its inode is replaced).
      module CaseFileWriter
        module_function

        # Exclusive sidecar lock around a case-file mutation.
        def with_case_lock(file_path)
          File.open("#{file_path}.lock", File::RDWR | File::CREAT, 0o600) do |lock|
            lock.flock(File::LOCK_EX)
            yield
          end
        end

        # Crash-atomic replace of the whole case file (fsynced tmp +
        # rename). Callers hold the sidecar lock.
        def write_atomic(file_path, new_content)
          tmp_path = "#{file_path}.tmp.#{Process.pid}.#{Thread.current.object_id}"
          File.open(tmp_path, "w") do |tmp|
            tmp.write(new_content)
            tmp.flush
            tmp.fsync
          end
          File.rename(tmp_path, file_path)
        ensure
          File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path)
        end

        # Field-only update under the sidecar lock: one locked
        # read-modify-write, replaced atomically — never the shared
        # FieldUpdater's in-place truncate(0) write.
        def apply_fields(file_path, set: {}, add: {}, remove: {})
          with_case_lock(file_path) do
            content = File.read(file_path)
            begin
              frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
            rescue Psych::SyntaxError => e
              # Same error shape as FieldUpdater.parse_strict: a corrupt
              # case file is a named, path-carrying refusal to rewrite —
              # never a raw parser error escaping the writer.
              raise ArgumentError, "#{file_path}: refusing to rewrite the file (#{e.message})"
            end
            # Strip the body's leading newline: rebuild re-inserts the
            # frontmatter/body separator, so keeping it would add one
            # blank line per write — compounding on every field update.
            body = body.sub(/\A\n/, "")
            Ace::Support::Items::Molecules::FieldUpdater.apply_set(frontmatter, set)
            Ace::Support::Items::Molecules::FieldUpdater.apply_add(frontmatter, add)
            Ace::Support::Items::Molecules::FieldUpdater.apply_remove(frontmatter, remove)
            write_atomic(file_path,
              Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, body))
          end
        end
      end
    end
  end
end
