# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/simulation_session_store"
require "yaml"

class SimulationSessionStoreTest < AceTaskflowTestCase
  def test_creates_session_directory_and_writes_artifacts
    with_real_test_project do
      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")
      session_dir = store.create_session_dir!("i50jj3")

      assert Dir.exist?(session_dir), "session directory should exist"

      request_path = store.write_yaml_artifact(session_dir, "request.yml", { "source" => "285.01" })
      summary_path = store.write_markdown_artifact(session_dir, "run-summary.md", "# Run Summary\n")

      assert File.exist?(request_path), "request.yml should be written"
      assert File.exist?(summary_path), "run-summary.md should be written"
      assert_equal "285.01", YAML.safe_load_file(request_path)["source"]
    end
  end

  def test_invalid_run_id_raises
    with_real_test_project do
      store = Ace::Taskflow::Molecules::SimulationSessionStore.new(cache_root: ".cache/ace-taskflow/simulations")

      error = assert_raises(ArgumentError) { store.create_session_dir!("bad-id") }
      assert_includes error.message, "Invalid run_id format"
    end
  end
end
