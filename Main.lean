module

import LeanTypst.Typst
import LeanTypst.EvalTypst

/-! Demo: compile a Typst snippet and display it as a rendered image in the Lean Infoview.
The second demo uses the `curryst` package (https://typst.app/universe/package/curryst/)
to typeset a proof tree, fetched on demand from the official Typst package registry. -/

#typst "$phi and psi -> theta$"

/-! `#eval-typst` demo: unlike `#typst`, this elaborates and evaluates an arbitrary term of
type `String`, so the Typst source can depend on Lean computation rather than being a fixed
literal. -/

def sumFormula (n : Nat) : String :=
  s!"$sum_(i=1)^{n} i = {n * (n + 1) / 2}$"

#eval-typst sumFormula 10

#typst r#"
#import "@preview/curryst:0.6.0": rule, prooftree

#let tree = rule(
  name: [$and$-intro],
  rule(name: [Ax], [$Gamma tack.r phi$]),
  rule(name: [Ax], [$Gamma tack.r psi$]),
  [$Gamma tack.r phi and psi$],
)

#context prooftree(tree, stroke: text.fill + 0.05em)
"#

public def main : IO Unit :=
  IO.println "lean-typst"
