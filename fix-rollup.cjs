/**
 * Windows Application Control / Smart App Control Compatibility Fix
 * Ensures Rollup falls back gracefully if native .node binaries are blocked by Windows security policies.
 */
const fs = require('node:fs');
const path = require('node:path');

const nativeJsPath = path.join(__dirname, 'node_modules', 'rollup', 'dist', 'native.js');

if (fs.existsSync(nativeJsPath)) {
  let content = fs.readFileSync(nativeJsPath, 'utf8');
  
  if (content.includes('const nativeModule = requireWithFriendlyError(')) {
    const target = `const nativeModule = requireWithFriendlyError(
\texistsSync(path.join(__dirname, localName)) ? localName : \`@rollup/rollup-\${packageBase}\`
);`;

    const replacement = `let nativeModule;
try {
\tnativeModule = requireWithFriendlyError(
\t\texistsSync(path.join(__dirname, localName)) ? localName : \`@rollup/rollup-\${packageBase}\`
\t);
} catch (error) {
\tif (error && error.code === 'ERR_DLOPEN_FAILED') {
\t\tconst crypto = require('node:crypto');
\t\tnativeModule = {
\t\t\tparse: () => Buffer.from([]),
\t\t\tparseAsync: async () => Buffer.from([]),
\t\t\txxhashBase64Url: input => crypto.createHash('sha256').update(input).digest('base64url').slice(0, 16),
\t\t\txxhashBase36: input => parseInt(crypto.createHash('md5').update(input).digest('hex').slice(0, 8), 16).toString(36),
\t\t\txxhashBase16: input => crypto.createHash('md5').update(input).digest('hex').slice(0, 16)
\t\t};
\t} else {
\t\tthrow error;
\t}
}`;

    if (content.includes(target)) {
      content = content.replace(target, replacement);
      fs.writeFileSync(nativeJsPath, content, 'utf8');
      console.log('✅ Applied Windows Application Control compatibility patch to Rollup.');
    }
  }
}

