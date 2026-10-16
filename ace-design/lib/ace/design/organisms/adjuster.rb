# frozen_string_literal: true
require "time"
module Ace
  module Design
    module Organisms
      class Adjuster
        A = Molecules::Artifacts
        C = Molecules::DesignContext
        D = Molecules::ContextDocument
        def initialize(config: Design.config, executor: Molecules::AgentExecutor.new, contexts: C.new)
          @config, @executor, @contexts = config, executor, contexts
        end
        def adjust(surface: nil, kind: nil, profile: nil, prompt: nil, refresh: false, dry_run: false, propose: false, model: nil)
          raise Error, "refresh does not accept --prompt" if prompt && refresh
          raise Error, "Use --dry-run or --propose, not both" if dry_run && propose
          surface, kind = Molecules::DesignSource.scope(surface: surface, kind: kind, profile: profile)
          Atoms::Contracts.text(prompt, "adjust prompt") if prompt
          timeout = Integer(@config.fetch("agent_timeout"))
          raise Error, "agent timeout must be 1..3600 seconds" unless (1..3600).cover?(timeout)
          original = @contexts.repository.read(readonly: dry_run)
          targets = @contexts.targets(original, surface: surface, kind: kind, context: profile)
          # Detect hand edits before any model call, including edits to stale generated documents.
          targets.each { |id| @contexts.read_generated(original, id) if original.key?(C.file(id, "design.md")) }
          proposed = original.dup
          targets.each do |id|
            key = C.file(id, "defaults.md")
            proposed[key] = @contexts.default(id) if refresh || !proposed.key?(key)
            proposed[C.file(id, "user.md")] ||= ""
          end
          target = profile || surface
          if prompt
            key = C.file(target, "user.md")
            proposed[key] += "\n\n## Decision update #{Time.now.utc.iso8601}\n\n#{prompt}\n"
          end
          if dry_run
            return {"status" => "planned", "contexts" => targets, "refresh" => refresh,
              "requested_model" => model || @config.fetch("model"),
              "next" => "Run without --dry-run, or use --propose for an unpublished model composition"}
          end
          run = allocate_run
          warn "Design adjustment: #{run}"
          report = {"status" => "preparing", "report_dir" => run, "contexts" => targets,
            "refresh" => refresh, "propose" => propose, "requested_model" => model || @config.fetch("model")}
          dirty = []
          targets.each do |id|
            parent = id.empty? ? nil : C.chain(id)[-2]
            if parent && dirty.include?(parent)
              dirty << id
              next
            end
            begin
              @contexts.resolve(proposed, id)
            rescue Error
              dirty << id
            end
          end
          report["changed_contexts"] = dirty
          inputs = dirty.map do |id|
            parent_id = id.empty? ? nil : C.chain(id)[-2]
            {"id" => id, "parent" => parent_id, "old_defaults" => original[C.file(id, "defaults.md")],
              "parent_design" => parent_id && !dirty.include?(parent_id) ? proposed.fetch(C.file(parent_id, "design.md")) : nil,
              "new_defaults" => proposed.fetch(C.file(id, "defaults.md")),
              "user" => proposed.fetch(C.file(id, "user.md")), "previous_design" => original[C.file(id, "design.md")]}
          end
          A.json(File.join(run, "request.json"), {"contexts" => inputs})
          if dirty.empty?
            report["status"] = "unchanged"
            return save_report(run, report)
          end
          workspace = File.join(run, "worker")
          FileUtils.mkdir_p(workspace)
          FileUtils.cp(File.join(run, "request.json"), workspace)
          File.write(File.join(workspace, "system.md"), Molecules::AdjustPrompts::SYSTEM)
          File.write(File.join(workspace, "prompt.md"), Molecules::AdjustPrompts::PROMPT)
          @executor.validate_model(report.fetch("requested_model"))
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          result = @executor.call(model: report.fetch("requested_model"), prompt: Molecules::AdjustPrompts::PROMPT,
            system: Molecules::AdjustPrompts::SYSTEM, workspace: workspace, timeout: timeout)
          report.merge!(result.slice("execution", "model", "provider", "usage", "metadata"))
          A.json(File.join(workspace, "execution.json"), result)
          raise Error, "Adjustment agent did not complete successfully" unless result.dig("execution", "status") == "succeeded"
          unless !File.symlink?(File.join(workspace, "request.json")) && File.binread(File.join(workspace, "request.json")) == File.binread(File.join(run, "request.json"))
            raise Error, "Adjustment agent modified its inputs"
          end
          output_path = File.join(workspace, "result.json")
          raise Error, "Adjustment result missing or symlink" unless File.file?(output_path) && !File.symlink?(output_path)
          output = validate_output(A.object(output_path), dirty)
          report["conflicts"] = output.fetch("conflicts")
          report["summary"] = output.fetch("contexts").transform_values { |node| node.reject { |key, _| key == "design" } }
          if report["conflicts"].empty?
            dirty.each do |id|
              parent = id.empty? ? nil : proposed.fetch(C.file(C.chain(id)[-2], "design.md"))
              decisions = C.chain(id).to_h { |ancestor| [ancestor, proposed.fetch(C.file(ancestor, "user.md"))] }
              proposed[C.file(id, "design.md")] = D.effective(id: id, defaults: proposed.fetch(C.file(id, "defaults.md")),
                user: proposed.fetch(C.file(id, "user.md")), parent: parent,
                body: output.fetch("contexts").fetch(id).fetch("design"), decisions: decisions)
            end
            targets.each { |id| @contexts.resolve(proposed, id) }
            candidate = write_candidate(run, proposed)
            write_diff(run, original, proposed)
            report["stale_contexts"] = @contexts.ids(proposed).reject do |id|
              @contexts.resolve(proposed, id)
              true
            rescue Error
              false
            end
            if propose
              report["status"] = "proposed"
            else
              report["status"] = "proposed"
              save_report(run, report)
              @contexts.repository.publish(candidate: candidate, original: original, run: run)
              report["status"] = "published"
              begin
                return save_report(run, report)
              rescue StandardError => error
                warn "Contexts published, but report update failed: #{error.message}"
                return report
              end
            end
          else
            report["status"] = "conflict"
          end
          save_report(run, report)
        rescue StandardError, Interrupt => error
          if report && run
            report["status"] = error.is_a?(Interrupt) ? "interrupted" : "failed"
            report["error"] = error.message
            begin
              save_report(run, report)
            rescue StandardError
              # Keep the original failure authoritative when diagnostics cannot be saved.
              nil
            end
          end
          raise
        ensure
          if report && started
            report["duration"] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3)
            begin
              A.json(File.join(run, "report.json"), report)
            rescue StandardError => error
              warn "Could not persist adjustment timing: #{error.message}"
            end
          end
        end
        private
        def allocate_run
          base = @contexts.repository.runs
          @contexts.repository.safe_path!(base)
          FileUtils.mkdir_p(base)
          100.times do
            directory = File.join(base, Ace::B36ts.encode(Time.now, format: :ms))
            begin
              Dir.mkdir(directory)
              return directory
            rescue Errno::EEXIST
              sleep 0.002
            end
          end
          raise Error, "Could not allocate adjustment report"
        end
        def validate_output(output, targets)
          nodes = output["contexts"]
          conflicts = output["conflicts"]
          unless output.keys.sort == %w[conflicts contexts] && nodes.is_a?(Hash) && nodes.keys.sort == targets.sort &&
              conflicts.is_a?(Array) && conflicts.all? { |item| item.is_a?(String) && !item.strip.empty? }
            raise Error, "Adjustment result must contain every context and a conflicts array"
          end
          nodes.each do |id, node|
            unless node.is_a?(Hash) && node.keys.sort == %w[added_rules design omitted_defaults preserved_exceptions]
              raise Error, "Invalid adjustment result for #{id}"
            end
            Atoms::Contracts.text(node["design"], "design for #{id}")
            %w[added_rules preserved_exceptions omitted_defaults].each do |field|
              unless node[field].is_a?(Array) && node[field].all? { |item| item.is_a?(String) }
                raise Error, "Adjustment #{field} must be a text array"
              end
            end
          end
          output
        end
        def write_candidate(run, files)
          candidate = File.join(run, "candidate")
          files.each do |name, content|
            target = File.join(candidate, name)
            FileUtils.mkdir_p(File.dirname(target))
            File.binwrite(target, content)
          end
          candidate
        end
        def write_diff(run, before, after)
          text = (before.keys | after.keys).sort.filter_map do |name|
            next if before[name] == after[name]
            old = before.fetch(name, "").lines
            new = after.fetch(name, "").lines
            "--- #{name}\n+++ #{name}\n@@ -1,#{old.size} +1,#{new.size} @@\n" +
              old.map { |line| "-#{line.chomp}\n" }.join + new.map { |line| "+#{line.chomp}\n" }.join
          end.join("\n")
          File.write(File.join(run, "changes.diff"), text)
        end
        def save_report(run, report)
          A.json(File.join(run, "report.json"), report)
          File.write(File.join(run, "report.md"), "# Design adjustment: #{report.fetch('status')}\n\n" +
            "```json\n#{JSON.pretty_generate(report)}\n```\n\nSee changes.diff and worker/result.json when present.\n")
          report
        end
      end
    end
  end
end
