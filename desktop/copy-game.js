// Copies the website files into desktop/game so the app always ships the current version of the game.
const fs = require('fs'), path = require('path');
const site = path.join(__dirname, '..'), out = path.join(__dirname, 'game');
const files = ['index.html', 'config.js', 'peerjs.min.js', 'credits.json', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png', 'skin-template.png'];
fs.rmSync(out, { recursive: true, force: true }); fs.mkdirSync(out, { recursive: true });
for (const f of files) { const src = path.join(site, f); if (fs.existsSync(src)) fs.copyFileSync(src, path.join(out, f)); }
console.log('copied the game into', out);
