import { useEffect, useState } from 'react'
import { useAsyncPersistent } from '@leanprover/infoview'
import { $typst } from '@myriaddreamin/typst.ts'
import { TypstSnippet } from '@myriaddreamin/typst.ts/contrib/snippet'

// The compiler WASM module alone is ~28MB, far too large to embed as a Lean
// string literal (`include_str`), so it is loaded lazily over the network
// instead of being bundled. This still avoids any dependency on a local
// Node.js installation: everything runs inside the infoview webview via WASM.
const TYPST_TS_VERSION = '0.7.0'
const compilerWasmUrl =
  `https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-web-compiler@${TYPST_TS_VERSION}/pkg/typst_ts_web_compiler_bg.wasm`
const rendererWasmUrl =
  `https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-renderer@${TYPST_TS_VERSION}/pkg/typst_ts_renderer_bg.wasm`

let initPromise: Promise<void> | undefined
function ensureInit(): Promise<void> {
  if (initPromise === undefined) {
    $typst.setCompilerInitOptions({ getModule: () => fetch(compilerWasmUrl) })
    $typst.setRendererInitOptions({ getModule: () => fetch(rendererWasmUrl) })
    // Fetch `@preview/...` packages (e.g. `curryst`) on demand from the
    // official Typst package registry, the same as a normal Typst install.
    $typst.use(TypstSnippet.fetchPackageRegistry())
    initPromise = Promise.resolve()
  }
  return initPromise
}

// VS Code injects `--vscode-*` CSS custom properties (mirroring its theme
// color IDs) into every webview, updated live on theme switch. This is the
// same technique ProofWidgets' `penroseDisplay.tsx` uses (`getCssColour`):
// setting the variable as a temporary element's `color` and reading back the
// browser-canonicalized `rgb(...)` is the only reliable way to resolve a CSS
// custom property to concrete channel values.
function resolveCssColor(cssColor: string): string {
  const el = document.createElement('div')
  el.style.display = 'none'
  el.style.color = cssColor
  document.body.appendChild(el)
  const resolved = getComputedStyle(el).color
  document.body.removeChild(el)
  return resolved
}

function currentForegroundColor(): string {
  return resolveCssColor('var(--vscode-editor-foreground)')
}

// Converts a computed `rgb(r, g, b)` / `rgba(r, g, b, a)` CSS color string
// into a Typst `rgb(..)` literal. Falls back to black if unparseable.
function toTypstRgb(cssColor: string): string {
  const m = cssColor.match(/rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)/)
  if (!m) return 'rgb(0, 0, 0)'
  const [, r, g, b] = m
  return `rgb(${r}, ${g}, ${b})`
}

/** Re-renders whenever VS Code's theme (and thus the infoview's foreground
 * color) changes, by watching for the attribute changes VS Code makes on
 * `<body>`/`<html>` when switching theme. */
function useForegroundColor(): string {
  const [color, setColor] = useState(currentForegroundColor)
  useEffect(() => {
    const update = () => setColor(currentForegroundColor())
    const observer = new MutationObserver(update)
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class', 'style'] })
    observer.observe(document.body, { attributes: true, attributeFilter: ['class', 'style'] })
    return () => observer.disconnect()
  }, [])
  return color
}

function wrapSource(src: string, foregroundColor: string): string {
  // `#set text(fill: ..)` only recolors text itself; things like `curryst`'s
  // inference-rule bars are drawn with their own explicit (default-black)
  // `stroke`, which a `#set` rule cannot reach. Call sites can still pick up
  // this color for such elements from Typst itself, with no injected name,
  // via `#context text.fill`, e.g. `#context prooftree(tree, stroke: text.fill + 0.05em)`.
  return `#set page(width: auto, height: auto, margin: 0.5em, fill: none)
#set text(fill: ${toTypstRgb(foregroundColor)})
${src}`
}

// The infoview webview is always Chromium/Electron (VS Code), so the
// non-standard but Chromium-supported `zoom` property is safe to rely on
// here; unlike `transform: scale`, it also resizes the layout box.
const DISPLAY_SCALE = 2

export interface TypstDisplayProps {
  src: string
}

export default function TypstDisplay({ src }: TypstDisplayProps): JSX.Element {
  const foregroundColor = useForegroundColor()
  const state = useAsyncPersistent(async () => {
    await ensureInit()
    return await $typst.svg({ mainContent: wrapSource(src, foregroundColor) })
  }, [src, foregroundColor])
  if (state.state === 'resolved') {
    return <div style={{ zoom: DISPLAY_SCALE }} dangerouslySetInnerHTML={{ __html: state.value }} />
  } else if (state.state === 'rejected') {
    return <span className="red">Typst render error: {String(state.error)}</span>
  }
  return <>Rendering…</>
}
