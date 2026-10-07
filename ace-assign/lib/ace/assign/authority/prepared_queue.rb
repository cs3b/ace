# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "yaml"
require_relative "prepared_work"
require_relative "private_directory"
require_relative "../molecules/lifecycle_exclusion"
require_relative "../organisms/assignment_executor"

module Ace
  module Assign
    module Authority
      # Existing assignment/progress files, rooted only in the authenticated
      # original worker scratch. This cache never supplies authority or a graph.
      class PreparedQueue
        attr_reader :cache_base, :directory, :work, :descriptor

        def initialize(work:, descriptor:)
          @work, @descriptor = work, descriptor
          @scratch = PrivateDirectory.verify!(descriptor.fetch("original_worker_scratch_root"))
          %w[mapping_id attempt_id assignment_id].each do |field|
            value = descriptor.fetch(field)
            unavailable!("queue identity") unless value.is_a?(String) && value.match?(PreparedWork::TOKEN)
          end
          @cache_base = File.join(@scratch, "prepared-queues", descriptor.fetch("mapping_id"), descriptor.fetch("attempt_id"))
          @directory = File.join(cache_base, descriptor.fetch("assignment_id"))
          definition = JSON.parse(work.definition_bytes(head: descriptor.fetch("prepared_head"), tree: descriptor.fetch("prepared_tree")))
          unavailable!("captured assignment metadata") unless %w[name source_config created_at].all? do |field|
            definition[field].is_a?(String) && !definition[field].empty?
          end
          validate_timestamp!(definition.fetch("created_at"))
          validate_timestamp!(definition["updated_at"]) if definition.key?("updated_at")
          @metadata = Models::Assignment.from_h(definition, cache_dir: directory).to_h
          lock_root = File.join(@scratch, "prepared-queue-exclusion")
          private_directory!(lock_root, create: true)
          @exclusion = Molecules::LifecycleExclusion.new(root: lock_root)
          @key = @exclusion.assignment_key(descriptor.values_at("mapping_id", "attempt_id", "assignment_id").join(":"))
        end

        # Called ONLY after the fixed adapter proves actual original self. Later
        # CLI consumers use with_executor and cannot recreate a missing queue.
        def activate_original!
          @exclusion.with_exclusive(@key) do
            publish_initial! unless File.exist?(directory) || File.symlink?(directory)
            executor = verified_executor
            result = executor.status
            state = result.fetch(:state)
            unavailable!("selected queue has failed progress") unless state.failed.empty?
            return nil if state.subtree_complete?(descriptor.fetch("scope"))
            unless state.steps.all? { |step| step.status == :pending }
              unavailable!("original adapter has already activated queue progress")
            end
            root = state.find_by_number(descriptor.fetch("scope"))
            unavailable!("original selected fork root") unless root && root.fork?
            executor.step_writer.mark_active(root.file_path)
            # Same held-byte consumer validates the resulting progress before
            # returning to the adapter that may now start its provider.
            executor.status
            root
          end
        end

        def with_executor
          @exclusion.with_exclusive(@key) do
            unavailable!("published queue is unavailable; no reconstruction") unless File.directory?(directory)
            yield verified_executor
          end
        end

        private

        def verified_executor
          private_directory!(directory)
          private_directory!(File.join(directory, "steps"))
          private_directory!(File.join(directory, "reports"))
          metadata = work.parse_queue_metadata!(held_read(File.join(directory, "assignment.yaml"), PreparedWork::MAX_MANIFEST))
          unavailable!("queue assignment metadata differs") unless metadata.is_a?(Hash) &&
            metadata.reject { |key, _| key == "updated_at" } == @metadata.reject { |key, _| key == "updated_at" }
          validate_timestamp!(metadata["updated_at"]) if metadata.key?("updated_at")
          unavailable!("queue job differs") unless held_read(File.join(directory, "job.yaml"), PreparedWork::MAX_TEXT) == work.files.fetch("job.yaml")
          owner = self
          scanner = Molecules::QueueScanner.new
          parser = scanner.method(:scan_captured)
          scanner.define_singleton_method(:scan) do |steps_dir, assignment:|
            raise AttemptErrors::EvidenceUnavailable, "prepared queue scanner path differs" unless steps_dir == File.join(owner.directory, "steps")
            steps, reports = owner.send(:captured_queue)
            parser.call(steps: steps, assignment: assignment, reports: reports)
          end
          Organisms::AssignmentExecutor.new(cache_base: cache_base,
            selected_assignment: Models::Assignment.from_h(metadata, cache_dir: directory), queue_scanner: scanner)
        end

        def captured_queue
          expected = work.manifest.fetch("steps").map { |entry| entry.fetch("filename") }
          steps_dir = File.join(directory, "steps")
          unavailable!("queue step inventory differs") unless Dir.children(steps_dir).sort == expected.sort
          steps = expected.to_h do |filename|
            bytes = held_read(File.join(steps_dir, filename), PreparedWork::MAX_TEXT)
            parsed = work.parse_queue_step!(bytes)
            accepted = work.parse_queue_step!(work.files.fetch("steps/" + filename))
            projection = ->(value) { value.fetch(:frontmatter).reject { |key, _| PreparedWork::PROGRESS.include?(key) } }
            unless projection.call(parsed) == projection.call(accepted) && parsed.fetch(:body) == accepted.fetch(:body) &&
                %w[pending active done failed].include?(parsed.fetch(:frontmatter).fetch("status", "pending"))
              unavailable!("queue work-bearing input differs")
            end
            [filename, bytes]
          end
          reports_dir = File.join(directory, "reports")
          allowed = work.manifest.fetch("steps").map do |entry|
            name = work.parse_queue_step!(work.files.fetch("steps/" + entry.fetch("filename"))).fetch(:frontmatter).fetch("name")
            Atoms::StepFileParser.generate_report_filename(entry.fetch("number"), name)
          end
          reports = Dir.children(reports_dir).to_h do |filename|
            unavailable!("queue report inventory differs") unless allowed.include?(filename)
            bytes = held_read(File.join(reports_dir, filename), PreparedWork::MAX_TEXT)
            work.parse_queue_step!(bytes)
            [filename, bytes]
          end
          [steps.freeze, reports.freeze]
        end

        def publish_initial!
          private_directory!(File.join(@scratch, "prepared-queues"), create: true)
          private_directory!(File.dirname(cache_base), create: true)
          private_directory!(cache_base, create: true)
          stage = File.join(cache_base, ".prepared-#{SecureRandom.hex(12)}")
          Dir.mkdir(stage, 0700)
          %w[steps reports].each { |name| Dir.mkdir(File.join(stage, name), 0700) }
          durable_write(File.join(stage, "assignment.yaml"), @metadata.to_yaml)
          durable_write(File.join(stage, "job.yaml"), work.files.fetch("job.yaml"))
          work.manifest.fetch("steps").each do |entry|
            name = entry.fetch("filename")
            durable_write(File.join(stage, "steps", name), work.files.fetch("steps/" + name))
          end
          %w[steps reports].each { |name| File.open(File.join(stage, name), File::RDONLY) { |file| file.fsync } }
          File.open(stage, File::RDONLY) { |file| file.fsync }
          unavailable!("queue publication collision") if File.exist?(directory) || File.symlink?(directory)
          File.rename(stage, directory)
          File.open(cache_base, File::RDONLY) { |file| file.fsync }
        ensure
          FileUtils.remove_entry(stage) if stage && File.directory?(stage) && !File.symlink?(stage)
        end

        def private_directory!(path, create: false)
          Dir.mkdir(path, 0700) if create && !File.exist?(path) && !File.symlink?(path)
          PrivateDirectory.verify!(path)
        end

        def durable_write(path, bytes)
          File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) do |file|
            file.write(bytes); file.flush; file.fsync
          end
        end

        def held_read(path, limit)
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            before = file.stat
            unavailable!("queue held file kind/size") unless before.file? && before.uid == Process.uid &&
              (before.mode & 0077).zero? && before.size.between?(1, limit)
            bytes = file.read(limit + 1).force_encoding(Encoding::UTF_8)
            after = file.stat
            unavailable!("queue held file changed") unless bytes.valid_encoding? && !bytes.include?("\0") &&
              bytes.bytesize == before.size && [before.dev, before.ino, before.size, before.mtime, before.ctime] ==
                [after.dev, after.ino, after.size, after.mtime, after.ctime]
            bytes.freeze
          end
        rescue SystemCallError
          unavailable!("queue held file unavailable")
        end

        def unavailable!(reason)
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: #{reason}"
        end

        def validate_timestamp!(value)
          unavailable!("captured assignment timestamp") unless value.is_a?(String)
          Time.iso8601(value)
        rescue ArgumentError
          unavailable!("captured assignment timestamp")
        end
      end
    end
  end
end
