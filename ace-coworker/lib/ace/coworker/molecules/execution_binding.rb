# frozen_string_literal: true

require "yaml"
require "tempfile"
require "date"

module Ace::Coworker::Molecules
  # The commission already owns the assignment identity. Keep the native
  # executor binding on that same document, never in a second registry.
  class ExecutionBinding
    def with_lock(path, create: false)
      File.open("#{path}.lock", File::RDWR | File::CREAT | File::NOFOLLOW, 0o600) do |lock|
        raise Ace::Coworker::Error, "executor commission lock is invalid" unless lock.stat.file?
        lock.flock(File::LOCK_EX)
        document = if create && !File.exist?(path) && !File.symlink?(path)
          {}
        else
          File.open(path, File::RDONLY | File::NOFOLLOW) do |file|
            raise Ace::Coworker::Error, "executor commission is invalid" unless file.stat.file?
            YAML.safe_load(file.read, permitted_classes: [Date, Time], aliases: false)
          end
        end
        raise Ace::Coworker::Error, "executor commission is invalid" unless document.is_a?(Hash)
        save = lambda do
          Tempfile.create([".execution-", ".yml"], File.dirname(path)) do |file|
            file.write(YAML.safe_dump(document))
            file.flush
            file.fsync
            File.rename(file.path, path)
            File.open(File.dirname(path), File::RDONLY) { |directory| directory.fsync }
          end
        end
        yield document, save
      end
    rescue Psych::Exception, SystemCallError => e
      raise Ace::Coworker::Error, "executor commission unavailable (#{e.class})"
    end
  end
end
