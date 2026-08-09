import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

export interface WorkspaceConfig {
  projects: string[];
  lastSelected?: string;
}

export function getGlobalDevosDir(): string {
  return path.join(os.homedir(), '.devos');
}

export function getWorkspaceConfigPath(): string {
  return path.join(getGlobalDevosDir(), 'workspace.json');
}

export function loadWorkspaceConfig(): WorkspaceConfig {
  const configPath = getWorkspaceConfigPath();
  if (!fs.existsSync(configPath)) {
    return { projects: [] };
  }
  try {
    const data = fs.readFileSync(configPath, 'utf8');
    return JSON.parse(data) as WorkspaceConfig;
  } catch {
    return { projects: [] };
  }
}

export function registerProjectInWorkspace(projectPath: string): void {
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
