# UPDATE_DOCUMENTATION

## Objetivo
Sua responsabilidade é manter toda a documentação do projeto sincronizada com o estado atual da implementação.

---

# Estado Atual da Fonte de Verdade (SSOT)

## PROJECT_BRIEF.md
# PROJECT BRIEF: DevOS 2.0

## 1. VISÃO GERAL DO PROJETO

### 1.1 Identificação do Projeto

* **Nome do Projeto:** DevOS 2.0
* **Natureza do Sistema:** Plataforma Ferramental de Desenvolvimento Assistido por Inteligência Artificial (CLI & Dashboard Local).
* **Fonte Única de Verdade (SSOT):** Sistema de arquivos local baseados em documentos Markdown (`PROJECT_BRIEF`, `PROJECT_STATUS`, `PROJECT_TASKS`, diretório `docs/`).

### 1.2 Descrição do Problema

O desenvolvimento de software assistido por Inteligência Artificial (IA) enfrenta problemas de perda de contexto entre sessões, falta de padronização arquitetural e dependência de ferramentas proprietárias. No modelo de desenvolvimento tradicional ou assistido por IAs isoladas, o conhecimento do projeto se fragmenta entre chats, ferramentas de gestão (Jira, Trello) e a memória dos desenvolvedores.

A versão 1.0 do DevOS resolveu a estruturação documental através de templates Markdown, agentes (AG Kit) e fluxos padronizados. Contudo, a operação do framework ainda exige intervenção manual intensiva para criação de estruturas, navegação em documentos, validação de consistência documental e execução de prompts de atualização.

### 1.3 Solução Proposta

O DevOS 2.0 evolui o framework de um conjunto estático de diretrizes e templates Markdown para uma **plataforma completa de desenvolvimento assistido por IA**. A solução introduz uma Interface de Linha de Comando (**CLI**) para automação e gestão do ciclo de vida dos projetos e uma aplicação Web (**Dashboard**) para visualização gráfica, consolidação de métricas e acompanhamento de status em tempo real.

A plataforma mantém os arquivos Markdown como a Fonte Única de Verdade (SSOT), eliminando a necessidade de bancos de dados no MVP e garantindo que o projeto permaneça interoperável, agnóstico de linguagem de programação e legível tanto por humanos quanto por qualquer modelo de IA.

---

## 2. OBJETIVOS E METAS

### 2.1 Objetivos Principais

* **Automação Operacional:** Eliminar a criação e manutenção manual de estruturas de diretórios, templates e metadados de documentação do framework DevOS.
* **Padronização Absoluta:** Forçar a aplicação consistente dos padrões do DevOS na inicialização de novos projetos ou na importação de sistemas existentes.
* **Centralização do Conhecimento:** Consolidar toda a regra de negócio, arquitetura, status e tarefas em uma estrutura documental unificada e padronizada.
* **Portabilidade de IA:** Permitir a alternância entre diferentes Modelos de Linguagem de Grande Escala (LLMs) — como ChatGPT, Claude, Gemini, Codex e AG Kit — sem perda de contexto operacional ou arquitetural.
* **Aceleração do Onboarding:** Reduzir o tempo de adaptação de novos desenvolvedores (humanos ou agentes sintéticos autônomos) através da leitura padronizada do estado do projeto.
* **Observabilidade de Engenharia:** Disponibilizar uma interface visual centralizada (Dashboard) para acompanhamento de métricas, roadmap, backlog e dívidas técnicas.

### 2.2 Metas de Sucesso (KPIs)

* Zero dependência de bancos de dados externos ou proprietários para o funcionamento da plataforma.
* Capacidade de inicializar e validar um projeto DevOS completo via CLI em tempo de execução inferior a 5 segundos.
* Interoperabilidade total com repositórios de código existentes, sem necessidade de alteração na stack tecnológica do software desenvolvido.

---

## 3. PERFIS DE USUÁRIOS E PERSONAS

### 3.1 Desenvolvedor de Software / Engenheiro de Software

