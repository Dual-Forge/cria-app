# IMPORT PROJECT

## Objetivo

Sua função é transformar um projeto já existente em um projeto compatível com o DevOS.

O projeto já possui código-fonte desenvolvido.

Seu objetivo NÃO é modificar o código.

Seu objetivo é compreender completamente o projeto e gerar um PROJECT_BRIEF.md seguindo o padrão oficial do DevOS.

Após a aprovação do PROJECT_BRIEF pelo usuário, toda a documentação será gerada utilizando o generate_docs.md.

---

# Regras Obrigatórias

Após gerar o PROJECT_BRIEF e a documentação, grave todos os documentos na estrutura oficial do projeto.

Utilize os arquivos da pasta .devos apenas como referência.

Nunca gere documentação dentro da pasta .devos.

Leia completamente o projeto antes de escrever qualquer documento.

Nunca invente informações.

Caso alguma informação não possa ser inferida, utilize TODO.

Nunca altere código.

Nunca reorganize arquivos.

Nunca implemente melhorias.

Nunca faça refatorações.

Seu único objetivo é compreender o projeto.

---

# Ordem de Análise

Siga exatamente esta sequência.

## 1. Estrutura do Projeto

Identifique:

- Framework
- Linguagem
- Organização das pastas
- Arquitetura
- Padrões utilizados

---

## 2. Tecnologias

Identifique toda a stack.

Frontend

Backend

Banco

ORM

Infraestrutura

Serviços externos

Bibliotecas principais

---

## 3. Banco de Dados

Identifique:

- entidades
- relacionamentos
- migrations
- estratégias
- padrões

---

## 4. Módulos

Identifique todos os módulos existentes.

Explique resumidamente a responsabilidade de cada um.

---

## 5. Funcionalidades

Liste todas as funcionalidades implementadas.

Agrupe por módulo.

---

## 6. Fluxos

Identifique os principais fluxos do sistema.

Exemplo:

Login

Cadastro

Pedidos

Relatórios

etc.

---

## 7. APIs

Identifique:

- endpoints
- autenticação
- integrações
- webhooks

---

## 8. Regras de Negócio

Extraia todas as regras de negócio identificáveis.

Nunca invente regras.

---

## 9. Arquitetura

Explique:

- padrão arquitetural
- camadas
- responsabilidades
- dependências

---

## 10. Segurança

Identifique:

- autenticação
- autorização
- armazenamento de dados
- uploads
- logs

---

## 11. UX

Identifique padrões visuais.

Design System.

Responsividade.

Componentes.

---

## 12. Código

Avalie:

- organização
- qualidade
- padrões
- consistência

---

## 13. Dívida Técnica

Liste possíveis dívidas técnicas encontradas.

---

## 14. Pendências

Liste tudo aquilo que não foi possível identificar.

Utilize TODO quando necessário.

---

# Geração do PROJECT_BRIEF

Após concluir toda a análise, gere um PROJECT_BRIEF.md completo utilizando o template oficial do DevOS.

Todo o conteúdo deverá possuir origem nas evidências encontradas durante a análise.

Nunca invente funcionalidades.

Nunca suponha regras de negócio.

Nunca complete informações ausentes.

---

# Resultado Esperado

Ao finalizar, o usuário deverá possuir um PROJECT_BRIEF.md completo e pronto para revisão.

Após a aprovação do usuário, o projeto poderá utilizar normalmente o fluxo oficial do DevOS através do generate_docs.md.

---

# Evidências e Estrutura do Projeto Atual

