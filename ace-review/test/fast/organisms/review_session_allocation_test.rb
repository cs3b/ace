# frozen_string_literal: true

require "test_helper"

class ReviewSessionAllocationTest < AceReviewTest
  def setup
    super
    @manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
    @options = Ace::Review::Models::ReviewOptions.new
  end

  def test_existing_automatic_candidate_is_immutable
    cache = @manager.send(:create_cache_directory)
    fixed = Time.utc(2026, 10, 6)
    existing = File.join(cache, "review-#{Ace::B36ts.encode(fixed)}")
    Dir.mkdir(existing)
    File.write(File.join(existing, "review.md"), "historical sentinel")
    Time.stub(:now, fixed) do
      session = @manager.send(:create_session_directory, @options, cache)
      refute_equal existing, session
      assert_equal [".review-session-claim"], Dir.children(session)
    end
    assert_equal "historical sentinel", File.read(File.join(existing, "review.md"))
  end

  def test_explicit_contender_can_never_share_an_automatic_session
    cache = @manager.send(:create_cache_directory)
    contender = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
    original = @manager.method(:claim_session_directory)
    intercepted = false
    claimed = nil
    @manager.stub(:claim_session_directory, ->(path) {
      unless intercepted
        intercepted = true
        options = Ace::Review::Models::ReviewOptions.new(session_dir: path)
        claimed = contender.send(:create_session_directory, options, nil)
        File.write(File.join(claimed, "review.md"), "explicit winner")
      end
      original.call(path)
    }) do
      automatic = @manager.send(:create_session_directory, @options, cache)
      refute_equal claimed, automatic
      assert File.file?(File.join(automatic, ".review-session-claim"))
    end
    assert_equal "explicit winner", File.read(File.join(claimed, "review.md"))
  end

  def test_explicit_directory_claim_is_permanent
    path = File.join(@test_dir, "empty")
    Dir.mkdir(path)
    options = Ace::Review::Models::ReviewOptions.new(session_dir: path)
    assert_equal path, @manager.send(:create_session_directory, options, nil)
    claim = File.binread(File.join(path, ".review-session-claim"))
    assert_raises(ArgumentError) { @manager.send(:create_session_directory, options, nil) }
    assert_equal claim, File.binread(File.join(path, ".review-session-claim"))
  end

  def test_invalid_explicit_paths_preserve_existing_contents
    target = File.join(@test_dir, "historical")
    Dir.mkdir(target)
    sentinel = File.join(target, "review.md")
    File.write(sentinel, "prior review")
    symlink = File.join(@test_dir, "link")
    File.symlink(target, symlink)
    [target, sentinel, symlink].each do |path|
      options = Ace::Review::Models::ReviewOptions.new(session_dir: path)
      assert_raises(ArgumentError) { @manager.send(:create_session_directory, options, nil) }
    end
    assert_equal ["review.md"], Dir.children(target)
    assert_equal "prior review", File.read(sentinel)
  end

  def test_allocation_errors_stop_before_extracting_content_or_executing_model
    @manager.stub(:prepare_review_config, {success: true, config: {}}) do
      @manager.stub(:create_cache_directory, -> { raise Errno::EACCES, "/blocked/sessions" }) do
        @manager.stub(:extract_review_content, ->(*) { flunk "Content extraction must not run" }) do
          result = @manager.execute_review(@options)
          refute result[:success]
          assert_includes result[:error], "/blocked/sessions"
          assert_includes result[:error], "fresh writable session"
        end
      end
    end
  end

  def test_explicit_refusal_stops_before_content_or_model
    path = File.join(@test_dir, "occupied")
    Dir.mkdir(path)
    File.write(File.join(path, "review.md"), "untouched")
    options = Ace::Review::Models::ReviewOptions.new(session_dir: path, auto_execute: true)
    @manager.stub(:prepare_review_config, {success: true, config: {}}) do
      @manager.stub(:extract_review_content, ->(*) { flunk "Content extraction must not run" }) do
        result = @manager.execute_review(options)
        refute result[:success]
        assert_includes result[:error], path
      end
    end
    assert_equal ["review.md"], Dir.children(path)
    assert_equal "untouched", File.read(File.join(path, "review.md"))
  end

  def test_failed_release_copy_never_publishes_a_partial_report
    release = File.join(@test_dir, "release")
    @manager.instance_variable_set(:@preset_manager, Struct.new(:review_base_path).new(release))
    session = File.join(@test_dir, "source")
    Dir.mkdir(session)
    File.write(File.join(session, "review.md"), "complete source")
    failing_copy = ->(_input, output) { output.write("partial"); raise IOError, "interrupted copy" }
    IO.stub(:copy_stream, failing_copy) do
      assert_raises(IOError) { @manager.send(:copy_to_release, session, {model: "test"}) }
    end
    assert_empty Dir.children(release)
    assert_equal "complete source", File.read(File.join(session, "review.md"))
  end

  def test_equal_clock_release_exports_never_replace_existing_report
    release = File.join(@test_dir, "release")
    preset = Struct.new(:review_base_path).new(release)
    @manager.instance_variable_set(:@preset_manager, preset)
    fixed = Time.utc(2026, 10, 6)
    Dir.mkdir(release)
    original = File.join(release, "review-report-test-#{Ace::B36ts.encode(fixed)}.md")
    File.write(original, "history")
    paths = Time.stub(:now, fixed) do
      %w[first second].map do |name|
        session = File.join(@test_dir, name)
        Dir.mkdir(session)
        File.write(File.join(session, "review.md"), name)
        @manager.send(:copy_to_release, session, {model: "test"})
      end
    end
    assert_equal 2, paths.uniq.length
    assert_equal %w[first second], paths.map { |path| File.read(path) }
    assert_equal "history", File.read(original)
  end
end
