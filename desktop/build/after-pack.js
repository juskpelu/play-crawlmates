// Gives Crawlmates.exe its icon and name. Pure JavaScript, so it also works when building on Linux or macOS
// (electron-builder's own way needs Wine there).
const fs = require('fs'), path = require('path');
module.exports = async function afterPack(ctx) {
  if (ctx.electronPlatformName !== 'win32') return;
  const ResEdit = require('resedit'); const PE = require('pe-library');
  const exe = path.join(ctx.appOutDir, ctx.packager.appInfo.productFilename + '.exe');
  const data = PE.NtExecutable.from(fs.readFileSync(exe), { ignoreCert: true });
  const res = PE.NtExecutableResource.from(data);
  const ico = ResEdit.Data.IconFile.from(fs.readFileSync(path.join(__dirname, 'icon.ico')));
  ResEdit.Resource.IconGroupEntry.replaceIconsForResource(res.entries, 1, 1033, ico.icons.map(i => i.data));
  const vi = ResEdit.Resource.VersionInfo.fromEntries(res.entries)[0] || ResEdit.Resource.VersionInfo.createEmpty();
  const v = ctx.packager.appInfo.version.split('.').map(Number);
  vi.setFileVersion(v[0], v[1], v[2], 0, 1033); vi.setProductVersion(v[0], v[1], v[2], 0, 1033);
  vi.setStringValues({ lang: 1033, codepage: 1200 }, {
    ProductName: 'Crawlmates', FileDescription: 'Crawlmates', CompanyName: 'Holden Slaughter',
    LegalCopyright: 'Holden Slaughter', OriginalFilename: 'Crawlmates.exe', InternalName: 'Crawlmates'
  });
  vi.outputToResourceEntries(res.entries);
  res.outputResource(data);
  fs.writeFileSync(exe, Buffer.from(data.generate()));
};
