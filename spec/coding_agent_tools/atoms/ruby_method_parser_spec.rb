# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::RubyMethodParser do
  subject { described_class.new }

  let(:sample_ruby_code) do
    <<~RUBY
      class TestClass
        def instance_method
          puts "hello"
        end

        def self.class_method
          puts "world"
        end

        private

        def private_method
          # implementation
        end
      end

      module TestModule
        def module_method
          # implementation
        end
      end
    RUBY
  end

  describe "#parse_content" do
    it "extracts instance methods" do
      methods = subject.parse_content(sample_ruby_code)
      
      instance_method = methods.find { |m| m.name == "instance_method" }
      expect(instance_method).not_to be_nil
      expect(instance_method.type).to eq(:def)
      expect(instance_method.start_line).to eq(2)
      expect(instance_method.end_line).to eq(4)
    end

    it "extracts class methods" do
      methods = subject.parse_content(sample_ruby_code)
      
      class_method = methods.find { |m| m.name == "self.class_method" }
      expect(class_method).not_to be_nil
      expect(class_method.type).to eq(:defs)
      expect(class_method.start_line).to eq(6)
      expect(class_method.end_line).to eq(8)
    end

    it "extracts private methods" do
      methods = subject.parse_content(sample_ruby_code)
      
      private_method = methods.find { |m| m.name == "private_method" }
      expect(private_method).not_to be_nil
      expect(private_method.type).to eq(:def)
    end

    it "extracts methods from modules" do
      methods = subject.parse_content(sample_ruby_code)
      
      module_method = methods.find { |m| m.name == "module_method" }
      expect(module_method).not_to be_nil
      expect(module_method.type).to eq(:def)
    end

    it "returns correct total number of methods" do
      methods = subject.parse_content(sample_ruby_code)
      expect(methods.length).to eq(4)
    end

    context "with nested classes" do
      let(:nested_ruby_code) do
        <<~RUBY
          class Outer
            def outer_method
            end

            class Inner
              def inner_method
              end
            end
          end
        RUBY
      end

      it "extracts methods from nested classes" do
        methods = subject.parse_content(nested_ruby_code)
        
        method_names = methods.map(&:name)
        expect(method_names).to contain_exactly("outer_method", "inner_method")
      end
    end

    context "with syntax errors" do
      let(:invalid_ruby_code) { "class TestClass\n  def missing_end\n" }

      it "raises ParseError" do
        expect {
          subject.parse_content(invalid_ruby_code)
        }.to raise_error(described_class::ParseError, /Syntax error/)
      end
    end

    context "with empty content" do
      it "returns empty array" do
        methods = subject.parse_content("")
        expect(methods).to eq([])
      end
    end
  end

  describe "#parse_file" do
    let(:temp_file) { Tempfile.new(["test", ".rb"]) }

    before do
      temp_file.write(sample_ruby_code)
      temp_file.rewind
    end

    after { temp_file.unlink }

    it "successfully parses valid Ruby file" do
      methods = subject.parse_file(temp_file.path)
      expect(methods.length).to eq(4)
      
      method_names = methods.map(&:name)
      expect(method_names).to include("instance_method", "self.class_method")
    end

    context "with non-existent file" do
      it "raises ParseError" do
        expect {
          subject.parse_file("/non/existent/file.rb")
        }.to raise_error(described_class::ParseError, /Cannot read file/)
      end
    end
  end

  describe "MethodDefinition" do
    let(:method_def) do
      described_class::MethodDefinition.new("test_method", 5, 10, :def)
    end

    describe "#line_range" do
      it "returns correct range" do
        expect(method_def.line_range).to eq(5..10)
      end
    end

    it "has correct attributes" do
      expect(method_def.name).to eq("test_method")
      expect(method_def.start_line).to eq(5)
      expect(method_def.end_line).to eq(10)
      expect(method_def.type).to eq(:def)
    end
  end
end