* **Descrição:** Profissional técnico responsável pela escrita de código, arquitetura e implementação de funcionalidades.
* **Necessidades:** Interface de linha de comando rápida para validação de documentação (`doctor`), geração de pacotes de contexto para envio a IAs (`generate`/`update`) e visualização rápida do status das tarefas e sprints na Dashboard.

### 3.2 Tech Lead / Arquiteto de Software

* **Descrição:** Responsável pela garantia da qualidade técnica, padronização arquitetural e gestão da dívida técnica do projeto.
* **Necessidades:** Capacidade de auditar a consistência entre o código e a documentação oficial, monitorar métricas de evolução e gerenciar múltiplos repositórios e projetos simultaneamente.

### 3.3 Agente de Inteligência Artificial (LLM / AG Kit)

* **Descrição:** Sistema consumidor e gerador de código e documentação que interage com o projeto.
* **Necessidades:** Acesso a uma estrutura de arquivos previsível, padronizada e semanticamente rica (Markdown com frontmatter estruturado) que sirva como prompt de sistema e contexto de execução.

---

## 4. ESPECIFICAÇÃO DE MÓDULOS E FUNCIONALIDADES

### 4.1 Módulo CLI (Command Line Interface)

A CLI será o principal ponto de entrada operacional do DevOS 2.0, desenvolvida em Node.js e TypeScript.

#### 4.1.1 Comando: `create-devos`

* **Descrição:** Utilitário global para criação de novos projetos do zero com a estrutura DevOS integrada.
* **Comportamento:**
1. Solicita o nome do projeto e o diretório de destino.
2. Gera a estrutura de diretórios padrão (`.devos/`, `docs/`, `src/`).
3. Instala os templates iniciais (`PROJECT_BRIEF.md`, `PROJECT_STATUS.md`, `PROJECT_TASKS.md`).
4. Inicializa um repositório Git local.



#### 4.1.2 Comando: `devos init`

* **Descrição:** Inicializa o framework DevOS em um projeto ou repositório já existente.
* **Comportamento:**
1. Analisa a raiz do diretório atual.
2. Cria o diretório de controle oculto `.devos/`.
3. Cria o diretório oficial de documentação `docs/` e os arquivos raiz de controle (`PROJECT_BRIEF`, `PROJECT_STATUS`, `PROJECT_TASKS`) sem sobrescrever arquivos existentes de mesmo nome.



#### 4.1.3 Comando: `devos dashboard`

* **Descrição:** Inicializa o servidor local integrado e abre a interface gráfica no navegador padrão do sistema.
* **Comportamento:**
1. Sobe uma instância de servidor local Node.js/Next.js embarcada na CLI (porta padrão `3000` ou fallback automático para porta disponível).
2. Conecta o servidor local ao sistema de arquivos do computador (`fs`) para leitura dos arquivos Markdown.
3. Dispara a abertura automática do navegador apontando para a interface da Dashboard.



#### 4.1.4 Comando: `devos doctor`

* **Descrição:** Ferramenta de diagnóstico, auditoria e análise de integridade do projeto DevOS.
* **Comportamento:**
1. **Verificação de Estrutura:** Valida a presença dos arquivos obrigatórios (`PROJECT_BRIEF`, `PROJECT_STATUS`, `PROJECT_TASKS`) e do diretório `docs/`.
2. **Análise Sintática:** Processa o Markdown e valida se o frontmatter (YAML/gray-matter) dos arquivos contém os metadados obrigatórios.
3. **Rastreamento de Pendências:** Varre todos os documentos do projeto em busca de marcadores `TODO`, `FIXME` e seções de "Pendências".
4. **Relatório de Consistência:** Exibe no terminal um relatório de saúde do projeto, apontando arquivos órfãos, links internos quebrados e métricas de completude da documentação.



#### 4.1.5 Comando: `devos generate`

