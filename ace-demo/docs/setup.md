---
doc-type: reference
purpose: System dependencies required to run ace-demo recordings.
update:
  update_frequency: on-change
  last-updated: '2026-03-05'
---

# ace-demo Setup

## Required Dependencies

### VHS

[VHS](https://github.com/charmbracelet/vhs) is the terminal recording engine. It executes `.tape` scripts and produces GIF/MP4/WebM output.

Install via your system package manager or download from the [VHS releases page](https://github.com/charmbracelet/vhs/releases).

Verify: `vhs --version`

### Chromium

VHS uses a headless Chromium browser to render the terminal. A system-installed Chromium is required — VHS cannot reliably auto-download one, especially on ARM64.

Install via your system package manager. The binary must be reachable as `chromium` or `google-chrome` in `$PATH`.

Verify: `chromium --version`

### ttyd

[ttyd](https://github.com/tsl0922/ttyd) is a terminal server that VHS connects to internally during recording. It must be installed separately.

Install via your system package manager.

Verify: `ttyd --version`

### ffmpeg (for `retime` and playback postprocess)

`ffmpeg` is required only when using:
- `ace-demo retime`
- `ace-demo record` with `--playback-speed` or configured postprocess speed

Verify: `ffmpeg -version`

---

## Arch Linux

```bash
sudo pacman -S vhs chromium ttyd
```

All three packages are in the `extra` repository. The `vhs` package pulls in `ttyd` as a dependency but it is safe to list it explicitly.

After installing, verify:

```bash
vhs --version
chromium --version
ttyd --version
```

Then record a built-in tape to confirm the full pipeline works:

```bash
ace-demo record hello
# Expected: Recorded: .ace-local/demo/hello.gif
```
