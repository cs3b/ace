# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "find"
require "ace/assign/authority/candidate_transfer"
require_relative "../molecules/command_policy"
require_relative "../molecules/command_test_runtime"

module Ace
  module Lab
    module Organisms
      # The existing ephemeral root helper owns materialization. This performs
      # data/object I/O only: no candidate code, Bundler or gemspec is run root.
      class CommandCandidateView
        def initialize(project:, definition:, policy_loader: nil)
          @project, @definition = project, definition
          @policy_loader = policy_loader || -> { Molecules::CommandPolicy.load(project: @project) }
        end

        def prepare!
          unless Process.uid.zero? && Process.euid.zero? && RUBY_PLATFORM.include?("linux")
            raise SecurityError, "candidate materialization requires Linux root"
          end
          recipe = @definition.fetch("materialization")
          selected = @policy_loader.call.select(
            selection: @definition.fetch("selection"), peer: @definition.fetch("requester"))
          runtime = Molecules::CommandTestRuntime.load(selected.fetch("source"))
          expected = runtime.compile(definition: selected, execution_id: recipe.fetch("execution_id"),
            candidate: @definition.fetch("candidate"))
          unless expected == @definition.except("native_binding")
            raise SecurityError, "root selected candidate command definition differs"
          end
          runtime.verify_installed!
          parent = recipe.fetch("root")
          Molecules::GrantResolver.trusted_directory!(parent)
          root = File.join(parent, recipe.fetch("execution_id"))
          # EXCL directory creation: replay/recovery never reuses another view.
          begin
            Dir.mkdir(root, 0o755)
          rescue Errno::EEXIST
            raise SecurityError, "candidate view already exists"
          end
          created = File.lstat(root)
          Dir.mktmpdir("input-", root) do |scratch|
            candidate = @definition.fetch("candidate")
            bytes = yield scratch
            materialized = Ace::Assign::Authority::CandidateTransfer.new(root: scratch).materialize_repository(
              bytes: bytes, sha256: candidate.fetch("sha256"), size: candidate.fetch("bytes"),
              head: candidate.fetch("head"), tree: candidate.fetch("tree"), root: scratch,
              max_entries: Molecules::CommandPolicy::MAX_SOURCE_ENTRIES)
            File.rename(materialized.fetch("directory"), File.join(root, "source"))
          end
          config = File.join(root, "config")
          Dir.mkdir(config, 0o755)
          write_new(File.join(config, "Gemfile"), runtime.gemfile(root))
          write_new(File.join(config, "runner.json"), runtime.configuration(root))
          output = File.join(root, "output")
          Dir.mkdir(output, 0o700)
          %w[tmp cache bundle reports].each { |name| Dir.mkdir(File.join(output, name), 0o700) }
          write_new(File.join(output, "Gemfile.lock"), "")
          File.chmod(0o600, File.join(output, "Gemfile.lock"))
          File.symlink(File.join(output, "Gemfile.lock"), File.join(config, "Gemfile.lock"))
          executor = @definition.fetch("executor")
          Find.find(output, ignore_error: false) { |path| File.chown(executor.fetch("uid"), executor.fetch("gid"), path) }
          seal(File.join(root, "source"))
          File.chmod(0o555, config)
          File.chmod(0o555, root)
          prepared = true
          true
        rescue SystemCallError
          raise SecurityError, "candidate view is not fully observable"
        ensure
          if created && !prepared
            current = begin
              File.lstat(root)
            rescue SystemCallError
              raise SecurityError, "failed candidate view identity is uncertain"
            end
            unless current.directory? && !current.symlink? && current.uid.zero? &&
                [current.dev, current.ino] == [created.dev, created.ino]
              raise SecurityError, "failed candidate view identity is uncertain"
            end
            # Only our fresh, generated, pre-child view is removed. Accepted
            # source bytes remain in the canonical journal; EEXIST is untouched.
            FileUtils.remove_entry_secure(root)
          end
        end

        private

        def write_new(path, bytes)
          File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0o444) do |file|
            file.write(bytes)
            file.chmod(0o444)
            file.flush
            file.fsync
          end
        end

        def seal(root)
          paths = []
          Find.find(root, ignore_error: false) do |path|
            stat = File.lstat(path)
            if stat.symlink?
              unless stat.uid.zero? && File.realpath(path).start_with?(root + "/")
                raise SecurityError, "candidate alias escaped sealed source"
              end
            elsif stat.file?
              File.chmod((stat.mode & 0o111).zero? ? 0o444 : 0o555, path)
            elsif stat.directory?
              paths << path
            else
              raise SecurityError, "candidate materialization contains unsupported entry"
            end
          end
          paths.reverse_each { |path| File.chmod(0o555, path) }
        end
      end
    end
  end
end