* **Descrição:** Orquestrador de contexto para criação de documentação inicial ou estrutural baseada no `PROJECT_BRIEF`.
* **Comportamento:**
1. Lê o arquivo `PROJECT_BRIEF.md` do projeto atual.
2. Carrega os templates de documentação e prompts oficiais do DevOS armazenados em `.devos/`.
3. **Modo Orquestrador:** Empacota o contexto lido e o template de instrução em um payload otimizado e o disponibiliza via Clipboard (área de transferência) ou exporta para um arquivo temporário de prompt (`.devos/out/prompt_generate.md`).
4. Informa ao usuário as instruções para colar o pacote de contexto na sua IA de preferência (ChatGPT, Claude, Gemini, Cursor, Windsurf ou AG Kit) para gerar os documentos técnicos na pasta `docs/`.



#### 4.1.6 Comando: `devos update`

* **Descrição:** Orquestrador de contexto para atualização contínua de documentação baseada nas alterações recentes de código ou status.
* **Comportamento:**
1. Identifica o escopo da atualização solicitada (ex: atualização de `PROJECT_STATUS` ou `PROJECT_TASKS`).
2. Varre os arquivos modificados recentemente ou recebe inputs via argumentos da CLI.
3. **Modo Orquestrador:** Gera um prompt estruturado contendo o estado atual do documento e as novas variáveis a serem processadas pela IA, copiando o resultado para o Clipboard ou exportando em `.devos/out/prompt_update.md`.



---

### 4.2 Módulo Dashboard (Aplicação Web Local)

A Dashboard é uma aplicação Next.js/React de leitura estrita (Read-Only no MVP), operando com suporte a **Workspace/Catálogo de Projetos**.

#### 4.2.1 Gestão de Workspace e Catálogo de Projetos

* **Funcionalidade:** A interface não se restringe a visualizar apenas um projeto isolado. Ela atua como uma central de controle onde o desenvolvedor pode gerenciar múltiplos repositórios locais.
* **Mecanismo de Persistência:** A CLI mantem um arquivo de configuração global no sistema operacional do usuário (ex: `~/.devos/workspace.json`), armazenando a lista de caminhos absolutos dos projetos registrados no computador.
* **Alternância Rápida:** A barra superior da Dashboard apresenta um seletor de projetos, permitindo alternar instantaneamente o contexto de visualização entre diferentes repositórios registrados no Workspace sem necessidade de reiniciar o terminal.

#### 4.2.2 Visão Geral do Projeto (Overview)

* **Funcionalidade:** Painel de consolidação com metadados extraídos do `PROJECT_BRIEF` e `PROJECT_STATUS`.
* **Elementos Exibidos:** Nome do projeto, descrição executiva, objetivos principais, stack tecnológica mapeada e status global da aplicação (ex: Planejamento, Em Desenvolvimento, Homologação, Produção).

#### 4.2.3 Acompanhamento de Execução (Roadmap, Backlog e Sprints)

* **Funcionalidade:** Leitura e processamento visual dos arquivos `PROJECT_TASKS.md` e `PROJECT_STATUS.md`.
* **Elementos Exibidos:**
* **Roadmap:** Linha do tempo ou visão em marcos (Milestones) das entregas futuras.
* **Backlog:** Listagem completa de funcionalidades mapeadas e não iniciadas.
* **Sprint Atual:** Painel destacando as tarefas ativas na iteração corrente, categorizadas por status (*To Do*, *In Progress*, *Done*).
* **Próxima Tarefa:** Alerta visual indicando a tarefa prioritária imediata para início de desenvolvimento.



#### 4.2.4 Explorador e Visualizador de Documentação

* **Funcionalidade:** Navegador interativo da árvore de diretórios `docs/`.
* **Elementos Exibidos:** Renderização visual rica dos arquivos Markdown, com suporte a realce de sintaxe para blocos de código, tabelas formatadas, navegação por índice (TOC - Table of Contents) interno de cada documento e busca textual por títulos ou conteúdo.

#### 4.2.5 Painel de Dívida Técnica e Pendências

* **Funcionalidade:** Consolidação dos dados extraídos pelo analisador sintático (mesma engine do `devos doctor`).
* **Elementos Exibidos:** Listagem centralizada de todos os itens marcados como `TODO`, `FIXME` e blocos de "Pendências" encontrados nos arquivos Markdown do projeto, permitindo filtragem por severidade ou arquivo de origem.

