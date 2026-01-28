# frozen_string_literal: true

require "yaml"
require "fileutils"

module Ace
  module Coworker
    module Molecules
      # Writes and updates step markdown files.
      #
      # Handles creation of new step files and updating existing ones,
      # including appending reports and updating frontmatter.
      class StepWriter
        # Create a new step file
        #
        # @param jobs_dir [String] Path to jobs directory
        # @param number [String] Step number
        # @param name [String] Step name
        # @param instructions [String] Step instructions
        # @param status [Symbol] Initial status
        # @param added_by [String, nil] How step was added
        # @param parent [String, nil] Parent step number
        # @return [String] Path to created file
        def create(jobs_dir:, number:, name:, instructions:, status: :pending,
                   added_by: nil, parent: nil)
          filename = Atoms::StepFileParser.generate_filename(number, name)
          file_path = File.join(jobs_dir, filename)

          frontmatter = {
            "name" => name,
            "status" => status.to_s
          }
          frontmatter["added_by"] = added_by if added_by
          frontmatter["parent"] = parent if parent

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

        # Mark step as done with report
        #
        # @param file_path [String] Path to step file
        # @param report_content [String] Report content to append
        # @return [String] Updated file path
        def mark_done(file_path, report_content:)
          content = File.read(file_path)
          parsed = Atoms::StepFileParser.parse(content)

          # Update frontmatter
          new_frontmatter = parsed[:frontmatter].merge({
            "status" => "done",
            "completed_at" => Time.now.utc.iso8601
          })

          # Append report section
          body = parsed[:body]
          new_body = "#{body}\n\n---\n\n# Report\n\n#{report_content}"

          new_content = build_file_content(new_frontmatter, new_body)
          atomic_write(file_path, new_content)

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

        # Append report content to step file
        #
        # @param file_path [String] Path to step file
        # @param report_content [String] Report content to append
        # @return [String] Updated file path
        def append_report(file_path, report_content)
          content = File.read(file_path)
          parsed = Atoms::StepFileParser.parse(content)

          body = parsed[:body]

          # Check if report section already exists
          if body.include?("\n---\n")
            # Append to existing report
            new_body = "#{body}\n\n#{report_content}"
          else
            # Create new report section
            new_body = "#{body}\n\n---\n\n# Report\n\n#{report_content}"
          end

          new_content = build_file_content(parsed[:frontmatter], new_body)
          atomic_write(file_path, new_content)

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

        def build_file_content(frontmatter, body)
          yaml = frontmatter.compact.to_yaml
          "#{yaml}---\n\n#{body}\n"
        end
      end
    end
  end
end
