import chalk from 'chalk';
import ora from 'ora';
import { runDoctorAudit } from '../lib/doctor-engine.js';
export async function doctorCommand(options) {
    const spinner = ora(chalk.bold('Executando devos doctor...')).start();
    const startTime = Date.now();
    const report = runDoctorAudit(process.cwd());
    const elapsedSeconds = ((Date.now() - startTime) / 1000).toFixed(2);
    spinner.stop();
    console.log('\n' + chalk.bold.underline('🩺 DevOS Doctor Diagnostic Report') + chalk.gray(` (${elapsedSeconds}s)\n`));
    console.log(chalk.bold('Métricas do Projeto:'));
    console.log(`  • Score de Integridade: ${report.score >= 80 ? chalk.green.bold(report.score + '/100') : chalk.yellow.bold(report.score + '/100')}`);
    console.log(`  • Arquivos Markdown Analisados: ${chalk.cyan(report.checkedFilesCount)}`);
    console.log(`  • Pendências Encontradas: ${chalk.yellow(report.todoCount + ' TODOs')}, ${chalk.red(report.fixmeCount + ' FIXMEs')}\n`);
    if (report.issues.length === 0) {
        console.log(chalk.green.bold('✨ Nenhum erro ou aviso encontrado! O projeto está 100% íntegro.\n'));
    }
    else {
        console.log(chalk.bold('Ocorrências Encontradas:'));
        for (const issue of report.issues) {
            const loc = issue.line ? `:${issue.line}` : '';
            if (issue.type === 'error') {
                console.log(`  ${chalk.red('✖ ERROR')}   ${chalk.bold(issue.file + loc)} - ${issue.message}`);
            }
            else if (issue.type === 'warning') {
                console.log(`  ${chalk.yellow('⚠ WARN')}    ${chalk.bold(issue.file + loc)} - ${issue.message}`);
            }
            else {
                console.log(`  ${chalk.blue('ℹ INFO')}    ${chalk.bold(issue.file + loc)} - ${issue.message}`);
            }
        }
        console.log('');
    }
    const errorsCount = report.issues.filter(i => i.type === 'error').length;
    if (options.ci && errorsCount > 0) {
        console.log(chalk.red.bold(`[CI/CD Mode] Interrompendo execução por conter ${errorsCount} erro(s).`));
        process.exit(1);
    }
}
