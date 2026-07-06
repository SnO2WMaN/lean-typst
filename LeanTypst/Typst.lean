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

/-- Compile a Typst snippet and display it as a rendered image in the infoview,
e.g. `#typst "$1 + 2 = 3$"`. -/
syntax (name := typstCmd) "#typst " str : command

@[command_elab typstCmd]
def elabTypstCmd : CommandElab := fun
  | stx@`(#typst $s:str) => do
    liftCoreM <| Widget.savePanelWidgetInfo
      (hash TypstDisplay.javascript)
      (return json% { src: $(← rpcEncode s.getString) })
      stx
  | stx => throwError "Unexpected syntax {stx}."

end LeanTypst
