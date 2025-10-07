# frozen_string_literal: true

require_relative "lib/ace/support/mac_clipboard/version"

Gem::Specification.new do |spec|
  spec.name = "ace-support-mac-clipboard"
  spec.version = Ace::Support::MacClipboard::VERSION
  spec.authors = ["ACE Team"]
  spec.email = ["ace@example.com"]

  spec.summary = "macOS NSPasteboard integration for ACE"
  spec.description = "Provides FFI-based access to macOS NSPasteboard for reading rich clipboard content (images, files, RTF, HTML)"
  spec.homepage = "https://github.com/your-org/ace-meta"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/your-org/ace-meta"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE.txt"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
