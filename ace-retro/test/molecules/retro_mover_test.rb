# frozen_string_literal: true

require "test_helper"

class RetroMoverTest < AceRetroTestCase
  def test_moves_retro_to_archive
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      archive_time = Time.utc(2026, 2, 28, 12, 0, 0)
      mover = Ace::Retro::Molecules::RetroMover.new(root)
      new_path = mover.move(retro, to: "archive", date: archive_time)

      refute Dir.exist?(retro_dir), "Original directory should be gone"
      assert Dir.exist?(new_path), "New directory should exist"
      assert_includes new_path, "_archive"
      rel = new_path.sub(File.join(root, "_archive") + "/", "")
      assert rel.include?("/"), "Expected partition path in #{rel}"
    end
  end

  def test_moves_retro_to_root
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review",
                                       special_folder: "_archive")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w", special_folder: "_archive")

      mover = Ace::Retro::Molecules::RetroMover.new(root)
      new_path = mover.move_to_root(retro)

      assert Dir.exist?(new_path)
      assert_equal root, File.dirname(new_path)
    end
  end

  def test_raises_if_destination_exists
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")
      archive_time = Time.utc(2026, 2, 28, 12, 0, 0)
      partition = Ace::Support::Items::Atoms::DatePartitionPath.compute(archive_time)
      dest = File.join(root, "_archive", partition, "8ppq7w-sprint-review")
      FileUtils.mkdir_p(dest)

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      mover = Ace::Retro::Molecules::RetroMover.new(root)

      assert_raises(ArgumentError) do
        mover.move(retro, to: "archive", date: archive_time)
      end
    end
  end

  def test_move_to_same_location_is_noop
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      mover = Ace::Retro::Molecules::RetroMover.new(root)
      result = mover.move_to_root(retro)

      assert_equal retro.path, result
      assert Dir.exist?(retro_dir), "Original directory should still exist"
    end
  end

  def test_path_traversal_rejected
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      mover = Ace::Retro::Molecules::RetroMover.new(root)

      assert_raises(ArgumentError) do
        mover.move(retro, to: "../../etc")
      end
    end
  end
end
