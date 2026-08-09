import fs from 'fs/promises';
import path from 'path';
import matter from 'gray-matter';
import { remark } from 'remark';
import html from 'remark-html';

export type ParsedDocument = {
  contentHtml: string;
  metadata: Record<string, any>;
  error?: string;
  filePath: string;
};

function getTargetDir(): string {
  return process.env.DEVOS_PROJECT_DIR || process.cwd();
}

export async function getParsedDocument(relativePath: string): Promise<ParsedDocument> {
  const fullPath = path.join(getTargetDir(), relativePath);
  try {
    const fileContents = await fs.readFile(fullPath, 'utf8');
    let matterResult;
    try {
      matterResult = matter(fileContents);
    } catch (e: any) {
      return {
        contentHtml: `<pre><code>${fileContents.replace(/</g, '&lt;')}</code></pre>`,
        metadata: {},
        error: `Erro de Frontmatter ou Estrutura Markdown: ${e.message}`,
        filePath: relativePath
      };
    }
    const processedContent = await remark().use(html).process(matterResult.content);
    return {
      contentHtml: processedContent.toString(),
      metadata: matterResult.data,
      filePath: relativePath
    };
  } catch (error: any) {
    return {
      contentHtml: '',
      metadata: {},
      error: `Erro ao ler o arquivo: ${error.message}`,
      filePath: relativePath
    };
  }
}

export type Task = { id: string, name: string, status: 'To Do' | 'In Progress' | 'Done', sprint: string };

