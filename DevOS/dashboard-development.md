# Dashboard Development

## Overview
Desenvolvimento da Dashboard Web do DevOS 2.0. O objetivo é fornecer uma interface gráfica local e *Read-Only* para visualizar o catálogo de projetos, o status das tarefas, Sprints, métricas, painel de dívida técnica e explorador de documentação, sem depender de banco de dados.

## Project Type
WEB

## Success Criteria
- [ ] Renderizar arquivos `.md` e seus metadados instantaneamente na Dashboard.
- [ ] Interface visual padronizada utilizando `shadcn/ui` e TailwindCSS.
- [ ] Motor de cache/revalidação resiliente a edições rápidas no filesystem (`chokidar`).
- [ ] Tolerância a falhas na leitura de frontmatters (sem erros 500 caso o documento seja malformado).

## Tech Stack
- **Framework:** Next.js (App Router) - Para roteamento moderno e suporte nativo a componentes no servidor e API routes locais.
- **UI:** React + TailwindCSS + `shadcn/ui` - Para construção modular, técnica e acessível da interface.
- **Parsing:** `remark`, `remark-html`, `gray-matter` - Para decodificar a SSOT do DevOS 2.0.
- **Watchers:** `chokidar` (ou `fs.watch`) - Para atualizar a renderização em tempo real.
- **Ícones:** Lucide Icons.

## File Structure
```
/
├── .devos/
├── docs/
├── src/
│   ├── app/                 (App Router: pages, layouts, api routes)
│   ├── components/          (Componentes shadcn/ui e próprios)
│   ├── lib/                 (Utilitários de parser, remark, file watchers)
│   └── styles/              (Tailwind globais)
├── PROJECT_BRIEF.md
├── PROJECT_STATUS.md
├── PROJECT_TASKS.md
└── package.json
```

## Task Breakdown

### 1. Setup do Projeto
- **Agent:** `frontend-specialist`
- **Skills:** `app-builder`
- **Priority:** P0
- **Dependencies:** Nenhuma
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Repositório inicial vazio para o código frontend.
  - *Output:* Instalação do Next.js (App Router), TailwindCSS, TypeScript e inicialização do `shadcn/ui`.
  - *Verify:* `npm run dev` abre uma página em branco funcional.

### 2. Implementação do Core Parser (`src/lib/parser.ts`)
- **Agent:** `backend-specialist`
- **Skills:** `clean-code`
- **Priority:** P1
- **Dependencies:** 1
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Arquivos `PROJECT_*.md` e `workspace.json` simulados.
  - *Output:* Funções capazes de ler frontmatters (YAML) e processar Markdown em AST/HTML tolerante a erros.
  - *Verify:* Executar testes unitários nas funções de parser garantindo Graceful Degradation em arquivos corrompidos.

### 3. Sistema de Roteamento e Componentes Base
- **Agent:** `frontend-specialist`
- **Skills:** `app-builder`
- **Priority:** P1
- **Dependencies:** 1
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Padrões definidos no `DESIGN_SYSTEM.md`.
  - *Output:* Sidebar de navegação, Topbar com seletor de Workspace, e Layout Shell.
  - *Verify:* Navegação fluida entre rotas `/`, `/tasks`, `/docs` e `/debt`.

### 4. Overview Panel (Página Inicial)
- **Agent:** `frontend-specialist`
- **Skills:** `clean-code`
- **Priority:** P2
- **Dependencies:** 2, 3
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Dados providos pelo parser do `PROJECT_BRIEF.md` e `PROJECT_STATUS.md`.
  - *Output:* Dashboard consolidado mostrando metas, descrição e métricas estáticas do projeto atual.
  - *Verify:* Alterar manualmente o Markdown local e verificar reflexo visual (se necessário, através de refresh ou hot reload futuro).

### 5. Task Board (Kanban/Sprints)
- **Agent:** `frontend-specialist`
- **Skills:** `app-builder`
- **Priority:** P2
- **Dependencies:** 2, 3
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Parsing do `PROJECT_TASKS.md`.
  - *Output:* Interface visual tipo Kanban mapeando *To Do*, *In Progress* e *Done* em modo Read-Only.
  - *Verify:* Exibição correta das tarefas na interface.

### 6. Document Explorer
- **Agent:** `frontend-specialist`
- **Skills:** `clean-code`
- **Priority:** P2
- **Dependencies:** 2, 3
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Árvore do diretório `docs/`.
  - *Output:* Árvore lateral colapsável com renderizador de markdown rico (syntax highlighting, tabelas) na área principal.
  - *Verify:* Renderização da `ARCHITECTURE.md` via UI.

### 7. Tech Debt & Observability
- **Agent:** `frontend-specialist`
- **Skills:** `clean-code`
- **Priority:** P3
- **Dependencies:** 2, 3
- **INPUT→OUTPUT→VERIFY:** 
  - *Input:* Varredura de TODO/FIXME nos `.md`.
  - *Output:* Tabela consolidada com as pendências, listando o arquivo de origem, e status.
  - *Verify:* Aparição de TODOs inseridos nos documentos de testes.

## Phase X: Verification
- [ ] Lint: Executar `npm run lint` e checagem de TS.
- [ ] Build: Executar `npm run build`.
- [ ] Funcional: Interface carrega sem erros de hidratação.
- [ ] Resiliência: Garantir que apagar/quebrar o `PROJECT_BRIEF.md` no sistema de arquivos localiza o erro em um componente ErrorBoundary ao invés de derrubar o servidor.
