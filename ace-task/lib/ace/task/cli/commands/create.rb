# frozen_string_literal: true

require "ace/support/cli"
require "fileutils"
require_relative "../../molecules/git_ignored_path"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task create
        class Create < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          # "next" is a move-to-root alias and is validated separately.
          BUILT_IN_DESTINATIONS = %w[maybe anytime archive].freeze

          desc <<~DESC.strip
            Create a new task

            Creates a new task with a B36TS-based type-marked ID (xxx.t.yyy).
          DESC

          example [
            '"Fix login bug"                              # Create task with title',
            '--title "Fix login bug"                      # Create task with title flag',
            '"Fix auth" --priority high --tags auth,security  # With priority and tags',
            '"Setup DB" --child-of q7w                    # Create as subtask',
            '"Track issue" --issue 276 --server forgejo-lab # Link one exact issue',
            '"Quick task" --in maybe                      # Create in _maybe/ folder',
            '"Filed task" --in _review                    # Create in an existing custom folder',
            '"Draft spec" --status draft --estimate TBD   # Create as draft with estimate',
            '"Preview only" --dry-run                     # Show what would be created'
          ]

          argument :title_arg, required: false, desc: "Task title"

          option :title, type: :string, desc: "Task title (alternative to positional TITLE)"
          option :priority, type: :string, aliases: %w[-p], desc: "Priority (critical, high, medium, low)"
          option :tags, type: :string, aliases: %w[-T], desc: "Tags (comma-separated)"
          option :status, type: :string, aliases: %w[-s], desc: "Initial status (draft, pending, blocked, ...)"
          option :estimate, type: :string, aliases: %w[-e], desc: "Effort estimate (e.g. TBD, 2h, 1d)"
          option :issue, type: :array, desc: "Issue number or URL to link"
          option :server, type: :string, desc: "Named forge server"
          option :"default-server", type: :boolean, desc: "Use the configured default forge server"
          option :"child-of", type: :string, desc: "Parent task reference (creates subtask)"
          option :in, type: :string, aliases: %w[-i],
            desc: "Top-level target (next, maybe, anytime, archive, or an existing custom folder)"
          option :"dry-run", type: :boolean, aliases: %w[-n], desc: "Preview without writing"

          option :git_commit, type: :boolean, aliases: %w[--gc], desc: "Auto-commit changes"

          option :root, type: :string, aliases: %w[-r], desc: "Exact task root directory (overrides project config)"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(title_arg: nil, **options)
            title = resolve_title(title_arg, options[:title])
            dry_run = options[:"dry-run"]
            priority = options[:priority]
            tags_str = options[:tags]
            tags = tags_str ? tags_str.split(",").map(&:strip).reject(&:empty?) : []
            status = options[:status]
            estimate = options[:estimate]
            issue = parse_issue(options[:issue])
            if !issue && (options[:server] || options[:"default-server"])
              raise Ace::Support::Cli::Error, "Server selection requires --issue"
            end
            remote_issue = issue && Ace::Task::Molecules::IssueLink.from_input(
              issue, server_name: options[:server], use_default: options[:"default-server"]
            )
            child_of = options[:"child-of"]
            in_folder = options[:in]

            if status
              valid = Ace::Task::Atoms::TaskValidationRules::VALID_STATUSES
              unless valid.include?(status)
                raise Ace::Support::Cli::Error.new("Invalid status '#{status}'. Valid: #{valid.join(", ")}")
              end
            end

            manager = if options[:root]
              Ace::Task::Organisms::TaskManager.new(root_dir: File.expand_path(options[:root]))
            else
              Ace::Task::Organisms::TaskManager.new
            end
            validate_destination!(manager, in_folder) if in_folder && !child_of
            # The preflight and the write resolve the same creation time, so
            # the checked paths are exactly the generated paths create writes.
            creation_time = Time.now.utc
            reject_ignored_creation_target!(manager, title: title, in_folder: in_folder,
              child_of: child_of, time: creation_time) if options[:git_commit]
            # Snapshot before any write so a rejected --git-commit can remove
            # exactly the artifacts this command created (including a placed
            # task, a new subtask, or an empty destination folder).
            placement_directories_before = directories_under(manager.root_dir) if
              (in_folder && !child_of) || options[:git_commit]

            if dry_run
              puts "Would create task:"
              puts "  Title:    #{title}"
              puts "  Status:   #{status}" if status
              puts "  Priority: #{priority}" if priority
              puts "  Estimate: #{estimate}" if estimate
              puts "  Issue:    #{remote_issue['url']}" if remote_issue
              puts "  Tags:     #{tags.join(", ")}" if tags.any?
              puts "  Parent:   #{child_of}" if child_of
              puts "  Folder:   #{in_folder}" if in_folder
              return
            end

            task = begin
              if child_of
                manager.create_subtask(
                  child_of,
                  title,
                  status: status,
                  priority: priority,
                  tags: tags,
                  estimate: estimate,
                  remote_issue: remote_issue
                )
              else
                manager.create(
                  title,
                  status: status,
                  priority: priority,
                  tags: tags,
                  estimate: estimate,
                  remote_issue: remote_issue,
                  time: creation_time
                )
              end
            rescue Ace::Task::Organisms::TaskManager::CreateRetriesExhaustedError => e
              raise Ace::Support::Cli::Error, e.message
            end

            unless task
              raise Ace::Support::Cli::Error.new("Parent task '#{child_of}' not found") if child_of
              raise Ace::Support::Cli::Error.new("Failed to create task")
            end

            # Move to folder if specified
            if in_folder && !child_of
              task = place_created_task(manager, task, in_folder, placement_directories_before)
            end

            if options[:git_commit]
              reject_ignored_created_task!(manager, task, placement_directories_before)
            end

            puts "Created task #{task.id}"
            puts "  Path: #{task.file_path}"
            if manager.last_update_note && !manager.last_update_note.strip.empty?
              puts "Info: #{manager.last_update_note}"
            end

            if options[:git_commit]
              Ace::Support::Items::Molecules::GitCommitter.commit(
                paths: [task.path],
                intention: "create task #{task.id}"
              )
            end
          rescue Ace::Git::Error, ArgumentError => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          # --git-commit preflight: resolve the known destination (the parent
          # family or the placement folder) and the exact task paths this
          # create call would write — generated ID and title-derived slugs, or
          # the next subtask character — so ignore rules are judged against the
          # real operation, never against sample names. The post-creation check
          # stays authoritative for ID-collision retries and concurrent changes.
          def reject_ignored_creation_target!(manager, title:, in_folder:, child_of:, time:)
            detector = Ace::Support::Items::Atoms::SpecialFolderDetector
            target = if child_of
              manager.show(child_of)&.path
            elsif in_folder && !detector.move_to_root?(in_folder)
              File.join(manager.root_dir, detector.normalize(in_folder))
            else
              manager.root_dir
            end
            return unless target

            if Ace::Task::Molecules::GitIgnoredPath.ignored?(target)
              raise Ace::Support::Cli::Error,
                "Cannot --git-commit into a Git-ignored destination: #{target}. " \
                  "Choose a tracked folder or omit --git-commit."
            end

            ignored = manager.planned_creation_paths(title, in_folder: in_folder, child_of: child_of, time: time)
              .find { |path| Ace::Task::Molecules::GitIgnoredPath.ignored?(path) }
            return unless ignored

            raise Ace::Support::Cli::Error,
              "Cannot --git-commit into a destination with Git-ignored child paths: #{ignored}. " \
                "Choose a tracked folder or adjust the ignore rules."
          end

          # --git-commit must not stage a task whose directory or spec path Git
          # ignores. The check runs on the created paths (covering generated
          # IDs, subtask folders, and the placed destination) and rolls the
          # creation back, so a rejected commit leaves no task behind.
          def reject_ignored_created_task!(manager, task, directories_before)
            return unless Ace::Task::Molecules::GitIgnoredPath.ignored_task?(task)

            begin
              remove_created_task_artifacts(manager, task)
              remove_empty_directories_created_since(manager.root_dir, directories_before)
            rescue StandardError => cleanup_error
              raise Ace::Support::Cli::Error,
                "Cannot --git-commit a Git-ignored task path: #{task.path}. " \
                  "Cleanup also failed: #{cleanup_error.message}"
            end

            raise_ignored_commit!(task.path)
          end

          def raise_ignored_commit!(path)
            raise Ace::Support::Cli::Error,
              "Cannot --git-commit a Git-ignored task path: #{path}. " \
                "Move the task to a tracked folder or omit --git-commit."
          end

          def validate_destination!(manager, target_folder)
            detector = Ace::Support::Items::Atoms::SpecialFolderDetector
            return if detector.move_to_root?(target_folder)

            if detector.virtual_filter?(target_folder)
              raise Ace::Support::Cli::Error,
                "Destination '#{target_folder}' is a virtual list filter, not a physical folder."
            end

            normalized = detector.normalize(target_folder)
            configured_path = File.join(manager.root_dir, normalized)
            normalized_built_ins = BUILT_IN_DESTINATIONS.map { |name| detector.normalize(name) }
            valid = !target_folder.strip.empty? &&
              !normalized.include?(File::SEPARATOR) &&
              !normalized.include?("..") &&
              (normalized_built_ins.include?(normalized) || Dir.exist?(configured_path)) &&
              destination_within_root?(manager.root_dir, configured_path)
            return if valid

            choices = (["next"] + BUILT_IN_DESTINATIONS).join(", ")
            raise Ace::Support::Cli::Error,
              "Destination '#{target_folder}' does not exist. " \
                "Use #{choices}, or an existing custom task folder."
          end

          def destination_within_root?(root, destination)
            return true unless File.exist?(destination)

            root_path = File.realpath(root)
            destination_path = File.realpath(destination)
            destination_path.start_with?(root_path + File::SEPARATOR)
          rescue Errno::ENOENT, Errno::EACCES
            false
          end

          def place_created_task(manager, task, target_folder, directories_before)
            placed_task = manager.update(task.id, move_to: target_folder)
            expected_folder = if Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?(target_folder)
              nil
            else
              Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(target_folder)
            end

            unless placed_task && placed_task.special_folder == expected_folder
              actual_folder = if placed_task
                placed_task.special_folder || "root"
              else
                "no task returned"
              end
              # This internal signal is wrapped below with rollback and an actionable CLI error.
              raise "placement returned #{actual_folder.inspect}, expected #{expected_folder || "root"}"
            end

            placed_task
          rescue Ace::Git::Error
            # update retains linked tasks after post-placement sync failures as
            # recovery records; those are not destination-placement failures.
            raise
          rescue StandardError => e
            begin
              remove_created_task_artifacts(manager, task)
              remove_empty_directories_created_since(manager.root_dir, directories_before)
            rescue StandardError => cleanup_error
              raise Ace::Support::Cli::Error,
                "Failed to create task in '#{target_folder}': #{e.message}. " \
                  "Cleanup also failed: #{cleanup_error.message}"
            end
            raise Ace::Support::Cli::Error,
              "Failed to create task in '#{target_folder}': #{e.message}. " \
                "No task was created; fix the destination and retry."
          end

          def remove_created_task_artifacts(manager, task)
            root = File.expand_path(manager.root_dir)
            candidates = [task.path]
            candidates.concat(
              Dir.glob(File.join(root, "**", "#{task.id}-*")).select { |path| File.directory?(path) }
            )

            candidates.uniq.each do |path|
              expanded = File.expand_path(path)
              next unless expanded.start_with?(root + File::SEPARATOR)

              FileUtils.rm_rf(expanded)
            end

            remaining = Dir.glob(File.join(root, "**", "#{task.id}-*")).select { |path| File.exist?(path) }
            return if remaining.empty?

            raise Ace::Support::Cli::Error,
              "Failed to remove partial task artifacts after placement failure: #{remaining.join(", ")}"
          end

          def directories_under(root)
            return [] unless Dir.exist?(root)

            [File.expand_path(root)] + Dir.glob(File.join(root, "**", "*"))
              .select { |path| File.directory?(path) }
              .map { |path| File.expand_path(path) }
          end

          def remove_empty_directories_created_since(root, directories_before)
            # Only directories created during this short command transaction
            # are candidates, and non-empty concurrent directories are retained.
            (directories_under(root) - directories_before).sort_by(&:length).reverse_each do |path|
              Dir.rmdir(path)
            rescue Errno::ENOENT, Errno::ENOTEMPTY
              next
            end
          end

          def resolve_title(positional_title, flag_title)
            positional_present = present_string?(positional_title)
            flag_present = present_string?(flag_title)

            if positional_present && flag_present
              raise Ace::Support::Cli::Error.new("Choose either positional TITLE or --title, not both")
            end

            return positional_title if positional_present
            return flag_title if flag_present

            raise Ace::Support::Cli::Error.new("Title required: provide positional TITLE or --title")
          end

          def present_string?(value)
            !value.nil? && !value.to_s.strip.empty?
          end

          def parse_issue(raw_values)
            values = Array(raw_values).flatten.compact
            return nil if values.empty?
            raise Ace::Support::Cli::Error.new("Only one --issue may be provided") if values.length > 1

            candidate = values.first.to_s.strip
            raise Ace::Support::Cli::Error.new("Issue identifier cannot be empty") if candidate.empty?

            candidate
          end
        end
      end
    end
  end
end
