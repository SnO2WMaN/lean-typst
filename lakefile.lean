import Lake
open Lake DSL System

-- Named without a hyphen so downstream projects can write a plain
-- `require lean_typst from git ...` — a hyphenated name (e.g. `«lean-typst»`)
-- requires guillemets there too, which is an easy trap for external users.
package lean_typst where
  version := v!"0.1.0"

require proofwidgets from git
  "https://github.com/leanprover-community/ProofWidgets4" @ "v0.0.102"

def widgetDir : FilePath := "widget"

nonrec def Lake.Package.widgetDir (pkg : Package) : FilePath :=
  pkg.dir / widgetDir

def Lake.Package.runNpmCommand (pkg : Package) (args : Array String) : LogIO Unit :=
  -- Running `cmd := "npm.cmd"` directly fails on Windows sometimes, so run via
  -- PowerShell there instead (mirrors ProofWidgets4's own lakefile).
  if Platform.isWindows then
    proc {
      cmd := "powershell"
      args := #["-Command", "npm.cmd"] ++ args
      cwd := some pkg.widgetDir
    } (quiet := true)
  else
    proc {
      cmd := "npm"
      args
      cwd := some pkg.widgetDir
    } (quiet := true)

input_file widgetPackageJson where
  path := widgetDir / "package.json"
  text := true

/-- Target to update `package-lock.json` whenever `package.json` has changed. -/
target widgetPackageLock pkg : FilePath := do
  let packageFile ← widgetPackageJson.fetch
  let packageLockFile := pkg.widgetDir / "package-lock.json"
  buildFileAfterDep (text := true) packageLockFile packageFile fun _srcFile => do
    pkg.runNpmCommand #["install"]

/-- The widget's TypeScript/TSX sources. -/
input_dir widgetJsSrcs where
  path := widgetDir / "src"
  filter := .extension <| .mem #["ts", "tsx", "js", "jsx"]
  text := true

input_file widgetBuildScript where
  path := widgetDir / "build.mjs"
  text := true

/-- Target to bundle the widget module from `widgetJsSrcs` with esbuild. -/
def widgetJsAllTarget (pkg : Package) : FetchM (Job Unit) := do
  let srcs ← widgetJsSrcs.fetch
  let buildScript ← widgetBuildScript.fetch
  let packageLock ← widgetPackageLock.fetch
  srcs.bindM (sync := true) fun _ =>
  buildScript.bindM (sync := true) fun _ =>
  packageLock.mapM fun _ => do
    let traceFile := pkg.widgetDir / "dist" / "lake.trace"
    buildUnlessUpToDate traceFile (← getTrace) traceFile do
      pkg.runNpmCommand #["clean-install"]
      pkg.runNpmCommand #["run", "build"]

target widgetJsAll pkg : Unit := widgetJsAllTarget pkg

@[default_target]
lean_lib LeanTypst where
  needs := #[widgetJsAll]

@[default_target]
lean_exe «lean-typst» where
  root := `Main
