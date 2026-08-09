# AI WORKFLOW

## Objetivo

Este documento define o fluxo obrigatório que toda IA deve seguir antes, durante e após qualquer tarefa.

O objetivo é garantir previsibilidade, consistência e qualidade durante todo o desenvolvimento.

---

# Fluxo Geral

Toda tarefa deve seguir obrigatoriamente o fluxo abaixo.

Receber Solicitação

↓

Compreender Objetivo

↓

Ler PROJECT_BRIEF.md

↓

Ler PROJECT_STATUS.md

↓

Ler PROJECT_TASKS.md

↓

Ler documentação relevante em docs/

↓

Analisar impactos

↓

Planejar implementação

↓

Executar tarefa

↓

Validar implementação

↓

Atualizar documentação

↓

Atualizar PROJECT_STATUS

↓

Atualizar PROJECT_TASKS

↓

Atualizar CHANGELOG

↓

Atualizar TECH_DEBT (se necessário)

↓

Atualizar .ai/memory.md (caso exista alguma decisão importante)

↓

Finalizar

---

# Antes de Desenvolver

Sempre verificar:

- Objetivo da tarefa
- Escopo
- Regras de negócio
- Arquitetura
- Banco
- Dependências
- Tecnologias
- Impactos

---

# Durante o Desenvolvimento

Sempre:

- seguir padrões do projeto
- reutilizar componentes
- evitar duplicação
- manter consistência
- respeitar arquitetura
- atualizar documentação quando necessário

---

# Após o Desenvolvimento

Sempre verificar:

- Build
- Typecheck
- Lint
- Testes
- Documentação
- Pendências

---

# Atualização da Documentação

Caso alguma informação tenha sido alterada, atualizar os documentos correspondentes.

Nunca deixar documentação inconsistente.

---

# Atualização da Memória

Registrar em .ai/memory.md apenas decisões importantes e permanentes.

Não registrar detalhes temporários.

---

# Encerramento

Antes de concluir qualquer tarefa:

- resumir o que foi feito
- listar arquivos alterados
- informar impactos
- informar pendências
- sugerir próximo passo