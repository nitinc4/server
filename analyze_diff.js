const fs = require('fs');
const path = require('path');

const junkDir = 'C:\\Users\\nitin\\Downloads\\junk\\server\\server';
const currentDir = 'C:\\Users\\nitin\\OneDrive\\Desktop\\projects\\Work\\zudo\\server\\server';

function getJsFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      if (!file.includes('node_modules') && !file.includes('.git')) {
        results = results.concat(getJsFiles(file));
      }
    } else {
      if (file.endsWith('.js')) results.push(file);
    }
  });
  return results;
}

const junkFiles = getJsFiles(junkDir).map(f => f.replace(junkDir, ''));
const currentFiles = getJsFiles(currentDir).map(f => f.replace(currentDir, ''));

const routesDiff = [];
const modelsDiff = [];

junkFiles.forEach(file => {
  if (!currentFiles.includes(file)) {
    console.log(`NEW FILE IN JUNK: ${file}`);
    return;
  }
  
  const junkContent = fs.readFileSync(path.join(junkDir, file), 'utf8');
  const currentContent = fs.readFileSync(path.join(currentDir, file), 'utf8');
  
  if (junkContent !== currentContent) {
    if (file.includes('routes')) routesDiff.push(file);
    if (file.includes('models')) modelsDiff.push(file);
  }
});

console.log('Modified Routes:', routesDiff);
console.log('Modified Models:', modelsDiff);

function extractRoutes(content) {
  const regex = /router\.(get|post|put|delete|patch)\s*\(\s*['"]([^'"]+)['"]/g;
  const routes = [];
  let match;
  while ((match = regex.exec(content)) !== null) {
    routes.push(`${match[1].toUpperCase()} ${match[2]}`);
  }
  return routes;
}

routesDiff.forEach(file => {
  const junkContent = fs.readFileSync(path.join(junkDir, file), 'utf8');
  const currentContent = fs.readFileSync(path.join(currentDir, file), 'utf8');
  
  const junkRoutes = extractRoutes(junkContent);
  const currentRoutes = extractRoutes(currentContent);
  
  const missingRoutes = junkRoutes.filter(r => !currentRoutes.includes(r));
  if (missingRoutes.length > 0) {
    console.log(`\nMissing routes in ${file}:`);
    missingRoutes.forEach(r => console.log(`  - ${r}`));
  }
});
