import fs from 'node:fs';
import path from 'node:path';
import matter from 'gray-matter';

export interface DoctorIssue {
  type: 'error' | 'warning' | 'info';
  file: string;
  line?: number;
  message: string;
}

export interface DoctorReport {
  structureOk: boolean;
  issues: DoctorIssue[];
  checkedFilesCount: number;
  todoCount: number;
  fixmeCount: number;
  score: number;
}

export function runDoctorAudit(targetDir: string = process.cwd()): DoctorReport {
  const issues: DoctorIssue[] = [];
  let checkedFilesCount = 0;
  let todoCount = 0;
  let fixmeCount = 0;

  // 1. Structure check
  const requiredFiles = ['PROJECT_BRIEF.md', 'PROJECT_STATUS.md', 'PROJECT_TASKS.md'];
  let structureOk = true;

  for (const file of requiredFiles) {
    const fullPath = path.join(targetDir, file);
    if (!fs.existsSync(fullPath)) {
      issues.push({
        type: 'error',
        file,
        message: `Arquivo obrigatório ausente: ${file}`
      });
      structureOk = false;
    }
  }

  const docsDir = path.join(targetDir, 'docs');
  if (!fs.existsSync(docsDir)) {
    issues.push({
      type: 'warning',
      file: 'docs/',
      message: 'Diretório oficial de documentação (docs/) não encontrado'
    });
  }

  // 2. Scan Markdown files recursively for frontmatter and TODOs/FIXMEs
  function scanFiles(currentDir: string) {
    if (!fs.existsSync(currentDir)) return;
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory()) {
        if (entry.name === 'node_modules' || entry.name === '.next' || entry.name === '.git' || entry.name === 'dist') {
          continue;
        }
        scanFiles(path.join(currentDir, entry.name));
      } else if (entry.isFile() && entry.name.endsWith('.md')) {
        checkedFilesCount++;
        const filePath = path.join(currentDir, entry.name);
        const relPath = path.relative(targetDir, filePath);
        
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          
          // Test gray-matter parsing
          try {
            matter(content);
          } catch (e: any) {
            issues.push({
              type: 'error',
              file: relPath,
              message: `Erro de frontmatter YAML: ${e.message}`
            });
          }

          // Scan lines for TODOs / FIXMEs
          const lines = content.split('\n');
          lines.forEach((line, idx) => {
            if (line.includes('TODO')) {
              todoCount++;
              issues.push({
                type: 'info',
                file: relPath,
                line: idx + 1,
                message: `Pendência [TODO]: ${line.trim().substring(0, 70)}`
              });
            }
            if (line.includes('FIXME')) {
              fixmeCount++;
              issues.push({
                type: 'warning',
                file: relPath,
                line: idx + 1,
                message: `Correção [FIXME]: ${line.trim().substring(0, 70)}`
              });
            }
          });
        } catch (err: any) {
          issues.push({
            type: 'error',
            file: relPath,
            message: `Falha de leitura no arquivo: ${err.message}`
          });
        }
      }
    }
  }

  scanFiles(targetDir);

  const errorCount = issues.filter(i => i.type === 'error').length;
  const warningCount = issues.filter(i => i.type === 'warning').length;

  // Calculate health score (0 to 100)
  let score = 100 - (errorCount * 25) - (warningCount * 5);
  if (score < 0) score = 0;

  return {
    structureOk,
    issues,
    checkedFilesCount,
    todoCount,
    fixmeCount,
    score
  };
}
