# frozen_string_literal: true

require "test_helper"
require "timeout"
require "open3"
require "rbconfig"

class ReviewSessionConcurrencyTest < AceReviewTest
  FIXED_TIME = Time.utc(2026, 10, 6)

  def setup
    super
    [["init", "-b", "main"], ["config", "user.name", "test"],
      ["config", "user.email", "test@example.com"]].each do |args|
      _out, err, status = Open3.capture3("git", *args, chdir: @test_dir)
      assert status.success?, err
    end
    File.write(File.join(@test_dir, "subject.rb"), "puts :subject\n")
    [["add", "subject.rb"], ["commit", "-m", "fixture"]].each do |args|
      _out, err, status = Open3.capture3("git", *args, chdir: @test_dir)
      assert status.success?, err
    end
    @head, = Open3.capture3("git", "rev-parse", "HEAD", chdir: @test_dir)
    @head = @head.strip
  end

  # Expensive input/provider boundaries are controlled; allocation, execution
  # orchestration, prompt/metadata persistence and publication remain real.
  class PreparedManager < Ace::Review::Organisms::ReviewManager
    private

    def prepare_review_config(_options)
      {success: true, config: {models: ["google:gemini-2.5-flash"]}}
    end

    def extract_review_content(_config, options)
      {success: true, subject: options.subject, context: nil}
    end

    def compose_review_prompt(_config, subject, session_dir, *_args)
      system = "Review the exact supplied subject"
      user = "Subject: #{subject}"
      File.write(File.join(session_dir, "system.prompt.md"), system)
      File.write(File.join(session_dir, "user.prompt.md"), user)
      {success: true, system_prompt: system, user_prompt: user}
    end
  end

  def test_concurrent_fixed_clock_preparations_keep_prompt_and_metadata_identity
    names = ["first sentinel", "second distinct sentinel"]
    results = race(names) do |name|
      PreparedManager.new(project_root: @test_dir).execute_review(subject: name, auto_execute: false)
    end
    assert results.all? { |result| result[:success] }, results.inspect
    paths = results.map { |result| result[:session_dir] }
    assert_equal 2, paths.uniq.length
    paths.zip(names).each do |path, name|
      assert_equal "Subject: #{name}", File.read(File.join(path, "user.prompt.md"))
      metadata = YAML.safe_load_file(File.join(path, "metadata.yml"), permitted_classes: [Time, Date, Symbol])
      assert_equal name.length, metadata["subject_size"]
      assert_equal @head, metadata["checkout_sha"]
      assert_equal FIXED_TIME.iso8601(6), metadata["timestamp"]
    end
  end

  def test_process_race_for_existing_empty_explicit_directory_has_one_owner
    path = File.join(@test_dir, "explicit")
    Dir.mkdir(path)
    results = race(%w[first second]) do |name|
      PreparedManager.new(project_root: @test_dir).execute_review(subject: name, session_dir: path)
    end
    assert_equal 1, results.count { |result| result[:success] }
    winner = results.index { |result| result[:success] }
    assert_equal "Subject: #{%w[first second][winner]}", File.read(File.join(path, "user.prompt.md"))
    assert File.file?(File.join(path, ".review-session-claim"))
    assert_includes results[1 - winner][:error], path
  end

  def test_interrupted_explicit_owner_cannot_be_reclaimed
    path = File.join(@test_dir, "interrupted")
    ready_read, ready_write = IO.pipe
    pid = fork do
      ready_read.close
      manager = PreparedManager.new(project_root: @test_dir)
      manager.send(:create_session_directory, Ace::Review::Models::ReviewOptions.new(session_dir: path), nil)
      ready_write.write("claimed\n")
      ready_write.flush
      Process.kill("STOP", Process.pid)
    end
    ready_write.close
    assert_equal "claimed\n", Timeout.timeout(10) { ready_read.gets }
    Process.kill("KILL", pid)
    Process.wait(pid)
    pid = nil
    claim = File.binread(File.join(path, ".review-session-claim"))
    result = PreparedManager.new(project_root: @test_dir).execute_review(subject: "later", session_dir: path)
    refute result[:success]
    assert_equal [".review-session-claim"], Dir.children(path)
    assert_equal claim, File.binread(File.join(path, ".review-session-claim"))
  ensure
    Process.kill("KILL", pid) if pid
    Process.wait(pid) if pid
    ready_read&.close
    ready_write&.close unless ready_write&.closed?
  end

  class ControlledExecutor
    def initialize(ready, gates)
      @ready, @gates = ready, gates
    end

    def execute(user_prompt:, session_dir:, **_options)
      name = user_prompt.delete_prefix("Subject: ")
      @ready << name
      @gates.fetch(name).pop
      report = File.join(session_dir, "review.md")
      File.write(report, "#{name} finding")
      {success: true, output_file: report, response: "#{name} finding"}
    end
  end

  class ReportSynthesizer
    def synthesize(report_paths:, **_options)
      title = File.read(report_paths.fetch(0))
      item = Ace::Review::Models::FeedbackItem.new(id: title.split.first, title: title,
        files: ["subject.rb:1"], reviewer: "google:gemini-2.5-flash", status: "draft",
        priority: "medium", finding: title, created: FIXED_TIME.iso8601, updated: FIXED_TIME.iso8601)
      {success: true, items: [item], metadata: {}}
    end
  end

  def test_concurrent_model_outputs_and_feedback_remain_attributable_in_both_orders
    [%w[first second], %w[second first]].each_with_index do |order, n|
      root = File.join(@test_dir, "order-#{n}")
      Dir.mkdir(root)
      managers = %w[first second].to_h do |name|
        manager = PreparedManager.new(project_root: root)
        manager.instance_variable_set(:@preset_manager, Struct.new(:review_base_path).new(File.join(root, "release")))
        [name, manager]
      end
      ready, finished = Queue.new, Queue.new
      gates = %w[first second].to_h { |name| [name, Queue.new] }
      executor = ControlledExecutor.new(ready, gates)
      feedback = Ace::Review::Organisms::FeedbackManager.new(synthesizer: ReportSynthesizer.new)
      results = {}
      threads = []
      Time.stub(:now, FIXED_TIME) do
        Ace::Review::Molecules::LlmExecutor.stub(:new, executor) do
          Ace::Review::Organisms::FeedbackManager.stub(:new, feedback) do
            threads = managers.map do |name, manager|
              Thread.new do
                results[name] = manager.execute_review(subject: name, auto_execute: true)
                finished << name
              end
            end
            2.times { Timeout.timeout(10) { ready.pop } }
            order.each do |name|
              gates.fetch(name) << true
              assert_equal name, Timeout.timeout(10) { finished.pop }
            end
            threads.each(&:value)
          end
        end
      end
      assert results.values.all? { |result| result[:success] }, results.inspect
      assert_equal 2, results.values.map { |result| result[:session_dir] }.uniq.length
      assert_equal 2, results.values.map { |result| result[:output_file] }.uniq.length
      results.each do |name, result|
        path = result[:session_dir]
        assert_equal "#{name} finding", File.read(File.join(path, "review.md"))
        assert_equal "#{name} finding", File.read(result[:output_file])
        metadata = YAML.safe_load_file(File.join(path, "llm_metadata.yml"), permitted_classes: [Time, Date, Symbol])
        assert_equal Digest::SHA256.hexdigest("#{name} finding"), metadata["report_sha256"]
        items = feedback.list(path)
        assert_equal ["#{name} finding"], items.map(&:title)
        output, = capture_io do
          Ace::Review::CLI::Commands::FeedbackSubcommands::List.new.call(session: path, format: "json")
        end
        assert_equal ["#{name} finding"], JSON.parse(output).map { |item| item.fetch("title") }
        assert_equal 1, result[:feedback_count]
        assert result[:feedback_paths].all? { |file| file.start_with?(path + "/") }
      end
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
      threads&.each(&:join)
    end
  end

  def test_exact_path_feedback_creation_consumes_only_that_single_model_report
    paths = Time.stub(:now, FIXED_TIME) do
      %w[first second].map do |name|
        result = PreparedManager.new(project_root: @test_dir).execute_review(subject: name)
        assert result[:success], result.inspect
        File.write(File.join(result[:session_dir], "review.md"), "#{name} finding")
        result[:session_dir]
      end
    end
    feedback = Ace::Review::Organisms::FeedbackManager.new(synthesizer: ReportSynthesizer.new)
    paths.zip(%w[first second]).each do |path, name|
      output, = capture_io do
        Ace::Review::Organisms::FeedbackManager.stub(:new, feedback) do
          Ace::Review::CLI::Commands::FeedbackSubcommands::Create.new.call(session: path)
        end
      end
      assert_includes output, "Created 1 feedback item"
      assert_equal ["#{name} finding"], feedback.list(path).map(&:title)
    end
  end

  def test_cli_occupied_session_refuses_nonzero_and_preserves_history
    path = File.join(@test_dir, "occupied")
    Dir.mkdir(path)
    File.write(File.join(path, "review.md"), "historical")
    create_test_preset("isolated", "instructions:\n  base: prompt://base/system\nsubject: {}\n")
    out, err, status = Open3.capture3(RbConfig.ruby, File.join(REPO_ROOT, "bin/ace-review"),
      "--preset", "isolated", "--subject", "sentinel", "--session-dir", path, "--auto-execute", chdir: @test_dir)
    refute status.success?, out + err
    assert_includes out + err, "Cannot allocate review session"
    assert_equal ["review.md"], Dir.children(path)
    assert_equal "historical", File.read(File.join(path, "review.md"))
  end

  private

  def race(names)
    workers = names.map do |name|
      gate_read, gate_write = IO.pipe
      result_read, result_write = IO.pipe
      pid = fork do
        gate_write.close
        result_read.close
        gate_read.read(1)
        result = Time.stub(:now, FIXED_TIME) { yield name }
        Marshal.dump(result, result_write)
        result_write.close
        exit! 0
      rescue => e
        Marshal.dump({success: false, error: "#{e.class}: #{e.message}"}, result_write)
        exit! 1
      end
      gate_read.close
      result_write.close
      [pid, gate_write, result_read]
    end
    workers.each { |_pid, gate, _result| gate.write("x"); gate.close }
    workers.map do |pid, _gate, result|
      value = Timeout.timeout(10) { Marshal.load(result) }
      result.close
      Process.wait(pid)
      value
    end
  ensure
    workers&.each do |pid, gate, result|
      gate.close unless gate.closed?
      result.close unless result.closed?
      begin
        Process.kill("KILL", pid)
        Process.wait(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
  end
end