#### 4.2.6 Histórico de Alterações e Métricas do Projeto

* **Funcionalidade:** Monitoramento da saúde e evolução do ecossistema DevOS do projeto.
* **Elementos Exibidos:**
* **Últimas Alterações:** Registro cronológico das últimas modificações realizadas nos arquivos de documentação e status.
* **Métricas do Projeto:** Quantidade total de documentos produzidos, taxa de completude de tarefas, proporção de documentação vs. código (quando aplicável via contagem de arquivos) e índice de resolutividade de `TODOs`.



---

## 5. ARQUITETURA E TECNOLOGIAS

### 5.1 Separação Arquitetural de Responsabilidades

A arquitetura do sistema impõe um desacoplamento estrito entre as ferramentas do framework e o código-fonte da aplicação que está sendo desenvolvida pelo usuário:

```
[ Sistema Operacional / Global ]
  ├── CLI (devos)
  └── ~/.devos/workspace.json (Catálogo Global de Projetos)

[ Repositório do Projeto do Usuário ]
  ├── .devos/                 <-- [FRAMEWORK] Templates, scripts e engine interna do DevOS
  ├── docs/                   <-- [PROJETO] Documentação técnica detalhada
  ├── PROJECT_BRIEF.md        <-- [PROJETO] Fonte única de verdade (Especificação)
  ├── PROJECT_STATUS.md       <-- [PROJETO] Estado atual e métricas
  ├── PROJECT_TASKS.md        <-- [PROJETO] Backlog, Sprints e tarefas
  └── src/ (ou similar)       <-- [PROJETO] Código-fonte da aplicação de negócio

```

### 5.2 Stack Tecnológica Definida

#### 5.2.1 Frontend / Dashboard

* **Framework Web:** Next.js (com roteamento App Router ou Pages Router, executando em modo de servidor local embarcado).
* **Biblioteca de Interface:** React.
* **Estilização:** TailwindCSS (para design responsivo, suporte a tema escuro/claro e performance de renderização).
* **Linguagem:** TypeScript.
* **Ícones e Componentes:** Biblioteca padrão compatível com Tailwind (ex: Lucide Icons).

#### 5.2.2 Backend Local / CLI

* **Runtime:** Node.js.
* **Linguagem:** TypeScript.
* **Biblioteca de CLI:** Framework para roteamento de comandos de terminal (ex: Commander.js ou Yargs).
* **Manipulação de Sistema de Arquivos:** Módulo nativo `fs` / `fs/promises` do Node.js.
* **Abertura de Browser:** Biblioteca multiplataforma para execução de URLs em navegadores (ex: `open`).

#### 5.2.3 Processamento de Markdown e Metadados (Parser Engine)

* **AST Markdown Parser:** `remark` (ecossistema unifed para análise de sintaxe abstrata de Markdown, transformação e validação estrutural).
* **Leitor de Frontmatter:** `gray-matter` (extração de metadados YAML/JSON localizados no cabeçalho dos arquivos `.md`).

### 5.3 Decisões Arquiteturais e Justificativas

* **Ausência de Banco de Dados no MVP:** A decisão de não utilizar SQLite, Mongo ou qualquer outro banco no MVP garante que o projeto permaneça portátil, simples de inspecionar através de qualquer IDE e elimine riscos de corrupção ou dessincronização de estado. O sistema de arquivos é o único banco de dados.
* **Padrão Orquestrador de IA (Sem chamadas API diretas no CLI MVP):** Em vez de exigir chaves de API (`OPENAI_API_KEY`, etc.) e gerenciar custos de billing dentro do CLI no MVP, o DevOS atuará como um **Orquestrador de Contexto**. Ele pré-processa os templates, estrutura o prompt exato e prepara o payload para o desenvolvedor aplicar no seu ambiente de IA preferido (AG Kit no terminal, Cursor, Claude Web, etc.). Isso reduz a complexidade de rede e segurança da CLI no MVP e mantém compatibilidade universal.
* **Servidor Embedded vs. File System API Pura:** A Dashboard será servida através de um servidor Node.js/Next.js local iniciado pelo comando `devos dashboard`. Essa decisão elimina restrições rigorosas de segurança de navegadores modernas (como as da *File System Access API* em páginas estáticas) e provê uma experiência de CLI nativa e fluida sem requerer upload manual de pastas por parte do usuário.

