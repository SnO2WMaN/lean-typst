module

public import LeanTypst.Typst
public meta import Lean.Meta.Eval
public import Lean.Elab.Command

public meta section

namespace LeanTypst
open Lean Server Elab Command Meta

/-- Elaborate a term of type `String` and display the resulting Typst source as a rendered
image in the Lean Infoview, via `LeanTypst.TypstDisplay`. Unlike `#typst "..."`, which only
accepts a string literal, this accepts an arbitrary term and evaluates it (mirroring how
`#eval` elaborates a term) — e.g. a project-specific pretty-printer returning Typst source
as a `String`, such as `#eval-typst prettyPrintProof myProof`. -/
syntax (name := evalTypstCmd) "#eval-typst " term : command

/-- `unsafe` because evaluating a term requires compiling and running it; exposed safely below
via the standard `implemented_by`/`opaque` pattern also used by `#eval` itself
(`Lean.Elab.Command.elabEvalCoreUnsafe`/`elabEvalCore`). -/
unsafe def elabEvalTypstCoreUnsafe (stx : Syntax) (t : TSyntax `term) : CommandElabM Unit := do
  let s : String ← liftTermElabM do
    let e ← Term.elabTermEnsuringType t (mkConst ``String)
    Term.synthesizeSyntheticMVarsNoPostponing
    evalExpr String (mkConst ``String) (← instantiateMVars e)
  if let some err ← checkTypstCompiles s then
    throwErrorAt stx "Typst compile error:\n{err}"
  liftCoreM <| Widget.savePanelWidgetInfo
    (hash TypstDisplay.javascript)
    (return json% { src: $(← rpcEncode s) })
    stx

@[implemented_by elabEvalTypstCoreUnsafe]
opaque elabEvalTypstCore (stx : Syntax) (t : TSyntax `term) : CommandElabM Unit

@[command_elab evalTypstCmd]
def elabEvalTypstCmd : CommandElab
  | stx@`(#eval-typst $t:term) => elabEvalTypstCore stx t
  | _ => throwUnsupportedSyntax

end LeanTypst
