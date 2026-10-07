# frozen_string_literal: true

require "ace/bundle"
require_relative "task_assignment_creator"
require_relative "../authority/prepared_work"

module Ace
  module Assign
    module Organisms
      # Captures managed preparation once. This owner neither registers nor
      # launches work; callers retain its exact output across uncertain replies.
      class PreparedWorkBuilder
        def initialize(export_root:, task_manager: nil, executor: nil, bundle_loader: nil)
          @tasks = task_manager || Ace::Task::Organisms::TaskManager.new
          @executor = executor || AssignmentExecutor.new
          @bundles = bundle_loader || Ace::Bundle::Organisms::BundleLoader.new
          @transfer = Authority::CandidateTransfer.new(root: export_root)
        end

        def call(task_ref:, project_id:, dependency_reports:)
          token!(project_id)
          @reads = {}
          @inventories = {}
          tasks = closure(task_ref)
          selected = tasks.fetch(task_ref)
          refuse!("selected task is not a reviewed leaf") unless
            %w[pending in-progress].include?(selected.status.to_s) && Array(selected.subtasks).empty?
          contexts = tasks.sort.to_h do |id, task|
            refuse!("task still needs review") unless task.metadata.fetch("needs_review", false) == false
            [id, capture_context(task)]
          end
          reports = capture_reports(dependency_reports, tasks, task_ref, project_id)
          result = TaskAssignmentCreator.new(task_manager: @tasks, executor: @executor)
            .call(task_refs: [task_ref], primary_task_ref: task_ref, project_id: project_id)
          assignment = result.fetch(:assignment)
          refuse!("managed association changed") unless assignment.task_id == task_ref && assignment.project_id == project_id
          job = read(assignment.source_config)
          read(assignment.assignment_file)
          inventory = inventory(assignment.steps_dir)
          step_files = inventory.to_h { |name| [name, read(File.join(assignment.steps_dir, name))] }
          roots = step_files.filter_map do |name, bytes|
            fm = Atoms::StepFileParser.parse(bytes).fetch(:frontmatter)
            Atoms::StepFileParser.parse_filename(name).fetch(:number) if fm["context"] == "fork" && fm["taskref"] == task_ref
          end
          refuse!("selected fork root is not unique") unless roots.one? && roots.first
          scope = roots.first
          files = {"definition.json" => JSON.generate(assignment.to_h), "job.yaml" => job}
          selected_steps = step_files.filter_map do |name, bytes|
            number = Atoms::StepFileParser.parse_filename(name).fetch(:number)
            refuse!("unexpected queue entry") unless number && name.end_with?(".st.md")
            next unless number == scope || number.start_with?(scope + ".")
            files["steps/#{name}"] = bytes
            record(name, bytes).merge("number" => number)
          end.sort_by { |entry| number_key(entry.fetch("number")) }
          context = contexts.map do |id, captured|
            spec_path = "context/#{id}/spec.md"
            text_path = "context/#{id}/bundle.txt"
            files[spec_path], files[text_path] = captured.values_at(:spec, :text)
            selected_reports = reports.fetch(id, []).map do |report|
              path = "context/#{id}/reports/#{report.fetch(:assignment_id)}/#{report.fetch(:number)}.r.md"
              files[path] = report.fetch(:bytes)
              {"assignment_id" => report.fetch(:assignment_id), "number" => report.fetch(:number),
                "file" => record(path, report.fetch(:bytes))}
            end
            {"uri" => "task://#{id}", "task_id" => id, "spec" => record(spec_path, files.fetch(spec_path)),
              "text" => record(text_path, files.fetch(text_path)), "reports" => selected_reports}
          end
          manifest = {"version" => 1, "assignment_id" => assignment.id, "project_id" => project_id,
            "task_id" => task_ref, "scope" => scope, "job" => record("job.yaml", job),
            "steps" => selected_steps, "context" => context}
          files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
          work = Authority::PreparedWork.new(files: files)
          current = closure(task_ref)
          refuse!("task dependency inventory changed") unless current.keys.sort == tasks.keys.sort
          refuse!("selected task expanded during capture") unless Array(current.fetch(task_ref).subtasks).empty?
          current.each { |id, task| refuse!("task context changed") unless capture_context(task) == contexts.fetch(id) }
          @inventories.each { |path, names| refuse!("input inventory changed") unless Dir.children(path).sort == names }
          @reads.each { |path, bytes| refuse!("captured input changed") unless read_bytes(path) == bytes }
          @transfer.export_prepared(work: work).merge("assignment_id" => assignment.id,
            "scope" => scope.freeze, "selection_sha256" => work.selection_sha256).freeze
        ensure
          @reads = nil
          @inventories = nil
        end

        private

        def closure(ref)
          found = {}; visiting = []
          walk = lambda do |id|
            token!(id)
            refuse!("dependency cycle: #{(visiting + [id]).join(' -> ')}") if visiting.include?(id)
            return if found.key?(id)
            refuse!("too many task contexts") if found.size >= 256
            task = @tasks.show(id)
            refuse!("missing or noncanonical task") unless task && task.id == id
            found[id] = task
            visiting << id
            Array(task.dependencies).each { |dependency| walk.call(dependency) }
            visiting.pop
          end
          walk.call(ref)
          found
        end

        def capture_context(task)
          spec = read(task.file_path)
          bundle = @bundles.load_file(task.file_path)
          errors = bundle.metadata.values_at(:error, :errors, "error", "errors").flatten.compact
          refuse!("unresolvable task context") unless errors.empty?
          text = bounded_text(bundle.content)
          # Deep-copy owner inventories; a loader may reuse mutable objects.
          {spec: spec, text: text, path: task.file_path,
            inventory: Marshal.dump([bundle.files, bundle.source_files])}
        end

        def capture_reports(selections, tasks, selected, project)
          refuse!("report selections must be explicit") unless selections.is_a?(Array) && selections.size <= 4096
          seen = {}; grouped = Hash.new { |hash, key| hash[key] = [] }
          selections.each do |selection|
            refuse!("report selector") unless selection.is_a?(Hash) && selection.keys.sort == %w[assignment_id number task_id]
            id, assignment_id, number = selection.values_at("task_id", "assignment_id", "number")
            token!(id); token!(assignment_id)
            refuse!("report scope") unless number.is_a?(String) && number.match?(Authority::PreparedWork::SCOPE)
            refuse!("report is not a dependency") unless id != selected && tasks.key?(id)
            identity = [id, assignment_id, number]
            refuse!("duplicate report") if seen[identity]
            seen[identity] = true
            assignment = @executor.assignment_manager.load(assignment_id)
            refuse!("report assignment association") unless assignment && assignment.task_id == id && assignment.project_id == project
            metadata = read(assignment.assignment_file)
            parsed_metadata = YAML.safe_load(metadata, permitted_classes: [Time, Date])
            refuse!("report assignment changed") unless parsed_metadata["session_id"] == assignment_id &&
              parsed_metadata["task_id"] == id && parsed_metadata["project_id"] == project
            inventory(assignment.reports_dir)
            matches = inventory(assignment.steps_dir).select do |name|
              name.end_with?(".st.md") && Atoms::StepFileParser.parse_filename(name)[:number] == number
            end
            refuse!("report step association") unless matches.one?
            step = matches.first
            read(File.join(assignment.steps_dir, step))
            parsed = Atoms::StepFileParser.parse_filename(step)
            filename = Atoms::StepFileParser.generate_report_filename(number, parsed.fetch(:name))
            grouped[id] << {assignment_id: assignment_id, number: number,
              bytes: read(File.join(assignment.reports_dir, filename))}
          end
          grouped.each_value { |entries| entries.sort_by! { |entry| [entry.fetch(:assignment_id), number_key(entry.fetch(:number))] } }
          grouped
        end

        def record(path, bytes)
          {"filename" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
        end

        def read(path)
          bytes = read_bytes(path)
          refuse!("captured input changed") if @reads.key?(path) && @reads.fetch(path) != bytes
          @reads[path] = bytes
          refuse!("capture inventory bound") if @reads.size > 4096 || @reads.values.sum(&:bytesize) > Authority::PreparedWork::MAX_TOTAL
          bytes
        end

        def inventory(path)
          names = Dir.children(path).sort.freeze
          refuse!("capture inventory bound") if names.size > 4096
          refuse!("input inventory changed") if @inventories.key?(path) && @inventories.fetch(path) != names
          @inventories[path] = names
        end

        def read_bytes(path)
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            refuse!("input is not a bounded regular file") unless file.stat.file? && file.stat.size <= Authority::PreparedWork::MAX_TEXT
            bounded_text(file.read(Authority::PreparedWork::MAX_TEXT + 1))
          end
        rescue SystemCallError
          refuse!("input unavailable")
        end

        def bounded_text(bytes)
          refuse!("input text bound") unless bytes.is_a?(String) && bytes.bytesize.between?(1, Authority::PreparedWork::MAX_TEXT)
          text = bytes.dup.force_encoding(Encoding::UTF_8)
          refuse!("input encoding") unless text.valid_encoding? && !text.include?("\0")
          text.freeze
        end

        def number_key(number) = number.split(".").map(&:to_i)
        def token!(value)
          refuse!("invalid identity") unless value.is_a?(String) && value.match?(Authority::PreparedWork::TOKEN)
        end
        def refuse!(message) = raise(AttemptErrors::ReceiptRejected, "prepared_input_invalid: #{message}")
      end
    end
  end
end
