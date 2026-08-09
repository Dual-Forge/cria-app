# Dashboard Module Specifications

## Objetivo
Descrever o funcionamento técnico e visual da Dashboard Web Local do DevOS 2.0.

---

## Estrutura do Módulo

O código-fonte da Dashboard reside na raiz do projeto dentro de `src/` no padrão Next.js App Router:

- `src/app/layout.tsx`: Layout Shell global que engloba a aplicação com Sidebar e gerencia compatibilidade de Hydration (suprimindo avisos causados por extensões de navegador).
- `src/app/globals.css`: Variáveis globais baseadas no **Typographic Brutalism** (cantos pontiagudos `--radius: 0rem`, Dark Theme forçado e acento em Acid Green).
- `src/app/page.tsx`: Overview Panel. Consome dados estruturados da parser engine e apresenta status atual de sprints, atividades, progresso, bloqueios, decisões e documentações de forma unificada.
- `src/app/tasks/page.tsx`: Task Board Kanban. Lê e exibe o andamento de tarefas divididas pelas raias do `PROJECT_TASKS.md`.
- `src/app/docs/page.tsx`: Document Explorer. Renderiza em master-detail a árvore de documentação contida em `docs/`.
- `src/app/debt/page.tsx`: Tech Debt Panel. Scanner recursivo que compila ocorrências de TODO/FIXME nos arquivos locais.
- `src/components/layout/Sidebar.tsx`: Sidebar minimalista para navegação.
- `src/components/ui/`: Componentes atômicos e reutilizáveis do `shadcn/ui`.
- `src/lib/parser.ts`: Core Parser Engine tolerante a falhas (remark + gray-matter).

---

## Core Parser Engine (`src/lib/parser.ts`)

A parser engine possui as seguintes funções de leitura:
1. `getParsedDocument(relativePath)`: Converte arquivos Markdown em HTML de forma segura com suporte a Frontmatter YAML.
2. `getTasks()`: Varre `PROJECT_TASKS.md` estruturando as raias de Sprints por status.
3. `getDocsTree()`: Mapeia de forma recursiva a estrutura de diretórios e arquivos de `docs/`.
4. `getTechDebt()`: Analisa de forma recursiva ocorrências de strings críticas (TODO e FIXME) dentro dos arquivos Markdown.
5. `getStatusInfo()`: Realiza scanner estruturado de `PROJECT_STATUS.md` extraindo metadados, progresso de barras e decisões.
