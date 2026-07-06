# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This is a freshly scaffolded Lean 4 project (`lake new`/`lake init` skeleton). The stated intent (from README.md) is a test project for previewing Typst documents in a webview from Lean, but no such functionality exists yet — the codebase is currently just the default "hello world" template.

## Commands

- Build: `lake build`
- Run the executable: `lake exe lean-typst-webview`
- Lean toolchain is pinned via `lean-toolchain` (`leanprover/lean4:v4.31.0`); do not need to install Lean separately if `elan` is set up.
- CI (`.github/workflows/lean_action_ci.yml`) runs `leanprover/lean-action@v1` on push/PR, which builds the project.

## Architecture

- `lakefile.toml` defines one library target `LeanTypstWebview` and one executable target `lean-typst-webview` (root `Main`).
- `LeanTypstWebview.lean` is the library root; it imports individual modules under `LeanTypstWebview/` (currently only `LeanTypstWebview/Basic.lean`). New library modules should be added under `LeanTypstWebview/` and imported here.
- `Main.lean` is the executable entry point; it imports the `LeanTypstWebview` library.
- No external dependencies are declared in `lakefile.toml` yet (`lake-manifest.json` has an empty `packages` list).
