# frozen_string_literal: true

require "yaml"
require "fileutils"

module Ace
  module Assign
    module Molecules
      # Writes and updates step markdown files.
      #
      # Handles creation of new step files and updating existing ones,
      # including appending reports and updating frontmatter.
      class StepWriter
        # Create a new step file
        #
        # @param steps_dir [String] Path to steps directory
        # @param number [String] Step number
        # @param name [String] Step name
        # @param instructions [String] Step instructions
        # @param status [Symbol] Initial status
        # @param added_by [String, nil] How step was added
        # @param parent [String, nil] Parent step number
        # @return [String] Path to created file
        def create(steps_dir:, number:, name:, instructions:, status: :pending,
                   added_by: nil, parent: nil, extra: {})
          filename = Atoms::StepFileParser.generate_filename(number, name)
          file_path = File.join(steps_dir, filename)

          frontmatter = {
            "name" => name,
            "status" => status.to_s
          }
          frontmatter["added_by"] = added_by if added_by
          frontmatter["parent"] = parent if parent
          frontmatter.merge!(extra.transform_keys(&:to_s)) if extra&.any?

          content = build_file_content(frontmatter, instructions)
          atomic_write(file_path, content)

          file_path
        end

        # Update step frontmatter
        #
        # @param file_path [String] Path to step file
        # @param updates [Hash] Frontmatter updates
        # @return [String] Updated file path
        def update_frontmatter(file_path, updates)
          content = File.read(file_path)
          parsed = Atoms::StepFileParser.parse(content)

          # Merge updates into frontmatter
          new_frontmatter = parsed[:frontmatter].merge(updates.transform_keys(&:to_s))

          # Rebuild file
          new_content = build_file_content(new_frontmatter, parsed[:body])
          atomic_write(file_path, new_content)

          file_path
        end

        # Mark step as in progress
        #
        # @param file_path [String] Path to step file
        # @return [String] Updated file path
        def mark_in_progress(file_path)
          update_frontmatter(file_path, {
            "status" => "in_progress",
            "started_at" => Time.now.utc.iso8601
          })
        end

        # Mark step as pending again after it becomes blocked by newly added children.
        #
        # @param file_path [String] Path to step file
        # @return [String] Updated file path
        def mark_pending(file_path)
          update_frontmatter(file_path, {
            "status" => "pending",
            "started_at" => nil,
            "completed_at" => nil,
            "error" => nil,
            "stall_reason" => nil
          })
        end

        # Mark step as done with report
        #
        # @param file_path [String] Path to step file
        # @param report_content [String] Report content to write
        # @param reports_dir [String] Path to reports directory
        # @return [String] Updated file path
        # @raise [ArgumentError] if report_content is nil or empty
        def mark_done(file_path, report_content:, reports_dir:)
          # Validate report content
          raise ArgumentError, "Report content cannot be nil" if report_content.nil?
          raise ArgumentError, "Report content cannot be empty" if report_content.strip.empty?

          content = File.read(file_path)
          parsed = Atoms::StepFileParser.parse(content)

          # Extract number and name from filename for report file
          filename_info = Atoms::StepFileParser.parse_filename(File.basename(file_path))

          # Update frontmatter only (status + completed_at)
          new_frontmatter = parsed[:frontmatter].merge({
            "status" => "done",
            "completed_at" => Time.now.utc.iso8601
          })

          # Write step file with updated frontmatter
          new_content = build_file_content(new_frontmatter, parsed[:body])
          atomic_write(file_path, new_content)

          # Write report to separate file
          report_filename = Atoms::StepFileParser.generate_report_filename(
            filename_info[:number],
            filename_info[:name]
          )
          report_path = File.join(reports_dir, report_filename)

          write_report(report_path, filename_info[:number], filename_info[:name], report_content)

          file_path
        end

        # Mark step as failed
        #
        # @param file_path [String] Path to step file
        # @param error_message [String] Error message
        # @return [String] Updated file path
        def mark_failed(file_path, error_message:)
          update_frontmatter(file_path, {
            "status" => "failed",
            "completed_at" => Time.now.utc.iso8601,
            "error" => error_message
          })
        end

        # Record fork execution PID metadata on a step.
        #
        # @param file_path [String] Path to fork root step file
        # @param launch_pid [Integer] PID of launcher process
        # @param tracked_pids [Array<Integer>] Observed subprocess/descendant PIDs
        # @return [String] Updated file path
        def record_fork_pid_info(file_path, launch_pid:, tracked_pids:, pid_file: nil)
          update_frontmatter(file_path, {
            "fork_launch_pid" => launch_pid.to_i,
            "fork_tracked_pids" => Array(tracked_pids).map(&:to_i).uniq.sort,
            "fork_pid_updated_at" => Time.now.utc.iso8601,
            "fork_pid_file" => pid_file
          })
        end

        # Append report content to step file
        #
        # @param file_path [String] Path to step file
        # @param report_content [String] Report content to append
        # @param reports_dir [String] Path to reports directory
        # @return [String] Updated file path
        def append_report(file_path, report_content, reports_dir:)
          # Extract number and name from filename for report file
          filename_info = Atoms::StepFileParser.parse_filename(File.basename(file_path))

          # Generate report filename
          report_filename = Atoms::StepFileParser.generate_report_filename(
            filename_info[:number],
            filename_info[:name]
          )
          report_path = File.join(reports_dir, report_filename)

          # Check if report file exists
          if File.exist?(report_path) && File.size(report_path) > 0
            # Append to existing report with file locking
            File.open(report_path, File::RDWR) do |f|
              f.flock(File::LOCK_EX)
              existing_content = f.read
              # Find the end of the frontmatter and append after it
              match = existing_content.match(/\n---\s*\n/)
              if match
                insertion_point = match.end(0)
                new_content = existing_content[0...insertion_point] + report_content + "\n" + existing_content[insertion_point..]
              else
                new_content = existing_content + "\n" + report_content
              end
              # Rewrite content in-place on locked file descriptor
              # This preserves the POSIX lock (rename would break it by replacing inode)
              f.rewind
              f.truncate(0)
              f.write(new_content)
              f.flush
              fsync_after_write(f)
            end
          else
            # Create new report file
            write_report(report_path, filename_info[:number], filename_info[:name], report_content)
          end

          file_path
        end

        private

        # Write content atomically using temp file + rename pattern.
        # Prevents partial writes if process crashes mid-write.
        def atomic_write(path, content)
          temp_path = "#{path}.tmp.#{Process.pid}"
          File.write(temp_path, content)
          File.rename(temp_path, path)
        end

        # Sync file to disk after write to ensure data persistence.
        # Especially important when rewriting in-place under file lock.
        #
        # @param file [File] File object to sync
        def fsync_after_write(file)
          file.fsync
        rescue IOError
          # fsync may not be supported on all file systems (e.g., NFS)
          # Gracefully degrade if not available
        end

        def build_file_content(frontmatter, body)
          yaml = frontmatter.compact.to_yaml
          "#{yaml}---\n\n#{body}\n"
        end

        # Write report to separate file with YAML frontmatter
        # @param report_path [String] Path to report file
        # @param number [String] Step number
        # @param name [String] Step name
        # @param content [String] Report content
        def write_report(report_path, number, name, content)
          frontmatter = {
            "step" => number,
            "name" => name,
            "completed_at" => Time.now.utc.iso8601
          }
          yaml = frontmatter.to_yaml
          report_content = "#{yaml}---\n\n#{content}\n"
          atomic_write(report_path, report_content)
        end
      end
    end
  end
end