---

## 6. REGRAS DE NEGÓCIO E DIRETRIZES DE SISTEMA

1. **Inviolabilidade da Fonte Única de Verdade (SSOT):** A Dashboard não possui permissão de escrita, alteração, criação ou deleção de arquivos no MVP. Ela opera em modo estritamente *Read-Only*. Qualquer alteração no estado do projeto deve ser realizada editando os arquivos Markdown (via IDE, via orquestração de IA ou futuramente pela CLI).
2. **Preservação de Fomato Universal:** É proibido criar extensões de arquivo proprietárias, esquemas binários ocultos ou estruturas que não sejam legíveis por editores de texto plano. Todo documento gerado ou consumido deve ser um Markdown válido (`.md`).
3. **Não-Substituição de Ferramentas Existentes:** O DevOS não atua como sistema de controle de versão (não substitui o Git/GitHub), não substitui rastreadores de issues corporativos complexos (não compete com Jira em gestão corporativa multi-equipe) e não substitui IDEs. Ele atua como camada de organização de contexto e padronização de conhecimento.
4. **Resiliência a Falhas Documentais:** Se a Dashboard ou o CLI (`doctor`) encontrarem um arquivo Markdown malformado ou com frontmatter inválido, o sistema não deve falhar criticamente (crash). Deve isolar o arquivo defeituoso, emitir um alerta visual na Dashboard/Terminal e continuar processando o restante do Workspace.
5. **Legibilidade Híbrida (Humano + IA):** Toda documentação gerada pelo DevOS deve manter uma estrutura clara para leitura humana (títulos bem definidos, listas, tabelas) e, simultaneamente, conter marcações semânticas precisas (frontmatters e cabeçalhos fixos) para otimizar o consumo por LLMs via técnicas de *Retrieval-Augmented Generation* (RAG) ou injeção direta em janela de contexto.

---

## 7. ESCOPO DO MVP E ROADMAP DE EVOLUÇÃO

### 7.1 Escopo do MVP (DevOS 2.0)

* Implementação integral da CLI com os comandos: `create-devos`, `devos init`, `devos dashboard`, `devos doctor`, `devos generate` e `devos update`.
* CLI operando em modo de **Orquestração de Contexto** para IA (geração de payloads otimizados para Clipboard/arquivos de saída sem integração de API de rede própria no terminal).
* Implementação da Dashboard Web Local (Next.js/React/Tailwind) servida localmente.
* Dashboard operando em modo estritamente **Read-Only** (leitura e visualização gráfica dos arquivos Markdown).
* Suporte a camada de **Workspace/Catálogo de Projetos**, permitindo registrar e alternar entre múltiplos repositórios locais via arquivo de configuração (`~/.devos/workspace.json`).
* Engine de parser de Markdown (`remark` + `gray-matter`) para processamento de metadados, identificação de TODOs, métricas de completude e status do projeto.

### 7.2 Roadmap de Evolução Futura

#### DevOS 2.1 (Pós-MVP Imediato)

* Suporte a chamadas diretas de API na CLI (`devos generate --auto`) mediante configuração de chaves (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.).
* Capacidade de edição visual básica na Dashboard (modo de escrita controlado para alteração de status de tarefas no `PROJECT_TASKS.md`).

#### DevOS 3.0 (Visão de Futuro)

* **Orquestração Completa e Agentes Autônomos:** Integração profunda com agentes de IA locais e remotos capazes de executar tarefas de desenvolvimento de forma autônoma.
* **Execução Automática de Tarefas:** Agentes lendo o `PROJECT_TASKS.md`, assumindo itens do Backlog, escrevendo código no repositório, rodando testes e gerando Pull Requests automaticamente, mantendo a documentação sincronizada sem intervenção humana.
* **Sincronização Bidirecional:** Atualização em tempo real de metadados entre a Dashboard, a CLI e os agentes atuantes em IDEs.

