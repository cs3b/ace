Here's a fish command to downcase all files and directories under docs-dev:

```fish
for file in (find docs-dev -depth)
    set lower (string lower $file)
    if test "$file" != "$lower"
        mv "$file" "$lower"
    end
end
```

This command:
1. Uses `find docs-dev -depth` to list all files and directories (processes deeper items first)
2. For each path, creates a lowercase version using `string lower`
3. If the original and lowercase versions differ, renames using `mv`

The `-depth` option is important because it processes deeper paths first, preventing issues when renaming parent directories.
