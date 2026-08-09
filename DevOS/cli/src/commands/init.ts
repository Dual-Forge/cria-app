import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import chalk from 'chalk';
import ora from 'ora';
import { registerProjectInWorkspace } from '../lib/workspace.js';

export async function initCommand(options: { path?: string }) {
  const targetDir = path.resolve(options.path || process.cwd());
  const spinner = ora(chalk.bold('Inicializando framework DevOS 2.0...')).start();

  try {
    // 1. Register project in global workspace
    registerProjectInWorkspace(targetDir);

    // 2. Create .devos directory
    const devosHiddenDir = path.join(targetDir, '.devos');
    if (!fs.existsSync(devosHiddenDir)) {
      fs.mkdirSync(devosHiddenDir, { recursive: true });
    }

    // 3. Create docs directory and copy templates
    const docsDir = path.join(targetDir, 'docs');
    if (!fs.existsSync(docsDir)) {
      fs.mkdirSync(docsDir, { recursive: true });
    }

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const devosRootDir = path.resolve(__dirname, '..', '..', '..');
    const templatesSrcDir = path.join(devosRootDir, 'templates', 'documents');

    let templatesCopied = 0;
    if (fs.existsSync(templatesSrcDir)) {
      const copyDir = (src: string, dest: string) => {
        const entries = fs.readdirSync(src, { withFileTypes: true });
        for (const entry of entries) {
          const srcPath = path.join(src, entry.name);
          const destPath = path.join(dest, entry.name);
          if (entry.isDirectory()) {
            if (!fs.existsSync(destPath)) {
              fs.mkdirSync(destPath, { recursive: true });
            }
            copyDir(srcPath, destPath);
          } else {
            if (!fs.existsSync(destPath)) {
              fs.copyFileSync(srcPath, destPath);
              templatesCopied++;
            }
          }
        }
      };
      copyDir(templatesSrcDir, docsDir);
    }

    // 4. Create base Markdown files if not existing
    const filesToCreate = [
      {
        name: 'PROJECT_BRIEF.md',
        content: `# PROJECT BRIEF: ${path.basename(targetDir)}\n\n## 1. VISÃO GERAL DO PROJETO\n\nDescreva a visão geral do projeto aqui.\n`
      },
      {
        name: 'PROJECT_STATUS.md',
        content: `# PROJECT STATUS\n\n## Informações Gerais\n\n### Projeto\n${path.basename(targetDir)}\n\n### Status Geral\n🟡 Planejamento\n\n---\n\n## Sprint Atual\nSprint 1 - Inicialização\n`
      },
      {
        name: 'PROJECT_TASKS.md',
        content: `# PROJECT TASKS\n\n## Sprints\n\n### Sprint 1 - Inicialização\n- [ ] **Configuração Inicial**: Inicializar estrutura DevOS 2.0.\n`
      }
    ];

    const created: string[] = [];
    const skipped: string[] = [];

    for (const f of filesToCreate) {
      const filePath = path.join(targetDir, f.name);
      if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, f.content, 'utf8');
        created.push(f.name);
      } else {
        skipped.push(f.name);
      }
    }

    spinner.succeed(chalk.green('DevOS 2.0 inicializado com sucesso!'));

    console.log('\n' + chalk.bold('Resumo da Operação:'));
    console.log(chalk.cyan(`  Projeto Registrado: ${targetDir}`));
    if (created.length > 0) {
      console.log(chalk.green(`  Arquivos Criados: ${created.join(', ')}`));
    }
    if (templatesCopied > 0) {
      console.log(chalk.green(`  Templates de Documentação Copiados: ${templatesCopied} arquivos em docs/`));
    }
    if (skipped.length > 0) {
      console.log(chalk.yellow(`  Arquivos Preservados (já existiam): ${skipped.join(', ')}`));
    }
    console.log('\n' + chalk.gray('Dica: Execute `devos doctor` para auditar o status do projeto.'));
  } catch (error: any) {
    spinner.fail(chalk.red(`Falha ao inicializar o DevOS: ${error.message}`));
    process.exit(1);
  }
}