---

## 8. RESTRIÇÕES, DEPENDÊNCIAS E RISCOS

### 8.1 Restrições Técnicas

* **Sem Banco de Dados no MVP:** Proibida a adoção de bancos relacionais, NoSQL ou em memória persistente (como Redis ou SQLite) no ciclo da Versão 2.0.
* **Sem Formatos Proprietários:** Proibido o uso de arquivos de estado em formatos não-padrão. Todos os dados do projeto devem residir em `.md` ou arquivos JSON de configuração de sistema (`workspace.json`).
* **Ambiente de Execução:** Dependência obrigatória de ambiente Node.js (versão 18+ LTS recomendada) instalado na máquina do usuário para execução da CLI e subida do servidor da Dashboard.

### 8.2 Dependências Externas

* **Bibliotecas NPM:** Dependência da estabilidade e manutenção dos pacotes `next`, `react`, `tailwindcss`, `remark`, `gray-matter`, e bibliotecas de CLI no ecossistema Node.js.
* **Navegador do Sistema Operacional:** Dependência de um navegador Web funcional no sistema operacional host para renderização da Dashboard.
* **Ferramentas de IA Externas (No MVP):** Dependência da disponibilidade e capacidade de processamento de IAs de terceiros (Claude, ChatGPT, AG Kit, Cursor) acionadas pelo usuário a partir dos prompts gerados pelo orquestrador do DevOS.

### 8.3 Riscos Conhecidos e Mitigações

* **Risco de Concorrência de Leitura no Sistema de Arquivos:** Modificações rápidas e sucessivas nos arquivos `.md` por parte do usuário em sua IDE enquanto a Dashboard consome os mesmos arquivos.
* *Mitigação:* Implementação de rotinas de leitura assíncrona não-bloqueante na Dashboard, com *debouncing* na atualização e observação de eventos de sistema (`chokidar` ou `fs.watch`) para revalidação de cache em memória sem travamento de processos.


* **Risco de Inconsistência por Edição Manual Indisciplinada:** O usuário pode editar o Markdown quebrando a estrutura esperada pelo parser (ex: remover blocos YAML obrigatórios).
* *Mitigação:* O comando `devos doctor` atua como camada de verificação contínua, indicando o erro estrutural exato, linha e coluna, orientando a correção antes que falhas de parsing afetem as métricas da Dashboard.


* **Risco de Estouro de Contexto em Projetos de Longa Duração:** Projetos muito maduros podem acumular um volume de documentação em `docs/` que exceda a janela de contexto de algumas LLMs ao utilizar o `devos generate` ou `devos update`.
* *Mitigação:* A engine de orquestração da CLI deverá ser modular, empacotando apenas os resumos executivos (`PROJECT_BRIEF`, `PROJECT_STATUS`) e os documentos diretamente relevantes ao escopo da tarefa, em vez de anexar a íntegra de toda a pasta `docs/`.



---

## 9. PENDÊNCIAS

Abaixo estão listadas as definições e refinamentos operacionais que precisam ser respondidos nas próximas etapas de detalhamento técnico para o início da implementação do DevOS 2.0 sem ambiguidades:

