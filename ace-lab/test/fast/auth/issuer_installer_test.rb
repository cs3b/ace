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
            readiness_verifier: -> { true }, state_verifier: ->(**) { true },
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

        def test_current_active_installation_and_verify_do_not_mutate_units_or_sessions
          @installer.call(**@runtime)
          @commands.clear
          assert_equal "current", @installer.call(**@runtime).fetch("status")
          assert_equal "current", @installer.verify(**@runtime).fetch("status")
          assert_empty @commands
          assert_raises(Error) { @installer.call(**@runtime.merge(gem_root: "/opt/ace/gems/gems/ace-lab-0.99.0")) }
          assert_empty @commands
        end

        def test_identical_stopped_deployment_can_be_activated_without_rewriting_files
          @installer.call(**@runtime)
          @commands.clear
          @installer.instance_variable_set(:@state_verifier, ->(**) { :inactive })
          assert_equal "would_activate", @installer.call(**@runtime, dry_run: true).fetch("status")
          assert_empty @commands
          assert_raises(Error) { @installer.verify(**@runtime) }
          assert_equal "activated", @installer.call(**@runtime).fetch("status")
          assert @commands.any? { |argv| argv.include?("enable") }
          refute @commands.any? { |argv| argv.include?("stop") || argv.include?("restart") }
        end

        def test_interrupted_file_install_reloads_inactive_units_before_effective_verification
          IssuerUnits.render(**@runtime).each { |name, contents| File.write(File.join(@dir, name), contents) }
          @installer.instance_variable_set(:@state_verifier, ->(**) { :inactive })
          @installer.instance_variable_set(:@activation_verifier, lambda do |**|
            raise Error, "stale units" unless @commands.any? { |argv| argv.include?("daemon-reload") }
          end)
          assert_equal "would_activate", @installer.call(**@runtime, dry_run: true).fetch("status")
          assert_empty @commands
          assert_equal "activated", @installer.call(**@runtime).fetch("status")
        end

        def test_readiness_requires_socket_and_completed_recovery_even_without_a_running_issuer
          states = {
            "ace-lab-auth.socket" => "ActiveState=active\nSubState=listening\n",
            "ace-lab-auth-recovery.service" => "ActiveState=active\nSubState=exited\nResult=success\n",
            "ace-lab-auth.service" => "ActiveState=inactive\nSubState=dead\nResult=success\nMainPID=0\n"
          }
          inspector = IssuerInstaller.new(runner: ->(argv) { "Id=#{argv.last}\n#{states.fetch(argv.last)}" })
          assert inspector.send(:verify_active_state!, ruby: @runtime[:ruby], gem_root: @runtime[:gem_root])
          states["ace-lab-auth.socket"] = "ActiveState=inactive\nSubState=dead\n"
          assert_raises(Error) { inspector.send(:verify_active_state!, ruby: @runtime[:ruby], gem_root: @runtime[:gem_root]) }
          states["ace-lab-auth.socket"] = "ActiveState=active\nSubState=listening\n"
          states["ace-lab-auth-recovery.service"] = "ActiveState=failed\nSubState=failed\nResult=exit-code\n"
          assert_raises(Error) { inspector.send(:verify_active_state!, ruby: @runtime[:ruby], gem_root: @runtime[:gem_root]) }
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

        def test_verifies_the_singleton_service
          runner = lambda do |argv|
            return true unless argv.include?("show")

            name = argv.last
            fragment = name
            policy = case name
            when "ace-lab-auth.service" then "User=root\nType=simple\nKillMode=control-group\n"
            when "ace-lab-auth-recovery.service" then "User=root\nType=oneshot\nRemainAfterExit=yes\n"
            else "Accept=no\n"
            end
            "Id=#{name}\nLoadState=loaded\nFragmentPath=#{File.join(@dir, fragment)}\nDropInPaths=\nNeedDaemonReload=no\n#{policy}"
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true },
            inactive_verifier: -> { true }, readiness_verifier: -> { true }, runner: runner)
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

        def test_shared_library_check_verifies_actual_mapping_and_rejects_replaced_inode
          library = File.join(@dir, "library.so")
          File.write(library, "fixture")
          maps = File.join(@dir, "maps")
          inode = File.stat(library).ino
          File.write(maps, "1000-2000 r-xp 0000 00:00 #{inode} #{library}\n")
          assert @installer.send(:verify_shared_libraries!, maps_path: maps)
          File.write(maps, "1000-2000 r-xp 0000 00:00 #{inode + 1} #{library}\n")
          assert_raises(Error) { @installer.send(:verify_shared_libraries!, maps_path: maps) }
          File.write(maps, "1000-2000 r-xp 0000 00:00 #{inode} #{library} (deleted)\n")
          assert_raises(Error) { @installer.send(:verify_shared_libraries!, maps_path: maps) }
        end

        def test_active_recovery_blocks_before_writing_or_enabling
          runner = lambda do |argv|
            name = argv.last
            state = name == "ace-lab-auth-recovery.service" ? "active" : "inactive"
            "Id=#{name}\nActiveState=#{state}\n"
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true },
            readiness_verifier: -> { true }, runner: runner)
          assert_raises(Error) { installer.call(**@runtime) }
          assert_empty Dir.children(@dir)
        end

        def test_active_issuer_instance_blocks_before_writing_or_enabling
          runner = lambda do |argv|
            if argv.last == "ace-lab-auth.service"
              "Id=ace-lab-auth.service\nActiveState=active\n"
            else
              "Id=#{argv.last}\nActiveState=inactive\n"
            end
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true },
            readiness_verifier: -> { true }, runner: runner)
          assert_raises(Error) { installer.call(**@runtime) }
          assert_empty Dir.children(@dir)
        end

        def test_unsupported_host_blocks_dry_run_and_install_without_writes
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true)
          platform = Object.new
          def platform.supported!
            raise Ace::Runtime::RuntimeUnavailableError, "missing kernel policy"
          end
          Ace::Runtime::Molecules::ProtectedLinux.stub(:new, platform) do
            [true, false].each do |dry_run|
              error = assert_raises(Error) { installer.call(**@runtime, dry_run: dry_run) }
              assert_match(/installation failed/, error.message)
            end
          end
          assert_empty Dir.children(@dir)
        end

        def test_accept_yes_is_refused_before_socket_activation
          runner = lambda do |argv|
            @commands << argv
            name = argv.last
            "Id=#{name}\nLoadState=loaded\nFragmentPath=#{File.join(@dir, name)}\nDropInPaths=\nNeedDaemonReload=no\nAccept=yes\n"
          end
          installer = IssuerInstaller.new(unit_dir: @dir, owner_uid: Process.uid, privileged: true,
            path_verifier: ->(_path, directory: false) { true }, runtime_verifier: ->(**) { true },
            inactive_verifier: -> { true }, readiness_verifier: -> { true }, runner: runner)
          error = assert_raises(Error) do
            installer.send(:verify_loaded_units!, unit_dir: @dir, units: ["ace-lab-auth.socket"])
          end
          assert_match(/unsafe lifecycle policy/, error.message)
          refute @commands.any? { |argv| argv.include?("enable") }
        end
      end
    end
  end
end
