import fs from 'node:fs';
import path from 'node:path';
import chalk from 'chalk';
import ora from 'ora';
import { fileURLToPath } from 'node:url';
import { copyToClipboard } from '../lib/clipboard.js';

function getDirectoryTree(dir: string, depth = 0): string {
  if (depth > 4) return ''; // Limit depth to avoid massive output
  let result = '';
  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'dist' || entry.name === 'out') {
        continue;
      }
      const indent = '  '.repeat(depth);
      if (entry.isDirectory()) {
        result += `${indent}📁 ${entry.name}/\n`;
        result += getDirectoryTree(path.join(dir, entry.name), depth + 1);
      } else {
        result += `${indent}📄 ${entry.name}\n`;
      }
    }
  } catch {}
  return result;
}

export async function importCommand() {
  const spinner = ora(chalk.bold('Mapeando estrutura do projeto para importação...')).start();
  const targetDir = process.cwd();

  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const devosRootDir = path.resolve(__dirname, '..', '..', '..');
  const templatePath = path.join(devosRootDir, 'templates', 'prompts', 'IMPORT_PROJECT_TEMPLATE.md');

  if (!fs.existsSync(templatePath)) {
    spinner.fail(chalk.red('Template IMPORT_PROJECT_TEMPLATE.md não encontrado!'));
    process.exit(1);
  }

  try {
    const templateContent = fs.readFileSync(templatePath, 'utf8');
    const tree = getDirectoryTree(targetDir);

    const payload = `
${templateContent}

---

# Evidências e Estrutura do Projeto Atual

## Árvore de Diretórios (Estrutura de Pastas):
\`\`\`
${tree || '(Sem arquivos detectados)'}
\`\`\`
`.trim();

    const outDir = path.join(targetDir, '.devos', 'out');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outFile = path.join(outDir, 'prompt_import.md');
    fs.writeFileSync(outFile, payload, 'utf8');

    const copied = await copyToClipboard(payload);

    spinner.succeed(chalk.green('Payload do IMPORT_PROJECT orquestrado com sucesso!'));

    console.log('\n' + chalk.bold('Resultado:'));
    if (copied) {
      console.log(chalk.cyan('  📋 Conteúdo copiado para a Área de Transferência (Clipboard)!'));
    } else {
      console.log(chalk.yellow('  ⚠ Não foi possível acessar o Clipboard nativamente.'));
    }
    console.log(chalk.gray(`  📁 Arquivo gerado em: ${path.relative(targetDir, outFile)}`));
  } catch (error: any) {
    spinner.fail(chalk.red(`Falha ao mapear projeto: ${error.message}`));
    process.exit(1);
  }
}
