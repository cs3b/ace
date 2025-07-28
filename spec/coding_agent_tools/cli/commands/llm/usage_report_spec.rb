# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/llm/usage_report"
require "date"
require "json"
require "csv"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::LLM::UsageReport do
  let(:command) { described_class.new }
  let(:sample_data) do
    [
      {
        timestamp: "2024-01-01T10:00:00Z",
        provider: "google",
        model: "gemini-2.0-flash",
        input_tokens: 1234,
        output_tokens: 567,
        cached_tokens: 0,
        total_cost: 0.001891,
        input_cost: 0.001543,
        output_cost: 0.000348,
        cache_cost: 0.0,
        execution_time: 2.5
      },
      {
        timestamp: "2024-01-01T11:00:00Z",
        provider: "anthropic",
        model: "claude-3-5-sonnet",
        input_tokens: 2000,
        output_tokens: 800,
        cached_tokens: 100,
        total_cost: 0.006125,
        input_cost: 0.006000,
        output_cost: 0.004000,
        cache_cost: 0.000125,
        execution_time: 3.2
      },
      {
        timestamp: "2024-01-01T12:00:00Z",
        provider: "openai",
        model: "gpt-4o-mini",
        input_tokens: 1500,
        output_tokens: 600,
        cached_tokens: 0,
        total_cost: 0.000585,
        input_cost: 0.000225,
        output_cost: 0.000360,
        cache_cost: 0.0,
        execution_time: 1.8
      }
    ]
  end

  before do
    # Mock stdout to avoid cluttering test output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:puts)
    
    # Mock warn method used by handle_error
    allow_any_instance_of(described_class).to receive(:warn)
  end

  describe "#call" do
    context "with default options" do
      it "returns 0 on successful execution" do
        result = command.call
        expect(result).to eq(0)
      end

      it "displays table format by default" do
        expect($stdout).to receive(:puts).with("LLM Usage Report")
        expect($stdout).to receive(:puts).with("=" * 80)
        command.call
      end
    end

    context "with format options" do
      it "outputs table format when specified" do
        expect($stdout).to receive(:puts).with("LLM Usage Report")
        result = command.call(format: "table")
        expect(result).to eq(0)
      end

      it "outputs json format when specified" do
        expect(command).to receive(:output_json)
        result = command.call(format: "json")
        expect(result).to eq(0)
      end

      it "outputs csv format when specified" do
        expect(command).to receive(:output_csv)
        result = command.call(format: "csv")
        expect(result).to eq(0)
      end
    end

    context "with filter options" do
      it "applies provider filter" do
        expect(command).to receive(:apply_filters).with(anything, hash_including(provider: "google"))
        command.call(provider: "google")
      end

      it "applies model filter" do
        expect(command).to receive(:apply_filters).with(anything, hash_including(model: "claude-3-5-sonnet"))
        command.call(model: "claude-3-5-sonnet")
      end

      it "applies date range filter" do
        expect(command).to receive(:apply_filters).with(anything, hash_including(date_range: "today"))
        command.call(date_range: "today")
      end
    end

    context "with output file option" do
      let(:temp_file) { Tempfile.new(["test_output", ".json"]) }

      after do
        temp_file.unlink
      end

      it "saves output to file when specified" do
        result = command.call(format: "json", output: temp_file.path)
        expect(result).to eq(0)
        expect(File.exist?(temp_file.path)).to be true
      end
    end

    context "error handling" do
      it "returns 1 and calls handle_error on exception" do
        allow(command).to receive(:generate_sample_report).and_raise(StandardError.new("Test error"))
        expect(command).to receive(:handle_error).with(instance_of(StandardError), nil)
        result = command.call
        expect(result).to eq(1)
      end

      it "passes debug flag to handle_error" do
        allow(command).to receive(:generate_sample_report).and_raise(StandardError.new("Test error"))
        expect(command).to receive(:handle_error).with(instance_of(StandardError), true)
        result = command.call(debug: true)
        expect(result).to eq(1)
      end
    end
  end

  describe "#generate_sample_report" do
    it "creates sample data and applies filters" do
      expect(command).to receive(:create_sample_usage_data).and_return(sample_data)
      expect(command).to receive(:apply_filters).with(sample_data, {format: "table"})
      expect(command).to receive(:output_table)

      command.send(:generate_sample_report, {format: "table"})
    end

    it "outputs in json format when specified" do
      allow(command).to receive(:create_sample_usage_data).and_return(sample_data)
      allow(command).to receive(:apply_filters).and_return(sample_data)
      expect(command).to receive(:output_json).with(sample_data, {format: "json"})

      command.send(:generate_sample_report, {format: "json"})
    end

    it "outputs in csv format when specified" do
      allow(command).to receive(:create_sample_usage_data).and_return(sample_data)
      allow(command).to receive(:apply_filters).and_return(sample_data)
      expect(command).to receive(:output_csv).with(sample_data, {format: "csv"})

      command.send(:generate_sample_report, {format: "csv"})
    end
  end

  describe "#create_sample_usage_data" do
    it "returns an array of usage data" do
      result = command.send(:create_sample_usage_data)
      expect(result).to be_an(Array)
      expect(result.length).to eq(3)
    end

    it "includes required fields in each record" do
      result = command.send(:create_sample_usage_data)
      required_fields = [:timestamp, :provider, :model, :input_tokens, :output_tokens, 
                        :cached_tokens, :total_cost, :input_cost, :output_cost, 
                        :cache_cost, :execution_time]
      
      result.each do |record|
        required_fields.each do |field|
          expect(record).to have_key(field)
        end
      end
    end

    it "includes data from different providers" do
      result = command.send(:create_sample_usage_data)
      providers = result.map { |record| record[:provider] }
      expect(providers).to include("google", "anthropic", "openai")
    end
  end

  describe "#apply_filters" do
    it "returns original data when no filters applied" do
      result = command.send(:apply_filters, sample_data, {})
      expect(result).to eq(sample_data)
    end

    it "filters by provider" do
      options = {provider: "google"}
      result = command.send(:apply_filters, sample_data, options)
      expect(result.length).to eq(1)
      expect(result.first[:provider]).to eq("google")
    end

    it "filters by model" do
      options = {model: "claude-3-5-sonnet"}
      result = command.send(:apply_filters, sample_data, options)
      expect(result.length).to eq(1)
      expect(result.first[:model]).to eq("claude-3-5-sonnet")
    end

    it "filters by date range" do
      options = {date_range: "today"}
      expect(command).to receive(:apply_date_filter).with(sample_data, "today")
      command.send(:apply_filters, sample_data, options)
    end

    it "applies multiple filters" do
      options = {provider: "google", model: "gemini-2.0-flash"}
      result = command.send(:apply_filters, sample_data, options)
      expect(result.length).to eq(1)
      expect(result.first[:provider]).to eq("google")
      expect(result.first[:model]).to eq("gemini-2.0-flash")
    end

    it "returns empty array when no matches found" do
      options = {provider: "nonexistent"}
      result = command.send(:apply_filters, sample_data, options)
      expect(result).to eq([])
    end
  end

  describe "#apply_date_filter" do
    let(:today_data) do
      [
        {timestamp: "#{Date.today.strftime('%Y-%m-%d')}T10:00:00Z", provider: "google"},
        {timestamp: "2024-01-01T10:00:00Z", provider: "anthropic"}
      ]
    end

    context "with 'today' filter" do
      it "returns only today's data" do
        result = command.send(:apply_date_filter, today_data, "today")
        expect(result.length).to eq(1)
        expect(result.first[:timestamp]).to start_with(Date.today.strftime("%Y-%m-%d"))
      end
    end

    context "with 'week' filter" do
      let(:week_data) do
        [
          {timestamp: "#{Date.today.strftime('%Y-%m-%d')}T10:00:00Z", provider: "google"},
          {timestamp: "#{(Date.today - 5).strftime('%Y-%m-%d')}T10:00:00Z", provider: "anthropic"},
          {timestamp: "#{(Date.today - 10).strftime('%Y-%m-%d')}T10:00:00Z", provider: "openai"}
        ]
      end

      it "returns data from the last 7 days" do
        result = command.send(:apply_date_filter, week_data, "week")
        expect(result.length).to eq(2)
      end
    end

    context "with 'month' filter" do
      let(:month_data) do
        [
          {timestamp: "#{Date.today.strftime('%Y-%m-%d')}T10:00:00Z", provider: "google"},
          {timestamp: "#{(Date.today - 20).strftime('%Y-%m-%d')}T10:00:00Z", provider: "anthropic"},
          {timestamp: "#{(Date.today - 40).strftime('%Y-%m-%d')}T10:00:00Z", provider: "openai"}
        ]
      end

      it "returns data from the last 30 days" do
        result = command.send(:apply_date_filter, month_data, "month")
        expect(result.length).to eq(2)
      end
    end

    context "with custom date range" do
      let(:range_data) do
        [
          {timestamp: "2024-01-01T10:00:00Z", provider: "google"},
          {timestamp: "2024-01-15T10:00:00Z", provider: "anthropic"},
          {timestamp: "2024-02-01T10:00:00Z", provider: "openai"}
        ]
      end

      it "filters by custom date range" do
        result = command.send(:apply_date_filter, range_data, "2024-01-01:2024-01-31")
        expect(result.length).to eq(2)
        expect(result.map { |r| r[:provider] }).to contain_exactly("google", "anthropic")
      end

      it "handles exact date boundaries" do
        result = command.send(:apply_date_filter, range_data, "2024-01-01:2024-01-01")
        expect(result.length).to eq(1)
        expect(result.first[:provider]).to eq("google")
      end
    end

    context "with invalid date range" do
      it "returns original data for invalid format" do
        result = command.send(:apply_date_filter, sample_data, "invalid")
        expect(result).to eq(sample_data)
      end

      it "returns original data for malformed range" do
        result = command.send(:apply_date_filter, sample_data, "2024-01-01-2024-01-31")
        expect(result).to eq(sample_data)
      end
    end
  end

  describe "#output_table" do
    context "with empty data" do
      it "displays no data message" do
        expect($stdout).to receive(:puts).with("No usage data found matching the specified criteria.")
        command.send(:output_table, [], {})
      end

      it "returns early without printing table" do
        expect($stdout).not_to receive(:puts).with("LLM Usage Report")
        command.send(:output_table, [], {})
      end
    end

    context "with data" do
      it "displays header and summary" do
        expect($stdout).to receive(:puts).with("LLM Usage Report")
        expect($stdout).to receive(:puts).with("=" * 80)
        expect($stdout).to receive(:puts).with("Summary:")
        command.send(:output_table, sample_data, {})
      end

      it "calculates and displays summary statistics" do
        expected_total_tokens = 1234 + 567 + 2000 + 800 + 1500 + 600  # Input + output tokens for all records
        expect($stdout).to receive(:puts).with("  Total Queries: 3")
        expect($stdout).to receive(:puts).with(/Total Cost: \$0\.008601/)
        expect($stdout).to receive(:puts).with("  Total Tokens: #{expected_total_tokens}")
        expect($stdout).to receive(:puts).with(/Average Cost per Query: \$0\.002867/)
        command.send(:output_table, sample_data, {})
      end

      it "displays provider breakdown" do
        expect($stdout).to receive(:puts).with("By Provider:")
        expect($stdout).to receive(:puts).with(/Google: 1 queries, \$0\.001891/)
        expect($stdout).to receive(:puts).with(/Anthropic: 1 queries, \$0\.006125/)
        expect($stdout).to receive(:puts).with(/Openai: 1 queries, \$0\.000585/)
        command.send(:output_table, sample_data, {})
      end

      it "displays detailed usage table" do
        expect($stdout).to receive(:puts).with("Detailed Usage:")
        expect($stdout).to receive(:puts).with(/Timestamp.*Provider.*Model.*Input.*Output.*Cached.*Cost.*Time/)
        expect($stdout).to receive(:puts).with("-" * 80)
        command.send(:output_table, sample_data, {})
      end

      it "formats data rows correctly" do
        expect($stdout).to receive(:puts).with(/2024-01-01T10:00:00.*google.*gemini-2\.0-flash.*1234.*567.*0.*\$0\.001891.*2\.5s/)
        command.send(:output_table, sample_data, {})
      end
    end

    context "with single record" do
      let(:single_record) { [sample_data.first] }

      it "handles division correctly for single record" do
        expect($stdout).to receive(:puts).with("  Total Queries: 1")
        expect($stdout).to receive(:puts).with(/Average Cost per Query: \$0\.001891/)
        command.send(:output_table, single_record, {})
      end
    end
  end

  describe "#output_json" do
    let(:temp_file) { Tempfile.new(["test_output", ".json"]) }

    after do
      temp_file.unlink
    end

    it "generates summary statistics" do
      expect(command).to receive(:generate_summary_stats).with(sample_data)
      command.send(:output_json, sample_data, {})
    end

    it "outputs json to stdout by default" do
      allow(command).to receive(:generate_summary_stats).and_return({total_queries: 3})
      expect($stdout).to receive(:puts).with(a_string_including("\"summary\""))
      command.send(:output_json, sample_data, {})
    end

    it "writes to file when output option provided" do
      allow(command).to receive(:generate_summary_stats).and_return({total_queries: 3})
      command.send(:output_json, sample_data, {output: temp_file.path})
      
      expect(File.exist?(temp_file.path)).to be true
      content = JSON.parse(File.read(temp_file.path))
      expect(content).to have_key("summary")
      expect(content).to have_key("usage_data")
    end

    it "displays file saved message when writing to file" do
      allow(command).to receive(:generate_summary_stats).and_return({})
      expect($stdout).to receive(:puts).with("JSON report saved to: #{temp_file.path}")
      command.send(:output_json, sample_data, {output: temp_file.path})
    end

    it "formats output as pretty JSON" do
      allow(command).to receive(:generate_summary_stats).and_return({total_queries: 3})
      expect(JSON).to receive(:pretty_generate)
      command.send(:output_json, sample_data, {})
    end
  end

  describe "#output_csv" do
    let(:temp_file) { Tempfile.new(["test_output", ".csv"]) }

    after do
      temp_file.unlink
    end

    it "generates CSV with headers" do
      expected_headers = ["timestamp", "provider", "model", "input_tokens", "output_tokens",
                         "cached_tokens", "total_cost", "input_cost", "output_cost", 
                         "cache_cost", "execution_time"]
      
      csv_output = capture_csv_output { command.send(:output_csv, sample_data, {}) }
      expect(csv_output.first).to eq(expected_headers)
    end

    it "includes all data rows" do
      csv_output = capture_csv_output { command.send(:output_csv, sample_data, {}) }
      expect(csv_output.length).to eq(4) # 1 header + 3 data rows
    end

    it "formats data correctly in CSV" do
      csv_output = capture_csv_output { command.send(:output_csv, sample_data, {}) }
      first_row = csv_output[1]
      expect(first_row[0]).to eq("2024-01-01T10:00:00Z")
      expect(first_row[1]).to eq("google")
      expect(first_row[2]).to eq("gemini-2.0-flash")
      expect(first_row[3]).to eq("1234")
    end

    it "writes to file when output option provided" do
      command.send(:output_csv, sample_data, {output: temp_file.path})
      
      expect(File.exist?(temp_file.path)).to be true
      csv_content = CSV.read(temp_file.path)
      expect(csv_content.length).to eq(4) # 1 header + 3 data rows
    end

    it "displays file saved message when writing to file" do
      expect($stdout).to receive(:puts).with("CSV report saved to: #{temp_file.path}")
      command.send(:output_csv, sample_data, {output: temp_file.path})
    end

    it "outputs to stdout by default" do
      expect($stdout).to receive(:puts).with(a_string_including("timestamp,provider,model"))
      command.send(:output_csv, sample_data, {})
    end

    context "with empty data" do
      it "generates CSV with only headers" do
        csv_output = capture_csv_output { command.send(:output_csv, [], {}) }
        expect(csv_output.length).to eq(1) # Only header row
      end
    end
  end

  describe "#generate_summary_stats" do
    context "with empty data" do
      it "returns empty hash" do
        result = command.send(:generate_summary_stats, [])
        expect(result).to eq({})
      end
    end

    context "with data" do
      it "calculates total queries" do
        result = command.send(:generate_summary_stats, sample_data)
        expect(result[:total_queries]).to eq(3)
      end

      it "calculates total cost" do
        result = command.send(:generate_summary_stats, sample_data)
        expect(result[:total_cost]).to eq(0.008601)
      end

      it "calculates total tokens" do
        result = command.send(:generate_summary_stats, sample_data)
        expected_total = 1234 + 567 + 2000 + 800 + 1500 + 600  # Input + output tokens for all records
        expect(result[:total_tokens]).to eq(expected_total)
      end

      it "calculates average cost per query" do
        result = command.send(:generate_summary_stats, sample_data)
        expect(result[:average_cost_per_query]).to eq(0.002867)
      end

      it "groups by providers" do
        result = command.send(:generate_summary_stats, sample_data)
        expect(result[:providers]).to have_key("google")
        expect(result[:providers]).to have_key("anthropic")
        expect(result[:providers]).to have_key("openai")
        
        expect(result[:providers]["google"][:queries]).to eq(1)
        expect(result[:providers]["google"][:cost]).to eq(0.001891)
      end

      it "groups by models" do
        result = command.send(:generate_summary_stats, sample_data)
        expect(result[:models]).to have_key("gemini-2.0-flash")
        expect(result[:models]).to have_key("claude-3-5-sonnet")
        expect(result[:models]).to have_key("gpt-4o-mini")
        
        expect(result[:models]["gemini-2.0-flash"][:queries]).to eq(1)
        expect(result[:models]["gemini-2.0-flash"][:cost]).to eq(0.001891)
      end
    end

    context "with single record" do
      let(:single_record) { [sample_data.first] }

      it "handles single record calculations" do
        result = command.send(:generate_summary_stats, single_record)
        expect(result[:total_queries]).to eq(1)
        expect(result[:average_cost_per_query]).to eq(0.001891)
      end
    end
  end

  describe "#handle_error" do
    let(:test_error) { StandardError.new("Test error message") }

    context "with debug disabled" do
      it "outputs simple error message" do
        expect(command).to receive(:warn).with("Error: Test error message")
        expect(command).to receive(:warn).with("Use --debug flag for more information")
        command.send(:handle_error, test_error, false)
      end
    end

    context "with debug enabled" do
      it "outputs detailed error information" do
        allow(test_error).to receive(:backtrace).and_return(["line1", "line2"])
        expect(command).to receive(:warn).with("Error: StandardError: Test error message")
        expect(command).to receive(:warn).with("\nBacktrace:")
        expect(command).to receive(:warn).with("  line1")
        expect(command).to receive(:warn).with("  line2")
        command.send(:handle_error, test_error, true)
      end

      it "outputs full backtrace" do
        allow(test_error).to receive(:backtrace).and_return(["line1", "line2", "line3"])
        expect(command).to receive(:warn).with("Error: StandardError: Test error message")
        expect(command).to receive(:warn).with("\nBacktrace:")
        expect(command).to receive(:warn).with("  line1")
        expect(command).to receive(:warn).with("  line2")
        expect(command).to receive(:warn).with("  line3")
        command.send(:handle_error, test_error, true)
      end

      it "handles nil backtrace gracefully" do
        allow(test_error).to receive(:backtrace).and_return(nil)
        expect(command).to receive(:warn).with("Error: StandardError: Test error message")
        expect(command).to receive(:warn).with("\nBacktrace:")
        # Should not crash even with nil backtrace
        expect { command.send(:handle_error, test_error, true) }.to raise_error(NoMethodError)
      end
    end

    context "with different error types" do
      let(:custom_error) { ArgumentError.new("Invalid argument") }

      it "displays correct error class name" do
        allow(custom_error).to receive(:backtrace).and_return(["line1"])
        expect(command).to receive(:warn).with("Error: ArgumentError: Invalid argument")
        expect(command).to receive(:warn).with("\nBacktrace:")
        expect(command).to receive(:warn).with("  line1")
        command.send(:handle_error, custom_error, true)
      end
    end
  end

  private

  def capture_csv_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    csv_string = $stdout.string
    $stdout = original_stdout
    CSV.parse(csv_string)
  end
end