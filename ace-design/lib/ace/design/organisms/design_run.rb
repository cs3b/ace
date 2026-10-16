# frozen_string_literal: true
require "fileutils"
require "securerandom"
require "digest"
require "time"
module Ace
  module Design
    module Organisms
      class DesignRun
        A = Molecules::Artifacts
        def initialize(root, executor: Molecules::AgentExecutor.new)
          @root = File.realpath(root)
          @executor = executor
          @mutex = Mutex.new
          reload
        end
        def status
          state = A.object(path("run.json"))
          state.merge("id" => File.basename(@root), "next" => "ace-design preview #{@root}", "session" => @root, "gallery" => File.file?(path("gallery.html")) ? path("gallery.html") : nil)
        end
        def resume
          locked do
            verify_inputs!
            verify_published!
            unless @state.fetch("preparation")["status"] == "succeeded"
              prepare
            end
            if @state.fetch("preparation")["status"] == "succeeded"
              pending = @preset.fetch("variants").reject { |s| @state.fetch("workers").fetch(s.fetch("id"))["status"] == "succeeded" }
              Molecules::Session.new(@root).write_gallery
              execute_slots(pending)
            end
            finish
          end
        end
        def revise(variant:, prompt:)
          Atoms::Contracts.text(prompt, "feedback")
          locked do
            verify_inputs!
            verify_published!
            slot = @preset.fetch("variants").find { |s| s.fetch("id") == variant }
            raise Error, "Unknown variant: #{variant}" unless slot
            raise Error, "Variant #{variant} has no published mockup" unless File.directory?(path("variants/#{variant}"))
            @state["status"] = "running"
            save
            execute_slot(slot, feedback: prompt)
            finish
          end
        end
        def select(variant:, decisions:)
          locked do
            verify_inputs!
            verify_published!
            session = Molecules::Session.new(@root)
            raise Error, "Select an available variant" unless session.variants.include?(variant)
            unless decisions.is_a?(Array) && !decisions.empty? && decisions.all? { |d| d.is_a?(String) && !d.strip.empty? }
              raise Error, "Provide at least one nonempty --decision"
            end
            selection = {"surface" => @metadata.fetch("surface"), "variant" => variant,
              "fixtures_sha256" => Digest::SHA256.file(path("fixtures.json")).hexdigest,
              "variant_sha256" => A.digest(path("variants/#{variant}")), "decisions" => decisions}
            A.json(path("selection.json"), selection)
            session.validate_selection
            selection
          end
        end
        private
        def path(relative)
          File.join(@root, relative)
        end
        def reload
          @metadata = A.object(path("session.json"))
          @preset = A.object(path("resolved.json"))
          @state = A.object(path("run.json"))
          unless %w[view component].include?(@metadata["kind"]) && @state.dig("inputs", "design.md")
            raise Error, "Session lacks task kind or frozen design assumptions; create a new session"
          end
        end
        def locked
          raise Error, "Refusing symlink lock" if File.symlink?(path(".run.lock"))
          File.open(path(".run.lock"), File::RDWR | File::CREAT, 0o600) do |lock|
            raise Error, "Session already has an active operation" unless lock.flock(File::LOCK_EX | File::LOCK_NB)
            reload
            Thread.handle_interrupt(Interrupt => :never) do
              recover_publication
              yield
            end
          rescue Interrupt => error
            @state["status"] = "interrupted"
            save_preserving_failure(error)
            raise
          ensure
            lock.flock(File::LOCK_UN)
          end
        end
        def save
          A.json(path("run.json"), @state)
        end
        # A diagnostic write must not replace the error that triggered it.
        def save_preserving_failure(failure)
          save
        rescue StandardError => persistence_error
          raise unless failure
          warn "Could not persist design state: #{persistence_error.message}"
          raise failure
        end
        def verify_inputs!
          @state.fetch("inputs").each do |file, digest|
            target = path(file)
            unless File.file?(target) && !File.symlink?(target) && Digest::SHA256.file(target).hexdigest == digest
              raise Error, "Shared input changed: #{file}; create a new session"
            end
          end
        end
        def verify_published!
          @state.fetch("workers").each do |id, worker|
            next unless worker["published_sha256"]
            unless A.digest(path("variants/#{id}")) == worker["published_sha256"]
              raise Error, "Published variant #{id} changed outside the runner; create a new session"
            end
          end
        end
        def workspace(id)
          directory = path("work/#{id}/#{SecureRandom.hex(8)}")
          FileUtils.mkdir_p(directory)
          %w[brief.md context.md design.md fixtures.json].each do |name|
            FileUtils.cp(path(name), File.join(directory, name)) if File.file?(path(name))
          end
          %w[source skills].each do |name|
            FileUtils.cp_r(path(name), File.join(directory, name)) if File.directory?(path(name))
          end
          FileUtils.cp(path("source-analysis.md"), directory) if File.file?(path("source-analysis.md"))
          directory
        end
        def invoke(directory, prompt, model:, execution_preset: nil, system: Molecules::DesignPrompts::SYSTEM)
          same_project = begin
            File.realpath(Dir.pwd) == File.realpath(@state.fetch("project_root"))
          rescue SystemCallError
            false
          end
          unless same_project
            raise Error, "Run model operations from #{@state.fetch('project_root')} to retain the project's ace-llm policies"
          end
          File.write(File.join(directory, "system.md"), system)
          File.write(File.join(directory, "prompt.md"), prompt)
          @executor.validate_model(model, execution_preset: execution_preset)
          result = Thread.handle_interrupt(Interrupt => :immediate) do
            @executor.call(model: model, prompt: prompt, system: system,
              workspace: directory, timeout: @preset.fetch("timeout"), execution_preset: execution_preset)
          end
          A.json(File.join(directory, "result.json"), result)
          unless result.dig("execution", "status") == "succeeded"
            raise Error, "Coding agent did not complete successfully; see #{directory}/result.json"
          end
          result
        end
        def check_copies(directory, names)
          names += @state.fetch("inputs").keys.select { |name| name.start_with?("source/", "skills/") || name == "source-analysis.md" }
          names.each do |name|
            target = File.join(directory, name)
            unless File.file?(target) && !File.symlink?(target) && File.binread(target) == File.binread(path(name))
              raise Error, "Worker modified shared input #{name}"
            end
          end
        end
        def prepare
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          directory = workspace("preparation")
          attempt = {"status" => "running", "workspace" => directory, "requested_model" => @preset.fetch("preparation_model")}
          @state["preparation_attempts"] ||= []
          @state["preparation_attempts"] << attempt
          @state["preparation"] = attempt
          @state["status"] = "running"
          save
          prompt = Molecules::DesignPrompts.preparation(@metadata, @preset, supplied: @state["supplied_fixtures"])
          A.write(path("prompts/preparation.md"), prompt)
          result = invoke(directory, prompt, model: @preset.fetch("preparation_model"))
          attempt.merge!(evidence(result))
          check_copies(directory, %w[brief.md context.md design.md] + (@state["supplied_fixtures"] ? ["fixtures.json"] : []))
          fixture = File.join(directory, "fixtures.json")
          directions_path = File.join(directory, "directions.json")
          [fixture, directions_path].each { |f| raise Error, "Preparation output missing or symlink: #{f}" unless File.file?(f) && !File.symlink?(f) }
          A.object(fixture)
          directions = A.object(directions_path)
          ids = @metadata.fetch("variants")
          unless directions.keys.sort == ids.sort && directions.values.all? { |v| v.is_a?(String) && !v.strip.empty? }
            raise Error, "directions.json must map every declared variant ID to a nonempty brief"
          end
          if @metadata["source"]
            analysis = File.join(directory, "source-analysis.md")
            raise Error, "Preparation must write source-analysis.md" unless File.file?(analysis) && !File.symlink?(analysis) && !File.read(analysis).strip.empty?
            A.write(path("source-analysis.md"), File.binread(analysis))
            @state["inputs"]["source-analysis.md"] = Digest::SHA256.file(analysis).hexdigest
          end
          verify_inputs!
          A.write(path("fixtures.json"), File.binread(fixture)) unless @state["supplied_fixtures"]
          A.json(path("directions.json"), directions)
          %w[fixtures.json directions.json].each { |f| @state["inputs"][f] = Digest::SHA256.file(path(f)).hexdigest }
          attempt["status"] = "succeeded"
          @preset.fetch("variants").each do |slot|
            File.write(path("prompts/#{slot.fetch('id')}.md"), Molecules::DesignPrompts.variant(@metadata, slot, direction: directions.fetch(slot.fetch("id"))))
          end
        rescue StandardError => e
          failure = e
          raise unless attempt
          attempt.merge!("status" => "failed", "error" => e.message)
        rescue Interrupt => error
          failure = error
          attempt["status"] = "interrupted" if attempt
          raise
        ensure
          if attempt && started
            attempt["duration"] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3)
            save_preserving_failure(failure)
          end
        end
        def execute_slots(slots)
          failure = nil
          threads = []
          begin
            @state["status"] = "running"
            save
            queue = Queue.new
            slots.each { |slot| queue << slot }
            [@preset.fetch("concurrency"), slots.size].min.times do
              threads << Thread.new do
                Thread.current.report_on_exception = false
                loop do
                  slot = begin
                    queue.pop(true)
                  rescue ThreadError
                    break
                  end
                  execute_slot(slot)
                end
              end
            end
            Thread.handle_interrupt(Interrupt => :immediate) { threads.each(&:value) }
          rescue Interrupt, StandardError => error
            failure = error
          ensure
            # Interrupt the provider capture boundary, which owns descendant cleanup.
            threads.each { |t| t.raise(Interrupt) if t.alive? }
            threads.each do |thread|
              begin
                thread.join
              rescue Interrupt, StandardError => error
                # Join every sibling even if recording a failure also failed.
                failure ||= error
              end
            end
          end
          raise failure if failure
        end
        def execute_slot(slot, feedback: nil)
          # Cancellation is delivered at the provider boundary. File publication
          # and its journal must finish atomically with respect to Ruby interrupts.
          Thread.handle_interrupt(Interrupt => :never) { execute_slot_work(slot, feedback: feedback) }
        end
        def execute_slot_work(slot, feedback: nil)
          id = slot.fetch("id")
          worker = @state.fetch("workers").fetch(id)
          # A failed/interrupted revision is resumed with the same feedback, not a fresh generation.
          feedback ||= worker["pending_feedback"]
          directory = workspace(id)
          output = File.join(directory, "variants", id)
          FileUtils.mkdir_p(File.dirname(output))
          FileUtils.cp_r(path("variants/#{id}"), output) if feedback
          FileUtils.mkdir_p(output)
          directions = A.object(path("directions.json"))
          prompt = Molecules::DesignPrompts.variant(@metadata, slot, direction: directions.fetch(id), feedback: feedback)
          attempt = {"status" => "running", "workspace" => directory, "requested_model" => slot.fetch("model"),
            "feedback" => feedback, "started_at" => Time.now.utc.iso8601}
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @mutex.synchronize do
            worker["status"] = "running"
            worker["pending_feedback"] = feedback
            worker.fetch("attempts") << attempt
            save
          end
          warn "#{id}: generating with #{slot.fetch('model')}"
          result = invoke(directory, prompt, model: slot.fetch("model"), execution_preset: slot["execution_preset"],
            system: slot.fetch("process", "ace") == "ace" ? Molecules::DesignPrompts::SYSTEM : Molecules::DesignPrompts::EXTERNAL_SYSTEM)
          @mutex.synchronize { attempt.merge!(evidence(result)); save }
          check_copies(directory, %w[brief.md context.md design.md fixtures.json])
          digest = A.validate_variant(output, types: slot.fetch("artifact_types", ["html"]), shared_reference: slot.fetch("process", "ace") == "ace")
          @mutex.synchronize do
            verify_inputs!
            publish(id, output, digest)
            worker.merge!("status" => "succeeded", "published_sha256" => digest)
            worker.delete("pending_feedback")
            attempt.merge!(evidence(result)).merge!("status" => "succeeded")
            if feedback
              File.open(path("feedback.md"), "a") do |file|
                file.puts "\n## #{Time.now.utc.iso8601} — #{id}\n\n#{feedback}\n\nPublished: #{digest}\nAttempt: #{directory}\n"
              end
            end
            save
            @state.delete("publication")
            save
            Molecules::Session.new(@root).write_gallery
          end
          warn "#{id}: ready"
        rescue StandardError => e
          failure = e
          warn "#{id}: failed — #{e.message}"
          @mutex.synchronize do
            recover_publication
            worker["status"] = "failed"
            attempt&.merge!("status" => "failed", "error" => e.message)
            save_preserving_failure(e)
          end
        rescue Interrupt => error
          failure = error
          @mutex.synchronize do
            worker["status"] = "interrupted"
            attempt&.merge!("status" => "interrupted")
            save_preserving_failure(error)
          end
          raise
        ensure
          if attempt
            @mutex.synchronize do
              attempt["duration"] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3)
              save_preserving_failure(failure)
            end
          end
        end
        def publish(id, output, digest)
          target = path("variants/#{id}")
          backup = path("history/#{id}/#{SecureRandom.hex(8)}")
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.mkdir_p(File.dirname(backup))
          previous = @state.fetch("workers").fetch(id)["published_sha256"]
          selection = path("selection.json")
          selection_backup = if File.exist?(selection) && A.object(selection)["variant"] == id
            path("history/selections/#{SecureRandom.hex(8)}.json")
          end
          @state["publication"] = {"id" => id, "backup" => backup, "previous" => previous,
            "digest" => digest, "selection_backup" => selection_backup}
          save
          File.rename(target, backup) if File.exist?(target)
          File.rename(output, target)
          if selection_backup
            FileUtils.mkdir_p(File.dirname(selection_backup))
            File.rename(selection, selection_backup)
          end
        end
        def recover_publication
          publication = @state["publication"]
          return unless publication
          id = publication.fetch("id")
          target = path("variants/#{id}")
          worker = @state.fetch("workers").fetch(id)
          # A saved success is committed even if the process stopped before clearing the journal.
          if worker["status"] == "succeeded" && worker["published_sha256"] == publication["digest"] &&
              File.directory?(target) && A.digest(target) == publication["digest"]
            @state.delete("publication")
            save
            return
          end
          if File.directory?(publication.fetch("backup"))
            FileUtils.rm_rf(target)
            File.rename(publication.fetch("backup"), target)
          elsif !publication["previous"]
            FileUtils.rm_rf(target)
          end
          if publication["selection_backup"] && File.file?(publication["selection_backup"])
            File.rename(publication["selection_backup"], path("selection.json"))
          end
          worker["status"] = "interrupted"
          worker["published_sha256"] = publication["previous"]
          @state.delete("publication")
          save
        end
        def evidence(result)
          result.slice("execution", "model", "provider", "usage", "metadata")
        end
        def finish
          @state["status"] = if @state["preparation"]["status"] != "succeeded"
            "failed"
          elsif @state.fetch("workers").values.all? { |w| w["status"] == "succeeded" }
            "succeeded"
          else
            "incomplete"
          end
          save
          Molecules::Session.new(@root).write_gallery if File.file?(path("directions.json"))
          status
        end
      end
    end
  end
end
