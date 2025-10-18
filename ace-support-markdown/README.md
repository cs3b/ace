# ace-support-markdown

Safe markdown editing with frontmatter support for ACE gems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ace-support-markdown'
```

## Usage

```ruby
require 'ace/support/markdown'

# Edit a markdown file with frontmatter
editor = Ace::Support::Markdown::Organisms::DocumentEditor.new("task.md")
editor.update_frontmatter({"status" => "done"})
result = editor.save!(backup: true, validate: true)

# Edit sections
editor.replace_section("## References", "New content")
editor.save!

# Build new documents
builder = Ace::Support::Markdown::Molecules::DocumentBuilder.new
builder.frontmatter({"id" => "task.079", "status" => "draft"})
builder.add_section(heading: "# Title", content: "Description")
builder.to_markdown
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
