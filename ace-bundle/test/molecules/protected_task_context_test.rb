# frozen_string_literal: true
require_relative "../test_helper"
require "ace/bundle/molecules/protected_task_context"
require "tmpdir"
require "fcntl"
require "fileutils"

class ProtectedTaskContextTest < AceTestCase
  Bridge = Ace::Bundle::Molecules::ProtectedTaskContext
  EntryOwner = Ace::Runtime::Molecules::ProtectedTaskContextEntry
  Status = Struct.new(:ok) { def success?; ok; end }

  # Installed file/mount owner is injected before invocation. The real private
  # read-only FD5 selector and fixed transport API are exercised without spawning.
  class Owner
    attr_reader :entries
    def initialize(discovery, interpreter)
      @discovery, @interpreter, @entries = discovery, interpreter, []
    end
    def with; yield @discovery; end
    def validate_pin!(pin); EntryOwner.new.validate_pin!(pin); end
    def with_entry(pin)
      @entries << pin
      File.open(@interpreter, File::RDONLY) do |file|
        yield EntryOwner::Entry.new(pin: pin, manifest: {}, body: "exact held wrapper #{pin.fetch('wrapper').fetch('sha256')}", interpreter: file)
      end
    end
  end

  def pin(name)
    {"manifest" => {"path" => "/fixture/#{name}.json", "bytes" => 100, "sha256" => name == "current" ? "1" * 64 : "2" * 64},
      "wrapper" => {"path" => "/fixture/#{name}.py", "bytes" => 200, "sha256" => name == "current" ? "3" * 64 : "4" * 64}}
  end

  def fixture(protected: true, discovery: true)
    Dir.mktmpdir("ace-bundle-fixed-entry-", "/tmp") do |root|
      interpreter = File.join(root, "interpreter")
      File.binwrite(interpreter, "controlled interpreter")
      owner = Owner.new(discovery ? pin("current") : nil, interpreter)
      selector = {mapping: "mapping", assignment: "assignment@010", attempt: "original-attempt"}
      association = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "original-attempt", "scope" => "010",
        "definition_digest" => "a" * 64, "selection_sha256" => "b" * 64}
      text = "---\nbundle:\n  commands: ['MUST NEVER EXECUTE']\n---\n{{unrendered.captured.instruction}}\n"
      records = [{"schema" => "ace.assign.task-context-principal/v1", "uid" => Process.uid, "protected_worker" => protected},
        association.merge("schema" => "ace.assign.task-context-selection/v1", "task_context_entry" => pin("original")),
        association.merge("schema" => "ace.assign.prepared-task-context/v1", "task_id" => "task", "text" => text)]
      calls = []
      outputs = records.map { |record| Ace::Herdr::Molecules::BoundedProcess::Result.new(JSON.generate(record) + "\n", "", Status.new(true), false) }
      runner = Object.new
      test = self
      runner.define_singleton_method(:call) do |argv, **options|
        calls << [argv, options]
        test.assert_equal ["/proc/self/fd/4", "-I", "-S", "-B", "-", "authority"], argv.first(6)
        test.assert_equal({}, options.fetch(:environment))
        test.assert_equal "/", options.fetch(:chdir)
        test.assert_equal true, options.fetch(:cleanup_group)
        test.assert_equal 30, options.fetch(:timeout_s)
        test.assert_equal 16_384, options.fetch(:stderr_limit)
        test.assert_equal [4, 5], options.fetch(:descriptor_mapping).keys.sort
        handles = options.fetch(:descriptor_mapping)
        handles.each_value { |handle| test.assert_equal Fcntl::O_RDONLY, handle.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE }
        test.assert_equal owner.entries.last.fetch("manifest"), JSON.parse(handles.fetch(5).read)
        test.assert_equal "exact held wrapper #{owner.entries.last.fetch('wrapper').fetch('sha256')}", options.fetch(:stdin_data)
        outputs.fetch(calls.size - 1)
      end
      bridge = Bridge.new(entry_owner: owner, runner: runner, env: {})
      yield bridge, owner, calls, outputs, records, selector, text, root
    end
  end

  def test_current_discovery_classifies_but_only_original_entry_returns_raw_text
    fixture do |bridge, owner, calls, _, _, selector, text, _|
      assert_equal text, bridge.load("task://task", options: selector)
      assert_equal [pin("current"), pin("current"), pin("original")], owner.entries
      assert_equal [1_024, 65_536, 6_307_840], calls.map { |_, options| options.fetch(:output_limit) }
      assert_equal ["authority", "task-context-principal"], calls.first.first.drop(5)
      assert_equal ["authority", "task-context-selection", "--mapping", "mapping", "--assignment", "assignment@010", "--attempt", "original-attempt"], calls[1].first.drop(5)
      assert_equal "task-context", calls.last.first[6]
      assert_equal ["--task", "task"], calls.last.first.last(2)
      assert calls.flat_map { |_, options| options.fetch(:descriptor_mapping).values }.all?(&:closed?)
    end
  end

  def test_actual_runtime_entry_returns_bundle_text_only_after_unchanged_verification
    artifact_root = File.expand_path(".ace-local/protected-entry-fixtures", Dir.pwd)
    FileUtils.mkdir_p(artifact_root)
    [false, true].each do |mutate|
      Dir.mktmpdir("actual-bundle-entry-", artifact_root) do |root|
        artifact = lambda do |name, bytes, mode = 0o644|
          path = File.join(root, name)
          File.binwrite(path, bytes)
          File.chmod(mode, path)
          {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
        end
        wrapper = artifact.call("wrapper.py", "# actual held selected body\n")
        interpreter = artifact.call("python", "controlled never executed interpreter", 0o755)
        bootstrap = %w[original_source owner preparation].to_h { |key| [key, artifact.call("#{key}.json", "held selected metadata")] }
        bootstrap["startup_entries"] = {"ace-assign" => artifact.call("assign.rb", "held selected assign")}
        manifest = {"schema" => EntryOwner::MANIFEST_SCHEMA, "role" => EntryOwner::ROLE,
          "wrapper" => wrapper, "interpreter" => interpreter, "bootstrap" => bootstrap}
        selected = {"manifest" => artifact.call("manifest.json", JSON.generate(manifest)), "wrapper" => wrapper}
        projection = artifact.call("projection.json", JSON.generate("schema" => EntryOwner::SCHEMA, "task_context_entry" => selected)).fetch("path")
        protection = Object.new
        protection.define_singleton_method(:root_path!) { |_| }
        protection.define_singleton_method(:verify!) do |_, handle, directory:|
          raise "controlled artifact kind differs" unless directory ? handle.stat.directory? : handle.stat.file?
        end
        artifacts = Class.new do
          define_method(:initialize) do
            @held = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: protection,
              file_limit: EntryOwner::FILE_LIMIT, total_limit: EntryOwner::TOTAL_LIMIT, count_limit: EntryOwner::COUNT_LIMIT)
          end
          define_method(:with) { |&block| @held.with { block.call(self) } }
          define_method(:read_path!) { |path, **options| raise "unexpected projection" unless path == EntryOwner::PATH; @held.read_path!(projection, **options) }
          define_method(:read!) { |reference| @held.read!(reference) }
          define_method(:verify_unchanged!) { @held.verify_unchanged! }
          define_method(:with_readonly_handle!) { |reference, &block| @held.with_readonly_handle!(reference, &block) }
        end
        owner = EntryOwner.new(artifacts_factory: -> { artifacts.new }, stat: ->(path) { raise "unexpected presence" unless path == EntryOwner::PATH; File.lstat(projection) })
        association = {"mapping_id" => "mapping", "assignment_id" => "assignment", "attempt_id" => "attempt", "scope" => "010", "definition_digest" => "a" * 64, "selection_sha256" => "b" * 64}
        text = "Exact captured text.\n"
        frames = [{"schema" => "ace.assign.task-context-principal/v1", "uid" => Process.uid, "protected_worker" => true},
          association.merge("schema" => "ace.assign.task-context-selection/v1", "task_context_entry" => selected),
          association.merge("schema" => "ace.assign.prepared-task-context/v1", "task_id" => "task", "text" => text)]
        handles = []
        test = self
        runner = Object.new
        runner.define_singleton_method(:call) do |_, **options|
          test.assert_equal "# actual held selected body\n", options.fetch(:stdin_data)
          test.assert_equal selected.fetch("manifest"), JSON.parse(options.fetch(:descriptor_mapping).fetch(5).read)
          handles.concat(options.fetch(:descriptor_mapping).values)
          frame = frames.shift
          File.binwrite(wrapper.fetch("path"), "changed after original response") if mutate && frames.empty?
          Ace::Herdr::Molecules::BoundedProcess::Result.new(JSON.generate(frame) + "\n", "", Status.new(true), false)
        end
        bridge = Bridge.new(entry_owner: owner, runner: runner, env: {})
        options = {mapping: "mapping", assignment: "assignment@010", attempt: "attempt"}
        if mutate
          assert_raises(Ace::Bundle::Error) { bridge.load("task://task", options: options) }
        else
          assert_equal text, bridge.load("task://task", options: options)
        end
        assert_empty frames
        assert handles.all?(&:closed?)
      end
    end
  end

  def test_absent_ordinary_and_installed_unrelated_principal_preserve_ordinary_mode
    fixture(protected: false, discovery: false) do |bridge, owner, calls, _, _, _, _, _|
      assert_nil bridge.load("task://ordinary")
      assert_empty calls
      assert_empty owner.entries
    end
    fixture(protected: false) do |bridge, _, calls, _, _, _, _, _|
      assert_nil bridge.load("task://ordinary")
      assert_equal 1, calls.size
    end
  end

  def test_dropped_hints_cannot_restore_ordinary_for_installed_protected_principal
    fixture do |bridge, _, calls, _, _, _, _, _|
      error = assert_raises(Ace::Bundle::Error) { bridge.load("task://task") }
      assert_match "prepared_input_mismatch", error.message
      assert_equal 1, calls.size
    end
    fixture(discovery: false) do |bridge, _, calls, _, _, selector, _, _|
      assert_raises(Ace::Bundle::Error) { bridge.load("task://task", options: selector) }
      assert_empty calls
    end
  end

  def test_extra_output_nonzero_truncated_and_mismatched_original_text_never_consumed
    %i[extra nonzero truncated digest].each do |bad|
      fixture do |bridge, _, _, outputs, records, selector, _, _|
        case bad
        when :extra then outputs.last.stdout += "{}\n"
        when :nonzero then outputs.last.status = Status.new(false)
        when :truncated then outputs.last.oversized = true
        when :digest
          records.last["definition_digest"] = "c" * 64
          outputs.last.stdout = JSON.generate(records.last) + "\n"
        end
        error = assert_raises(Ace::Bundle::Error) { bridge.load("task://task", options: selector) }
        assert_match(bad == :nonzero ? "prepared_input_unavailable" : "prepared_input_mismatch", error.message)
      end
    end
  end

  def test_typed_uid_and_original_ref_fields_refuse_before_original_entry_spawn
    fixture do |bridge, owner, calls, outputs, records, selector, _, _|
      records.first["uid"] = Process.uid.to_f
      outputs.first.stdout = JSON.generate(records.first) + "\n"
      assert_raises(Ace::Bundle::Error) { bridge.load("task://task", options: selector) }
      assert_equal 1, calls.size
      refute_includes owner.entries, pin("original")
    end
    fixture do |bridge, owner, calls, outputs, records, selector, _, _|
      reference = records[1].fetch("task_context_entry").fetch("manifest")
      reference["bytes"] = reference.fetch("bytes").to_f
      outputs[1].stdout = JSON.generate(records[1]) + "\n"
      assert_raises(Ace::Bundle::Error) { bridge.load("task://task", options: selector) }
      assert_equal 2, calls.size
      refute_includes owner.entries, pin("original")
    end
  end

  def test_bundle_direct_load_keeps_captured_frontmatter_and_tokens_as_raw_text
    fixture do |bridge, _, _, _, _, selector, text, root|
      loader = Ace::Bundle::Organisms::BundleLoader.new(selector.merge(base_dir: root))
      loader.instance_variable_set(:@protected_task_context, bridge)
      bundle = loader.load_auto("task://task")
      assert_equal text, bundle.content
      assert_equal [{path: "task://task", content: text}], bundle.source_files
      assert_equal true, bundle.metadata.fetch(:protected_prepared)
      assert_empty bundle.commands
    end
  end

  def test_bundle_files_base_and_sections_consume_text_without_parsing_captured_commands
    %i[files base sections].each do |shape|
      fixture do |bridge, _, _, _, _, selector, text, root|
        loader = Ace::Bundle::Organisms::BundleLoader.new(selector.merge(base_dir: root))
        loader.instance_variable_set(:@protected_task_context, bridge)
        config = case shape
        when :files
          File.write(File.join(root, "note.txt"), "Ordinary mutable code context.\n")
          {"files" => ["task://task", "note.txt"]}
        when :base then {"base" => "task://task"}
        when :sections then {"sections" => {"captured" => {"files" => ["task://task"]}}}
        end
        bundle = if shape == :base || shape == :sections
          template = File.join(root, "selected-template.md")
          File.write(template, YAML.dump("bundle" => config) + "---\nMutable outer template.\n")
          loader.load_file(template)
        else
          loader.load_auto(YAML.dump("bundle" => config))
        end
        records = shape == :sections ? bundle.sections.values.flat_map { |section| Array(section[:_processed_files]) } : bundle.source_files
        source = records.find { |record| record[:path] == "task://task" }
        assert source, "#{shape} must retain the captured URI content record"
        assert_equal text, source.fetch(:content)
        assert_empty bundle.commands
        assert_equal "task://task", bundle.source_files.first.fetch(:path) if shape == :files
      end
    end
  end
end