## Árvore de Diretórios (Estrutura de Pastas):
```
📄 AGENTS.md
📄 CLAUDE.md
📁 cli/
  📄 package-lock.json
  📄 package.json
  📁 src/
    📁 commands/
      📄 brief.ts
      📄 dashboard.ts
      📄 doctor.ts
      📄 generate.ts
      📄 import.ts
      📄 init.ts
      📄 update-status.ts
      📄 update-tasks.ts
      📄 update.ts
    📄 index.ts
    📁 lib/
      📄 clipboard.ts
      📄 doctor-engine.ts
      📄 workspace.ts
  📄 tsconfig.json
📄 components.json
📄 dashboard-development.md
📁 docs/
  📁 adr/
  📄 API_SPEC.md
  📄 ARCHITECTURE.md
  📄 BACKLOG.md
  📄 BUSINESS_RULES.md
  📄 CHANGELOG.md
  📄 CODE_STYLE.md
  📄 DATABASE.md
  📄 DESIGN_SYSTEM.md
  📄 DEVELOPMENT_GUIDE.md
  📄 ENVIRONMENT.md
  📄 ERROR_HANDLING.md
  📁 modules/
    📄 cli.md
    📄 dashboard.md
  📄 README.md
  📄 ROADMAP.md
  📁 runbooks/
  📄 SECURITY.md
  📄 TECH_DEBT.md
  📄 TECH_STACK.md
  📄 TESTING.md
  📄 UX_RULES.md
  📄 VISION.md
📄 eslint.config.mjs
📄 next-env.d.ts
📄 next.config.ts
📄 package-lock.json
📄 package.json
📄 postcss.config.mjs
📄 PROJECT_BRIEF.md
📄 PROJECT_STATUS.md
📄 PROJECT_TASKS.md
📁 public/
  📄 file.svg
  📄 globe.svg
  📄 next.svg
  📄 vercel.svg
  📄 window.svg
📄 README.md
📁 src/
  📁 app/
    📁 debt/
      📄 page.tsx
    📁 docs/
      📄 page.tsx
    📄 favicon.ico
    📄 globals.css
    📄 layout.tsx
    📄 page.tsx
    📁 tasks/
      📄 page.tsx
  📁 components/
    📁 layout/
      📄 Sidebar.tsx
    📁 overview/
      📄 BriefExpandable.tsx
    📁 ui/
      📄 badge.tsx
      📄 button.tsx
      📄 card.tsx
      📄 progress.tsx
      📄 scroll-area.tsx
      📄 separator.tsx
      📄 table.tsx
  📁 lib/
    📄 parser.ts
    📄 utils.ts
📁 templates/
  📁 documents/
    📄 API_SPEC_TEMPLATE.md
    📄 ARCHITECTURE_TEMPLATE.md
    📄 BACKLOG_TEMPLATE.md
    📄 BUSINESS_RULES_TEMPLATE.md
    📄 CHANGELOG_TEMPLATE.md
    📄 CODE_STYLE_TEMPLATE.md
    📄 DATABASE_TEMPLATE.md
    📄 DESIGN_SYSTEM_TEMPLATE.md
    📄 DEVELOPMENT_GUIDE_TEMPLATE.md
    📄 ENVIRONMENT_TEMPLATE.md
    📄 ERROR_HANDLING_TEMPLATE.md
    📄 PROJECT_BRIEF_TEMPLATE.md
    📄 PROJECT_STATUS_TEMPLATE.md
    📄 PROJECT_TASKS_TEMPLATE.md
    📄 README_TEMPLATE.md
    📄 ROADMAP_TEMPLATE.md
    📄 SECURITY_TEMPLATE.md
    📄 TECH_DEBT_TEMPLATE.md
    📄 TECH_STACK_TEMPLATE.md
    📄 TESTING_TEMPLATE.md
    📄 UX_RULES_TEMPLATE.md
    📄 VISION_TEMPLATE.md
  📁 prompts/
    📄 GENERATE_DOCUMENTATION.md
    📄 GENERATE_PROJECT_BRIEF.md
    📄 IMPORT_PROJECT_TEMPLATE.md
    📄 UPDATE_DOCUMENTATION.md
    📄 UPDATE_PROJECT_STATUS.md
    📄 UPDATE_PROJECT_TASKS.md
  📄 PROMPT_GENERATE_DOCUMENTATION.md
  📄 PROMPT_GENERATE_PROJECT_BRIEF.md
📄 tsconfig.json
📄 tsconfig.tsbuildinfo

```