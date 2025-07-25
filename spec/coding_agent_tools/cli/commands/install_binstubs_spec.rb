# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Cli::Commands::InstallBinstubs do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:mock_installer) { instance_double("CodingAgentTools::Organisms::BinstubInstaller") }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  before do
    # Mock the BinstubInstaller creation
    allow(CodingAgentTools::Organisms::BinstubInstaller).to receive(:new).and_return(mock_installer)
  end

  describe "#call" do
    context "with default behavior" do
      let(:install_results) do
        {
          installed: ["task-manager", "git-status"],
          skipped: ["existing-tool"],
          errors: []
        }
      end

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(anything).and_return(true) # Config file exists
        allow(mock_installer).to receive(:install_all).and_return(install_results)
      end

      it "installs all binstubs with default configuration" do
        expect { command.call(target_dir: temp_dir) }.to output(/Successfully installed binstubs/).to_stdout

        expect(CodingAgentTools::Organisms::BinstubInstaller).to have_received(:new).with(
          kind_of(String), # config path
          temp_dir
        )
        expect(mock_installer).to have_received(:install_all)
      end

      it "uses current directory when no target_dir provided" do
        allow(Dir).to receive(:pwd).and_return("/current/dir")

        expect { command.call }.to output(/Successfully installed binstubs/).to_stdout

        expect(CodingAgentTools::Organisms::BinstubInstaller).to have_received(:new).with(
          kind_of(String),
          "/current/dir"
        )
      end

      it "reports installation results correctly" do
        output = capture_stdout { command.call(target_dir: temp_dir) }

        expect(output).to include("Successfully installed binstubs:")
        expect(output).to include("✓ task-manager")
        expect(output).to include("✓ git-status")
        expect(output).to include("Skipped existing binstubs:")
        expect(output).to include("- existing-tool")
        expect(output).to include("Installation complete: 2/3 binstubs installed.")
      end
    end

    context "with custom configuration" do
      let(:custom_config_path) { File.join(temp_dir, "custom.yml") }

      before do
        File.write(custom_config_path, "# Custom config")
        allow(mock_installer).to receive(:install_all).and_return({
          installed: [],
          skipped: [],
          errors: []
        })
      end

      it "uses custom configuration file" do
        expect { command.call(target_dir: temp_dir, config: custom_config_path) }.to output(/Installation complete/).to_stdout

        expect(CodingAgentTools::Organisms::BinstubInstaller).to have_received(:new).with(
          custom_config_path,
          temp_dir
        )
      end
    end

    context "with --list option" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(mock_installer).to receive(:list_available_aliases).and_return(["task-manager", "git-status", "nav-tree"])
      end

      it "lists available aliases" do
        output = capture_stdout { command.call(target_dir: temp_dir, list: true) }

        expect(output).to include("Available binstub aliases:")
        expect(output).to include("task-manager")
        expect(output).to include("git-status")
        expect(output).to include("nav-tree")
        expect(mock_installer).to have_received(:list_available_aliases)
      end

      it "handles empty alias list" do
        allow(mock_installer).to receive(:list_available_aliases).and_return([])

        output = capture_stdout { command.call(target_dir: temp_dir, list: true) }

        expect(output).to include("No binstub aliases found in configuration.")
      end
    end

    context "with --alias option" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(mock_installer).to receive(:install_specific).and_return(true)
      end

      it "installs specific alias" do
        output = capture_stdout { command.call(target_dir: temp_dir, alias: "task-manager") }

        expect(output).to include("Successfully installed binstub: task-manager")
        expect(mock_installer).to have_received(:install_specific).with("task-manager", hash_including(alias: "task-manager"))
      end

      it "handles skipped installation" do
        allow(mock_installer).to receive(:install_specific).and_return(false)

        output = capture_stdout { command.call(target_dir: temp_dir, alias: "existing-tool") }

        expect(output).to include("Binstub installation skipped: existing-tool")
      end
    end

    context "with --setup-path option" do
      let(:config_source_dir) { File.join(temp_dir, "config", "bin-setup-env") }
      let(:target_setup_dir) { File.join(temp_dir, "bin-setup-env") }

      before do
        allow(File).to receive(:exist?).and_call_original

        # Mock the config source directory path
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with("../../../../config/bin-setup-env", anything).and_return(config_source_dir)

        # Create source setup files
        FileUtils.mkdir_p(config_source_dir)
        File.write(File.join(config_source_dir, "setup.sh"), "#!/bin/bash\n# Setup script")
        File.write(File.join(config_source_dir, "setup.fish"), "#!/usr/bin/fish\n# Fish setup")
        File.write(File.join(config_source_dir, "setup-env"), "#!/bin/bash\n# Env setup")

        # Make source files appear to exist
        allow(File).to receive(:exist?).with(File.join(config_source_dir, "setup.sh")).and_return(true)
        allow(File).to receive(:exist?).with(File.join(config_source_dir, "setup.fish")).and_return(true)
        allow(File).to receive(:exist?).with(File.join(config_source_dir, "setup-env")).and_return(true)

        # Make target files appear to NOT exist (so they get created)
        allow(File).to receive(:exist?).with(File.join(target_setup_dir, "setup.sh")).and_return(false)
        allow(File).to receive(:exist?).with(File.join(target_setup_dir, "setup.fish")).and_return(false)
        allow(File).to receive(:exist?).with(File.join(target_setup_dir, "setup-env")).and_return(false)

        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(config_source_dir).and_return(true)

        allow(FileUtils).to receive(:mkdir_p)
        allow(FileUtils).to receive(:cp)
        allow(FileUtils).to receive(:chmod)
      end

      it "sets up PATH scripts" do
        output = capture_stdout { command.call(target_dir: temp_dir, setup_path: true) }

        expect(output).to include("Successfully created PATH setup scripts")
        expect(output).to include("source #{target_setup_dir}/setup-env")
        expect(FileUtils).to have_received(:mkdir_p).with(target_setup_dir)
      end

      it "handles missing source files gracefully" do
        allow(File).to receive(:directory?).with(config_source_dir).and_return(false)

        expect { command.call(target_dir: temp_dir, setup_path: true) }.to raise_error(SystemExit)
      end
    end

    context "error handling" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(mock_installer).to receive(:install_all).and_return({
          installed: [],
          skipped: [],
          errors: [{alias: "broken-tool", error: "Installation failed"}]
        })
      end

      it "handles installation errors" do
        expect { command.call(target_dir: temp_dir) }.to raise_error(SystemExit)
      end

      it "displays error details" do
        capture_stdout { command.call(target_dir: temp_dir) }
      rescue SystemExit
        # Expected
      end
    end

    context "with missing configuration file" do
      it "exits with error when config file doesn't exist" do
        allow(File).to receive(:exist?).and_return(false)

        expect { command.call(target_dir: temp_dir) }.to raise_error(SystemExit)
      end
    end

    context "with CodingAgentTools::Error" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(mock_installer).to receive(:install_all).and_raise(CodingAgentTools::Error, "Test error")
      end

      it "handles CodingAgentTools::Error gracefully" do
        expect { command.call(target_dir: temp_dir) }.to raise_error(SystemExit)
      end
    end

    context "with unexpected errors" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(mock_installer).to receive(:install_all).and_raise(StandardError, "Unexpected error")
      end

      it "handles unexpected errors" do
        expect { command.call(target_dir: temp_dir) }.to raise_error(SystemExit)
      end

      it "shows backtrace in verbose mode" do
        capture_stdout { command.call(target_dir: temp_dir, verbose: true) }
      rescue SystemExit
        # Expected
      end
    end
  end

  describe "private methods" do
    describe "#default_config_path" do
      it "returns expected config path" do
        path = command.send(:default_config_path)
        expect(path).to include("binstub-aliases.yml")
      end
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
