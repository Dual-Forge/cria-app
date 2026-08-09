import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
export function getGlobalDevosDir() {
    return path.join(os.homedir(), '.devos');
}
export function getWorkspaceConfigPath() {
    return path.join(getGlobalDevosDir(), 'workspace.json');
}
export function loadWorkspaceConfig() {
    const configPath = getWorkspaceConfigPath();
    if (!fs.existsSync(configPath)) {
        return { projects: [] };
    }
    try {
        const data = fs.readFileSync(configPath, 'utf8');
        return JSON.parse(data);
    }
    catch {
        return { projects: [] };
    }
}
export function registerProjectInWorkspace(projectPath) {
    const devosDir = getGlobalDevosDir();
    if (!fs.existsSync(devosDir)) {
        fs.mkdirSync(devosDir, { recursive: true });
    }
    const absPath = path.resolve(projectPath);
    const config = loadWorkspaceConfig();
    if (!config.projects.includes(absPath)) {
        config.projects.push(absPath);
    }
    config.lastSelected = absPath;
    fs.writeFileSync(getWorkspaceConfigPath(), JSON.stringify(config, null, 2), 'utf8');
}
