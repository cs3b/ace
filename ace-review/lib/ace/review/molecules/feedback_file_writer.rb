# frozen_string_literal: true

require "yaml"
require "fileutils"
require "tempfile"

module Ace
  module Review
    module Molecules
      # Writes FeedbackItem instances to disk as markdown files with YAML frontmatter.
      #
      # Files are written atomically (temp file + rename) with file locking
      # to ensure safe concurrent access.
      #
      # @example Write a feedback item
      #   writer = FeedbackFileWriter.new
      #   result = writer.write(feedback_item, "/path/to/feedback")
      #   result[:success] #=> true
      #   result[:path]    #=> "/path/to/feedback/8o7abc-missing-error-handling.s.md"
      #
      class FeedbackFileWriter
        # Write a FeedbackItem to disk
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item to write
        # @param directory [String] The directory to write to
        # @return [Hash] Result hash with :success, :path or :error keys
        def write(feedback_item, directory)
          validate_inputs(feedback_item, directory)

          filename = generate_filename(feedback_item)
          file_path = File.join(directory, filename)
          content = generate_content(feedback_item)

          write_atomic(file_path, content)
        rescue ArgumentError => e
          {success: false, error: e.message}
        rescue SystemCallError, IOError => e
          {success: false, error: "Failed to write feedback file: #{e.message}"}
        end

        private

        # Validate inputs before writing
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item
        # @param directory [String] The directory path
        # @raise [ArgumentError] If inputs are invalid
        def validate_inputs(feedback_item, directory)
          raise ArgumentError, "feedback_item is required" if feedback_item.nil?
          raise ArgumentError, "directory is required" if directory.nil? || directory.empty?
          raise ArgumentError, "directory does not exist: #{directory}" unless Dir.exist?(directory)

          unless feedback_item.is_a?(Models::FeedbackItem)
            raise ArgumentError, "feedback_item must be a FeedbackItem"
          end

          raise ArgumentError, "feedback_item.id is required" if feedback_item.id.nil? || feedback_item.id.empty?
          raise ArgumentError, "feedback_item.title is required" if feedback_item.title.nil? || feedback_item.title.empty?
        end

        # Generate the filename for a feedback item
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item
        # @return [String] The filename in format: {id}-{slug}.s.md
        def generate_filename(feedback_item)
          slug = Atoms::FeedbackSlugGenerator.generate(feedback_item.title)
          "#{feedback_item.id}-#{slug}.s.md"
        end

        # Generate the file content with YAML frontmatter and markdown sections
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item
        # @return [String] The complete file content
        def generate_content(feedback_item)
          frontmatter = generate_frontmatter(feedback_item)
          sections = generate_sections(feedback_item)

          "#{frontmatter}#{sections}"
        end

        # Generate YAML frontmatter
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item
        # @return [String] YAML frontmatter with delimiters
        def generate_frontmatter(feedback_item)
          data = {
            "id" => feedback_item.id,
            "title" => feedback_item.title,
            "files" => feedback_item.files,
            "status" => feedback_item.status,
            "priority" => feedback_item.priority,
            "created" => feedback_item.created,
            "updated" => feedback_item.updated
          }

          # Use reviewers array if multiple reviewers, otherwise use legacy reviewer key
          if feedback_item.reviewers.length > 1
            data["reviewers"] = feedback_item.reviewers.dup
            data["consensus"] = feedback_item.consensus if feedback_item.consensus
          else
            data["reviewer"] = feedback_item.reviewer
          end

          data = data.compact

          "---\n#{data.to_yaml.sub(/\A---\n/, "")}---\n\n"
        end

        # Generate markdown sections
        #
        # @param feedback_item [Models::FeedbackItem] The feedback item
        # @return [String] Markdown sections
        def generate_sections(feedback_item)
          sections = []

          sections << "## Finding\n#{feedback_item.finding}" if feedback_item.finding
          sections << "## Context\n#{feedback_item.context}" if feedback_item.context
          sections << "## Research\n#{feedback_item.research}" if feedback_item.research
          sections << "## Resolution\n#{feedback_item.resolution}" if feedback_item.resolution

          sections.join("\n\n")
        end

        # Write content atomically with file locking and retries
        #
        # Uses a dedicated lock file in the target directory to ensure
        # concurrent processes properly coordinate writes. Lock file is
        # cleaned up after successful write.
        #
        # @param file_path [String] The target file path
        # @param content [String] The content to write
        # @return [Hash] Result hash with :success and :path or :error
        def write_atomic(file_path, content)
          dir = File.dirname(file_path)
          lock_file_path = File.join(dir, ".feedback.lock")

          temp_file = nil
          result = nil

          # Open lock file (create if needed)
          File.open(lock_file_path, File::RDWR | File::CREAT) do |lock_file|
            # Acquire exclusive lock with retry
            unless acquire_lock(lock_file)
              return {success: false, error: "Could not acquire file lock"}
            end

            begin
              # Create temp file and write
              temp_file = Tempfile.new(["feedback", ".s.md"], dir)
              temp_file.write(content)
              temp_file.flush
              temp_file.fsync
              temp_path = temp_file.path
              temp_file.close

              # Atomic rename
              File.rename(temp_path, file_path)

              result = {success: true, path: file_path}
            ensure
              temp_file.close! if temp_file && !temp_file.closed?
            end
          end

          result
        rescue Errno::EAGAIN, Errno::EACCES => e
          {success: false, error: "File lock timeout: #{e.message}"}
        ensure
          # Clean up lock file after write completes
          begin
            FileUtils.rm_f(lock_file_path)
          rescue => e
            warn "Failed to clean up lock file #{lock_file_path}: #{e.message}"
          end
        end

        # Attempt to acquire an exclusive file lock
        #
        # Uses non-blocking lock with retry logic and exponential backoff.
        # This prevents indefinite waiting while allowing for transient
        # lock contention. Falls back to blocking lock if retries exhausted.
        #
        # @param lock_file [File] The lock file to lock
        # @param max_attempts [Integer] Maximum number of non-blocking attempts
        # @return [Boolean] True if lock acquired
        def acquire_lock(lock_file, max_attempts: 5)
          max_attempts.times do |attempt|
            # Try non-blocking lock first
            result = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
            return true if result == 0

            # If not acquired and not the last attempt, wait with exponential backoff
            break if attempt == max_attempts - 1

            # Exponential backoff: 0.01s, 0.02s, 0.04s, 0.08s, 0.16s
            sleep_time = 0.01 * (2**attempt)
            sleep(sleep_time)
          end

          # Fall back to blocking lock if all non-blocking attempts failed
          # This ensures we eventually acquire the lock, just may wait longer
          lock_file.flock(File::LOCK_EX)
          true
        rescue Errno::EAGAIN, Errno::EACCES, Errno::EINTR
          false
        end
      end
    end
  end
end
