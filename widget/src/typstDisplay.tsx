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

function wrapSource(src: string): string {
  return `#set page(width: auto, height: auto, margin: 0.5em)\n${src}`
}

// The infoview webview is always Chromium/Electron (VS Code), so the
// non-standard but Chromium-supported `zoom` property is safe to rely on
// here; unlike `transform: scale`, it also resizes the layout box.
const DISPLAY_SCALE = 2

export interface TypstDisplayProps {
  src: string
}

export default function TypstDisplay({ src }: TypstDisplayProps): JSX.Element {
  const state = useAsyncPersistent(async () => {
    await ensureInit()
    return await $typst.svg({ mainContent: wrapSource(src) })
  }, [src])
  if (state.state === 'resolved') {
    return <div style={{ zoom: DISPLAY_SCALE }} dangerouslySetInnerHTML={{ __html: state.value }} />
  } else if (state.state === 'rejected') {
    return <span className="red">Typst render error: {String(state.error)}</span>
  }
  return <>Rendering…</>
}
