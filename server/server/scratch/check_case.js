const fs = require('fs');
const path = require('path');

const getFiles = (dir, files_ = []) => {
  const files = fs.readdirSync(dir);
  for (const i in files) {
    const name = path.join(dir, files[i]);
    if (fs.statSync(name).isDirectory()) {
      if (files[i] !== 'node_modules' && files[i] !== '.git') {
        getFiles(name, files_);
      }
    } else {
      if (name.endsWith('.js')) {
        files_.push(name);
      }
    }
  }
  return files_;
};

const allFiles = getFiles('.');
let issuesFound = false;

allFiles.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const dir = path.dirname(file);
  const matches = content.matchAll(/require\(['"](\.\.?\/[^'"]+)['"]\)/g);
  for (const match of matches) {
    const reqPath = match[1];
    let fullPath = path.resolve(dir, reqPath);
    if (!fullPath.endsWith('.js')) {
        if (fs.existsSync(fullPath + '.js')) {
            fullPath += '.js';
        } else if (fs.existsSync(path.join(fullPath, 'index.js'))) {
            fullPath = path.join(fullPath, 'index.js');
        }
    }

    if (fs.existsSync(fullPath)) {
        const actualName = fs.readdirSync(path.dirname(fullPath)).find(f => f.toLowerCase() === path.basename(fullPath).toLowerCase());
        if (actualName && actualName !== path.basename(fullPath)) {
            console.log(`CASE MISMATCH in ${file}:`);
            console.log(`  Required: ${path.basename(fullPath)}`);
            console.log(`  Actual:   ${actualName}`);
            issuesFound = true;
        }
    } else {
        console.log(`FILE NOT FOUND in ${file}: ${reqPath}`);
        issuesFound = true;
    }
  }
});

if (!issuesFound) {
    console.log('No case sensitivity or file missing issues found in local requires.');
}
