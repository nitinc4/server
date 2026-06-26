const fs = require('fs');
const path = require('path');

const ACTIVE_DIR = 'C:\\Users\\nitin\\OneDrive\\Desktop\\projects\\Work\\zudo\\zudo_new\\admin\\src';
const JUNK_DIR = 'C:\\Users\\nitin\\Downloads\\junk\\admin\\admin\\src';

function getAllFiles(dir, fileList = []) {
  if (!fs.existsSync(dir)) return fileList;
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    if (fs.statSync(filePath).isDirectory()) {
      if (file !== 'node_modules' && file !== '.git') {
        getAllFiles(filePath, fileList);
      }
    } else {
      fileList.push(filePath);
    }
  }
  return fileList;
}

const activeFiles = getAllFiles(ACTIVE_DIR).map(f => path.relative(ACTIVE_DIR, f));
const junkFiles = getAllFiles(JUNK_DIR).map(f => path.relative(JUNK_DIR, f));

const missingFiles = junkFiles.filter(f => !activeFiles.includes(f));
const commonFiles = junkFiles.filter(f => activeFiles.includes(f));

let report = `=== Admin Panel Diff Analysis ===\n\n`;
report += `Total JUNK files: ${junkFiles.length}\n`;
report += `Total ACTIVE files: ${activeFiles.length}\n\n`;

report += `--- MISSING FILES (in junk, not in active) ---\n`;
missingFiles.forEach(f => {
  report += `- ${f}\n`;
});

report += `\n--- COMMON FILES WITH DIFFERENCES (Size/Content checks) ---\n`;

for (const f of commonFiles) {
  const activePath = path.join(ACTIVE_DIR, f);
  const junkPath = path.join(JUNK_DIR, f);
  const activeStats = fs.statSync(activePath);
  const junkStats = fs.statSync(junkPath);
  
  // Just comparing size for a quick check, could compare content
  if (activeStats.size !== junkStats.size) {
    // Check if the file is a js/jsx/ts/tsx file to do a rough line count difference
    if (f.match(/\.(js|jsx|ts|tsx)$/)) {
        const activeLines = fs.readFileSync(activePath, 'utf8').split('\n').length;
        const junkLines = fs.readFileSync(junkPath, 'utf8').split('\n').length;
        
        if (activeLines !== junkLines) {
            report += `- ${f} (Active: ${activeLines} lines, Junk: ${junkLines} lines)\n`;
        }
    } else {
        report += `- ${f} (Active size: ${activeStats.size}, Junk size: ${junkStats.size})\n`;
    }
  }
}

fs.writeFileSync('C:\\Users\\nitin\\OneDrive\\Desktop\\projects\\Work\\zudo\\admin_diff.txt', report);
console.log('Analysis complete. Results saved to admin_diff.txt');
