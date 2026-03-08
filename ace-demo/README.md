# ace-demo

`ace-demo` records terminal demos from VHS tape files.

## Usage

```bash
# Record from a tape preset or file
ace-demo record hello
ace-demo record ./path/to/custom.tape --format mp4
ace-demo record hello --output /tmp/demo.gif
ace-demo record hello --pr 123                          # record + attach to PR
ace-demo record hello --playback-speed 4x              # keep original + create hello-4x.gif

# Record inline (generate tape on-the-fly from shell commands)
ace-demo record my-demo -- "git status" "make deploy"
ace-demo record my-demo --dry-run -- "echo hello"       # preview tape, no VHS
echo "echo hello" | ace-demo record my-demo             # stdin

# Post-process an existing recording
ace-demo retime .ace-local/demo/hello.gif --playback-speed 8x

# Attach an existing recording to a PR
ace-demo attach .ace-local/demo/hello.gif --pr 123
ace-demo attach .ace-local/demo/hello.gif --pr 123 --dry-run

# Discover available tapes
ace-demo list
ace-demo show hello

# Create a new tape file
ace-demo create my-demo -- "git status" "make deploy"
ace-demo create my-demo --desc "Deploy flow" --tags ci -- "git status"
```
