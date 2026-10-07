# frozen_string_literal: true
require "ace/assign/authority/prepared_work"
require "ace/assign/authority/transfer_codec"
require "open3"
require "tempfile"

module Ace
  module Assign
    # Real immutable transport shared by controlled lifecycle fixtures. Source
    # validators and Git/JournalMutation remain real; kernel/runtime are injected.
    module PreparedRegistrationFixture
      Artifact = Struct.new(:definition_bytes, :bundle, :work, :head, :tree, keyword_init: true) do
        def header(expected_generation:)
          {"assignment_id" => work.manifest.fetch("assignment_id"), "definition_digest" => Digest::SHA256.hexdigest(definition_bytes), "prepared_head" => head, "prepared_tree" => tree,
            "manifest_sha256" => work.manifest_sha256, "expected_generation" => expected_generation}
        end

        def with_input(root:)
          descriptor = Authority::TransferCodec.new.descriptor([bundle], purpose: :candidate)
          Tempfile.create("prepared-fixture", root, binmode: true) do |file|
            file.write(bundle); file.flush; file.rewind
            yield Authority::TransferCodec::Input.new(file, descriptor), descriptor
          end
        end
      end

      def self.build(root:, definition:, scope:)
        definition = definition.reject { |key, _| key == "prepared_work" }
        directory = Dir.mktmpdir("prepared-fixture-tree-", root); File.chmod(0700, directory)
        task = definition.fetch("task_id")
        step_path = "steps/#{scope}-execute.st.md"
        files = {"definition.json" => JSON.generate(definition), "job.yaml" => YAML.dump({"steps" => [{"number" => scope, "context" => "fork", "taskref" => task}]}),
          step_path => YAML.dump({"name" => "execute", "status" => "pending", "context" => "fork", "taskref" => task}) + "---\nExact fixture work.\n",
          "context/#{task}/spec.md" => YAML.dump({"id" => task, "status" => "pending", "needs_review" => false, "dependencies" => []}) + "---\nReviewed fixture task.\n",
          "context/#{task}/bundle.txt" => "Exact fixture context.\n"}
        record = ->(path) { {"filename" => path, "bytes" => files.fetch(path).bytesize, "sha256" => Digest::SHA256.hexdigest(files.fetch(path))} }
        manifest = {"version" => 1, "assignment_id" => definition.fetch("session_id"), "project_id" => definition.fetch("project_id"), "task_id" => task, "scope" => scope,
          "job" => record.call("job.yaml"), "steps" => [record.call(step_path).merge("number" => scope, "filename" => File.basename(step_path))],
          "context" => [{"uri" => "task://#{task}", "task_id" => task, "spec" => record.call("context/#{task}/spec.md"), "text" => record.call("context/#{task}/bundle.txt"), "reports" => []}]}
        files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
        files.each { |path, bytes| target = File.join(directory, path); FileUtils.mkdir_p(File.dirname(target)); File.binwrite(target, bytes) }
        git = lambda do |*args|
          output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
          raise error unless status.success?
          output
        end
        git.call("init", "-b", "main"); git.call("add", "."); git.call("-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "prepared fixture")
        head = git.call("rev-parse", "HEAD").strip; tree = git.call("rev-parse", "HEAD^{tree}").strip
        bundle_path = File.join(directory, "fixture.bundle"); git.call("bundle", "create", bundle_path, "--all")
        work = Authority::PreparedWork.new(files: files)
        Artifact.new(work: work, definition_bytes: work.definition_bytes(head: head, tree: tree), bundle: File.binread(bundle_path), head: head, tree: tree)
      ensure
        FileUtils.rm_rf(directory) if directory
      end
    end
  end
end
