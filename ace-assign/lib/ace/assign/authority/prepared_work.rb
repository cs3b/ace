# frozen_string_literal: true

require "json"
require "digest"
require "yaml"
require "date"
require_relative "../atoms/step_file_parser"
require_relative "candidate_transfer"

module Ace
  module Assign
    module Authority
      # Closed prepared-input tree. Git transport and canonical publication are
      # owned by CandidateTransfer/LaunchLifecycle; this object owns their shared
      # byte contract, never a registration, attempt or progress ledger.
      class PreparedWork
        MAX_TEXT = 1024 * 1024
        MAX_TOTAL = 64 * 1024 * 1024
        MAX_MANIFEST = 32_768
        TOKEN = /\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,199}\z/
        SCOPE = /\A[0-9]+(?:\.[0-9]+)*\z/
        SHA = /\A[0-9a-f]{64}\z/
        TOP = %w[version assignment_id project_id task_id scope job steps context].freeze
        RECORD = %w[bytes filename sha256].freeze
        PROGRESS = %w[status started_at completed_at error stall_reason fork_launch_pid fork_tracked_pids fork_pid_updated_at fork_pid_file].freeze
        attr_reader :manifest, :files, :definition, :selection_sha256, :manifest_sha256

        def initialize(files:)
          invalid!("file inventory") unless files.is_a?(Hash) && files.size.between?(4, 4096)
          @files = files.to_h do |path, bytes|
            invalid!("file path") unless path.is_a?(String) && !path.start_with?("/") && path.split("/", -1).all? { |part| !part.empty? && !%w[. .. .git].include?(part.downcase) }
            invalid!("text size") unless bytes.is_a?(String) && bytes.bytesize.between?(1, MAX_TEXT)
            text = bytes.dup.force_encoding(Encoding::UTF_8)
            invalid!("UTF-8") unless text.valid_encoding? && !text.include?("\0")
            [path.dup.freeze, text.freeze]
          end.freeze
          invalid!("expanded size") if @files.values.sum(&:bytesize) > MAX_TOTAL
          manifest_bytes = @files.fetch("manifest.json")
          invalid!("manifest size") if manifest_bytes.bytesize > MAX_MANIFEST
          @manifest = parse_json(manifest_bytes)
          closed!(@manifest, TOP)
          invalid!("version") unless @manifest["version"].is_a?(Integer) && @manifest["version"] == 1
          %w[assignment_id project_id task_id].each { |key| token!(@manifest[key]) }
          scope!(@manifest["scope"])
          canonical = self.class.canonical_manifest(@manifest)
          invalid!("manifest serialization") unless manifest_bytes == canonical + "\n"
          @selection_sha256 = Digest::SHA256.hexdigest(canonical).freeze
          @manifest_sha256 = Digest::SHA256.hexdigest(manifest_bytes).freeze
          @used = %w[manifest.json definition.json]
          record!(@manifest["job"], "job.yaml")
          @job = yaml!(@files.fetch("job.yaml"))
          steps!
          context!
          task_closure!
          selected_root!
          invalid!("undeclared file") unless @used.sort == @files.keys.sort
          definition_bytes = @files.fetch("definition.json")
          invalid!("definition size") if definition_bytes.bytesize > MAX_MANIFEST
          @definition = parse_json(definition_bytes)
          invalid!("base definition") unless @definition.is_a?(Hash) && !@definition.key?("prepared_work") &&
            @definition["session_id"] == @manifest["assignment_id"] && @definition["project_id"] == @manifest["project_id"] && @definition["task_id"] == @manifest["task_id"]
          deep_freeze(@definition)
          deep_freeze(@manifest)
          freeze
        rescue KeyError, JSON::ParserError, Psych::Exception => error
          invalid!(error.message)
        end

        # The existing transport verifies complete Git objects before this
        # shared byte contract parses anything. Preserve the original input for
        # the eventual registration journal; CandidateTransfer may reexport it.
        def self.admit(bytes:, head:, tree:, sha256:, size:, root:)
          transfer = CandidateTransfer.new(root: root)
          transfer.admit(bytes: bytes, head: head, sha256: sha256, size: size) do |repository, deadline, result|
            raise ArgumentError, "prepared_input_invalid: Git tree differs" unless result.fetch("tree") == tree
            new(files: transfer.prepared_files(repository: repository, deadline: deadline, head: head))
          end
        end

        def reference(head:, tree:)
          invalid!("Git identity") unless [head, tree].all? { |id| id.is_a?(String) && id.match?(/\A[0-9a-f]{40}\z/) }
          {"version" => 1, "task_id" => manifest.fetch("task_id"), "scope" => manifest.fetch("scope"),
            "prepared_head" => head, "prepared_tree" => tree, "manifest_bytes" => files.fetch("manifest.json").bytesize,
            "manifest_sha256" => manifest_sha256, "selection_sha256" => selection_sha256}.freeze
        end

        def definition_bytes(head:, tree:)
          bytes = JSON.generate(definition.merge("prepared_work" => reference(head: head, tree: tree)))
          invalid!("final definition size") if bytes.bytesize > MAX_MANIFEST
          bytes.freeze
        end

        # StepFileParser owns body/frontmatter semantics; only these progress
        # fields differ from accepted work. Reports are separate mutable output.
        def self.work_projection(bytes)
          parsed = Atoms::StepFileParser.parse(bytes)
          {"frontmatter" => parsed.fetch(:frontmatter).reject { |key, _| PROGRESS.include?(key) }, "body" => parsed.fetch(:body)}
        end

        def self.canonical_manifest(value)
          sorted = lambda do |item|
            case item
            when Hash then item.keys.sort.to_h { |key| [key, sorted.call(item.fetch(key))] }
            when Array then item.map { |entry| sorted.call(entry) }
            else item
            end
          end
          JSON.generate(TOP.to_h { |key| [key, sorted.call(value.fetch(key))] })
        end

        private

        def steps!
          steps = @manifest["steps"]
          invalid!("steps") unless steps.is_a?(Array) && steps.size.between?(1, 256)
          @step_frontmatter = {}
          numbers = steps.map do |step|
            closed!(step, %w[number filename bytes sha256])
            number = step.fetch("number"); scope!(number)
            invalid!("step scope") unless number == @manifest["scope"] || number.start_with?(@manifest["scope"] + ".")
            filename = step.fetch("filename")
            record!(step.reject { |key, _| key == "number" }, "steps/" + filename)
            # Step record filenames are basenames; inventory paths add steps/.
            content = @files.fetch("steps/" + filename)
            match = Atoms::StepFileParser::FRONTMATTER_REGEX.match(content)
            invalid!("step frontmatter") unless match
            fm = yaml!(match[1])
            invalid!("initial status") unless fm.is_a?(Hash) && fm.fetch("status", "pending") == "pending"
            @step_frontmatter[number] = fm
            invalid!("step name") unless fm["name"].is_a?(String) && !fm["name"].empty?
            invalid!("step filename") unless filename == Atoms::StepFileParser.generate_filename(number, fm["name"])
            number
          end
          invalid!("step ordering/root") unless numbers.uniq == numbers && numbers == numbers.sort_by { |n| n.split(".").map(&:to_i) } && numbers.first == @manifest["scope"]
        end

        def context!
          context = @manifest["context"]
          invalid!("context") unless context.is_a?(Array) && context.size.between?(1, 256)
          uris = context.map do |entry|
            closed!(entry, %w[uri task_id spec text reports]); token!(entry["task_id"])
            uri = "task://" + entry.fetch("task_id")
            invalid!("context URI") unless entry["uri"] == uri
            prefix = "context/" + entry.fetch("task_id")
            record!(entry["spec"], prefix + "/spec.md")
            record!(entry["text"], prefix + "/bundle.txt")
            reports = entry["reports"]
            invalid!("reports") unless reports.is_a?(Array)
            identities = reports.map do |report|
              closed!(report, %w[assignment_id number file]); token!(report["assignment_id"]); scope!(report["number"])
              record!(report["file"], prefix + "/reports/" + report.fetch("assignment_id") + "/" + report.fetch("number") + ".r.md")
              [report["assignment_id"], report["number"].split(".").map(&:to_i)]
            end
            invalid!("report ordering") unless identities.uniq == identities && identities == identities.sort
            uri
          end
          invalid!("context ordering/selected task") unless uris.uniq == uris && uris == uris.sort && uris.include?("task://" + @manifest["task_id"])
        end

        def selected_root!
          scope = @manifest.fetch("scope"); task = @manifest.fetch("task_id")
          root = @step_frontmatter.fetch(scope)
          invalid!("selected fork root") unless root["context"] == "fork" && root["taskref"] == task
          @step_frontmatter.each do |number, fm|
            invalid!("selected taskref") if fm.key?("taskref") && fm["taskref"] != task
            next if number == scope
            parent = number.split(".")[0...-1].join(".")
            invalid!("selected parent association") unless fm["parent"] == parent && @step_frontmatter.key?(parent)
          end
          invalid!("job steps") unless @job.is_a?(Hash) && @job["steps"].is_a?(Array)
          roots = @job.fetch("steps").select { |step| step.is_a?(Hash) && step["context"] == "fork" && step["taskref"] == task }
          invalid!("job selected root") unless roots.one? && roots.first.values_at("number", "taskref") == [scope, task]
        end

        def task_closure!
          specs = @manifest.fetch("context").to_h do |entry|
            content = @files.fetch(entry.fetch("spec").fetch("filename"))
            match = Atoms::StepFileParser::FRONTMATTER_REGEX.match(content)
            invalid!("task frontmatter") unless match
            task = yaml!(match[1])
            invalid!("task association") unless task.is_a?(Hash) && task["id"] == entry["task_id"] && task.fetch("needs_review", false) == false
            dependencies = task.fetch("dependencies", [])
            invalid!("task dependencies") unless dependencies.is_a?(Array) && dependencies.uniq == dependencies
            dependencies.each { |dependency| token!(dependency) }
            [entry.fetch("task_id"), task]
          end
          selected = specs.fetch(@manifest.fetch("task_id"))
          invalid!("selected reviewed status") unless %w[pending in-progress].include?(selected["status"])
          visiting = []; visited = []
          walk = lambda do |id|
            invalid!("dependency cycle: " + (visiting + [id]).join(" -> ")) if visiting.include?(id)
            return if visited.include?(id)
            visiting << id
            specs.fetch(id).fetch("dependencies", []).each { |dependency| walk.call(dependency) }
            visiting.pop; visited << id
          end
          walk.call(@manifest.fetch("task_id"))
          invalid!("undeclared context") unless visited.sort == specs.keys.sort
        end

        def record!(record, path)
          closed!(record, RECORD)
          # Selected step record uses an exact basename; other records use the
          # exact canonical relative artifact path.
          expected = path.start_with?("steps/") ? path.delete_prefix("steps/") : path
          invalid!("content reference") unless record["filename"] == expected && record["bytes"].is_a?(Integer) && record["bytes"].positive? && record["sha256"].is_a?(String) && record["sha256"].match?(SHA)
          bytes = @files.fetch(path)
          invalid!("content digest") unless record["bytes"] == bytes.bytesize && record["sha256"] == Digest::SHA256.hexdigest(bytes)
          invalid!("duplicate file") if @used.include?(path)
          @used << path
        end

        def yaml!(bytes)
          ast = Psych.parse_stream(bytes)
          invalid!("YAML requires one document") unless ast.children.size == 1
          scanner = Psych::ScalarScanner.new(Psych::ClassLoader::Restricted.new([], []))
          pending = [[ast, 0]]
          until pending.empty?
            node, depth = pending.pop
            invalid!("YAML nesting exceeds 32") if depth > 32
            invalid!("YAML alias") if node.is_a?(Psych::Nodes::Alias)
            if node.is_a?(Psych::Nodes::Mapping)
              keys = node.children.each_slice(2).map(&:first)
              decoded = keys.map do |key|
                invalid!("YAML mapping keys") unless key.is_a?(Psych::Nodes::Scalar) && [nil, "tag:yaml.org,2002:str"].include?(key.tag)
                value = key.plain && key.tag.nil? ? scanner.tokenize(key.value) : key.value
                invalid!("YAML mapping keys must be strings") unless value.is_a?(String)
                value
              end
              invalid!("duplicate YAML key") unless decoded.uniq.size == decoded.size
            end
            (node.children || []).each { |child| pending << [child, depth + 1] }
          end
          value = YAML.safe_load(bytes, permitted_classes: [Time, Date], aliases: false)
          values = [value]
          until values.empty?
            item = values.pop
            case item
            when Hash
              invalid!("YAML mapping keys must be strings") unless item.keys.all? { |key| key.is_a?(String) }
              values.concat(item.values)
            when Array then values.concat(item)
            when String
              invalid!("YAML string encoding") unless item.valid_encoding? && !item.include?("\0")
            when Float then invalid!("YAML nonfinite number") unless item.finite?
            when Integer, TrueClass, FalseClass, NilClass, Time, Date
              # Managed files retain StepFileParser's standard timestamp types.
            else invalid!("unsupported YAML value")
            end
          end
          value
        end

        def parse_json(bytes)
          JSON.parse(bytes, create_additions: false, max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
        end

        def closed!(value, keys)
          invalid!("closed fields") unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def token!(value)
          invalid!("identity") unless value.is_a?(String) && value.match?(TOKEN)
        end

        def scope!(value)
          invalid!("scope") unless value.is_a?(String) && value.match?(SCOPE)
        end

        def deep_freeze(value)
          case value
          when Hash then value.each { |key, item| deep_freeze(key); deep_freeze(item) }
          when Array then value.each { |item| deep_freeze(item) }
          end
          value.freeze
        end

        def invalid!(reason)
          raise ArgumentError, "prepared_input_invalid: #{reason}"
        end
      end
    end
  end
end
