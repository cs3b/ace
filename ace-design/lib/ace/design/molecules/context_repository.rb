# frozen_string_literal: true
require "fileutils"
module Ace
  module Design
    module Molecules
      # Cooperative readers and publishers share one lock. Expensive model work
      # happens outside it; publication compares the complete original snapshot.
      class ContextRepository
        attr_reader :root, :runs
        def initialize(project: Dir.pwd)
          @project = File.realpath(project)
          @root = File.join(@project, ".ace-config/design")
          @runs = File.join(@project, ".ace-local/design/adjust")
          @journal = File.join(@project, ".ace-local/design/context-transaction.json")
          @lock = File.join(@project, ".ace-local/design/context.lock")
        end
        def safe_path!(path)
          relative = path.delete_prefix(@project + "/")
          raise Error, "Context path escapes project" if relative == path || relative.split("/").include?("..")
          cursor = @project
          relative.split("/").each do |part|
            cursor = File.join(cursor, part)
            raise Error, "Refusing context symlink: #{cursor}" if File.symlink?(cursor)
          end
        end
        def locked
          safe_path!(@lock)
          FileUtils.mkdir_p(File.dirname(@lock))
          File.open(@lock, File::RDWR | File::CREAT, 0o600) do |file|
            raise Error, "Design contexts are being published; retry" unless file.flock(File::LOCK_EX | File::LOCK_NB)
            Thread.handle_interrupt(Interrupt => :never) do
              recover
              yield
            end
          ensure
            file.flock(File::LOCK_UN)
          end
        end
        def read(readonly: false)
          return locked { read_unlocked } unless readonly
          safe_path!(@lock)
          safe_path!(@journal)
          reader = lambda do
            raise Error, "Pending profile transaction; run profile show to recover before dry-run" if File.exist?(@journal)
            read_unlocked
          end
          unless File.exist?(@lock)
            begin
              snapshot = reader.call
            rescue Error, SystemCallError
              # A first publisher may have moved a file during the unguarded read.
              # Retry under its lock if it appeared; otherwise retain the error.
              raise unless File.exist?(@lock)
            end
            # Publishers keep this lock file permanently. If it appeared during
            # our read, discard the potentially mixed snapshot and read again.
            return snapshot unless File.exist?(@lock)
          end
          safe_path!(@lock)
          File.open(@lock, File::RDONLY) do |file|
            raise Error, "Design contexts are being published; retry" unless file.flock(File::LOCK_SH | File::LOCK_NB)
            reader.call
          ensure
            file.flock(File::LOCK_UN)
          end
        end
        def read_unlocked
          safe_path!(root)
          return {} unless File.exist?(root)
          Artifacts.files(root).to_h { |name| [name, File.binread(File.join(root, name))] }
        end
        def publish(candidate:, original:, run:)
          locked do
            raise Error, "Design contexts changed during adjust; retry with current inputs" unless read_unlocked == original
            safe_path!(candidate)
            safe_path!(run)
            raise Error, "Invalid adjustment directory" unless File.dirname(run) == runs && File.basename(run).match?(/\A[0-9a-z]+\z/)
            backup = File.join(run, "previous")
            raise Error, "Adjustment was already published" if File.exist?(backup)
            # Keep the exact proposal as durable recovery evidence, including first initialization.
            staging = File.join(run, "publishing")
            safe_path!(staging)
            raise Error, "Adjustment publication already staged" if File.exist?(staging)
            FileUtils.cp_r(candidate, staging)
            FileUtils.mkdir_p(File.dirname(root))
            Artifacts.json(@journal, {"token" => File.basename(run), "had_root" => File.exist?(root)})
            begin
              File.rename(root, backup) if File.exist?(root)
              File.rename(staging, root)
              File.unlink(@journal) # commit point; the previous tree remains in the report directory
            rescue Exception # rollback synchronous errors and process interrupts, then propagate
              recover
              raise
            end
          end
        end
        def recover
          safe_path!(@journal)
          return unless File.file?(@journal)
          journal = Artifacts.object(@journal)
          token = journal.fetch("token")
          raise Error, "Invalid context transaction token" unless token.is_a?(String) && token.match?(/\A[0-9a-z]+\z/)
          backup = File.join(runs, token, "previous")
          safe_path!(backup)
          safe_path!(root)
          if File.directory?(backup)
            FileUtils.rm_rf(root)
            File.rename(backup, root)
          elsif journal.fetch("had_root") == false
            FileUtils.rm_rf(root)
          end
          File.unlink(@journal)
        end
      end
    end
  end
end
