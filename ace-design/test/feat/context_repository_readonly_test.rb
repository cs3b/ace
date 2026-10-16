# frozen_string_literal: true
require_relative "../test_helper"

class ContextRepositoryReadonlyTest < DesignTest
  Repository = Ace::Design::Molecules::ContextRepository

  def test_first_read_creates_no_lock_or_directories
    Dir.mktmpdir do |project|
      assert_empty Repository.new(project: project).read(readonly: true)
      assert_empty Dir.children(project)
    end
  end

  def test_first_publication_during_unguarded_read_discards_old_snapshot
    Dir.mktmpdir do |project|
      publisher = Repository.new(project: project)
      run = File.join(publisher.runs, "abc123")
      candidate = File.join(run, "candidate")
      FileUtils.mkdir_p(candidate)
      File.write(File.join(candidate, "design.md"), "Published rules")
      reader = Repository.new(project: project)
      reads = 0
      reader.define_singleton_method(:read_unlocked) do
        result = super()
        reads += 1
        publisher.publish(candidate: candidate, original: {}, run: run) if reads == 1
        result
      end
      assert_equal({"design.md" => "Published rules"}, reader.read(readonly: true))
      assert_equal 2, reads
    end
  end

  def test_first_publisher_still_holding_lock_cannot_return_library_fallback
    Dir.mktmpdir do |project|
      reader = Repository.new(project: project)
      lock = nil
      reader.define_singleton_method(:read_unlocked) do
        result = super()
        path = File.join(project, ".ace-local/design/context.lock")
        FileUtils.mkdir_p(File.dirname(path))
        lock = File.open(path, File::RDWR | File::CREAT, 0o600)
        lock.flock(File::LOCK_EX | File::LOCK_NB)
        result
      end
      error = assert_raises(Ace::Design::Error) { reader.read(readonly: true) }
      assert_includes error.message, "being published; retry"
    ensure
      lock&.close
    end
  end

  def test_read_error_during_first_publication_retries_with_the_new_lock
    Dir.mktmpdir do |project|
      reader = Repository.new(project: project)
      reads = 0
      reader.define_singleton_method(:read_unlocked) do
        reads += 1
        if reads == 1
          path = File.join(project, ".ace-local/design/context.lock")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "")
          FileUtils.mkdir_p(root)
          File.write(File.join(root, "design.md"), "Published rules")
          raise Errno::ENOENT, "source moved during publication"
        end
        super()
      end
      assert_equal({"design.md" => "Published rules"}, reader.read(readonly: true))
      assert_equal 2, reads
    end
  end

  def test_unrelated_read_error_is_not_hidden
    Dir.mktmpdir do |project|
      reader = Repository.new(project: project)
      reader.define_singleton_method(:read_unlocked) { raise Errno::EACCES, "unreadable profile" }
      assert_raises(Errno::EACCES) { reader.read(readonly: true) }
      assert_empty Dir.children(project)
    end
  end
end
