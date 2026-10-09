# Agent guidance for img-remix

This is a Bun/TypeScript terminal tool for Windows and macOS. `index.ts` holds
its CLI and OpenRouter requests; `open.ts` opens results and folders without
going through cmd.exe; `img-remix` is the macOS launcher.

## Working here

- Use test-first development for non-trivial changes. Write or update the test
  first, then implement the change until it passes. Extract a test seam if needed.
- When behaviour, startup, settings, output or tested expectations change, update
  the relevant tests and rerun them. Run `bun test` and `bunx tsc --noEmit` before
  committing, then smoke-test the actual CLI. Use mocked API responses for tests;
  don't spend API credits without being asked.
- `.env` lives beside `index.ts` at this repo's root. Keep `.env.example` to empty
  variable names and never commit real keys. Environment variables take precedence.
- Keep source in this clone. `C:\dev\tools` contains only generated launchers and
  any large external binaries, never source. Never commit `.exe` or `.dll` files.
- Write `.bat` launchers as ASCII. `install-lib.ps1` uses `-Encoding ASCII`.
- This is an interactive terminal CLI, so its Explorer verb deliberately opens
  `cmd.exe /k`. Keep its terminal visible for prompts and errors.
- `install.ps1` uses `$PSScriptRoot`, runs `deps.ps1` unless `-SkipDeps` is given,
  and installs only this tool. `deps.ps1` must remain self-contained, idempotent,
  report missing system dependencies clearly, and fail if installation fails.
- Preserve other tools' Explorer verbs and shared Mike's Tools root properties.
  The verb ID is `ImgRemix`; uninstall only our launchers, verb and converted icon.
- `install.sh` links the launcher into `~/.local/bin` or its supplied directory.
  Reinstall after moving the clone. Editing source does not require reinstalling.
- Parse all `.ps1` files with `pwsh -NoProfile -File tests/parse-powershell.ps1`.
  Test Windows scripts directly on Windows and check exit codes. The Windows
  installer smoke test is restricted to ephemeral CI runners because it uses HKCU.
- Run `bash -n img-remix install.sh uninstall.sh` for shell syntax checks.
- Keep existing screenshots. Use plain, friendly writing without em or en dashes.
- Start PR descriptions with `## Why`, explaining what prompted the change.

There was no dedicated tool-specific section in the original agent guidance.
The CLI has no persisted settings or tool-specific log folder to migrate.
