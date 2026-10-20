# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"
require "open3"
require "rubygems/package"
require "rubygems/installer"

class ToolchainTest < AceSupportCliTestCase
  Toolchain = Ace::Support::Cli::Toolchain

  def with_mode(mode)
    old = ENV["ACE_TOOLCHAIN"]
    ENV["ACE_TOOLCHAIN"] = mode
    yield
  ensure
    ENV["ACE_TOOLCHAIN"] = old
  end

  def test_auto_keeps_project_binstub
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p("#{root}/bin")
      File.write("#{root}/bin/ace-nav", "#!/bin/sh\nexit 99\n")
      File.chmod(0o755, "#{root}/bin/ace-nav")
      with_mode("auto") do
        assert_equal "#{root}/bin/ace-nav", Toolchain.executable("ace-nav", project_root: root)
        assert_empty Toolchain.child_environment
      end
    end
  end

  def test_path_gem_is_not_an_installed_gem
    Dir.mktmpdir do |root|
      File.write("#{root}/sample.gemspec", "# source\n")
      spec = Gem::Specification.new { |s| s.name = "sample"; s.version = "1.0" }
      spec.loaded_from = "#{root}/sample.gemspec"
      refute Toolchain.installed_spec?(spec)
    end
  end

  def test_real_installed_spec_and_executable_ignore_poisoned_project
    Dir.mktmpdir do |root|
      gem_root = "#{root}/gems/ace-fixture-1.0"
      FileUtils.mkdir_p(["#{root}/specifications", "#{gem_root}/exe", "#{root}/project/bin", "#{gem_root}/lib/ace/support/cli"])
      spec = Gem::Specification.new do |s|
        s.name = "ace-fixture"
        s.version = "1.0"
        s.summary = "fixture"
        s.authors = ["test"]
        s.bindir = "exe"
        s.executables = ["ace-fixture"]
      end
      File.write("#{root}/specifications/ace-fixture-1.0.gemspec", spec.to_ruby)
      File.write("#{gem_root}/exe/ace-fixture", "#!/usr/bin/env ruby\nrequire_relative '../lib/ace/support/cli/toolchain'\nAce::Support::Cli::Toolchain.verify_loaded!\nputs 'installed'\n")
      File.chmod(0o755, "#{gem_root}/exe/ace-fixture")
      File.write("#{root}/project/bin/ace-fixture", "#!/bin/sh\ntouch #{root}/poison\n")
      File.chmod(0o755, "#{root}/project/bin/ace-fixture")
      File.write("#{root}/project/Gemfile", "raise 'poison Gemfile'\n")
      File.write("#{root}/project/poison.rb", "raise 'poison Ruby preload'\n")
      helper = File.expand_path("../../../lib/ace/support/cli/toolchain", __dir__)
      FileUtils.cp("#{helper}.rb", "#{gem_root}/lib/ace/support/cli/toolchain.rb")
      # Install a real built gem, including RubyGems' generated activation wrapper.
      spec.files = ["exe/ace-fixture", "lib/ace/support/cli/toolchain.rb"]
      artifact = Dir.chdir(gem_root) { Gem::Package.build(spec, true) }
      FileUtils.mv("#{gem_root}/#{artifact}", "#{root}/#{artifact}")
      Gem::Installer.at("#{root}/#{artifact}", install_dir: root, wrappers: true).install
      script = <<~RUBY
        gem "ace-fixture", "1.0"
        require "ace/support/cli/toolchain"
        t = Ace::Support::Cli::Toolchain
        path = t.executable("ace-fixture", project_root: Dir.pwd)
        puts path
        ENV["BUNDLE_GEMFILE"] = File.join(Dir.pwd, "Gemfile")
        ENV["RUBYOPT"] = "-r" + File.join(Dir.pwd, "poison.rb")
        system(t.child_environment, path) || abort("fixture failed")
      RUBY
      env = {"ACE_TOOLCHAIN" => "installed", "GEM_HOME" => root, "GEM_PATH" => root,
             "RUBYOPT" => nil, "RUBYLIB" => nil, "BUNDLE_GEMFILE" => nil, "BUNDLER_SETUP" => nil}
      out, err, status = Open3.capture3(env, Gem.ruby, "-e", script, chdir: "#{root}/project")
      assert status.success?, err
      assert_equal "#{root}/bin/ace-fixture\ninstalled", out.strip
      refute File.exist?("#{root}/poison")
      _, err, status = Open3.capture3(env, Gem.ruby, "-e", script.sub('t.executable("ace-fixture"', 't.executable("missing-cli"'), chdir: "#{root}/project")
      refute status.success?
      assert_includes err, "unavailable"
      File.write("#{root}/project/source.gemspec", "# source dependency\n")
      injected = <<~RUBY
        source = Gem::Specification.new { |s| s.name = "ace-source"; s.version = "1.0" }
        source.loaded_from = File.join(Dir.pwd, "source.gemspec")
        Gem.loaded_specs["ace-source"] = source
      RUBY
      poisoned = script.sub('path = t.executable', injected + 'path = t.executable')
      _, err, status = Open3.capture3(env, Gem.ruby, "-e", poisoned, chdir: "#{root}/project")
      refute status.success?
      assert_includes err, "loaded source dependency ace-source"
      FileUtils.rm("#{root}/bin/ace-fixture")
      _, err, status = Open3.capture3(env, Gem.ruby, "-e", script, chdir: "#{root}/project")
      refute status.success?
      assert_includes err, "installed launcher ace-fixture missing"
    end
  end

  def test_post_shell_setup_restores_ruby_and_mode_and_clears_source_injection
    with_mode("installed") do
      command = 'export PATH=/poison RUBYOPT=-r/poison BUNDLE_GEMFILE=/poison BUNDLER_SETUP=/poison; ' +
        Toolchain.shell_setup + 'ruby -e ' + Shellwords.escape('puts ENV.fetch("ACE_TOOLCHAIN"); puts RbConfig.ruby; puts ENV.key?("BUNDLE_GEMFILE")')
      out, err, status = Open3.capture3("/bin/bash", "--noprofile", "--norc", "-c", command)
      assert status.success?, err
      assert_equal ["installed", Gem.ruby, "false"], out.lines.map(&:strip)
    end
  end

  def test_invalid_mode_is_not_silent_auto
    with_mode("instaled") { assert_raises(Toolchain::Error) { Toolchain.installed? } }
  end
end
