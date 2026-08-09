#!/usr/bin/env node
import { Command } from 'commander';
import { initCommand } from './commands/init.js';
import { doctorCommand } from './commands/doctor.js';
import { dashboardCommand } from './commands/dashboard.js';
import { generateCommand } from './commands/generate.js';
import { updateCommand } from './commands/update.js';
import { briefCommand } from './commands/brief.js';
import { importCommand } from './commands/import.js';
import { updateStatusCommand } from './commands/update-status.js';
import { updateTasksCommand } from './commands/update-tasks.js';
const program = new Command();
program
    .name('devos')
    .description('DevOS 2.0 CLI - AI-assisted development framework orchestrator')
    .version('2.0.0');
// 1. devos init
program
    .command('init')
    .description('Inicializa o framework DevOS 2.0 no diretório atual ou especificado')
    .option('-p, --path <path>', 'Caminho do diretório de destino')
    .action(initCommand);
// 2. create-devos
program
    .command('create-devos [name]')
    .description('Utilitário para criar um novo projeto DevOS do zero')
    .action(async (name, options) => {
    const targetPath = name ? `./${name}` : '.';
    await initCommand({ path: targetPath });
});
// 3. devos dashboard
program
    .command('dashboard')
    .description('Inicializa o servidor local da Dashboard e abre no navegador')
    .option('-p, --port <port>', 'Porta inicial do servidor (padrão 3000 com auto-fallback)')
    .action(dashboardCommand);
// 4. devos doctor
program
    .command('doctor')
    .description('Executa diagnóstico de integridade, frontmatter e pendências')
    .option('--ci', 'Retorna código de erro (exit code 1) se falhas forem encontradas')
    .action(doctorCommand);
// 5. devos generate
program
    .command('generate')
    .description('Orquestra o contexto do PROJECT_BRIEF e envia para a área de transferência')
    .action(generateCommand);
// 6. devos update
program
    .command('update')
    .description('Orquestra o contexto para atualização da documentação e envia para o clipboard')
    .action(updateCommand);
// 7. devos brief
program
    .command('brief')
    .description('Orquestra o prompt GENERATE_PROJECT_BRIEF e copia para o clipboard')
    .action(briefCommand);
// 8. devos import
program
    .command('import')
    .description('Orquestra o prompt IMPORT_PROJECT com a estrutura de arquivos e envia para o clipboard')
    .action(importCommand);
// 9. devos update-status
program
    .command('update-status')
    .description('Orquestra o prompt UPDATE_PROJECT_STATUS e copia para o clipboard')
    .action(updateStatusCommand);
// 10. devos update-tasks
program
    .command('update-tasks')
    .description('Orquestra o prompt UPDATE_PROJECT_TASKS e copia para o clipboard')
    .action(updateTasksCommand);
program.parse(process.argv);
