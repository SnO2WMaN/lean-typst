import * as esbuild from 'esbuild';

await esbuild.build({
  entryPoints: ['src/typstDisplay.tsx'],
  outfile: 'dist/typstDisplay.js',
  bundle: true,
  format: 'esm',
  target: 'es2020',
  minify: true,
  jsx: 'automatic',
  external: ['react', 'react-dom', 'react/jsx-runtime', '@leanprover/infoview'],
});
