# frozen_string_literal: true

require "tmpdir"
require "fileutils"

module Ace
  module Core
    module TestSupport
      # Provides isolated test environment for integration testing
      class TestEnvironment
        attr_reader :temp_dir, :home_dir, :project_dir, :gem_dir

        def initialize
          @original_env = {}
          @original_pwd = nil
        end

        # Set up isolated test environment
        def setup
          @temp_dir = Dir.mktmpdir('ace-test')
          @home_dir = File.join(@temp_dir, 'home')
          @project_dir = File.join(@temp_dir, 'project')
          @gem_dir = File.join(@temp_dir, 'gem')

          # Create directory structure
          Dir.mkdir(@home_dir)
          Dir.mkdir(@project_dir)
          Dir.mkdir(@gem_dir)

          # Store original environment
          @original_env['HOME'] = ENV['HOME']
          @original_env['ACE_CONFIG_PATH'] = ENV['ACE_CONFIG_PATH']
          @original_pwd = Dir.pwd

          # Set test environment
          ENV['HOME'] = @home_dir
          ENV['ACE_CONFIG_PATH'] = nil
          Dir.chdir(@project_dir)
        end

        # Tear down test environment
        def teardown
          # Restore original environment
          Dir.chdir(@original_pwd) if @original_pwd
          @original_env.each { |k, v| ENV[k] = v }

          # Clean up temp directory
          FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
        end

        # Create config directory structure
        def create_config_dirs
          create_project_config_dir
          create_home_config_dir
          create_gem_config_dir
        end

        # Create project config directory
        def create_project_config_dir
          config_dir = File.join(@project_dir, '.ace', 'core')
          FileUtils.mkdir_p(config_dir)
          config_dir
        end

        # Create home config directory
        def create_home_config_dir
          config_dir = File.join(@home_dir, '.ace', 'core')
          FileUtils.mkdir_p(config_dir)
          config_dir
        end

        # Create gem config directory
        def create_gem_config_dir
          config_dir = File.join(@gem_dir, 'config', 'ace', 'core')
          FileUtils.mkdir_p(config_dir)
          config_dir
        end

        # Write config file to specified location
        def write_config(type, filename, content)
          path = case type
                 when :project
                   File.join(create_project_config_dir, filename)
                 when :home
                   File.join(create_home_config_dir, filename)
                 when :gem
                   File.join(create_gem_config_dir, filename)
                 else
                   raise ArgumentError, "Unknown config type: #{type}"
                 end

          File.write(path, content)
          path
        end

        # Write .env file to project directory
        def write_env_file(filename = '.env', content = '')
          path = File.join(@project_dir, filename)
          File.write(path, content)
          path
        end

        # Create a subdirectory in project
        def create_subdirectory(name)
          path = File.join(@project_dir, name)
          FileUtils.mkdir_p(path)
          path
        end

        # Change to subdirectory
        def chdir(subdir = nil)
          if subdir
            Dir.chdir(File.join(@project_dir, subdir))
          else
            Dir.chdir(@project_dir)
          end
        end

        # Get config path for type
        def config_path(type)
          case type
          when :project
            File.join(@project_dir, '.ace', 'core')
          when :home
            File.join(@home_dir, '.ace', 'core')
          when :gem
            File.join(@gem_dir, 'config', 'ace', 'core')
          else
            raise ArgumentError, "Unknown config type: #{type}"
          end
        end

        # Verify directory structure
        def verify_structure
          {
            temp: Dir.exist?(@temp_dir),
            home: Dir.exist?(@home_dir),
            project: Dir.exist?(@project_dir),
            gem: Dir.exist?(@gem_dir)
          }
        end
      end
    end
  end
end