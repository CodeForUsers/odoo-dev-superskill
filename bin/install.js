#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Determine destination directory. Default to .agents/skills/odoo-dev-superskill in the current working directory
const cwd = process.cwd();
const destDir = path.join(cwd, '.agents', 'skills', 'odoo-dev-superskill');

// Get the directory of the installed npm package
const packageDir = path.resolve(__dirname, '..');

console.log(`\n🚀 Installing odoo-dev-superskill...`);

try {
  // Ensure the destination directory exists
  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }

  const itemsToCopy = ['SKILL.md', 'README.md', 'references', 'scripts', 'templates'];

  itemsToCopy.forEach((item) => {
    const srcPath = path.join(packageDir, item);
    const destPath = path.join(destDir, item);

    if (fs.existsSync(srcPath)) {
      // Use cp -r for simplicity across OS (assuming Unix-like for agent environments)
      // For cross-platform, a custom recursive copy function is better, but execSync cp is fine for most agent environments.
      execSync(`cp -R "${srcPath}" "${destPath}"`);
      console.log(`✅ Copied ${item}`);
    } else {
      console.warn(`⚠️ Warning: ${item} not found in package directory.`);
    }
  });

  console.log(`\n🎉 Successfully installed odoo-dev-superskill to:`);
  console.log(`   ${destDir}`);
  console.log(`\nYour AI Agent is now equipped with the ultimate Odoo ICA development skill.`);
  console.log(`Start a conversation with your agent and mention 'Odoo' or '__manifest__.py' to trigger it.\n`);

} catch (error) {
  console.error(`\n❌ Error installing odoo-dev-superskill:`, error.message);
  process.exit(1);
}