1. **Definição de Porta e Fallback do Servidor Local:** Caso a porta padrão (`3000`) já esteja em uso no sistema do desenvolvedor ao executar `devos dashboard`, a CLI deve tentar subir automaticamente na próxima porta sequencial disponível (`3001`, `3002`, etc.) sem aviso bloqueante, ou deve solicitar confirmação interativa no terminal?
2. **Formato Exato de Comunicação Inter-Processos (CLI -> Clipboard):** Para o recurso de Clipboard nos comandos `devos generate` e `devos update`, devemos adotar bibliotecas multiplataforma nativas como `clipboardy` para garantir que a cópia para a área de transferência funcione de maneira idêntica em Windows, macOS e Linux (incluindo ambientes WSL2 sem interface gráfica nativa configurada)?
3. **Escopo de Observabilidade do `devos doctor` no CI/CD:** O comando `devos doctor` deverá possuir uma flag específica (ex: `devos doctor --ci`) para retornar códigos de saída de erro HTTP/POSIX (`exit code 1`) quando encontrar marcações de `TODO` ou inconsistências no frontmatter, permitindo bloquear Pull Requests em pipelines de Integração Contínua (GitHub Actions, GitLab CI)?
4. ~~**Padronização Visual da Dashboard (Theming):** A Dashboard deverá adotar um Design System específico em cima do TailwindCSS (como shadcn/ui, Radix UI ou Headless UI) para padronizar os componentes visuais, modais, tabelas e navegadores de diretório no MVP?~~ **Resolvido:** `shadcn/ui` adotado como padrão oficial. Estilo visual: Typographic Brutalism (Dark Theme, Acid Green, Sharp Geometry).
5. **Estrutura do Esquema de Frontmatter YAML:** Qual será o catálogo exato de campos obrigatórios e opcionais exigidos pela engine do `remark`/`gray-matter` no frontmatter dos arquivos na pasta `docs/` (ex: `title`, `status`, `author`, `last_updated`, `dependencies`, `tags`) para que o `devos doctor` valide o documento como 100% íntegro?

---

## PROJECT_STATUS.md
# PROJECT STATUS

> Este documento representa o estado atual do projeto.
>
> Ele deve ser atualizado sempre que houver progresso relevante.
>
> Seu objetivo é permitir que qualquer desenvolvedor ou IA compreenda rapidamente em que ponto o projeto se encontra.

---

# Informações Gerais

## Projeto

DevOS 2.0

## Versão Atual

v2.0.0 — DevOS 2.0 MVP (CLI + Dashboard)

## Status Geral

✅ Concluído (MVP 2.0)

---

# Sprint Atual

**Sprint 3 — CLI Foundation & Context Orchestration** (Concluída)

**Objetivo:** Implementar o módulo CLI (`@devos/cli`) em Node.js e TypeScript com Commander.js, adicionando os comandos `create-devos`, `devos init`, `devos doctor`, `devos dashboard` (com auto-fallback silencioso de porta), `devos generate` e `devos update` com cópia automática para o Clipboard.

---

# Progresso Geral

Documentação / Planejamento

██████████ 100%

Dashboard Web (MVP)

██████████ 100%

CLI (devos commands)

██████████ 100%

Integração CLI ↔ Dashboard

██████████ 100%

Testes

██████████ 100%

Deploy / Publicação de Pacote NPM

░░░░░░░░░░ 0%

---

# Última Atividade

**Data:** 2026-07-22

**Atividade:** UI/UX Overhaul completo da Dashboard. Reformulação visual para estética Brutalist Tech com Dark Theme, geometria Sharp (border-radius 0px), paleta Acid Green, correção do Hydration Error de extensões de navegador, fix de overflow em documentos Markdown longos e instalação do plugin `@tailwindcss/typography`.

---

# Próxima Atividade

Início da **Sprint 3 — CLI Foundation**: Implementação do core da CLI em Node.js/TypeScript com os comandos `create-devos`, `devos init`, `devos doctor` e `devos dashboard` (que iniciará o servidor Next.js embarcado).

---

# Bloqueios

Nenhum.

---

# Módulos

| Módulo | Status |
|--------|--------|
| Documentação do Projeto (`docs/`) | Concluído |
| Core Parser Engine (`src/lib/parser.ts`) | Concluído |
| Dashboard – Layout Shell & Roteamento | Concluído |
| Dashboard – Overview Panel (`/`) | Concluído |
| Dashboard – Task Board Kanban (`/tasks`) | Concluído |
| Dashboard – Document Explorer (`/docs`) | Concluído |
| Dashboard – Tech Debt Panel (`/debt`) | Concluído |
| Design System & UI/UX (Brutalist Theme) | Concluído |
| CLI Core (Commander.js) | Concluído |
| Comando `create-devos` | Concluído |
| Comando `devos init` | Concluído |
| Comando `devos doctor` | Concluído |
| Comando `devos dashboard` | Concluído |
| Comando `devos generate` | Concluído |
| Comando `devos update` | Concluído |
| Workspace Manager (`~/.devos/workspace.json`) | Concluído |

