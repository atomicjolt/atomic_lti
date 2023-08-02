import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['app/javascript/atomic_lti/init_app.js'],
  outdir: 'app/assets/builds/atomic_lti',
  bundle: true,
  assetNames: '[name]-[hash].digested',
  logLevel: 'info',
  publicPath: 'assets',
  sourcemap: 'external',
  minify: true,
  loader: {
    '.js': 'jsx'
  }
})
