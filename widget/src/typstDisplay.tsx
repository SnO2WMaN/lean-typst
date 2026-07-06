import { useAsyncPersistent } from '@leanprover/infoview'
import { $typst } from '@myriaddreamin/typst.ts'

// The compiler WASM module alone is ~28MB, far too large to embed as a Lean
// string literal (`include_str`), so it is loaded lazily over the network
// instead of being bundled. This still avoids any dependency on a local
// Node.js installation: everything runs inside the infoview webview via WASM.
const TYPST_TS_VERSION = '0.7.0'
const compilerWasmUrl =
  `https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-web-compiler@${TYPST_TS_VERSION}/pkg/typst_ts_web_compiler_bg.wasm`
const rendererWasmUrl =
  `https://cdn.jsdelivr.net/npm/@myriaddreamin/typst-ts-renderer@${TYPST_TS_VERSION}/pkg/typst_ts_renderer_bg.wasm`

let wasmInitialized = false
function ensureWasmInit(): void {
  if (wasmInitialized) return
  wasmInitialized = true
  $typst.setCompilerInitOptions({ getModule: () => fetch(compilerWasmUrl) })
  $typst.setRendererInitOptions({ getModule: () => fetch(rendererWasmUrl) })
}

function wrapSource(src: string): string {
  return `#set page(width: auto, height: auto, margin: 0.5em)\n${src}`
}

export interface TypstDisplayProps {
  src: string
}

export default function TypstDisplay({ src }: TypstDisplayProps): JSX.Element {
  ensureWasmInit()
  const state = useAsyncPersistent(() => $typst.svg({ mainContent: wrapSource(src) }), [src])
  if (state.state === 'resolved') {
    return <div dangerouslySetInnerHTML={{ __html: state.value }} />
  } else if (state.state === 'rejected') {
    return <span className="red">Typst render error: {String(state.error)}</span>
  }
  return <>Rendering…</>
}
