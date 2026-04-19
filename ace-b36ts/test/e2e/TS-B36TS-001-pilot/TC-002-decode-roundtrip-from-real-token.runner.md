# Goal 2 - Decode Roundtrip from Real Token

## Goal

Generate a real compact token with `ace-b36ts encode`, then decode it using
public CLI formats to prove a maintainer-visible roundtrip path.

## Workspace

Save command captures to `results/tc/02/`.

## Constraints

- Use only `ace-b36ts ...` commands from documented usage/help paths.
- Do not fabricate token values.
- Capture stdout/stderr/exit for every command.

## Steps

1. Run `ace-b36ts encode "2026-03-20 00:00:00 UTC" --format day` and save `encode.*`.
2. Resolve the generated token from `encode.stdout` by reading the capture file and selecting the first non-empty line that is only lowercase base36 characters.
3. Save the resolved token into `results/tc/02/token.txt`.
4. Run `ace-b36ts decode <token> --format iso` and save `decode-iso.*`.
5. Run `ace-b36ts decode <token> --format timestamp` and save `decode-ts.*`.
6. In runner observations, mention the resolved token and both decode output modes.

Use an extraction step equivalent to:

```bash
ruby -e 'token = File.read("results/tc/02/encode.stdout").lines.map(&:strip).find { |line| line.match?(/\A[0-9a-z]+\z/) }; abort("missing encoded token") unless token; File.write("results/tc/02/token.txt", token + "\n")'
```
