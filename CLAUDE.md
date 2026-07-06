# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

A Lean 4 project that adds `#typst` and `#eval-typst` commands for compiling and displaying
Typst snippets as images in the Lean Infoview, rendered client-side via a WASM build of
the Typst compiler (`typst.ts`) — no local Typst or Node.js install is needed at
elaboration time.

## Commands

- Build: `lake build` (also builds the `widget/` TypeScript bundle via npm/esbuild; see below)
- Run the executable: `lake exe lean-typst`
- Lean toolchain is pinned via `lean-toolchain` (`leanprover/lean4:v4.31.0`).
- Widget-only rebuild: `cd widget && npm run build`
- Widget typecheck: `cd widget && npx tsc --noEmit -p .`
- CI (`.github/workflows/lean_action_ci.yml`) runs `leanprover/lean-action@v1` on push/PR.

## Architecture

- `lakefile.lean` (not TOML, since it needs a custom build target) declares:
  - `require proofwidgets` — provides the Lean-side widget/RPC infrastructure (`Component`, `Widget.savePanelWidgetInfo`, etc.). Pin the tag to match `lean-toolchain` exactly.
  - a `widgetJsAll` custom target that runs `npm clean-install && npm run build` inside `widget/`, mirroring ProofWidgets4's own lakefile pattern. `lean_lib LeanTypst` depends on it via `needs`, so `lake build` always rebuilds the widget bundle first.
- `LeanTypst.lean` / `LeanTypst/` is the library root; `LeanTypst/Typst.lean` defines the `#typst "..."` command, `LeanTypst/EvalTypst.lean` defines `#eval-typst <term>`.
- `Main.lean` is the executable entry point and also hosts the `#typst`/`#eval-typst` demos (open it in VS Code to see them render in the Infoview).
- `LeanTypst/Typst.lean`: the `#typst` elaborator just saves a `LeanTypst.TypstDisplay` panel widget with the raw Typst source string as props (`include_str`-embeds the compiled `widget/dist/typstDisplay.js`). All actual compilation happens later, client-side, when the infoview renders the widget.
- `LeanTypst/EvalTypst.lean`: `#eval-typst <term>` elaborates and evaluates an arbitrary term of type `String` (mirroring core Lean's `#eval` command, including its `unsafe`-impl/`opaque`-wrapper pattern around `Lean.Meta.evalExpr`), then feeds the resulting string to the same `LeanTypst.TypstDisplay` widget as `#typst`. This is a separate command rather than an overload of `#typst` because `term` syntactically subsumes string literals, which would make the two commands' parses ambiguous on `#typst "..."`.
- `widget/src/typstDisplay.tsx`: the React widget component.
  - Uses `@myriaddreamin/typst.ts`'s WASM compiler/renderer. The compiler WASM alone is ~28MB — far too large for `include_str` — so it's `fetch()`ed lazily from jsDelivr instead of bundled.
  - `@preview/...` packages (e.g. `curryst`, used in the proof-tree demo) are fetched on demand from the official Typst package registry via `TypstSnippet.fetchPackageRegistry()` — the same mechanism a normal Typst install uses, not vendored.
  - Reads the infoview's current `--vscode-editor-foreground` (via a temporary DOM element, the same technique as ProofWidgets' `penroseDisplay.tsx`) and bakes it into the compiled source with `#set text(fill: ..)`, re-rendering on theme switch via a `MutationObserver`. Typst source that draws its own strokes (e.g. `curryst`'s proof-tree bars) can pick up the same color from Typst itself with `#context text.fill`, without needing any injected variable name.
  - `widget/build.mjs` bundles this with esbuild, marking `react`, `react-dom`, `react/jsx-runtime`, and `@leanprover/infoview` external (resolved at runtime by the infoview's own import map, like ProofWidgets' components).
- `widget/node_modules`, `widget/dist`, and the Lake trace files under `widget/` are gitignored; `widget/package-lock.json` is committed.
