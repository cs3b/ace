#!/usr/bin/env ruby
# frozen_string_literal: true

# Performance benchmark for ace-git-secrets scanning
#
# Usage: ruby test/performance/benchmark_scan.rb
#
# This script benchmarks:
# - Gitleaks runner performance
# - Full scan performance via HistoryScanner
#
# Requirements:
# - gitleaks installed (brew install gitleaks)
# - benchmark-ips gem (optional, for detailed reports)

require_relative "../test_helper"
require "benchmark"
require "tempfile"
require "fileutils"

class ScanBenchmark
  SAMPLE_CONTENT = <<~CONTENT
    # Configuration file
    DATABASE_URL=postgres://localhost:5432/mydb
    API_KEY=some_random_value
    SECRET_TOKEN=ghp_1234567890abcdefghijklmnopqrstuvwxyzAB
    ANTHROPIC_KEY=sk-ant-test1234567890abcdefghijklmnopqrstuvwxyz
    ANOTHER_VALUE=not_a_secret
    OPENAI_KEY=sk-test1234567890abcdefghijklmnopqrstuvwxyzABCD
  CONTENT

  def initialize
    @temp_repos = []
  end

  def cleanup
    @temp_repos.each { |dir| FileUtils.rm_rf(dir) if Dir.exist?(dir) }
  end

  def run
    puts "=" * 60
    puts "ace-git-secrets Performance Benchmark"
    puts "=" * 60
    puts

    unless Ace::Git::Secrets::Atoms::GitleaksRunner.available?
      puts "WARNING: gitleaks not installed. Install with: brew install gitleaks"
      puts "Skipping benchmarks that require gitleaks."
      puts
      return
    end

    benchmark_gitleaks_runner
    benchmark_full_scan
  ensure
    cleanup
  end

  private

  def benchmark_gitleaks_runner
    puts "Gitleaks Runner Performance"
    puts "-" * 40

    repo = create_test_repo(5)
    @temp_repos << repo

    runner = Ace::Git::Secrets::Atoms::GitleaksRunner.new

    Benchmark.bm(25) do |x|
      x.report("File scan (no git):") do
        10.times { runner.scan_files(path: repo) }
      end

      x.report("History scan:") do
        10.times { runner.scan_history(path: repo) }
      end
    end
    puts
  end

  def benchmark_full_scan
    puts "Full Scan Performance (HistoryScanner)"
    puts "-" * 40

    # Create repos of different sizes
    sizes = [5, 20, 50]

    sizes.each do |commit_count|
      repo = create_test_repo(commit_count)
      @temp_repos << repo

      puts "Repository with #{commit_count} commits:"

      Benchmark.bm(25) do |x|
        x.report("  Full scan:") do
          scanner = Ace::Git::Secrets::Molecules::HistoryScanner.new(
            repository_path: repo
          )
          scanner.scan
        end
      end
    end
    puts
  end

  def create_test_repo(commit_count)
    dir = Dir.mktmpdir("benchmark-repo")

    Dir.chdir(dir) do
      system("git init -q", exception: true)
      system("git config user.email 'bench@test.com'", exception: true)
      system("git config user.name 'Benchmark'", exception: true)

      commit_count.times do |i|
        # Some files with secrets, some without
        content = i.even? ? SAMPLE_CONTENT : "No secrets here #{i}"
        File.write("file_#{i}.txt", content)
        system("git add file_#{i}.txt", exception: true)
        system("git commit -q -m 'Commit #{i}'", exception: true)
      end
    end

    dir
  end
end

# Run if executed directly
if __FILE__ == $PROGRAM_NAME
  ScanBenchmark.new.run
end
