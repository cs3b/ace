# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_installer"

module Ace
  module Lab
    module Auth
      class IssuerInstallerTest < Minitest::Test
        def setup
          @dir = Dir.mktmpdir
          @commands = []
          @installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true },
            runtime_verifier: ->(**) { true },
            activation_verifier: ->(**) { true },
            inactive_verifier: -> { true },
            runner: ->(argv) { @commands << argv; true })
          @runtime = {ruby: "/opt/ace/ruby/bin/ruby", gem_home: "/opt/ace/gems",
                      gem_root: "/opt/ace/gems/gems/ace-lab-0.14.2"}
        end

        def teardown = FileUtils.remove_entry(@dir)

        def test_installs_and_activates_exact_owned_units
          result = @installer.call(**@runtime)
          assert_equal "installed", result.fetch("status")
          assert_equal 3, Dir.children(@dir).size
          assert Dir.children(@dir).all? { |name| File.read(File.join(@dir, name)).start_with?(IssuerUnits::MARKER) }
          assert @commands.any? { |argv| argv.include?("daemon-reload") }
          assert @commands.any? { |argv| argv.include?("enable") && argv.include?("ace-lab-auth.socket") }
          assert @commands.any? { |argv| argv.include?("is-active") && argv.include?("ace-lab-auth-recovery.service") }
        end

        def test_dry_run_writes_nothing_and_executes_no_systemctl
          assert_equal "would_install", @installer.call(**@runtime, dry_run: true).fetch("status")
          assert_empty Dir.children(@dir)
          assert_empty @commands
        end

        def test_foreign_or_changed_unit_blocks_before_any_write
          foreign = File.join(@dir, "ace-lab-auth.socket")
          File.write(foreign, "[Socket]\nListenStream=/foreign\n")
          assert_raises(Error) { @installer.call(**@runtime) }
          assert_equal ["ace-lab-auth.socket"], Dir.children(@dir)
          assert_empty @commands
        end

        def test_verifies_a_template_using_a_control_instance
          runner = lambda do |argv|
            return true unless argv.include?("show")

            name = argv.last
            fragment = name.sub("@ace-verify.service", "@.service")
            "Id=#{name}\nLoadState=loaded\nFragmentPath=#{File.join(@dir, fragment)}\nDropInPaths=\nNeedDaemonReload=no\n"
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true },
            inactive_verifier: -> { true }, runner: runner)
          assert_equal "installed", installer.call(**@runtime).fetch("status")
        end

        def test_runtime_without_installed_specification_is_rejected
          gem_home = File.join(@dir, "gems-home")
          gem_root = File.join(gem_home, "gems", "ace-lab-0.14.2")
          FileUtils.mkdir_p(File.join(gem_root, "libexec"))
          %w[issuer-request issuer-cleanup issuer-recover].each do |name|
            File.write(File.join(gem_root, "libexec", name), "")
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true })
          error = installer.stub(:verify_ruby!, true) do
            assert_raises(Error) do
              installer.send(:verify_runtime!, ruby: RbConfig.ruby, gem_home: gem_home, gem_root: gem_root)
            end
          end
          assert_match(/specification/, error.message)
        end

        def test_runtime_rejects_an_untrusted_file_before_loading_specifications
          gem_home = File.join(@dir, "gems-home")
          gem_root = File.join(gem_home, "gems", "ace-lab-0.14.2")
          FileUtils.mkdir_p(gem_root)
          File.symlink("/tmp", File.join(gem_home, "cache"))
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true })
          error = installer.stub(:verify_ruby!, true) do
            assert_raises(Error) do
              installer.send(:verify_runtime!, ruby: RbConfig.ruby, gem_home: gem_home, gem_root: gem_root)
            end
          end
          assert_match(/unsafe path/, error.message)
        end

        def test_runtime_rejects_a_different_interpreter
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true)
          error = assert_raises(Error) { installer.send(:verify_ruby!, "/bin/sh") }
          assert_match(/differs/, error.message)
        end

        def test_active_recovery_blocks_before_writing_or_enabling
          runner = lambda do |argv|
            name = argv.last
            state = name == "ace-lab-auth-recovery.service" ? "active" : "inactive"
            "Id=#{name}\nActiveState=#{state}\n"
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true }, runner: runner)
          assert_raises(Error) { installer.call(**@runtime) }
          assert_empty Dir.children(@dir)
        end

        def test_active_issuer_instance_blocks_before_writing_or_enabling
          runner = lambda do |argv|
            if argv.include?("list-units")
              "ace-lab-auth@1.service loaded active running\n"
            else
              "Id=#{argv.last}\nActiveState=inactive\n"
            end
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true }, runner: runner)
          assert_raises(Error) { installer.call(**@runtime) }
          assert_empty Dir.children(@dir)
        end
      end
    end
  end
end
