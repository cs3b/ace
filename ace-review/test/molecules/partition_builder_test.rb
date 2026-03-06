# frozen_string_literal: true

require "test_helper"

class PartitionBuilderTest < AceReviewTest
  def test_no_strategy_returns_single_partition
    files = ["lib/foo.rb", "test/bar_test.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: nil
    )
    assert_equal 1, partitions.size
    assert_equal "partition-all", partitions.first.id
    assert_equal "none", partitions.first.strategy
    assert_equal files.size, partitions.first.files.size
  end

  def test_empty_strategy_returns_single_partition
    files = ["lib/foo.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: ""
    )
    assert_equal 1, partitions.size
    assert_equal "partition-all", partitions.first.id
  end

  def test_glob_based_partition_groups_files
    create_partition_definition("two-groups", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
          - "test/**/*.rb"
        docs:
          - "docs/**/*.md"
    YAML

    files = ["lib/foo.rb", "test/bar_test.rb", "docs/guide.md"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "two-groups", project_root: @test_dir
    )

    assert_equal 2, partitions.size
    code_partition = partitions.find { |p| p.metadata["group"] == "code" }
    docs_partition = partitions.find { |p| p.metadata["group"] == "docs" }
    assert_equal ["lib/foo.rb", "test/bar_test.rb"], code_partition.files
    assert_equal ["docs/guide.md"], docs_partition.files
  end

  def test_first_matching_group_wins
    create_partition_definition("overlap", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
        all-ruby:
          - "**/*.rb"
    YAML

    files = ["lib/foo.rb", "app/bar.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "overlap", project_root: @test_dir
    )

    code_partition = partitions.find { |p| p.metadata["group"] == "code" }
    ruby_partition = partitions.find { |p| p.metadata["group"] == "all-ruby" }
    assert_equal ["lib/foo.rb"], code_partition.files
    assert_equal ["app/bar.rb"], ruby_partition.files
  end

  def test_catch_all_collects_unmatched_files
    create_partition_definition("with-catch-all", <<~YAML)
      catch_all: true
      groups:
        code:
          - "lib/**/*.rb"
    YAML

    files = ["lib/foo.rb", "README.md", "Gemfile"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "with-catch-all", project_root: @test_dir
    )

    assert_equal 2, partitions.size
    other_partition = partitions.find { |p| p.metadata["group"] == "other" }
    assert other_partition
    assert_equal ["Gemfile", "README.md"], other_partition.files
    assert_equal true, other_partition.metadata["catch_all"]
  end

  def test_no_catch_all_excludes_unmatched_files
    create_partition_definition("no-catch-all", <<~YAML)
      catch_all: false
      groups:
        code:
          - "lib/**/*.rb"
    YAML

    files = ["lib/foo.rb", "README.md"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "no-catch-all", project_root: @test_dir
    )

    assert_equal 1, partitions.size
    assert_equal "code", partitions.first.metadata["group"]
  end

  def test_empty_groups_skipped
    create_partition_definition("sparse", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
        docs:
          - "docs/**/*.md"
    YAML

    files = ["lib/foo.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "sparse", project_root: @test_dir
    )

    assert_equal 1, partitions.size
    assert_equal "code", partitions.first.metadata["group"]
  end

  def test_raises_for_unknown_partition
    error = assert_raises(ArgumentError) do
      Ace::Review::Molecules::PartitionBuilder.build(
        subject_files: ["lib/foo.rb"], strategy: "nonexistent", project_root: @test_dir
      )
    end
    assert_includes error.message, "nonexistent"
  end

  def test_handles_empty_file_list
    create_partition_definition("empty-test", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
    YAML

    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: [], strategy: "empty-test", project_root: @test_dir
    )
    assert_equal 0, partitions.size
  end

  def test_partition_attributes
    create_partition_definition("attrs", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
    YAML

    files = ["lib/foo.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "attrs", project_root: @test_dir
    )

    p = partitions.first
    assert_respond_to p, :id
    assert_respond_to p, :label
    assert_respond_to p, :files
    assert_respond_to p, :strategy
    assert_respond_to p, :metadata
    assert_equal "attrs", p.strategy
    assert_equal "partition-code", p.id
    assert_equal "code", p.label
  end

  def test_files_are_sorted_within_partitions
    create_partition_definition("sorted", <<~YAML)
      groups:
        code:
          - "lib/**/*.rb"
    YAML

    files = ["lib/z.rb", "lib/a.rb", "lib/m.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "sorted", project_root: @test_dir
    )

    assert_equal ["lib/a.rb", "lib/m.rb", "lib/z.rb"], partitions.first.files
  end

  def test_dotmatch_flag_matches_dotfiles
    create_partition_definition("dotfiles", <<~YAML)
      groups:
        config:
          - ".ace/**/*.yml"
    YAML

    files = [".ace/review/config.yml", "lib/foo.rb"]
    partitions = Ace::Review::Molecules::PartitionBuilder.build(
      subject_files: files, strategy: "dotfiles", project_root: @test_dir
    )

    assert_equal 1, partitions.size
    assert_equal [".ace/review/config.yml"], partitions.first.files
  end

  private

  def create_partition_definition(name, content)
    dir = File.join(@test_dir, ".ace/review/partitions")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{name}.yml"), content)
  end
end
