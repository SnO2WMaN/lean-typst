import LeanTypstWebview.Typst

/-! Demo: compile a Typst snippet and display it as a rendered image in the Lean Infoview. -/

#typst "$phi and psi -> theta$"

def main : IO Unit :=
  IO.println "lean-typst-webview"
