import fs from 'node:fs';
import path from 'node:path';
import chalk from 'chalk';
import ora from 'ora';
import { fileURLToPath } from 'node:url';
import { copyToClipboard } from '../lib/clipboard.js';

export async function updateStatusCommand() {
  const spinner = ora(chalk.bold('Orquestrando contexto para atualização do PROJECT_STATUS...')).start();
  const targetDir = process.cwd();

  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const devosRootDir = path.resolve(__dirname, '..', '..', '..');
  const templatePath = path.join(devosRootDir, 'templates', 'prompts', 'UPDATE_PROJECT_STATUS.md');

  if (!fs.existsSync(templatePath)) {
    spinner.fail(chalk.red('Template UPDATE_PROJECT_STATUS.md não encontrado!'));
    process.exit(1);
  }

  // Read PROJECT_BRIEF and PROJECT_TASKS
  const briefPath = path.join(targetDir, 'PROJECT_BRIEF.md');
  const tasksPath = path.join(targetDir, 'PROJECT_TASKS.md');
  const briefContent = fs.existsSync(briefPath) ? fs.readFileSync(briefPath, 'utf8') : '(Ausente)';
  const tasksContent = fs.existsSync(tasksPath) ? fs.readFileSync(tasksPath, 'utf8') : '(Ausente)';

  try {
    const templateContent = fs.readFileSync(templatePath, 'utf8');

    const payload = `
${templateContent}

---

# Informações de Contexto Atual

## PROJECT_BRIEF.md
${briefContent}

---

## PROJECT_TASKS.md
${tasksContent}
`.trim();

    const outDir = path.join(targetDir, '.devos', 'out');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outFile = path.join(outDir, 'prompt_update_status.md');
    fs.writeFileSync(outFile, payload, 'utf8');

    const copied = await copyToClipboard(payload);

    spinner.succeed(chalk.green('Payload do UPDATE_PROJECT_STATUS orquestrado com sucesso!'));

    console.log('\n' + chalk.bold('Resultado:'));
    if (copied) {
      console.log(chalk.cyan('  📋 Conteúdo copiado para a Área de Transferência (Clipboard)!'));
    } else {
      console.log(chalk.yellow('  ⚠ Não foi possível acessar o Clipboard nativamente.'));
    }
    console.log(chalk.gray(`  📁 Arquivo gerado em: ${path.relative(targetDir, outFile)}`));
  } catch (error: any) {
    spinner.fail(chalk.red(`Falha ao empacotar contexto: ${error.message}`));
    process.exit(1);
  }
}