---

# Últimas Decisões

- **2026-07-22:** Adoção de **Next.js App Router** como roteador padrão da Dashboard (descartando Pages Router).
- **2026-07-22:** Adoção de **shadcn/ui** como biblioteca de componentes base da Dashboard.
- **2026-07-22:** Adoção do estilo visual **Typographic Brutalism** com Dark Theme forçado, Acid Green como cor de acento e border-radius = 0rem (Sharp Geometry) para toda a interface.
- **2026-07-22:** Instalação do `@tailwindcss/typography` para renderização segura e responsiva de Markdown rico.

---

# Próxima Revisão

Atualizar após conclusão da Sprint 3 (CLI Foundation).

---

# Observações

- A Dashboard pode ser iniciada manualmente via `npm run dev` dentro do diretório `DevOS/` enquanto a CLI não está implementada.
- O servidor roda na porta `3000` por padrão.
- O `suppressHydrationWarning` foi adicionado ao HTML raiz para resolver conflitos de extensões de navegador com o React SSR.


---

## PROJECT_TASKS.md
# PROJECT TASKS

Este arquivo centraliza o acompanhamento e status de desenvolvimento para a Dashboard (DevOS 2.0).
As tarefas listadas aqui correspondem ao plano `dashboard-development.md`.

## Sprints

### Sprint 1 - Dashboard Foundation
**Objetivo:** Setup do Next.js, shadcn/ui e do Core Parser de Markdown.

- [x] (Done) **Setup do Projeto**: Inicializar Next.js (App Router), TailwindCSS, TypeScript e shadcn/ui.
- [x] (Done) **Implementação do Core Parser**: Criar `src/lib/parser.ts` para ler frontmatters (YAML) via `gray-matter` e gerar AST HTML tolerante a erros.
- [x] (Done) **Sistema de Roteamento e Shell**: Construir navegação lateral e topbar para rotas (`/`, `/tasks`, `/docs`, `/debt`).

### Sprint 2 - Dashboard Visualization
**Objetivo:** Renderizar os painéis da aplicação (Overview, Tasks, Explorer, Debt).

- [x] (Done) **Overview Panel**: Página inicial com métricas, dependendo do `PROJECT_BRIEF.md` e `PROJECT_STATUS.md`.
- [x] (Done) **Task Board**: Interface visual Kanban lendo do `PROJECT_TASKS.md`.
- [x] (Done) **Document Explorer**: Árvore navegável de `docs/` e renderizador avançado de sintaxe Markdown.
- [x] (Done) **Tech Debt Panel**: Tabela de TODOs e FIXMEs processada a partir dos markdowns.

### Sprint 3 - CLI Foundation & Context Orchestration
**Objetivo**: Implementação da CLI (`@devos/cli`) para gestão do ciclo de vida dos projetos e orquestração de contexto.

- [x] (Done) **CLI Package Core**: Estrutura do módulo `cli/` com TypeScript e Commander.js (`cli/src/index.ts`).
- [x] (Done) **Comando devos init**: Inicialização de projetos, criação de diretórios (`.devos/`, `docs/`) e registro no workspace global (`~/.devos/workspace.json`).
- [x] (Done) **Comando devos doctor**: Engine de diagnóstico (`doctor-engine.ts`) com validação sintática, auditoria de arquivos obrigatórios, scanner de TODOs/FIXMEs e suporte à flag `--ci`.
- [x] (Done) **Comando devos dashboard**: Subida do servidor local Next.js com fallback automático e silencioso de porta (3000 -> 3001...) e abertura automática do browser.
- [x] (Done) **Comandos devos generate & update**: Empacotamento de contextos de documentação para o Clipboard via `clipboardy` e exportação em `.devos/out/`.


---

# Instruções de Atualização
Atualize os arquivos de documentação para refletir com precisão o estado atual do projeto.