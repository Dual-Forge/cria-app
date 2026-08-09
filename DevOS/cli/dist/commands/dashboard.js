import net from 'node:net';
import path from 'node:path';
import { spawn } from 'node:child_process';
import chalk from 'chalk';
import ora from 'ora';
import open from 'open';
import { registerProjectInWorkspace } from '../lib/workspace.js';
async function findAvailablePort(startPort) {
    let port = startPort;
    while (port < startPort + 100) {
        const available = await new Promise((resolve) => {
            const server = net.createServer();
            server.once('error', () => resolve(false));
            server.once('listening', () => {
                server.close(() => resolve(true));
            });
            server.listen(port);
        });
        if (available)
            return port;
        port++;
    }
    return startPort;
}
import { fileURLToPath } from 'node:url';
export async function dashboardCommand(options) {
    const projectDir = process.cwd();
    registerProjectInWorkspace(projectDir);
    const initialPort = options.port ? parseInt(options.port, 10) : 3000;
    const port = await findAvailablePort(initialPort);
    if (port !== initialPort && !options.port) {
        console.log(chalk.yellow(`[DevOS Port Fallback] Porta ${initialPort} em uso. Alternando silenciosamente para a porta ${port}.`));
    }
    const spinner = ora(chalk.bold(`Iniciando servidor local da Dashboard DevOS na porta ${port}...`)).start();
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const devosRootDir = path.resolve(__dirname, '..', '..', '..');
    const child = spawn('npx', ['next', 'dev', '-p', port.toString()], {
        cwd: devosRootDir,
        shell: true,
        stdio: 'ignore',
        env: {
            ...process.env,
            DEVOS_PROJECT_DIR: projectDir
        }
    });
    // Wait 3 seconds for server startup, then open browser
    setTimeout(async () => {
        const url = `http://localhost:${port}`;
        spinner.succeed(chalk.green(`Dashboard ativa em ${chalk.underline(url)}`));
        console.log(chalk.gray('Pressione Ctrl+C para encerrar o servidor.'));
        try {
            await open(url);
        }
        catch {
            // Ignored if browser fail to open in headless
        }
    }, 3500);
    child.on('error', (err) => {
        spinner.fail(chalk.red(`Erro ao iniciar servidor Next.js: ${err.message}`));
        process.exit(1);
    });
}
