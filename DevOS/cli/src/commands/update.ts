import fs from 'node:fs';
import path from 'node:path';
import chalk from 'chalk';
import ora from 'ora';
import { copyToClipboard } from '../lib/clipboard.js';

export async function updateCommand() {
  const spinner = ora(chalk.bold('Orquestrando contexto para atualização de documentação...')).start();
  const targetDir = process.cwd();

  const files = ['PROJECT_BRIEF.md', 'PROJECT_STATUS.md', 'PROJECT_TASKS.md'];
  const contents: Record<string, string> = {};

  for (const f of files) {
    const fPath = path.join(targetDir, f);
    if (fs.existsSync(fPath)) {
      contents[f] = fs.readFileSync(fPath, 'utf8');
    } else {
      contents[f] = '(Arquivo ausente)';
    }
  }

  try {
    const payload = `
# UPDATE_DOCUMENTATION

## Objetivo
Sua responsabilidade é manter toda a documentação do projeto sincronizada com o estado atual da implementação.

---

# Estado Atual da Fonte de Verdade (SSOT)

## PROJECT_BRIEF.md
${contents['PROJECT_BRIEF.md']}

---

## PROJECT_STATUS.md
${contents['PROJECT_STATUS.md']}

---

## PROJECT_TASKS.md
${contents['PROJECT_TASKS.md']}

---

# Instruções de Atualização
Atualize os arquivos de documentação para refletir com precisão o estado atual do projeto.
`.trim();

    // Export to temporary output file in .devos/out/
    const outDir = path.join(targetDir, '.devos', 'out');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outFile = path.join(outDir, 'prompt_update.md');
    fs.writeFileSync(outFile, payload, 'utf8');

    // Copy to clipboard
    const copied = await copyToClipboard(payload);

    spinner.succeed(chalk.green('Payload de Atualização Orquestrado com Sucesso!'));

    console.log('\n' + chalk.bold('Resultado:'));
    if (copied) {
      console.log(chalk.cyan('  📋 Conteúdo copiado para a Área de Transferência (Clipboard)!'));
    } else {
      console.log(chalk.yellow('  ⚠ Não foi possível acessar o Clipboard nativamente.'));
    }
    console.log(chalk.gray(`  📁 Arquivo gerado em: ${path.relative(targetDir, outFile)}`));
    console.log('\n' + chalk.bold('Próximo Passo:'));
    console.log(chalk.white('  Cole o conteúdo na sua IA de preferência para atualizar a documentação.'));
  } catch (error: any) {
    spinner.fail(chalk.red(`Falha ao empacotar contexto: ${error.message}`));
    process.exit(1);
  }
}
