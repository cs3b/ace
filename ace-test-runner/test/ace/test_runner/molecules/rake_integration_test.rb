# frozen_string_literal: true

require "test_helper"
require "ace/test_runner/molecules/rake_integration"
require "tempfile"
require "tmpdir"

class Ace::TestRunner::Molecules::RakeIntegrationTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @rakefile_path = File.join(@temp_dir, "Rakefile")
    @integration = Ace::TestRunner::Molecules::RakeIntegration.new(@rakefile_path)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
  end

  def test_check_status_no_rakefile
    status = @integration.check_status

    refute status[:integrated]
    refute status[:rakefile_exists]
    assert_match /No Rakefile found/, status[:message]
  end

  def test_check_status_with_rakefile_no_integration
    create_basic_rakefile

    status = @integration.check_status

    refute status[:integrated]
    assert status[:rakefile_exists]
    assert_match /not set as default/, status[:message]
  end

  def test_check_status_with_integration
    create_integrated_rakefile

    status = @integration.check_status

    assert status[:integrated]
    assert status[:rakefile_exists]
    assert_match /currently set as default/, status[:message]
  end

  def test_set_default_creates_rakefile_if_missing
    result = @integration.set_default

    assert result[:success]
    assert File.exist?(@rakefile_path)
    assert_match /Successfully set ace-test/, result[:message]
  end

  def test_set_default_with_existing_rakefile
    create_basic_rakefile

    result = @integration.set_default

    assert result[:success]
    assert File.exist?(@rakefile_path)
    assert File.exist?("#{@rakefile_path}.ace-backup")

    content = File.read(@rakefile_path)
    assert_match /ace-test-runner integration/, content
    assert_match /Ace::TestRunner::RakeTask/, content
  end

  def test_set_default_with_existing_test_task
    create_rakefile_with_test_task

    result = @integration.set_default

    assert result[:success]

    content = File.read(@rakefile_path)
    assert_match /ace-test-runner integration/, content
    assert_match /Ace::TestRunner::RakeTask/, content
    # Original test task should be commented out
    assert_match /# Rake::TestTask\.new/, content
  end

  def test_set_default_idempotent
    result1 = @integration.set_default
    assert result1[:success]

    result2 = @integration.set_default
    assert result2[:success]
    assert_match /already set as default/, result2[:message]
  end

  def test_unset_default_with_no_integration
    create_basic_rakefile

    result = @integration.unset_default

    assert result[:success]
    assert_match /not currently set as default/, result[:message]
  end

  def test_unset_default_with_integration_and_backup
    create_basic_rakefile
    original_content = File.read(@rakefile_path)

    @integration.set_default
    result = @integration.unset_default

    assert result[:success]
    assert_match /restored original Rakefile/, result[:message]
    assert_equal original_content, File.read(@rakefile_path)
    refute File.exist?("#{@rakefile_path}.ace-backup")
  end

  def test_unset_default_with_integration_no_backup
    create_integrated_rakefile

    result = @integration.unset_default

    assert result[:success]
    assert_match /removed ace-test configuration/, result[:message]

    content = File.read(@rakefile_path)
    refute_match /ace-test-runner integration/, content
    refute_match /Ace::TestRunner::RakeTask/, content
  end

  def test_integration_config_includes_fallback
    @integration.set_default

    content = File.read(@rakefile_path)
    assert_match /rescue LoadError/, content
    assert_match /Fallback to standard Rake::TestTask/, content
  end

  def test_integration_config_respects_environment_variables
    @integration.set_default

    content = File.read(@rakefile_path)
    assert_match /ENV\["PATTERN"\]/, content
    assert_match /ENV\["VERBOSE"\]/, content
    assert_match /ENV\["FORMAT"\]/, content
  end

  private

  def create_basic_rakefile
    File.write(@rakefile_path, <<~RUBY)
      # frozen_string_literal: true

      require "bundler/gem_tasks"

      task default: :test
    RUBY
  end

  def create_rakefile_with_test_task
    File.write(@rakefile_path, <<~RUBY)
      # frozen_string_literal: true

      require "bundler/gem_tasks"
      require "rake/testtask"

      Rake::TestTask.new(:test) do |t|
        t.libs << "test"
        t.libs << "lib"
        t.test_files = FileList["test/**/*_test.rb"]
        t.verbose = true
      end

      task default: :test
    RUBY
  end

  def create_integrated_rakefile
    File.write(@rakefile_path, <<~RUBY)
      # frozen_string_literal: true

      require "bundler/gem_tasks"

      # ace-test-runner integration
      begin
        require "ace/test_runner/rake_task"

        Ace::TestRunner::RakeTask.new(:test) do |t|
          t.description = "Run tests with ace-test"
        end
      rescue LoadError
        require "rake/testtask"
        Rake::TestTask.new(:test)
      end
      # End of ace-test-runner integration

      task default: :test
    RUBY
  end
end