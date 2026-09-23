# frozen_string_literal: true

require "test_helper"
require "ace/hitl/molecules/lab_request_submitter"

class LabRequestSubmitterTest < AceHitlTestCase
  def recording_runner
    calls = []
    runner = lambda do |argv|
      calls << argv
      ["{\"id\": \"labreq42\", \"requested\": true}", "", class_return_status(0)]
    end
    [calls, runner]
  end

  def class_return_status(code)
    status = Object.new
    status.define_singleton_method(:success?) { code.zero? }
    status.define_singleton_method(:exitstatus) { code }
    status
  end

  def build_submitter(runner)
    Ace::Hitl::Molecules::LabRequestSubmitter.new(
      bin: "/usr/local/bin/lab-hitl",
      runner: runner,
      id_generator: -> { "hitl-deadbeef1234" }
    )
  end

  def base_kwargs
    {
      request_id: "hitl-deadbeef1234",
      work: "W685",
      attempt: "A-a73ebdaeb811210d51e0251e",
      project: "ace",
      harness: "pi",
      plan: "ace-hitl ask",
      question: "Proceed?",
      ace_hitl_id: "abc123"
    }
  end

  def test_generated_request_id_matches_lab_bounds
    submitter = Ace::Hitl::Molecules::LabRequestSubmitter.new
    id = submitter.generate_request_id

    assert_match(/\A[A-Za-z0-9_-]{6,64}\Z/, id)
  end

  def test_exact_argv_without_effect_flags
    calls, runner = recording_runner
    submitter = build_submitter(runner)

    argv = submitter.build_argv(**base_kwargs)
    assert_equal [
      "/usr/local/bin/lab-hitl", "request",
      "--id", "hitl-deadbeef1234",
      "--work", "W685",
      "--attempt", "A-a73ebdaeb811210d51e0251e",
      "--project", "ace",
      "--harness", "pi",
      "--plan", "ace-hitl ask",
      "--question", "Proceed?",
      "--ace-hitl-id", "abc123"
    ], argv

    submitter.submit(argv)
    assert_equal 1, calls.length
    assert_equal argv, calls.first
  end

  def test_exact_argv_effect_passthrough_order_is_stable
    submitter = build_submitter(recording_runner[1])

    argv = submitter.build_argv(
      **base_kwargs,
      match: "\\A[0-9]{6}\\Z",
      effect_args: ["/usr/bin/notify", "{answer}", "extra"],
      effect_cwd: "/tmp",
      effect_timeout: "300"
    )

    assert_equal [
      "/usr/local/bin/lab-hitl", "request",
      "--id", "hitl-deadbeef1234",
      "--work", "W685",
      "--attempt", "A-a73ebdaeb811210d51e0251e",
      "--project", "ace",
      "--harness", "pi",
      "--plan", "ace-hitl ask",
      "--question", "Proceed?",
      "--ace-hitl-id", "abc123",
      "--effect-match", "\\A[0-9]{6}\\Z",
      "--effect-arg", "/usr/bin/notify",
      "--effect-arg", "{answer}",
      "--effect-arg", "extra",
      "--effect-cwd", "/tmp",
      "--effect-timeout-s", "300"
    ], argv
  end

  def test_effect_flags_omitted_when_not_declared
    submitter = build_submitter(recording_runner[1])

    argv = submitter.build_argv(**base_kwargs)

    refute_includes(argv.join(" "), "--effect-match")
    refute_includes(argv.join(" "), "--effect-arg")
    refute_includes(argv.join(" "), "--effect-cwd")
    refute_includes(argv.join(" "), "--effect-timeout-s")
  end

  def test_submit_returns_lab_request_id
    _, runner = recording_runner
    submitter = build_submitter(runner)

    assert_equal "labreq42", submitter.submit(submitter.build_argv(**base_kwargs))
  end

  def test_submit_failure_raises_with_lab_stderr
    runner = lambda do |_argv|
      ["", "lab-hitl: invalid work id", class_return_status(1)]
    end
    submitter = build_submitter(runner)

    error = assert_raises(Ace::Hitl::Molecules::LabRequestSubmitter::SubmissionError) do
      submitter.submit(submitter.build_argv(**base_kwargs))
    end
    assert_match(/invalid work id/, error.message)
  end

  def test_submit_unparseable_output_raises
    runner = lambda do |_argv|
      ["not json", "", class_return_status(0)]
    end
    submitter = build_submitter(runner)

    error = assert_raises(Ace::Hitl::Molecules::LabRequestSubmitter::SubmissionError) do
      submitter.submit(submitter.build_argv(**base_kwargs))
    end
    assert_match(/could not parse lab-hitl request output as JSON/, error.message)
  end

  def test_submit_missing_binary_is_reported_as_execution_failure
    runner = lambda do |_argv|
      raise Errno::ENOENT, "/usr/local/bin/lab-hitl"
    end
    submitter = build_submitter(runner)

    error = assert_raises(Ace::Hitl::Molecules::LabRequestSubmitter::SubmissionError) do
      submitter.submit(submitter.build_argv(**base_kwargs))
    end
    assert_match(%r{could not execute /usr/local/bin/lab-hitl}, error.message)
    assert_match(/Errno::ENOENT/, error.message)
    refute_match(/could not parse/, error.message)
  end

  def test_env_override_selects_binary
    with_env("ACE_HITL_LAB_BIN" => "/opt/fake-lab-hitl") do
      submitter = Ace::Hitl::Molecules::LabRequestSubmitter.new

      argv = submitter.build_argv(**base_kwargs)

      assert_equal "/opt/fake-lab-hitl", argv[0]
    end
  end
end
