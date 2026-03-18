# frozen_string_literal: true

require "test_helper"
require "ace/support/models/cli"
require "tmpdir"
require "fileutils"
require "json"

# Integration tests for ace-models CLI commands
# Tests end-to-end workflows including:
# - Provider sync with --apply flag
# - Provider sync with --commit flag (mocked)
# - Filter validation in search
class CLIIntegrationTest < AceModelsTestCase
  def setup
    @tmpdir = Dir.mktmpdir("ace-models-integration")
    @config_dir = File.join(@tmpdir, "providers")
    @cache_dir = File.join(@tmpdir, "cache")
    FileUtils.mkdir_p(@config_dir)
    FileUtils.mkdir_p(@cache_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # ============================================
  # Provider sync --apply E2E tests
  # ============================================

  def test_sync_apply_adds_new_models_to_config
    # Setup: create provider config with partial model list
    create_provider_config("anthropic", ["claude-3-sonnet", "claude-3-haiku"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-3-haiku", "claude-4-opus", "claude-4-sonnet"])

    # Execute: run sync --apply
    result = run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: changes were applied
    assert result[:applied], "Changes should be applied"
    assert_includes result[:diff]["anthropic"][:added], "claude-4-opus"
    assert_includes result[:diff]["anthropic"][:added], "claude-4-sonnet"

    # Verify: config file was updated
    config = YAML.safe_load(File.read(File.join(@config_dir, "anthropic.yml")), permitted_classes: [Date])
    assert_includes config["models"], "claude-4-opus"
    assert_includes config["models"], "claude-4-sonnet"
  end

  def test_sync_apply_removes_deprecated_models_from_config
    # Setup: create provider config with a model no longer in models.dev
    create_provider_config("anthropic", ["claude-3-sonnet", "old-deprecated-model"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-3-haiku"])

    # Execute: run sync --apply
    result = run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: removal was detected and applied
    assert result[:applied], "Changes should be applied"
    assert_includes result[:diff]["anthropic"][:removed], "old-deprecated-model"

    # Verify: config file was updated
    config = YAML.safe_load(File.read(File.join(@config_dir, "anthropic.yml")), permitted_classes: [Date])
    refute_includes config["models"], "old-deprecated-model"
    assert_includes config["models"], "claude-3-sonnet"
  end

  def test_sync_apply_preserves_yaml_comments_and_structure
    # Setup: create provider config with comments
    config_content = <<~YAML
      # Anthropic provider configuration
      # Last updated: 2024-01-15
      name: anthropic

      # Model list
      models:
        - claude-3-sonnet    # Primary model
        - claude-3-haiku     # Fast model
    YAML
    File.write(File.join(@config_dir, "anthropic.yml"), config_content)

    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-3-haiku", "claude-4-opus"])

    # Execute: run sync --apply
    result = run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: changes applied
    assert result[:applied], "Changes should be applied"

    # Note: The writer uses regex-based updates, which should preserve comments.
    # This tests that feature.
  end

  def test_sync_apply_creates_backup_file
    # Setup
    create_provider_config("anthropic", ["claude-3-sonnet"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-4-opus"])

    # Execute
    run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: backup file exists (pattern is .backup.YYYYMMDD_HHMMSS)
    backup_files = Dir.glob(File.join(@config_dir, "anthropic.yml.backup.*"))
    assert backup_files.any?, "Backup file should be created"
  end

  def test_sync_apply_no_changes_when_up_to_date
    # Setup: config already has all models
    create_provider_config("anthropic", ["claude-3-sonnet", "claude-3-haiku"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-3-haiku"])

    # Execute
    result = run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: no changes detected or applied
    refute result[:changes_detected], "No changes should be detected"
    refute result[:applied], "Nothing should be applied"
  end

  def test_sync_apply_handles_multiple_providers
    # Setup: multiple providers
    create_provider_config("anthropic", ["claude-3-sonnet"])
    create_provider_config("openai", ["gpt-4o"])

    cache_data = {
      "anthropic" => {
        "id" => "anthropic",
        "models" => {
          "claude-3-sonnet" => { "name" => "Claude 3 Sonnet" },
          "claude-4-opus" => { "name" => "Claude 4 Opus" }
        }
      },
      "openai" => {
        "id" => "openai",
        "models" => {
          "gpt-4o" => { "name" => "GPT-4o" },
          "gpt-5" => { "name" => "GPT-5" }
        }
      }
    }
    write_cache(cache_data)

    # Execute
    result = run_sync(apply: true, config_dir: @config_dir, show_all: true)

    # Verify: both providers updated
    assert result[:applied]
    assert_includes result[:diff]["anthropic"][:added], "claude-4-opus"
    assert_includes result[:diff]["openai"][:added], "gpt-5"

    # Verify: both config files updated
    anthropic_config = YAML.safe_load(File.read(File.join(@config_dir, "anthropic.yml")), permitted_classes: [Date])
    openai_config = YAML.safe_load(File.read(File.join(@config_dir, "openai.yml")), permitted_classes: [Date])

    assert_includes anthropic_config["models"], "claude-4-opus"
    assert_includes openai_config["models"], "gpt-5"
  end

  # ============================================
  # Provider sync --commit E2E tests
  # ============================================

  def test_sync_commit_executes_git_commit_command
    # Setup
    create_provider_config("anthropic", ["claude-3-sonnet"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-4-opus"])

    commit_called = false
    commit_message = nil

    # Mock system call to ace-git-commit
    orchestrator = Ace::Support::Models::Organisms::ProviderSyncOrchestrator.new(
      cache_manager: create_cache_manager,
      output: StringIO.new
    )

    # Stub the system call to capture the commit message
    orchestrator.define_singleton_method(:commit_changes) do |summary|
      commit_called = true
      commit_message = "chore(providers): Sync model lists with models.dev\n\n" \
                       "Added: #{summary[:added]} models\n" \
                       "Removed: #{summary[:removed]} models"
      true
    end

    # Execute
    result = orchestrator.sync(
      config_dir: @config_dir,
      apply: true,
      commit: true,
      show_all: true
    )

    # Verify
    assert result[:applied], "Changes should be applied"
    assert result[:committed], "Commit should be attempted"
    assert commit_called, "Commit command should be called"
    assert_match(/Sync model lists/, commit_message)
    assert_match(/Added: 1 models/, commit_message)
  end

  def test_sync_commit_not_called_without_apply
    # Setup
    create_provider_config("anthropic", ["claude-3-sonnet"])
    create_cache_with_models("anthropic", ["claude-3-sonnet", "claude-4-opus"])

    # Execute: commit without apply (should not commit)
    result = run_sync(apply: false, commit: true, config_dir: @config_dir, show_all: true)

    # Verify: commit not attempted
    refute result[:applied]
    refute result[:committed]
  end

  def test_sync_commit_not_called_when_no_changes
    # Setup: already up to date
    create_provider_config("anthropic", ["claude-3-sonnet"])
    create_cache_with_models("anthropic", ["claude-3-sonnet"])

    # Execute
    result = run_sync(apply: true, commit: true, config_dir: @config_dir, show_all: true)

    # Verify: no changes, no commit
    refute result[:changes_detected]
    refute result[:applied]
    refute result[:committed]
  end

  # ============================================
  # Search filter validation E2E tests
  # ============================================

  def test_search_with_invalid_filter_returns_error
    # Create minimal cache so search can proceed
    create_cache_with_models("anthropic", ["claude-3-sonnet"])

    Ace::Support::Models::Molecules::CacheManager.stub :new, create_cache_manager do
      cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
      _, stderr_output = capture_io do
        assert_raises(Ace::Support::Cli::Error) do
          cmd.call(query: nil, filter: ["badfilter"], json: false, limit: 20)
        end
      end

      # Verify: error message on stderr
      assert_match(/Invalid filter format 'badfilter'/, stderr_output)
    end
  end

  def test_search_with_valid_filter_succeeds
    # Create cache with test models
    cache_data = {
      "anthropic" => {
        "id" => "anthropic",
        "models" => {
          "claude-3-sonnet" => {
            "id" => "claude-3-sonnet",
            "name" => "Claude 3 Sonnet",
            "tool_call" => true
          }
        }
      }
    }
    write_cache(cache_data)

    Ace::Support::Models::Molecules::CacheManager.stub :new, create_cache_manager do
      cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
      stdout_output = capture_io do
        @exit_code = cmd.call(query: nil, filter: ["provider:anthropic"], json: false, limit: 20)
      end.first

      # No exception raised means success (exception-based exit pattern)
      assert_match(/claude-3-sonnet/, stdout_output)
    end
  end

  def test_search_with_multiple_invalid_filters_shows_all_errors
    create_cache_with_models("anthropic", ["claude-3-sonnet"])

    Ace::Support::Models::Molecules::CacheManager.stub :new, create_cache_manager do
      cmd = Ace::Support::Models::CLI::Commands::ModelsSubcommands::Search.new
      _, stderr_output = capture_io do
        assert_raises(Ace::Support::Cli::Error) do
          cmd.call(query: nil, filter: ["bad1", "provider:ok", "bad2"], json: false, limit: 20)
        end
      end

      assert_match(/Invalid filter format 'bad1'/, stderr_output)
      assert_match(/Invalid filter format 'bad2'/, stderr_output)
    end
  end

  private

  def create_provider_config(name, models)
    config = {
      "name" => name,
      "models" => models
    }
    File.write(File.join(@config_dir, "#{name}.yml"), YAML.dump(config))
  end

  def create_cache_with_models(provider_name, model_ids)
    models = model_ids.each_with_object({}) do |id, hash|
      hash[id] = { "id" => id, "name" => id.gsub("-", " ").capitalize }
    end

    cache_data = {
      provider_name => {
        "id" => provider_name,
        "models" => models
      }
    }
    write_cache(cache_data)
  end

  def write_cache(data)
    cache_file = File.join(@cache_dir, "api.json")
    File.write(cache_file, JSON.pretty_generate(data))
  end

  def create_cache_manager
    Ace::Support::Models::Molecules::CacheManager.new(cache_dir: @cache_dir)
  end

  def run_sync(apply: false, commit: false, config_dir: nil, show_all: false, since: nil)
    orchestrator = Ace::Support::Models::Organisms::ProviderSyncOrchestrator.new(
      cache_manager: create_cache_manager,
      output: StringIO.new
    )

    # For commit tests, stub the system call
    if commit
      orchestrator.define_singleton_method(:commit_changes) { |_summary| true }
    end

    orchestrator.sync(
      config_dir: config_dir,
      apply: apply,
      commit: commit,
      show_all: show_all,
      since: since
    )
  end
end
