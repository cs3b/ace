# Description: Showcase ace-llm querying a model, listing providers, and saving output
# Tags: ace-llm,docs,getting-started

Output ace-llm/docs/demo/ace-llm-getting-started.gif

Set FontSize 16
Set Width 1100
Set Height 680

# Scene 1: Query with a built-in alias
Type 'ace-llm gflash "Explain why CLI tools beat GUIs for automation, in 3 bullets" --quiet'
Enter
Sleep 8s

# Scene 2: See available providers and models
Type 'ace-llm --list-providers'
Enter
Sleep 4s

# Scene 3: Save output to a file
Type 'ace-llm gflash "Write a one-line commit message for a typo fix" --quiet -o /tmp/msg.txt && cat /tmp/msg.txt'
Enter
Sleep 6s
