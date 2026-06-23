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
const requires = new Set();

allFiles.forEach(file => {
  const content = fs.readFileSync(file, 'utf8');
  const matches = content.matchAll(/require\(['"]([^.][^'"]+)['"]\)/g);
  for (const match of matches) {
    requires.add(match[1]);
  }
});

console.log('Detected external requires:');
console.log(Array.from(requires).sort());
