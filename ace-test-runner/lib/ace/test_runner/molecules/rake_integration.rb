# frozen_string_literal: true

require "fileutils"
require "erb"

module Ace
  module TestRunner
    module Molecules
      # Manages Rakefile integration for ace-test
      class RakeIntegration
        BACKUP_EXTENSION = ".ace-backup"
        MARKER_COMMENT = "# ace-test-runner integration"

        def initialize(rakefile_path = "Rakefile")
          @rakefile_path = rakefile_path
        end

        # Set ace-test as the default rake test runner
        def set_default
          validate_environment!

          if already_integrated?
            return {success: true, message: "ace-test is already set as default rake test runner"}
          end

          backup_rakefile
          inject_ace_test_config

          {success: true, message: "Successfully set ace-test as default rake test runner"}
        rescue => e
          restore_from_backup if backup_exists?
          {success: false, message: "Failed to set ace-test as default: #{e.message}"}
        end

        # Remove ace-test as the default rake test runner
        def unset_default
          unless already_integrated?
            return {success: true, message: "ace-test is not currently set as default"}
          end

          if backup_exists?
            restore_from_backup
            {success: true, message: "Successfully restored original Rakefile"}
          else
            remove_ace_test_config
            {success: true, message: "Successfully removed ace-test configuration"}
          end
        rescue => e
          {success: false, message: "Failed to unset ace-test as default: #{e.message}"}
        end

        # Check if ace-test is currently set as default
        def check_status
          if !rakefile_exists?
            {
              integrated: false,
              message: "No Rakefile found in current directory",
              rakefile_exists: false
            }
          elsif already_integrated?
            {
              integrated: true,
              message: "ace-test is currently set as default rake test runner",
              rakefile_exists: true,
              backup_exists: backup_exists?
            }
          else
            {
              integrated: false,
              message: "ace-test is not set as default rake test runner",
              rakefile_exists: true,
              has_test_task: has_test_task?
            }
          end
        end

        private

        def validate_environment!
          unless rakefile_exists?
            # Create a basic Rakefile if it doesn't exist
            create_basic_rakefile
          end
        end

        def rakefile_exists?
          File.exist?(@rakefile_path)
        end

        def backup_exists?
          File.exist?(backup_path)
        end

        def backup_path
          "#{@rakefile_path}#{BACKUP_EXTENSION}"
        end

        def already_integrated?
          return false unless rakefile_exists?

          content = File.read(@rakefile_path)
          content.include?(MARKER_COMMENT) && content.include?("Ace::TestRunner::RakeTask")
        end

        def has_test_task?
          return false unless rakefile_exists?

          content = File.read(@rakefile_path)
          content.match?(/task\s+:test|Rake::TestTask\.new/)
        end

        def backup_rakefile
          FileUtils.cp(@rakefile_path, backup_path)
        end

        def restore_from_backup
          FileUtils.mv(backup_path, @rakefile_path, force: true)
        end

        def inject_ace_test_config
          original_content = File.read(@rakefile_path)

          # Check if there's an existing test task
          if has_test_task?
            # Comment out existing test task and add ace-test task
            modified_content = comment_out_existing_test_task(original_content)
            modified_content += "\n\n" + ace_test_rake_config
          else
            # Just append ace-test configuration
            modified_content = original_content + "\n\n" + ace_test_rake_config
          end

          File.write(@rakefile_path, modified_content)
        end

        def remove_ace_test_config
          content = File.read(@rakefile_path)

          # Remove ace-test configuration block
          content = content.gsub(/#{Regexp.escape(MARKER_COMMENT)}.*?# End of ace-test-runner integration/mo, "")

          # Uncomment original test task if it was commented
          content = uncomment_original_test_task(content)

          File.write(@rakefile_path, content.strip + "\n")
        end

        def comment_out_existing_test_task(content)
          # Comment out existing Rake::TestTask
          content = content.gsub(/^(require\s+["']rake\/testtask["'])/, '# \1 # Commented by ace-test')
          content = content.gsub(/^(Rake::TestTask\.new.*?)^end/m) do |match|
            match.split("\n").map { |line| "# #{line}" }.join("\n")
          end

          # Comment out simple task :test definitions
          content.gsub(/^(task\s+:test\s+do.*?)^end/m) do |match|
            match.split("\n").map { |line| "# #{line}" }.join("\n")
          end
        end

        def uncomment_original_test_task(content)
          # Uncomment lines that were commented by ace-test
          content.gsub(/^# (.*) # Commented by ace-test$/, '\1')

          # Uncomment task blocks (more complex - would need proper parsing)
          # For now, just leave them commented as user can manually uncomment if needed
        end

        def create_basic_rakefile
          File.write(@rakefile_path, basic_rakefile_template)
        end

        def basic_rakefile_template
          <<~RAKEFILE
            # frozen_string_literal: true

            require "bundler/gem_tasks" if File.exist?("Gemfile")

            # Default task
            task default: :test
          RAKEFILE
        end

        def ace_test_rake_config
          <<~CONFIG
            #{MARKER_COMMENT}
            begin
              require "ace/test_runner/rake_task"

              # Use ace-test as the default test runner
              Ace::TestRunner::RakeTask.new(:test) do |t|
                t.description = "Run tests with ace-test"
                t.libs << "test" << "lib"
                t.pattern = ENV["PATTERN"] || "test/**/*_test.rb"
                t.verbose = ENV["VERBOSE"] == "true"
                t.format = ENV["FORMAT"] || ENV["ACE_TEST_FORMAT"]
              end
            rescue LoadError
              # Fallback to standard Rake::TestTask if ace-test-runner is not available
              require "rake/testtask"

              Rake::TestTask.new(:test) do |t|
                t.libs << "test" << "lib"
                t.test_files = FileList[ENV["PATTERN"] || "test/**/*_test.rb"]
                t.verbose = ENV["VERBOSE"] == "true"
                t.warning = ENV["WARNING"] == "true"
              end

              puts "Warning: ace-test-runner not found. Using standard Rake::TestTask."
              puts "Install ace-test-runner gem to use advanced test features."
            end
            # End of ace-test-runner integration
          CONFIG
        end
      end
    end
  end
end
