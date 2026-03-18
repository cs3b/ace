# frozen_string_literal: true

require "fileutils"

module Ace
  module Assign
    module Molecules
      # Handles step file renumbering with cascade support and atomic operations.
      #
      # Extracted from AssignmentExecutor to provide:
      # - Testable renumbering logic
      # - Transactional rename with rollback on failure
      # - Parent metadata updates for descendants
      #
      # @example Basic usage
      #   renumberer = StepRenumberer.new(step_writer: step_writer, queue_scanner: scanner)
      #   renumberer.renumber(steps_dir, ["010", "011"])
      class StepRenumberer
        attr_reader :step_writer, :queue_scanner

        def initialize(step_writer:, queue_scanner:)
          @step_writer = step_writer
          @queue_scanner = queue_scanner
        end

        # Renumber steps by shifting their file numbers.
        # Also cascades to all descendants to prevent orphaning children.
        #
        # @param steps_dir [String] Path to steps directory
        # @param numbers_to_shift [Array<String>] Step numbers to shift
        # @return [Hash] Result with :renamed (count) and :rollback_needed (bool)
        def renumber(steps_dir, numbers_to_shift)
          return { renamed: 0, rollback_needed: false } if numbers_to_shift.empty?

          all_numbers = queue_scanner.step_numbers(steps_dir)
          sorted_steps = build_shift_list(numbers_to_shift, all_numbers)

          # Track operations for potential rollback
          completed_renames = []
          rollback_needed = false

          begin
            sorted_steps.each do |old_number|
              new_number = calculate_new_number(old_number, numbers_to_shift)
              next if new_number == old_number

              # Calculate new parent for frontmatter update
              new_parent = calculate_new_parent(old_number, numbers_to_shift)

              rename_result = rename_step_files(
                steps_dir,
                old_number,
                new_number,
                new_parent: new_parent
              )

              completed_renames << { old: old_number, new: new_number, files: rename_result[:files] }
            end
          rescue StandardError => e
            rollback_needed = true
            rollback_renames(completed_renames)
            raise e
          end

          { renamed: completed_renames.size, rollback_needed: rollback_needed }
        end

        private

        # Build complete list of steps to shift including descendants.
        #
        # @param numbers_to_shift [Array<String>] Explicit steps to shift
        # @param all_numbers [Array<String>] All existing step numbers
        # @return [Array<String>] Sorted list (deepest children first)
        def build_shift_list(numbers_to_shift, all_numbers)
          all_to_shift = []
          numbers_to_shift.each do |num|
            all_to_shift << num
            # Find all descendants (steps starting with "num.")
            all_numbers.each do |n|
              all_to_shift << n if Atoms::StepNumbering.child_of?(n, num)
            end
          end
          all_to_shift.uniq!

          # Sort in reverse by full number (deeper children first, then parents)
          # This prevents filename collisions and ensures proper cascade
          all_to_shift.sort.reverse
        end

        # Calculate the new number for a step being shifted.
        #
        # @param old_number [String] Current step number
        # @param numbers_to_shift [Array<String>] Steps explicitly being shifted
        # @return [String] New step number
        def calculate_new_number(old_number, numbers_to_shift)
          if numbers_to_shift.include?(old_number)
            Atoms::StepNumbering.shift_number(old_number, 1)
          else
            # This is a descendant - cascade parent shift
            parent_old = Atoms::StepNumbering.parse(old_number)[:parent]
            parent_new = if parent_old && numbers_to_shift.include?(parent_old)
                           Atoms::StepNumbering.shift_number(parent_old, 1)
                         end

            # Replace old parent prefix with new parent prefix
            if parent_new
              old_number.sub(/^#{Regexp.escape(parent_old)}/, parent_new)
            else
              # Find shifted ancestor
              ancestor = numbers_to_shift.find { |n| Atoms::StepNumbering.child_of?(old_number, n) }
              if ancestor
                new_ancestor = Atoms::StepNumbering.shift_number(ancestor, 1)
                old_number.sub(/^#{Regexp.escape(ancestor)}/, new_ancestor)
              else
                old_number
              end
            end
          end
        end

        # Calculate new parent number for frontmatter update.
        #
        # @param old_number [String] Step being renamed
        # @param numbers_to_shift [Array<String>] Steps explicitly being shifted
        # @return [String, nil] New parent number or nil if no parent update needed
        def calculate_new_parent(old_number, numbers_to_shift)
          old_parent = Atoms::StepNumbering.parse(old_number)[:parent]
          return nil unless old_parent

          ancestor = numbers_to_shift.find { |n| old_parent == n || Atoms::StepNumbering.child_of?(old_parent, n) }
          if ancestor
            new_ancestor = Atoms::StepNumbering.shift_number(ancestor, 1)
            old_parent.sub(/^#{Regexp.escape(ancestor)}/, new_ancestor)
          else
            old_parent
          end
        end

        # Rename step and report files from one number to another.
        #
        # @param steps_dir [String] Path to steps directory
        # @param old_number [String] Old step number
        # @param new_number [String] New step number
        # @param new_parent [String, nil] New parent number for frontmatter update
        # @return [Hash] Result with :files (renamed file paths)
        def rename_step_files(steps_dir, old_number, new_number, new_parent: nil)
          renamed_files = []

          # Find step file with this number
          pattern = File.join(steps_dir, "#{old_number}-*.st.md")
          step_files = Dir.glob(pattern)

          step_files.each do |old_path|
            filename = File.basename(old_path)
            new_filename = filename.sub(/^#{Regexp.escape(old_number)}/, new_number)
            new_path = File.join(steps_dir, new_filename)

            FileUtils.mv(old_path, new_path)
            renamed_files << { old_path: old_path, new_path: new_path, type: :step }

            # Add audit trail metadata to track renumbering history
            metadata = {
              "renumbered_from" => old_number,
              "renumbered_at" => Time.now.utc.iso8601
            }
            metadata["parent"] = new_parent if new_parent
            step_writer.update_frontmatter(new_path, metadata)
          end

          # Also rename any report files
          cache_dir = File.dirname(steps_dir)
          reports_dir = File.join(cache_dir, "reports")
          if File.directory?(reports_dir)
            report_pattern = File.join(reports_dir, "#{old_number}-*.r.md")
            report_files = Dir.glob(report_pattern)

            report_files.each do |old_path|
              filename = File.basename(old_path)
              new_filename = filename.sub(/^#{Regexp.escape(old_number)}/, new_number)
              new_path = File.join(reports_dir, new_filename)

              FileUtils.mv(old_path, new_path)
              renamed_files << { old_path: old_path, new_path: new_path, type: :report }
            end
          end

          { files: renamed_files }
        end

        # Rollback completed renames on failure.
        #
        # @param completed_renames [Array<Hash>] List of completed rename operations
        # @return [Array<Hash>] List of rollback errors (empty if all succeeded)
        def rollback_renames(completed_renames)
          rollback_errors = []

          # Reverse order to undo in opposite sequence
          completed_renames.reverse_each do |rename|
            rename[:files].each do |file_info|
              next unless File.exist?(file_info[:new_path])

              FileUtils.mv(file_info[:new_path], file_info[:old_path])
            rescue StandardError => e
              # Capture rollback errors but continue attempting remaining rollbacks
              rollback_errors << {
                file: file_info[:new_path],
                target: file_info[:old_path],
                error: e.message
              }
            end
          end

          # Warn about rollback failures if any occurred
          if rollback_errors.any?
            warn "[ace-assign] Warning: #{rollback_errors.size} file(s) failed to rollback during renumber recovery:"
            rollback_errors.each do |err|
              warn "  - #{err[:file]} -> #{err[:target]}: #{err[:error]}"
            end
          end

          rollback_errors
        end
      end
    end
  end
end
