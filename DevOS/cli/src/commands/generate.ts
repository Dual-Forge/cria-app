import fs from 'node:fs';
import path from 'node:path';
import chalk from 'chalk';
import ora from 'ora';
import { copyToClipboard } from '../lib/clipboard.js';

export async function generateCommand() {
  const spinner = ora(chalk.bold('Orquestrando contexto para geração de documentação...')).start();
  const targetDir = process.cwd();

  const briefPath = path.join(targetDir, 'PROJECT_BRIEF.md');
  if (!fs.existsSync(briefPath)) {
    spinner.fail(chalk.red('PROJECT_BRIEF.md não encontrado na raiz do projeto! Execute `devos init` primeiro.'));
    process.exit(1);
  }

  try {
    const briefContent = fs.readFileSync(briefPath, 'utf8');

    const payload = `
# GENERATE_DOCUMENTATION

## Objetivo
Sua responsabilidade é gerar toda a documentação técnica e funcional do projeto utilizando exclusivamente o conteúdo presente em PROJECT_BRIEF.md.

---

# Conteúdo do PROJECT_BRIEF.md

${briefContent}

---

# Instruções de Saída
Por favor, processe a documentação técnica e crie os arquivos Markdown correspondentes no diretório docs/.
`.trim();

    // Export to temporary output file in .devos/out/
    const outDir = path.join(targetDir, '.devos', 'out');
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outFile = path.join(outDir, 'prompt_generate.md');
    fs.writeFileSync(outFile, payload, 'utf8');

    // Copy to clipboard
    const copied = await copyToClipboard(payload);

    spinner.succeed(chalk.green('Payload de Contexto Orquestrado com Sucesso!'));

    console.log('\n' + chalk.bold('Resultado:'));
    if (copied) {
      console.log(chalk.cyan('  📋 Conteúdo copiado para a Área de Transferência (Clipboard)!'));
    } else {
      console.log(chalk.yellow('  ⚠ Não foi possível acessar o Clipboard nativamente.'));
    }
    console.log(chalk.gray(`  📁 Arquivo gerado em: ${path.relative(targetDir, outFile)}`));
    console.log('\n' + chalk.bold('Próximo Passo:'));
    console.log(chalk.white('  Cole o conteúdo na sua IA de preferência (ChatGPT, Claude, Cursor, AG Kit) para gerar os documentos.'));
  } catch (error: any) {
    spinner.fail(chalk.red(`Falha ao empacotar contexto: ${error.message}`));
    process.exit(1);
  }
}
