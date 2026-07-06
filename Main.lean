import LeanTypstWebview.Typst

/-! Demo: compile a Typst snippet and display it as a rendered image in the Lean Infoview.
The second demo uses the `curryst` package (https://typst.app/universe/package/curryst/)
to typeset a proof tree, fetched on demand from the official Typst package registry. -/

#typst "$phi and psi -> theta$"

#typst r#"
#import "@preview/curryst:0.6.0": rule, prooftree

#let tree = rule(
  name: [∧-intro],
  rule(name: [Ax], [$Γ ⊢ φ$]),
  rule(name: [Ax], [$Γ ⊢ ψ$]),
  [$Γ ⊢ φ ∧ ψ$],
)

#prooftree(tree)
"#

def main : IO Unit :=
  IO.println "lean-typst-webview"
