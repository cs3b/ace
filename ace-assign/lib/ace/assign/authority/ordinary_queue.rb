# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "prepared_work"
require_relative "private_directory"
require_relative "../organisms/assignment_executor"

module Ace
  module Assign
    module Authority
      # A disposable projection for the existing queue engine. Only bytes read
      # from (or about to be committed to) the canonical execution ref enter it.
      # No files left by an earlier coordinator are recovery input.
      class OrdinaryQueue
        attr_reader :bytes

        def initialize(work:, root:, bytes: nil)
          raise ArgumentError, "ordinary queue requires prepared work" unless work.is_a?(PreparedWork)
          @work, @root = work, PrivateDirectory.verify!(root)
          value = if bytes
            invalid! unless bytes.is_a?(String) && bytes.bytesize.between?(1, PreparedWork::MAX_TOTAL)
            JSON.parse(bytes)
          else
            {"version" => 1, "steps" => work.manifest.fetch("steps").to_h { |step|
              name = step.fetch("filename"); [name, work.files.fetch("steps/#{name}")]
            }, "reports" => {}}
          end
          validate!(value, initial: bytes.nil?)
          @bytes = Atoms::EvidenceDigest.canonical_json(value).freeze
        rescue JSON::ParserError
          invalid!
        end

        def status
          value = JSON.parse(@bytes)
          assignment = Models::Assignment.from_h(@work.definition, cache_dir: File.join(@root, @work.manifest.fetch("assignment_id")))
          Molecules::QueueScanner.new.scan_captured(steps: value.fetch("steps"), reports: value.fetch("reports"), assignment: assignment)
        end

        # This returns proposed bytes only. The lifecycle owns authorization,
        # generation, replay and publication together with its attempt events.
        def transition(operation:, scope: @work.manifest.fetch("scope"), step: nil, report: nil, message: nil)
          invalid! unless @work.manifest.fetch("steps").any? { |entry| entry.fetch("number") == scope }
          value = JSON.parse(@bytes)
          Dir.mktmpdir("ordinary-queue-", @root) do |scratch|
            File.chmod(0o700, scratch)
            directory = File.join(scratch, @work.manifest.fetch("assignment_id"))
            %w[steps reports].each { |name| FileUtils.mkdir_p(File.join(directory, name), mode: 0700) }
            assignment = Models::Assignment.from_h(@work.definition, cache_dir: directory)
            write(File.join(directory, "assignment.yaml"), assignment.to_h.to_yaml)
            write(File.join(directory, "job.yaml"), @work.files.fetch("job.yaml"))
            %w[steps reports].each do |group|
              value.fetch(group).each { |filename, content| write(File.join(directory, group, filename), content) }
            end
            executor = Organisms::AssignmentExecutor.new(cache_base: scratch, selected_assignment: assignment)
            case operation
            when :activate
              state = executor.status.fetch(:state)
              invalid! unless state.find_by_number(scope)&.status == :pending
              executor.step_writer.mark_active(state.find_by_number(scope).file_path)
            when :start
              executor.start_step(step_number: step, fork_root: scope)
            when :finish
              executor.finish_step(report_content: report, step_number: step, fork_root: scope)
            when :fail
              executor.fail(message, fork_root: scope)
            else
              raise ArgumentError, "unknown ordinary queue transition"
            end
            result = {"version" => 1}
            %w[steps reports].each do |group|
              result[group] = Dir.children(File.join(directory, group)).to_h do |filename|
                [filename, File.binread(File.join(directory, group, filename)).force_encoding(Encoding::UTF_8)]
              end
            end
            self.class.new(work: @work, root: @root, bytes: Atoms::EvidenceDigest.canonical_json(result))
          end
        end

        private

        def validate!(value, initial:)
          invalid! unless value.is_a?(Hash) && value.keys.sort == %w[reports steps version] && value["version"].is_a?(Integer) && value["version"] == 1 &&
            value["steps"].is_a?(Hash) && value["reports"].is_a?(Hash)
          expected = @work.manifest.fetch("steps").map { |step| step.fetch("filename") }
          invalid! unless value.fetch("steps").keys.sort == expected.sort
          reports = []
          value.fetch("steps").each do |filename, content|
            parsed = @work.parse_queue_step!(content)
            progress = parsed.fetch(:frontmatter).keys & PreparedWork::PROGRESS
            allowed = initial ? %w[status] : %w[status started_at completed_at error stall_reason]
            invalid! unless (progress - allowed).empty?
            original = @work.files.fetch("steps/#{filename}")
            invalid! unless PreparedWork.work_projection(content) == PreparedWork.work_projection(original) &&
              %w[pending active done failed].include?(parsed.fetch(:frontmatter).fetch("status", "pending"))
            info = Atoms::StepFileParser.parse_filename(filename)
            reports << Atoms::StepFileParser.generate_report_filename(info.fetch(:number), info.fetch(:name))
          end
          invalid! unless (value.fetch("reports").keys - reports).empty?
          value.fetch("reports").each_value { |content| @work.parse_queue_step!(content) }
          invalid! if Atoms::EvidenceDigest.canonical_json(value).bytesize > PreparedWork::MAX_TOTAL
        end

        def write(path, content)
          File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) { |file| file.write(content) }
        end

        def invalid!
          raise AttemptErrors::EvidenceUnavailable, "ordinary canonical queue differs from its accepted work"
        end
      end
    end
  end
end