export async function getTasks(): Promise<Record<string, Task[]>> {
  const fullPath = path.join(getTargetDir(), 'PROJECT_TASKS.md');
  const sprints: Record<string, Task[]> = {};
  let currentSprint = '';
  try {
    const fileContents = await fs.readFile(fullPath, 'utf8');
    const lines = fileContents.split('\n');
    let idCounter = 1;
    for (const line of lines) {
      const sprintMatch = line.match(/^### (Sprint .*)/);
      if (sprintMatch) {
        currentSprint = sprintMatch[1];
        sprints[currentSprint] = [];
      }
      const taskMatch = line.match(/^- \[(.)\] \((.*?)\) \*\*(.*?)\*\*: (.*)/);
      if (taskMatch && currentSprint) {
        const marker = taskMatch[1];
        let status: 'To Do' | 'In Progress' | 'Done' = 'To Do';
        if (marker.toLowerCase() === 'x' || taskMatch[2] === 'Done') status = 'Done';
        else if (marker === '/' || taskMatch[2] === 'In Progress') status = 'In Progress';
        sprints[currentSprint].push({
          id: `T${idCounter++}`,
          name: `${taskMatch[3]}: ${taskMatch[4]}`,
          status,
          sprint: currentSprint
        });
      }
    }
  } catch (e) {}
  return sprints;
}

export type DocNode = { name: string, path: string, isDir: boolean, children?: DocNode[] };

export async function getDocsTree(dirPath = 'docs'): Promise<DocNode[]> {
  const fullPath = path.join(getTargetDir(), dirPath);
  const nodes: DocNode[] = [];
  try {
    const entries = await fs.readdir(fullPath);
    for (const entry of entries) {
      const entryPath = path.join(fullPath, entry);
      const stats = await fs.stat(entryPath);
      if (stats.isDirectory()) {
        const children = await getDocsTree(path.join(dirPath, entry));
        nodes.push({ name: entry, path: path.join(dirPath, entry).replace(/\\/g, '/'), isDir: true, children });
      } else if (entry.endsWith('.md')) {
        nodes.push({ name: entry.replace('.md', ''), path: path.join(dirPath, entry).replace(/\\/g, '/'), isDir: false });
      }
    }
  } catch (e) {}
  return nodes;
}

export type TechDebt = { file: string, type: 'TODO' | 'FIXME', line: number, text: string };

export async function getTechDebt(): Promise<TechDebt[]> {
  const debts: TechDebt[] = [];
  async function scanDir(dirPath: string) {
    const fullPath = path.join(getTargetDir(), dirPath);
    try {
      const entries = await fs.readdir(fullPath);
      for (const entry of entries) {
        if (entry === 'node_modules' || entry === '.next' || entry === '.git') continue;
        const entryPath = path.join(fullPath, entry);
        const stats = await fs.stat(entryPath);
        if (stats.isDirectory()) {
          await scanDir(path.join(dirPath, entry));
        } else if (entry.endsWith('.md')) {
          const content = await fs.readFile(entryPath, 'utf8');
          const lines = content.split('\n');
          lines.forEach((line, idx) => {
            const todoMatch = line.match(/TODO(.*)/);
            if (todoMatch) debts.push({ file: path.join(dirPath, entry).replace(/\\/g, '/'), type: 'TODO', line: idx + 1, text: todoMatch[1].substring(0, 80) });
            const fixmeMatch = line.match(/FIXME(.*)/);
            if (fixmeMatch) debts.push({ file: path.join(dirPath, entry).replace(/\\/g, '/'), type: 'FIXME', line: idx + 1, text: fixmeMatch[1].substring(0, 80) });
          });
        }
      }
    } catch (e) {}
  }
  await scanDir('');
  return debts;
}

// ─── PROJECT STATUS STRUCTURED PARSER ───────────────────────────────────────

export type ProgressItem = { label: string; value: number };

export type StatusInfo = {
  projectName: string;
  version: string;
  generalStatus: string;
  currentSprintTitle: string;
  currentSprintStatus: string;
  sprintObjective: string;
  lastActivity: string;
  lastActivityDate: string;
  nextActivity: string;
  blockers: string[];
  progress: ProgressItem[];
  recentDecisions: string[];
  modules: { name: string; status: string }[];
  nextRevision: string;
  observations: string[];
};

function parseProgressBar(bar: string): number {
  const filled = (bar.match(/█/g) || []).length;
  const total = filled + (bar.match(/░/g) || []).length;
  if (total === 0) return 0;
  return Math.round((filled / total) * 100);
}

/** Gets multi-line content after a heading until the next `---` or `#` */
function getSection(lines: string[], heading: string): string[] {
  const idx = lines.findIndex(l => l === `## ${heading}` || l === `# ${heading}`);
  if (idx === -1) return [];
  const result: string[] = [];
  for (let i = idx + 1; i < lines.length; i++) {
    if (lines[i] === '---' || lines[i].startsWith('# ')) break;
    result.push(lines[i]);
  }
  return result;
}

export async function getStatusInfo(): Promise<StatusInfo | null> {
  const fullPath = path.join(getTargetDir(), 'PROJECT_STATUS.md');
  try {
    const raw = await fs.readFile(fullPath, 'utf8');
    const lines = raw.split('\n').map(l => l.trim());

    const getFirst = (heading: string): string => {
      const section = getSection(lines, heading);
      return section.find(l => l !== '' && l !== '---') || '';
    };

    // ── Progress bars (label on one line, bar 1-2 lines later) ──
    const progress: ProgressItem[] = [];
    const progressStart = lines.findIndex(l => l === '# Progresso Geral');
    if (progressStart !== -1) {
      const section = getSection(lines, 'Progresso Geral');
      let i = 0;
      while (i < section.length) {
        const line = section[i];
        if (line && !line.match(/^[█░]/) && !line.startsWith('#')) {
          // Look ahead past blank lines for the bar
          let barIdx = i + 1;
          while (barIdx < section.length && section[barIdx] === '') barIdx++;
          if (barIdx < section.length && section[barIdx].match(/^[█░]/)) {
            progress.push({ label: line, value: parseProgressBar(section[barIdx]) });
            i = barIdx + 1;
            continue;
          }
        }
        i++;
      }
    }

    // ── Sprint Atual: title + objective ──
    const sprintSection = getSection(lines, 'Sprint Atual');
    const sprintRaw = sprintSection.find(l => l !== '') || '';
    // Bold markdown stripped
    const sprintClean = sprintRaw.replace(/\*\*/g, '');
    // Split "Sprint X — Title (Status)" extracting status in parens
    const sprintStatusMatch = sprintClean.match(/\(([^)]+)\)\s*$/);
    const currentSprintStatus = sprintStatusMatch ? sprintStatusMatch[1] : '';
    const currentSprintTitle = sprintClean.replace(/\s*\([^)]+\)\s*$/, '').trim();

    // Objective: first line starting with **Objetivo:**
    const objLine = sprintSection.find(l => l.startsWith('**Objetivo:**'));
    const sprintObjective = objLine ? objLine.replace(/^\*\*Objetivo:\*\*\s*/, '') : '';

    // ── Bloqueios: list of strings ──
    const blockSection = getSection(lines, 'Bloqueios');
    const blockers = blockSection
      .filter(l => l.startsWith('- '))
      .map(l => l.replace(/^- /, ''));
    if (blockers.length === 0) {
      const noneText = blockSection.find(l => l !== '');
      if (noneText && noneText !== 'Nenhum.') blockers.push(noneText);
    }

    // ── Last activity ──
    const lastActSection = getSection(lines, 'Última Atividade');
    const lastActivityDate = (lastActSection.find(l => l.startsWith('**Data:**')) || '').replace('**Data:**', '').trim();
    const lastActivity = (lastActSection.find(l => l.startsWith('**Atividade:**')) || '').replace('**Atividade:**', '').trim();

    // ── Next activity ──
    const nextActSection = getSection(lines, 'Próxima Atividade');
    const nextActivity = nextActSection.filter(l => l !== '').join(' ');

    // ── Recent decisions ──
    const recentDecisions = getSection(lines, 'Últimas Decisões')
      .filter(l => l.startsWith('- '))
      .map(l => l.replace(/^- /, ''));

    // ── Modules table ──
    const modules: { name: string; status: string }[] = [];
    for (const l of getSection(lines, 'Módulos')) {
      const match = l.match(/^\|(.+)\|(.+)\|$/);
      if (match) {
        const name = match[1].trim();
        const status = match[2].trim();
        if (name !== 'Módulo' && !name.startsWith('-')) modules.push({ name, status });
      }
    }

    // ── Next revision ──
    const nextRevision = getSection(lines, 'Próxima Revisão').find(l => l !== '') || '';

    // ── Observations ──
    const observations = getSection(lines, 'Observações')
      .filter(l => l.startsWith('- '))
      .map(l => l.replace(/^- /, ''));

    return {
      projectName: getFirst('Projeto') || 'DevOS 2.0',
      version: getFirst('Versão Atual') || '',
      generalStatus: getFirst('Status Geral') || '',
      currentSprintTitle,
      currentSprintStatus,
      sprintObjective,
      lastActivity,
      lastActivityDate,
      nextActivity,
      blockers,
      progress,
      recentDecisions,
      modules,
      nextRevision,
      observations,
    };
  } catch {
    return null;
  }
}


