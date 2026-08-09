import fs from 'node:fs';
import path from 'node:path';
import chalk from 'chalk';
import ora from 'ora';
import { fileURLToPath } from 'node:url';
import { copyToClipboard } from '../lib/clipboard.js';

export async function briefCommand() {
  const spinner = ora(chalk.bold('Orquestrando contexto para geração do PROJECT_BRIEF...')).start();
  const targetDir = process.cwd();

  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);
  const devosRootDir = path.resolve(__dirname, '..', '..', '..');
  const templatePath = path.join(devosRootDir, 'templates', 'prompts', 'GENERATE_PROJECT_BRIEF.md');

  if (!fs.existsSync(templatePath)) {
    spinner.fail(chalk.red('Template GENERATE_PROJECT_BRIEF.md não encontrado!'));
    process.exit(1);
  }

  try {
    const templateContent = fs.readFileSync(templatePath, 'utf8');

    const payload = `
${templateContent}

---

# Informações Adicionais
Diretório atual: ${targetDir}
`.trim();

    const outDir = path.join(targetDir, '.devos', 'out');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outFile = path.join(outDir, 'prompt_brief.md');
    fs.writeFileSync(outFile, payload, 'utf8');

    const copied = await copyToClipboard(payload);

    spinner.succeed(chalk.green('Payload do PROJECT_BRIEF orquestrado com sucesso!'));

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
