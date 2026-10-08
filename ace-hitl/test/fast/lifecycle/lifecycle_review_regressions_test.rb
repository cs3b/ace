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

      published = Queue.new
      resume_create = Queue.new
      answer_read = Queue.new
      initialize_projection = creator.method(:initialize_projection_locked!)
      creator.define_singleton_method(:initialize_projection_locked!) do |value|
        published << value
        resume_create.pop
        initialize_projection.call(value)
      end

      # Publication and initial projection share the real lifecycle lock.
      # Pause after publication so the broker can read the request, but must
      # wait until create has initialized its projection before delivery.
      create = Thread.new { creator.create(**request_args(project: "ace")) }
      value = published.pop
      delivery = Thread.new do
        broker.deliver(value.fetch("id"), lambda do |_limit|
          answer_read << true
          "approved"
        end)
      end
      answer_read.pop
      File.open(File.join(root, "locks", "hitl001.lock"), File::RDWR) do |lock|
        refute lock.flock(File::LOCK_EX | File::LOCK_NB), "create holds the request lock through projection"
      end
      refute delivery.join(0), "delivery cannot commit before create releases its lock"
      resume_create << true
      create.value
      delivery.value
      creator.define_singleton_method(:initialize_projection_locked!, initialize_projection)

      # A repeated initialization after completed delivery must retain the
      # same-incarnation projection, rather than overwriting it as created.
      creator.send(:initialize_projection!, value)
      record = JSON.parse(File.read(File.join(root, "public", "hitl001.json")))
      assert_equal "answer-delivered", record["state"]
      assert_equal "ace", record["project"]
      assert_equal value.fetch("incarnation"), record.fetch("incarnation")
    ensure
      resume_create << true if resume_create
      [create, delivery].compact.each do |thread|
        thread.kill if thread.alive?
        thread.join
      end

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
