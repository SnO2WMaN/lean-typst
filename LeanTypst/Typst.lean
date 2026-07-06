module

public import ProofWidgets.Component.HtmlDisplay

public meta section

namespace LeanTypst
open Lean Server Elab Command ProofWidgets

structure TypstDisplayProps where
  src : String
  deriving RpcEncodable

/-- Compiles and renders `TypstDisplayProps.src` as Typst source, entirely client-side in
the infoview webview via a WASM build of the Typst compiler (`typst.ts`). No external
process (e.g. `node`) is ever spawned by the Lean server. -/
@[widget_module]
def TypstDisplay : Component TypstDisplayProps where
  javascript := include_str ".." / "widget" / "dist" / "typstDisplay.js"

/-- Best-effort local compile check for `src`: if a `typst` executable is on `PATH`,
actually compiles it and returns `some err` (the compiler's diagnostic) on failure. Returns
`none` both when it compiles successfully and when `typst` isn't installed — the widget's
own client-side (WASM) compilation is the only hard requirement, this is just an earlier and
more legible diagnostic when a local `typst` happens to be available (e.g. during CI or
interactive development), surfaced as a real Lean error instead of a silent blank/broken
widget that can only be noticed by eye in the infoview. -/
def checkTypstCompiles (src : String) : IO (Option String) := do
  try
    let out ← IO.Process.output
      { cmd := "typst", args := #["compile", "-", "-f", "svg", "-"] } (some src)
    return if out.exitCode == 0 then none else some out.stderr
  catch _ => return none

/-- Compile a Typst snippet and display it as a rendered image in the infoview,
e.g. `#typst "$1 + 2 = 3$"`. -/
syntax (name := typstCmd) "#typst " str : command

@[command_elab typstCmd]
def elabTypstCmd : CommandElab := fun
  | stx@`(#typst $s:str) => do
    let src := s.getString
    if let some err ← checkTypstCompiles src then
      throwErrorAt stx "Typst compile error:\n{err}"
    liftCoreM <| Widget.savePanelWidgetInfo
      (hash TypstDisplay.javascript)
      (return json% { src: $(← rpcEncode src) })
      stx
  | stx => throwError "Unexpected syntax {stx}."

end LeanTypst
