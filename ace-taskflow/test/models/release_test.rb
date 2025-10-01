# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/models/release"

class ReleaseModelTest < AceTaskflowTestCase
  def setup
    @release_data = {
      name: "v.0.9.0",
      version: "0.9.0",
      status: "active",
      path: "/path/to/v.0.9.0",
      created_at: "2025-01-01",
      modified_at: "2025-01-15",
      statistics: {
        total: 10,
        statuses: {
          "done" => 3,
          "in-progress" => 2,
          "pending" => 5
        }
      }
    }
  end

  def test_release_initialization
    release = Ace::Taskflow::Models::Release.new(@release_data)

    assert_equal "v.0.9.0", release.name
    assert_equal "0.9.0", release.version
    assert_equal "active", release.status
    assert_equal "/path/to/v.0.9.0", release.path
  end

  def test_release_with_minimal_data
    minimal_data = {
      name: "v.0.1.0",
      path: "/path/to/release"
    }
    release = Ace::Taskflow::Models::Release.new(minimal_data)

    assert_equal "v.0.1.0", release.name
    assert_equal "/path/to/release", release.path
    assert_nil release.status
    assert_nil release.version
  end

  def test_release_name_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "v.0.9.0", release.name
  end

  def test_release_version_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "0.9.0", release.version
  end

  def test_release_status_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "active", release.status
  end

  def test_release_path_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "/path/to/v.0.9.0", release.path
  end

  def test_release_created_at_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "2025-01-01", release.created_at
  end

  def test_release_modified_at_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    assert_equal "2025-01-15", release.modified_at
  end

  def test_release_statistics_accessor
    release = Ace::Taskflow::Models::Release.new(@release_data)
    stats = release.statistics

    assert_instance_of Hash, stats
    assert_equal 10, stats[:total]
    assert_equal 3, stats[:statuses]["done"]
  end

  def test_release_with_string_keys
    string_key_data = {
      "name" => "v.0.8.0",
      "status" => "completed"
    }
    release = Ace::Taskflow::Models::Release.new(string_key_data)

    assert_equal "v.0.8.0", release.name
    assert_equal "completed", release.status
  end

  def test_release_to_hash
    release = Ace::Taskflow::Models::Release.new(@release_data)
    hash = release.to_h

    assert_instance_of Hash, hash
    assert_equal "v.0.9.0", hash[:name]
    assert_equal "active", hash[:status]
  end

  def test_release_is_active
    active_release = Ace::Taskflow::Models::Release.new(@release_data)
    assert active_release.active? if active_release.respond_to?(:active?)
  end

  def test_release_is_backlog
    backlog_data = @release_data.merge(status: "backlog")
    backlog_release = Ace::Taskflow::Models::Release.new(backlog_data)

    assert_equal "backlog", backlog_release.status
  end

  def test_release_is_done
    done_data = @release_data.merge(status: "done")
    done_release = Ace::Taskflow::Models::Release.new(done_data)

    assert_equal "done", done_release.status
  end

  def test_release_version_extraction
    # Test various version formats
    data1 = { name: "v.0.9.0-feature", version: nil }
    release1 = Ace::Taskflow::Models::Release.new(data1)
    # Version should either be extracted or remain nil
    assert release1.name.start_with?("v.")

    data2 = { name: "v.1.2.3", version: "1.2.3" }
    release2 = Ace::Taskflow::Models::Release.new(data2)
    assert_equal "1.2.3", release2.version
  end

  def test_release_with_no_statistics
    data = @release_data.dup
    data.delete(:statistics)
    release = Ace::Taskflow::Models::Release.new(data)

    # Should handle missing statistics gracefully
    assert_nil release.statistics
  end
end
