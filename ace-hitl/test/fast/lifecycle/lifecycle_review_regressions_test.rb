# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"

# Regression tests for the PR#336 review findings (codex astra high,
# session review-8wq2uw): each test asserts the CORRECTED behavior of a
# probe that reproduced the reported defect.
class LifecycleReviewRegressionsTest < AceHitlTestCase
  include LifecycleFixtures

  def unprivileged_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: false)
  end

  def root_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: true)
  end

  def test_concurrent_exclusive_writers_never_lose_records_or_leak_temporaries
    Dir.mktmpdir("atomic-regression") do |folder|
      path = File.join(folder, "record.json")
      25.times do |round|
        results = Array.new(4) do |writer|
          Thread.new do
            Ace::Hitl::Lifecycle::AtomicJson.call(path, {"writer" => "#{round}-#{writer}"},
              mode: 0o600, exclusive: true)
            :committed
          rescue Errno::EEXIST
            :exists
          end
        end.map(&:value)

        assert_equal 1, results.count(:committed), "exactly one writer commits per round"
        assert_equal 3, results.count(:exists)
        assert_equal 1, Dir.children(folder).count { |name| name.end_with?(".json") },
          "no temporary files may survive a round"
        File.delete(path)
      end
    end
  end

  def test_deliver_rejects_a_request_recreated_while_the_answer_was_read
    with_lifecycle_root do |root|
      requester = make_store(root: root)
      broker = make_store(root: root, identity: root_identity)
      requester.create(**request_args)
      reader = lambda do |_limit|
        requester.cancel("hitl001")
        requester.create(**request_args(kind: "otp", otp: otp_context))
        "approved"
      end

      error = assert_raises(Ace::Hitl::Lifecycle::StateError) do
        broker.deliver("hitl001", reader)
      end
      assert_match(/cancelled and recreated/, error.message)
      refute_path_exists File.join(root, "secrets", "hitl001.answer")
    end
  end

  def test_create_never_regresses_a_projection_a_broker_already_delivered
    with_lifecycle_root do |root|
      creator = make_store(root: root)
      broker = make_store(root: root, identity: root_identity)

      # The broker wins the lifecycle lock first and completes a full
      # delivery before the creator's projection initialization runs:
      # the initialization must recognize the current-incarnation
      # projection and leave it untouched.
      creator.define_singleton_method(:with_request_lock) do |request_id, &block|
        broker.deliver(request_id, ->(_limit) { "approved" })
        block.call(request_id)
      end
      creator.create(**request_args)

      record = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "answer-delivered", record["state"]
    end
  end

  def test_timeout_terminates_the_whole_callback_process_group
    Dir.mktmpdir("effect-group-regression") do |folder|
      declaration = {"argv" => [RbConfig.ruby, "-e", 'fork { sleep 2; File.write("marker", "survived") }; sleep 20'],
        "cwd" => folder, "timeout_s" => 1}
      _, timed_out = Ace::Hitl::Lifecycle::Effects.execute(declaration, "answer", Process.uid, Process.gid)
      assert timed_out
      sleep 2.5
      refute_path_exists File.join(folder, "marker")
    end
  end

  def test_answers_are_substituted_literally_into_the_callback_argv
    Dir.mktmpdir("effect-substitution-regression") do |folder|
      declaration = {"argv" => [RbConfig.ruby, "-e", 'File.write("marker", ARGV[0])', "{answer}"], "cwd" => folder,
        "timeout_s" => 2}
      Ace::Hitl::Lifecycle::Effects.execute(declaration, "a\\&b", Process.uid, Process.gid)
      assert_equal "a\\&b", File.read(File.join(folder, "marker"))
    end
  end

  def test_single_element_effect_declaration_never_reaches_a_shell
    Dir.mktmpdir("effect-shell-regression") do |folder|
      declaration = {"argv" => ["printf shell-ran > marker"], "cwd" => folder, "timeout_s" => 2}
      # Forced [cmd, argv0] form: the string is exec'd directly and
      # fails as a missing binary instead of running through a shell.
      assert_raises(Errno::ENOENT) do
        Ace::Hitl::Lifecycle::Effects.execute(declaration, "answer", Process.uid, Process.gid)
      end
      refute_path_exists File.join(folder, "marker")
    end
  end

  def test_multibyte_answer_is_measured_in_decoded_characters
    reader, writer = IO.pipe
    writer.write("é" * 2500)
    writer.close
    with_lifecycle_root do |root|
      store = make_store(root: root)
      answer = store.send(:read_bounded_answer, ->(limit) { reader.read(limit) })
      assert_equal 2500, answer.length
    end
  ensure
    reader&.close
    writer&.close unless writer&.closed?
  end
end
